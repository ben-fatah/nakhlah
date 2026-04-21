import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:onnxruntime/onnxruntime.dart';
import 'package:path_provider/path_provider.dart';

import '../models/scan_result.dart';
import 'date_metadata.dart';

// ── Constants ─────────────────────────────────────────────────────────────────

/// Asset path of the robust v1 ONNX model (EfficientNet-B2, 17 classes).
/// Exported from nakhlah_robust_v1_best.pth with opset=11, IR=9.
const String _kModelAsset = 'assets/models/nakhlah_robust_v1.onnx';

/// Name used when extracting the model to the documents directory.
/// Bump this name whenever the model file changes so the sentinel forces
/// re-extraction and the old stale file on-device is replaced.
const String _kModelFileName = 'nakhlah_robust_v1.onnx';

/// Sentinel file written alongside the model so we can detect a stale extract.
/// Contents = model asset key. If it doesn't match, we delete + re-extract.
const String _kSentinelFileName = 'nakhlah_model.sentinel';
const String _kSentinelContents = _kModelAsset; // change if model changes

/// Model input resolution (must match training cfg.img_size = 260).
const int _kModelInputSize = 260;

/// Resize target: 260 + 32 (mirrors Python T.Resize(SZ + 32)).
const int _kResizeSize = 292;

/// ImageNet normalisation — from nakhlah_model_v2_metadata.json.
const List<double> _kMean = [0.485, 0.456, 0.406];
const List<double> _kStd  = [0.229, 0.224, 0.225];

/// Class labels in the same order as model output logits.
/// Must exactly match the training order from nakhlah_robust_v1_metadata.json.
const List<String> _kClassNames = [
  'ajwa', 'allig', 'amber', 'aseel', 'deglet_nour',
  'galaxy', 'kalmi', 'khorma', 'medjool', 'meneifi',
  'muzafati', 'nabtat_ali', 'rutab', 'shaishe',
  'sokari', 'sugaey', 'zahidi',
];

/// How long to wait for a single inference before declaring a timeout.
const Duration _kInferenceTimeout = Duration(seconds: 30);

// ── Isolate payloads ──────────────────────────────────────────────────────────

/// Sent from the main isolate → inference isolate.
class _InferRequest {
  final String imagePath;
  final String modelPath;
  final SendPort replyPort;
  const _InferRequest(this.imagePath, this.modelPath, this.replyPort);
}

/// Sent back from the inference isolate → main isolate.
class _InferResult {
  final String? label;
  final double? confidence;
  final String? error;
  const _InferResult({this.label, this.confidence, this.error});
}

// ── Top-level isolate entry point ─────────────────────────────────────────────
// Must be a top-level (non-closure) function for Isolate.spawn.

void _inferenceIsolateMain(SendPort mainSendPort) {
  // Reply with our receive port so the main isolate can send us requests.
  final receivePort = ReceivePort();
  mainSendPort.send(receivePort.sendPort);

  // onnxruntime requires explicit OrtEnv.init() in every isolate before
  // creating any OrtSession — without this the session build throws on Android.
  OrtEnv.instance.init();

  // Session is lazily created on first request and reused thereafter.
  // If session creation fails we null it out so the next request retries
  // (which will also fail and propagate the error, rather than hanging).
  OrtSession? session;

  receivePort.listen((dynamic message) {
    if (message == null) {
      // Graceful shutdown signal.
      session?.release();
      receivePort.close();
      return;
    }

    final req = message as _InferRequest;
    try {
      // Build session once; if previously failed, session is null here and
      // we attempt again (to propagate the real error each time).
      session ??= _buildSession(req.modelPath);
      final result = _infer(session!, req.imagePath);
      req.replyPort.send(_InferResult(
        label: result.label,
        confidence: result.confidence,
      ));
    } catch (e, st) {
      // On session-build failure, null it so the next call retries cleanly.
      session = null;
      req.replyPort.send(_InferResult(error: '$e\n$st'));
    }
  });
}

// ── Session factory ───────────────────────────────────────────────────────────

OrtSession _buildSession(String modelPath) {
  // Verify file exists before handing path to native layer.
  final file = File(modelPath);
  if (!file.existsSync()) {
    throw LocalInferenceException(
      'Model file not found at $modelPath — re-extract required.',
    );
  }

  final options = OrtSessionOptions()
    ..setIntraOpNumThreads(2)
    ..setInterOpNumThreads(1)
    ..setSessionGraphOptimizationLevel(GraphOptimizationLevel.ortEnableAll);

  // Hardware acceleration — silently skip if provider unavailable.
  try { options.appendNnapiProvider(NnapiFlags.cpuDisabled); } catch (_) {}
  try { options.appendCoreMLProvider(CoreMLFlags.useCpuOnly); } catch (_) {}

  return OrtSession.fromFile(file, options);
}

// ── Inference ─────────────────────────────────────────────────────────────────

