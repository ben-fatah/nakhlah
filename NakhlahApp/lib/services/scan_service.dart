import 'dart:io';
import 'package:dio/dio.dart';

/// Response from POST /predict
class ScanApiResult {
  final String label;
  final String nameAr;
  final double confidence;
  final String originEn;
  final String originAr;
  final int calories;
  final int carbs;
  final int fiber;
  final int potassium;

  const ScanApiResult({
    required this.label,
    required this.nameAr,
    required this.confidence,
    required this.originEn,
    required this.originAr,
    required this.calories,
    required this.carbs,
    required this.fiber,
    required this.potassium,
  });

  factory ScanApiResult.fromJson(Map<String, dynamic> j) => ScanApiResult(
        label:      j['label'] as String,
        nameAr:     j['nameAr'] as String,
        confidence: (j['confidence'] as num).toDouble(),
        originEn:   j['originEn'] as String,
        originAr:   j['originAr'] as String,
        calories:   (j['calories'] as num).toInt(),
        carbs:      (j['carbs'] as num).toInt(),
        fiber:      (j['fiber'] as num).toInt(),
        potassium:  (j['potassium'] as num).toInt(),
      );
}

class ScanService {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://nakhlah-1.onrender.com',
  );
  static const String _apiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue: 'c2f3c3a316aa6d95cb4cd3516f674f97',
  );

  /// Generous timeouts to survive Render free-tier cold starts.
  /// Cold start: server wakes up + loads ~200 MB model = up to 60 s.
  /// Inference itself is fast (~1–2 s on CPU) once warm.
  static final _dio = Dio(
    BaseOptions(
      baseUrl:        _baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 90),
      headers: {'X-API-Key': _apiKey},
    ),
  );

  /// Fire-and-forget warmup.  Call this once when the app starts
  /// (e.g. in main() after Firebase init) so the Render instance wakes
  /// up before the user taps Scan.
  ///
  /// Errors are swallowed — warmup failure must never block the UI.
  static Future<void> warmup() async {
    try {
      await _dio.get<dynamic>(
        '/warmup',
        options: Options(
          receiveTimeout: const Duration(seconds: 90),
          sendTimeout: const Duration(seconds: 10),
        ),
      );
    } catch (_) {
      // Intentionally ignored — this is a best-effort pre-warm.
    }
  }

  /// Sends [imageFile] to the API and returns a [ScanApiResult].
  ///
  /// Retries once on timeout (covers the case where warmup was not called
  /// and the server is still booting on the first attempt).
  /// Throws [ScanServiceException] on any unrecoverable error.
  static Future<ScanApiResult> classify(File imageFile) async {
    return _classifyWithRetry(imageFile, retries: 1);
  }

  static Future<ScanApiResult> _classifyWithRetry(
    File imageFile, {
    required int retries,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.uri.pathSegments.last,
        ),
      });

      final response = await _dio.post<dynamic>(
        '/predict',
        data: formData,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        // Guard against non-map responses (e.g. HTML error pages)
        if (data is! Map<String, dynamic>) {
          throw ScanServiceException(
            'Unexpected response format from server. Please try again.',
          );
        }
        return ScanApiResult.fromJson(data);
      }

      throw ScanServiceException(
        'Unexpected status ${response.statusCode}',
      );
    } on DioException catch (e) {
      final isTimeout = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout;

      if (isTimeout && retries > 0) {
        // The server was cold-starting. Give it another try with a longer
        // window — by now it should be up.
        return _classifyWithRetry(imageFile, retries: retries - 1);
      }

      throw ScanServiceException(_dioErrorMessage(e));
    } on ScanServiceException {
      rethrow;
    } catch (e) {
      throw ScanServiceException('Unexpected error: $e');
    }
  }

  static String _dioErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Could not reach the server. Check your internet connection.';
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Server is taking too long to respond. The server may be '
            'waking up — please try again in a moment.';
      case DioExceptionType.badResponse:
        final code   = e.response?.statusCode;
        final detail = _extractDetail(e.response?.data);
        if (code == 401) return 'Authentication failed. Contact support.';
        if (code == 413) return 'Image is too large (max 5 MB).';
        if (code == 415) return 'Unsupported image format. Use JPEG or PNG.';
        if (code == 422) return 'Could not read image: $detail';
        return 'Server error ($code): $detail';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  /// Safely extracts the "detail" field from an error response body,
  /// handling both Map<String,dynamic> and plain String bodies
  /// (e.g. Render sometimes returns HTML on gateway errors).
  static String _extractDetail(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['detail']?.toString() ?? 'Unknown error';
    }
    if (data is String && data.length < 200) return data;
    return 'Unknown error';
  }
}

class ScanServiceException implements Exception {
  final String message;
  const ScanServiceException(this.message);
  @override
  String toString() => message;
}