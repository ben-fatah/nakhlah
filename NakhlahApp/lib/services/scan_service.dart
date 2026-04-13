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

  factory ScanApiResult.fromJson(Map<String, dynamic> j) {
    return ScanApiResult(
      label: _str(j, 'label'),
      nameAr: _str(j, 'nameAr'),
      confidence: _dbl(j, 'confidence'),
      originEn: _str(j, 'originEn'),
      originAr: _str(j, 'originAr'),
      calories: _int(j, 'calories'),
      carbs: _int(j, 'carbs'),
      fiber: _int(j, 'fiber'),
      potassium: _int(j, 'potassium'),
    );
  }

  static String _str(Map<String, dynamic> j, String key) =>
      (j[key] as String?) ?? '';
  static double _dbl(Map<String, dynamic> j, String key) =>
      (j[key] as num?)?.toDouble() ?? 0.0;
  static int _int(Map<String, dynamic> j, String key) =>
      (j[key] as num?)?.toInt() ?? 0;
}

class ScanService {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://nakhlah-1.onrender.com',
  );

  // The actual API key configured on Render.
  // Override at build time with: --dart-define=API_KEY=your-key
  static const String _apiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue: 'c2f3c3a316aa6d95cb4cd3516f674f97',
  );

  static final _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 90),
      headers: {'X-API-Key': _apiKey},
    ),
  );

  /// Fire-and-forget warmup to reduce cold-start latency.
  static Future<void> warmup() async {
    try {
      await _dio.get<dynamic>(
        '/warmup',
        options: Options(
          receiveTimeout: const Duration(seconds: 90),
          sendTimeout: const Duration(seconds: 10),
        ),
      );
    } catch (_) {}
  }

  /// Sends [imageFile] to POST /predict and returns a [ScanApiResult].
  /// Retries once on timeout to handle cold-start.
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

      final response = await _dio.post<dynamic>('/predict', data: formData);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is! Map<String, dynamic>) {
          throw ScanServiceException(
            'Unexpected response from server. Please try again.',
          );
        }
        return ScanApiResult.fromJson(data);
      }

      throw ScanServiceException('Server error (${response.statusCode}).');
    } on DioException catch (e) {
      final isTimeout =
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout;

      if (isTimeout && retries > 0) {
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
        return 'Server is waking up — please try again in a moment.';
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
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