class _TopResult {
  final String label;
  final double confidence;
  _TopResult(this.label, this.confidence);
}

_TopResult _infer(OrtSession session, String imagePath) {
  // Step 1: Preprocess image → CHW Float32List
  final tensor = _preprocess(imagePath);

  // Step 2: Create OrtValue input tensor — shape [1, 3, 260, 260]
  const int c = 3;
  const int h = _kModelInputSize;
  const int w = _kModelInputSize;
  final inputTensor = OrtValueTensor.createTensorWithDataList(
    tensor,
    [1, c, h, w],
  );

  final runOptions = OrtRunOptions();
  final inputs = {session.inputNames.first: inputTensor};

  // Step 3: Run inference
  final outputs = session.run(runOptions, inputs);
  inputTensor.release();
  runOptions.release();

  // Step 4: Extract logits — shape [1, 9] → flat list
  final outTensor = outputs.first as OrtValueTensor;
  final logitsRaw = outTensor.value as List<List<double>>;
  final List<double> logits = logitsRaw[0];
  outTensor.release();

  // Step 5: Numerically stable softmax
  final double maxLogit = logits.reduce(math.max);
  final expVals = logits.map((x) => math.exp(x - maxLogit)).toList();
  final double sumExp = expVals.reduce((a, b) => a + b);
  final probs = expVals.map((e) => e / sumExp).toList();

  // Step 6: Top-1
  int topIdx = 0;
  for (int i = 1; i < probs.length; i++) {
    if (probs[i] > probs[topIdx]) topIdx = i;
  }

  return _TopResult(_kClassNames[topIdx], probs[topIdx]);
}

// ── Preprocessing — mirrors Python eval_transform exactly ─────────────────────
//
//   T.Resize(292)           → resize shortest side to 292 px
//   T.CenterCrop(260)       → crop centre to 260×260
//   T.ToTensor()            → HWC uint8 [0,255] → CHW float32 [0,1]
//   T.Normalize(mean, std)  → (pixel - mean) / std

Float32List _preprocess(String imagePath) {
  final bytes = File(imagePath).readAsBytesSync();
  img.Image? decoded = img.decodeImage(bytes);
  if (decoded == null) throw Exception('Cannot decode image at $imagePath');

  // Drop alpha channel if present
  if (decoded.numChannels == 4) {
    decoded = img.Image.fromBytes(
      width: decoded.width,
      height: decoded.height,
      bytes: decoded.getBytes().buffer,
      numChannels: 3,
    );
  }

  // Step 1: Resize so *shorter* side = _kResizeSize
  final int w = decoded.width;
  final int h = decoded.height;
  final img.Image resized;
  if (w <= h) {
    resized = img.copyResize(
      decoded,
      width: _kResizeSize,
      interpolation: img.Interpolation.linear,
    );
  } else {
    resized = img.copyResize(
      decoded,
      height: _kResizeSize,
      interpolation: img.Interpolation.linear,
    );
  }

  // Step 2: CenterCrop to _kModelInputSize × _kModelInputSize
  final int rw = resized.width;
  final int rh = resized.height;
  final int x0 = (rw - _kModelInputSize) ~/ 2;
  final int y0 = (rh - _kModelInputSize) ~/ 2;
  final img.Image cropped = img.copyCrop(
    resized,
    x: x0,
    y: y0,
    width: _kModelInputSize,
    height: _kModelInputSize,
  );

  // Step 3: ToTensor + Normalize → CHW Float32List
  final int pixelCount = _kModelInputSize * _kModelInputSize;
  final Float32List out = Float32List(3 * pixelCount);

  for (int py = 0; py < _kModelInputSize; py++) {
    for (int px = 0; px < _kModelInputSize; px++) {
      final pixel = cropped.getPixel(px, py);
      final int idx = py * _kModelInputSize + px;
      out[0 * pixelCount + idx] = (pixel.r / 255.0 - _kMean[0]) / _kStd[0];
      out[1 * pixelCount + idx] = (pixel.g / 255.0 - _kMean[1]) / _kStd[1];
      out[2 * pixelCount + idx] = (pixel.b / 255.0 - _kMean[2]) / _kStd[2];
    }
  }

  return out;
}

// ── Local Inference Service (singleton) ──────────────────────────────────────

/// Singleton that manages a long-lived background [Isolate] for ONNX inference.
///
/// All heavy work runs off the UI thread:
///   - ONNX model load (once)
///   - Image decode, resize, crop, normalize
///   - OrtSession.run()
///
/// Usage:
/// ```dart
/// // In main(): await LocalInferenceService.instance.init();
/// // In scan flow:
/// final result = await LocalInferenceService.instance.classify(imageFile);
/// ```
class LocalInferenceService {
  LocalInferenceService._();
  static final LocalInferenceService instance = LocalInferenceService._();

