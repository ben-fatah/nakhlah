import 'package:cloud_firestore/cloud_firestore.dart';

import '../l10n/app_localizations.dart';

/// A date variety (used on the Explore screen).
///
/// Currently populated with static data; the [fromFirestore] / [toFirestore]
/// methods are ready for a future Firestore-backed catalogue.
class DateVariety {
  final String Function(AppLocalizations l) nameGetter;
  final String Function(AppLocalizations l) originGetter;
  final String Function(AppLocalizations l) descriptionGetter;
  final int kcal;
  final int carbs;
  final int fiber;
  final int potassium;
  final double price;
  final String imagePath;
  final String tag;

  const DateVariety({
    required this.nameGetter,
    required this.originGetter,
    required this.descriptionGetter,
    required this.kcal,
    required this.carbs,
    required this.fiber,
    required this.potassium,
    required this.price,
    required this.imagePath,
    required this.tag,
  });

  /// Create a [DateVariety] from a Firestore document.
  factory DateVariety.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    final name = data['name'] as String? ?? '';
    final origin = data['origin'] as String? ?? '';
    final description = data['description'] as String? ?? '';
    return DateVariety(
      nameGetter: (_) => name,
      originGetter: (_) => origin,
      descriptionGetter: (_) => description,
      kcal: (data['kcal'] as num?)?.toInt() ?? 0,
      carbs: (data['carbs'] as num?)?.toInt() ?? 0,
      fiber: (data['fiber'] as num?)?.toInt() ?? 0,
      potassium: (data['potassium'] as num?)?.toInt() ?? 0,
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      imagePath: data['imagePath'] as String? ?? '',
      tag: data['tag'] as String? ?? '',
    );
  }

  /// Serialize to Firestore-compatible map.
  Map<String, dynamic> toFirestore() {
    return {
      'kcal': kcal,
      'carbs': carbs,
      'fiber': fiber,
      'potassium': potassium,
      'price': price,
      'imagePath': imagePath,
      'tag': tag,
    };
  }

  /// Returns a copy with selected fields overridden.
  DateVariety copyWith({
    String Function(AppLocalizations l)? nameGetter,
    String Function(AppLocalizations l)? originGetter,
    String Function(AppLocalizations l)? descriptionGetter,
    int? kcal,
    int? carbs,
    int? fiber,
    int? potassium,
    double? price,
    String? imagePath,
    String? tag,
  }) {
    return DateVariety(
      nameGetter: nameGetter ?? this.nameGetter,
      originGetter: originGetter ?? this.originGetter,
      descriptionGetter: descriptionGetter ?? this.descriptionGetter,
      kcal: kcal ?? this.kcal,
      carbs: carbs ?? this.carbs,
      fiber: fiber ?? this.fiber,
      potassium: potassium ?? this.potassium,
      price: price ?? this.price,
      imagePath: imagePath ?? this.imagePath,
      tag: tag ?? this.tag,
    );
  }
}
