import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A single scan history entry.
class ScanHistoryEntry {
  final String id;
  final String nameEn;
  final String nameAr;
  final String originEn;
  final String originAr;
  final double confidence;
  final int calories;
  final int carbs;
  final int fiber;
  final int potassium;
  final String? imageUrl;
  final String imagePath; // local asset path fallback
  final DateTime scannedAt;

  ScanHistoryEntry({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.originEn,
    required this.originAr,
    required this.confidence,
    required this.calories,
    required this.carbs,
    required this.fiber,
    required this.potassium,
    this.imageUrl,
    required this.imagePath,
    required this.scannedAt,
  });

  int get matchPercent => (confidence * 100).round();

  Map<String, dynamic> toJson() => {
    'id': id,
    'nameEn': nameEn,
    'nameAr': nameAr,
    'originEn': originEn,
    'originAr': originAr,
    'confidence': confidence,
    'calories': calories,
    'carbs': carbs,
    'fiber': fiber,
    'potassium': potassium,
    'imageUrl': imageUrl,
    'imagePath': imagePath,
    'scannedAt': scannedAt.toIso8601String(),
  };

  factory ScanHistoryEntry.fromJson(Map<String, dynamic> json) =>
      ScanHistoryEntry(
        id: json['id'] as String,
        nameEn: json['nameEn'] as String,
        nameAr: json['nameAr'] as String,
        originEn: json['originEn'] as String,
        originAr: json['originAr'] as String,
        confidence: (json['confidence'] as num).toDouble(),
        calories: (json['calories'] as num).toInt(),
        carbs: (json['carbs'] as num).toInt(),
        fiber: (json['fiber'] as num).toInt(),
        potassium: (json['potassium'] as num).toInt(),
        imageUrl: json['imageUrl'] as String?,
        imagePath: json['imagePath'] as String? ?? '',
        scannedAt: DateTime.parse(json['scannedAt'] as String),
      );
}

/// Global scan history state — persisted to [SharedPreferences].
final scanHistoryNotifier = ScanHistoryNotifier();

class ScanHistoryNotifier extends ValueNotifier<List<ScanHistoryEntry>> {
  static const _prefsKey = 'scan_history';
  SharedPreferences? _prefs;

  ScanHistoryNotifier() : super([]);

  void init(SharedPreferences prefs) {
    if (_prefs == prefs) return;
    _prefs = prefs;
    _load();
  }

  void _load() {
    final raw = _prefs?.getString(_prefsKey);
    if (raw == null) return;
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => ScanHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      value = list;
    } catch (_) {
      value = [];
    }
  }

  void _persist() {
    final encoded = jsonEncode(value.map((e) => e.toJson()).toList());
    _prefs?.setString(_prefsKey, encoded);
  }

  void add(ScanHistoryEntry entry) {
    value = [entry, ...value];
    _persist();
  }

  void remove(String id) {
    value = value.where((e) => e.id != id).toList();
    _persist();
  }

  void clear() {
    value = [];
    _persist();
  }
}
