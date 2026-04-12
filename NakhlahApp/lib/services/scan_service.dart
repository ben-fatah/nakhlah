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
    label: j['label'] as String,
    nameAr: j['nameAr'] as String,
    confidence: (j['confidence'] as num).toDouble(),
    originEn: j['originEn'] as String,
    originAr: j['originAr'] as String,
    calories: (j['calories'] as num).toInt(),
    carbs: (j['carbs'] as num).toInt(),
    fiber: (j['fiber'] as num).toInt(),
    potassium: (j['potassium'] as num).toInt(),
  );
}

class ScanService {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://nakhlah-ai.onrender.com', // ← your Render URL
  );
  static const String _apiKey = String.fromEnvironment(
    'API_KEY',
    defaultValue: 'change-me', // ← from Render env
  );

  static final _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'X-API-Key': _apiKey},
    ),
  );

  /// Sends [imageFile] to the API and returns a [ScanApiResult].
  /// Throws [ScanServiceException] on any error.
  static Future<ScanApiResult> classify(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.uri.pathSegments.last,
        ),
      });

      final response = await _dio.post<Map<String, dynamic>>(
        '/predict',
        data: formData,
      );

      if (response.statusCode == 200 && response.data != null) {
        return ScanApiResult.fromJson(response.data!);
      }
      throw ScanServiceException('Unexpected status ${response.statusCode}');
    } on DioException catch (e) {
      final msg = _dioErrorMessage(e);
      throw ScanServiceException(msg);
    }
  }

  static String _dioErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Request timed out. The server may be starting up — try again.';
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        final detail = (e.response?.data as Map?)?['detail'] ?? 'Unknown error';
        if (code == 401) return 'Authentication failed.';
        if (code == 413) return 'Image is too large (max 5 MB).';
        if (code == 415) return 'Unsupported image format.';
        return 'Server error ($code): $detail';
      case DioExceptionType.connectionError:
        return 'No connection. Check your internet.';
      default:
        return 'Something went wrong: ${e.message}';
    }
  }
}

class ScanServiceException implements Exception {
  final String message;
  const ScanServiceException(this.message);
  @override
  String toString() => message;
}
