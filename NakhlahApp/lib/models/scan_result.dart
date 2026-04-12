/// Holds the data returned by the AI classification model for a single scan.
///
/// Both English and Arabic strings are stored so the result screen can
/// switch language without a network round-trip.
class ScanResult {
  /// Display name in English — e.g. "Medjool Date".
  final String nameEn;

  /// Display name in Arabic — e.g. "تمر المجدول".
  final String nameAr;

  /// Origin/region label in English — e.g. "Al Madinah, Saudi Arabia".
  final String originEn;

  /// Origin/region label in Arabic — e.g. "المدينة المنورة، السعودية".
  final String originAr;

  /// Model confidence in the range 0.0–1.0 (e.g. 0.98 = 98 %).
  final double confidence;

  // ── Nutrition per 100 g ────────────────────────────────────────────────────

  final int calories;    // kcal
  final int carbs;       // g
  final int fiber;       // g
  final int potassium;   // mg

  /// Optional network image URL returned by the API.
  /// When null the result screen falls back to a generic icon.
  final String? imageUrl;

  const ScanResult({
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
  });

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Returns the variety name in the currently active locale.
  String localizedName(bool isArabic) => isArabic ? nameAr : nameEn;

  /// Returns the origin string in the currently active locale.
  String localizedOrigin(bool isArabic) => isArabic ? originAr : originEn;

  /// Confidence as a whole-number percentage string — e.g. "98%".
  String get confidencePercent => '${(confidence * 100).round()}%';
}
