import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../repositories/scan_repository.dart';
import '../services/local_inference_service.dart';
import 'scan_result_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  bool _flashOn = false;
  bool _isCameraInitialized = false;
  bool _isAnalyzing = false;
  File? _pickedImage;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initializeCamera();
  }

  // ── Camera ─────────────────────────────────────────────────────────────────

  Future<void> _initializeCamera() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera permission is required')),
          );
        }
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final controller = CameraController(
        cameras.first,
        ResolutionPreset.medium, // ⚡ medium instead of high — we compress anyway
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      _cameraController = controller;
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        _cameraController = null;
        return;
      }
      setState(() => _isCameraInitialized = true);
    } catch (e) {
      await _cameraController?.dispose();
      _cameraController = null;
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Camera error: $e')));
      }
    }
  }

  // ── Gallery ────────────────────────────────────────────────────────────────

  Future<void> _pickFromGallery() async {
    try {
      PermissionStatus status = await Permission.photos.request();
      if (!status.isGranted) status = await Permission.storage.request();

      if (status.isPermanentlyDenied) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Permission Required'),
              content: const Text(
                'Gallery access was permanently denied. Enable it in Settings.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    openAppSettings();
                  },
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );
        }
        return;
      }

      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gallery permission is required'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1080,
      );
      if (picked == null) return;

      setState(() {
        _pickedImage = File(picked.path);
        _isAnalyzing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).imagePicked),
            backgroundColor: const Color(0xFF5C3A1E),
            margin: const EdgeInsets.all(16),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open gallery: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── Capture / analyze ──────────────────────────────────────────────────────

  Future<void> _onCaptureTap() async {
    if (_pickedImage != null) {
      await _analyzeImage(_pickedImage!);
    } else if (_isCameraInitialized && _cameraController != null) {
      try {
        final XFile photo = await _cameraController!.takePicture();
        await _analyzeImage(File(photo.path));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Capture failed: $e')));
        }
      }
    }
  }

  /// Compress → local ONNX inference → save (local + Firebase) → navigate.
  Future<void> _analyzeImage(File rawImage) async {
    setState(() => _isAnalyzing = true);

    try {
      // ── Step 1: Compress image (target ≤ 150 KB) ─────────────────────────
      final compressed = await _compressImage(rawImage);

      // ── Step 2: Local ONNX inference (runs in background isolate) ──────────
      final result = await LocalInferenceService.instance.classify(compressed);

      if (!mounted) return;

      // ── Step 3: Hybrid save (local immediately, Firebase async) ────────────
      await ScanRepository.instance.saveScan(
        result: result,
        imageFile: compressed,
      );

      // ── Step 4: Navigate to result screen ─────────────────────────────────
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ScanResultScreen(result: result)),
        );
      }
    } on LocalInferenceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scan failed: $e'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  /// Compress an image to ≤ 150 KB, resizing to max 640 px on the longest side.
  ///
  /// The model only needs 260 px; compression at 640 px gives a comfortable
  /// 2× margin while staying well under the 150 KB target.
  Future<File> _compressImage(File source) async {
    try {
      final bytes = await source.readAsBytes();
      final original = img.decodeImage(bytes);
      if (original == null) return source;

      // Resize: longest side → 640 px
      img.Image resized;
      if (original.width >= original.height) {
        resized = img.copyResize(original, width: 640,
            interpolation: img.Interpolation.linear);
      } else {
        resized = img.copyResize(original, height: 640,
            interpolation: img.Interpolation.linear);
      }

      final compressed = img.encodeJpg(resized, quality: 80);

      // Write to a new temp file so the original is untouched
      final tmpDir = await getTemporaryDirectory();
      final outPath = '${tmpDir.path}/scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final outFile = await File(outPath).writeAsBytes(compressed);

      final kb = outFile.lengthSync() / 1024;
      debugPrint('[ScanScreen] Compressed: ${source.lengthSync() ~/ 1024} KB → ${kb.round()} KB');
      return outFile;
    } catch (e) {
      debugPrint('[ScanScreen] Compression failed (using original): $e');
      return source; // safe fallback — inference will still work
    }
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _cameraController?.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isAr = localeProvider.isArabic;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    _CircleButton(
                      icon: Icons.arrow_back,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            l.scanDateFruit,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.circle, size: 8, color: Color(0xFFD4A017)),
                              SizedBox(width: 6),
                              Text(
                                'NAKHLAH AI · OFFLINE',
                                style: TextStyle(
                                  color: Color(0xFFD4A017),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _CircleButton(
                      icon: _pickedImage != null ? Icons.close : Icons.help_outline,
                      onTap: () {
                        if (_pickedImage != null) {
                          setState(() => _pickedImage = null);
                        }
                      },
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Viewfinder
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Container(
                      height: MediaQuery.of(context).size.height * 0.42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFD4A017)
                              .withValues(alpha: _pulseAnimation.value),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4A017)
                                .withValues(alpha: _pulseAnimation.value * 0.5),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: _buildFrameContent(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Status label
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  _isAnalyzing
                      ? l.analyzing
                      : _pickedImage != null
                          ? l.imagePicked
                          : l.alignDate,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),

              const Spacer(),

              // Controls
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        _CircleButton(
                          icon: Icons.photo_library_outlined,
                          size: 52,
                          onTap: _pickFromGallery,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l.gallery,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 10),
                        ),
                      ],
                    ),
                    // Shutter
                    GestureDetector(
                      onTap: _isAnalyzing ? null : _onCaptureTap,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isAnalyzing
                              ? Colors.grey.shade700
                              : const Color(0xFF5C3A1E),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD4A017)
                                  .withValues(alpha: 0.3),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: _isAnalyzing
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFD4A017),
                                  strokeWidth: 3,
                                ),
                              )
                            : const Icon(
                                Icons.filter_center_focus,
                                color: Colors.white,
                                size: 36,
                              ),
                      ),
                    ),
                    Column(
                      children: [
                        _CircleButton(
                          icon: _flashOn ? Icons.flash_on : Icons.flash_off,
                          size: 52,
                          onTap: () async {
                            if (_cameraController == null) return;
                            try {
                              await _cameraController!.setFlashMode(
                                _flashOn ? FlashMode.off : FlashMode.torch,
                              );
                              setState(() => _flashOn = !_flashOn);
                            } catch (_) {}
                          },
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l.flash,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Progress / status bar
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_awesome,
                          color: Color(0xFFD4A017), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        _isAnalyzing ? l.analyzing : l.optimizing,
                        style: const TextStyle(
                          color: Color(0xFFD4A017),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 60),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _isAnalyzing ? null : 1.0,
                        backgroundColor: Colors.white12,
                        color: const Color(0xFF7D5A3C),
                        minHeight: 4,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrameContent() {
    if (_pickedImage != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(_pickedImage!, fit: BoxFit.cover),
          if (_isAnalyzing)
            Container(
              color: Colors.black.withValues(alpha: 0.4),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFFD4A017)),
              ),
            ),
        ],
      );
    }
    if (_isCameraInitialized && _cameraController != null) {
      return CameraPreview(_cameraController!);
    }
    return Container(
      color: Colors.black,
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4A017)),
        ),
      ),
    );
  }
}

// ── Reusable circle button ─────────────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white12,
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.45),
      ),
    );
  }
}
