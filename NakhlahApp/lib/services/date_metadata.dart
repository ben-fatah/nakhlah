import 'dart:convert';
import 'package:flutter/services.dart';

/// Metadata for a single date variety, mirroring the backend DATE_METADATA dict.
class DateMeta {
  final String nameAr;
  final String originEn;
  final String originAr;
  final int calories;
  final int carbs;
  final int fiber;
  final int potassium;

  const DateMeta({
    required this.nameAr,
    required this.originEn,
    required this.originAr,
    required this.calories,
    required this.carbs,
    required this.fiber,
    required this.potassium,
  });

  factory DateMeta.fromJson(Map<String, dynamic> json) => DateMeta(
        nameAr: json['nameAr'] as String? ?? '',
        originEn: json['originEn'] as String? ?? '',
        originAr: json['originAr'] as String? ?? '',
        calories: (json['calories'] as num?)?.toInt() ?? 0,
        carbs: (json['carbs'] as num?)?.toInt() ?? 0,
        fiber: (json['fiber'] as num?)?.toInt() ?? 0,
        potassium: (json['potassium'] as num?)?.toInt() ?? 0,
      );
}

/// Loads and caches date metadata from the bundled JSON asset.
///
/// Call [DateMetadataLoader.instance] after [WidgetsFlutterBinding.ensureInitialized].
/// The map is identical to the Python backend's DATE_METADATA dict.
class DateMetadataLoader {
  DateMetadataLoader._();
  static DateMetadataLoader? _instance;
  static DateMetadataLoader get instance {
    _instance ??= DateMetadataLoader._();
    return _instance!;
  }

  Map<String, DateMeta>? _cache;

  /// Load and parse the JSON asset once; return cached map on repeat calls.
  Future<Map<String, DateMeta>> load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/models/date_metadata.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    _cache = decoded.map(
      (key, value) =>
          MapEntry(key.toLowerCase(), DateMeta.fromJson(value as Map<String, dynamic>)),
    );
    return _cache!;
  }

  /// Synchronous lookup after [load()] has been called at startup.
  DateMeta? lookup(String label) => _cache?[label.trim().toLowerCase()];
}
