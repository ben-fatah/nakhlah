/// Holds the data returned by the AI classification model for a single scan.
class ScanResult {
  final String nameEn;
  final String nameAr;
  final String originEn;
  final String originAr;
  final double confidence;
  final int calories;
  final int carbs;
  final int fiber;
  final int potassium;

  /// Network image URL returned by the API (optional).
  final String? imageUrl;

  /// ✅ Local file path of the image the user captured/picked.
  /// This is what gets displayed on the result screen.
  final String? localImagePath;

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
    this.localImagePath,
  });

  String localizedName(bool isArabic) => isArabic ? nameAr : nameEn;
  String localizedOrigin(bool isArabic) => isArabic ? originAr : originEn;
  String get confidencePercent => '${(confidence * 100).round()}%';
}