  Isolate? _isolate;
  SendPort? _toIsolateSendPort;
  bool _ready = false;
  String? _cachedModelPath;

  // ── Startup ──────────────────────────────────────────────────────────────

  /// Extract the ONNX asset to the app documents dir.
  ///
  /// Uses a sentinel file to detect a stale / wrong model version and forces
  /// re-extraction when the sentinel content doesn't match [_kSentinelContents].
  /// This handles the case where an old IR-10 model was previously cached.
  Future<String> _ensureModelExtracted() async {
    if (_cachedModelPath != null) return _cachedModelPath!;

    final dir      = await getApplicationDocumentsDirectory();
    final modelFile    = File('${dir.path}/$_kModelFileName');
    final sentinelFile = File('${dir.path}/$_kSentinelFileName');

    // Check sentinel to detect stale / wrong model on device.
    bool stale = true;
    if (modelFile.existsSync() && sentinelFile.existsSync()) {
      final sentinel = sentinelFile.readAsStringSync().trim();
      stale = sentinel != _kSentinelContents;
    }

    if (stale) {
      // Delete any old model file (wrong IR version, different name, etc.)
      if (modelFile.existsSync()) await modelFile.delete();

      // Extract fresh copy from bundle.
      final data = await rootBundle.load(_kModelAsset);
      await modelFile.writeAsBytes(data.buffer.asUint8List(), flush: true);

      // Write sentinel so next launch skips extraction.
      await sentinelFile.writeAsString(_kSentinelContents, flush: true);
    }

    _cachedModelPath = modelFile.path;
    return _cachedModelPath!;
  }

  /// Spawn the inference isolate and wait for its [SendPort].
  ///
  /// Safe to call multiple times — subsequent calls return immediately if
  /// already initialised. Also used internally to restart after a crash.
  Future<void> init() async {
    if (_ready) return;

    _cachedModelPath = await _ensureModelExtracted();

    final receivePort = ReceivePort();
    _isolate = await Isolate.spawn<SendPort>(
      _inferenceIsolateMain,
      receivePort.sendPort,
      debugName: 'NakhlahONNX',
      errorsAreFatal: false, // let Dart errors come back as _InferResult.error
    );
    _toIsolateSendPort = await receivePort.first as SendPort;
    _ready = true;
  }

  /// Tear down the current isolate and reset state so [init] can restart it.
  void _reset() {
    _toIsolateSendPort?.send(null); // ask isolate to shut down gracefully
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _toIsolateSendPort = null;
    _ready = false;
    // Keep _cachedModelPath — no need to re-extract the file.
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Classify an image file and return a fully-populated [ScanResult].
  ///
  /// Throws [LocalInferenceException] on failure.
  Future<ScanResult> classify(File imageFile) async {
    // Re-init if isolate died or was never started.
    if (!_ready) await init();

    // Ensure metadata is loaded even if main() fire-and-forget hasn't completed yet.
    await DateMetadataLoader.instance.load();

    final replyPort = ReceivePort();
    _toIsolateSendPort!.send(
      _InferRequest(imageFile.path, _cachedModelPath!, replyPort.sendPort),
    );

    // Wait for result with a hard timeout to prevent the UI from hanging
    // forever if the isolate crashes without sending a reply.
    final _InferResult response;
    try {
      response = await replyPort.first
          .timeout(_kInferenceTimeout)
          .then((v) => v as _InferResult);
    } on TimeoutException {
      replyPort.close();
      // Isolate is likely dead — reset so next call spawns a fresh one.
      _reset();
      throw const LocalInferenceException(
        'Inference timed out. The model may have crashed. Please try again.',
      );
    } finally {
      replyPort.close();
    }

    if (response.error != null) {
      // On a session-build error we restart the isolate so the next scan gets
      // a fresh session rather than hanging on a dead isolate.
      _reset();
      throw LocalInferenceException(response.error!);
    }

    final label      = response.label!;
    final confidence = response.confidence!;
    final meta       = DateMetadataLoader.instance.lookup(label);

    return ScanResult(
      nameEn:     label,
      nameAr:     meta?.nameAr  ?? label,
      originEn:   meta?.originEn ?? '',
      originAr:   meta?.originAr ?? '',
      confidence: confidence,
      calories:   meta?.calories  ?? 0,
      carbs:      meta?.carbs     ?? 0,
      fiber:      meta?.fiber     ?? 0,
      potassium:  meta?.potassium ?? 0,
      localImagePath: imageFile.path,
    );
  }

  // ── Teardown ──────────────────────────────────────────────────────────────

  /// Shut down the isolate cleanly. Call only on full app exit.
  void dispose() => _reset();
}

// ── Exception ─────────────────────────────────────────────────────────────────

class LocalInferenceException implements Exception {
  final String message;
  const LocalInferenceException(this.message);

  @override
  String toString() => 'LocalInferenceException: $message';
}
