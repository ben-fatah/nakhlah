import 'package:cloud_firestore/cloud_firestore.dart';

import '../l10n/app_localizations.dart';

/// A market product (used on MarketScreen and ProductDetailScreen).
///
/// [id] is the stable identifier used for favorites tracking and seller
/// association. It matches the [tag] field for static data; Firestore-backed
/// products will carry the document ID.
///
/// Bilingual fields are expressed as getter functions so that the object
/// remains locale-agnostic — the caller resolves the displayed string by
/// passing the current [AppLocalizations] instance.
class Product {
  /// Stable product identifier (matches [tag] for static data).
  final String id;

  final String Function(AppLocalizations l) nameGetter;
  final String Function(AppLocalizations l) descriptionGetter;
  final double rating;
  final int reviews;
  final double price;
  final String Function(AppLocalizations l) unitGetter;
  final String imagePath;

  /// Category tag for filter chips (e.g. 'medjool', 'ajwa').
  final String tag;
  final bool isVerified;

  const Product({
    required this.id,
    required this.nameGetter,
    required this.descriptionGetter,
    required this.rating,
    required this.reviews,
    required this.price,
    required this.unitGetter,
    required this.imagePath,
    required this.tag,
    required this.isVerified,
  });

  // ── Firestore ──────────────────────────────────────────────────────────────

  /// Creates a [Product] from a Firestore document snapshot.
  ///
  /// Localized fields fall back to a single stored string because Firestore
  /// documents store the resolved text rather than a getter function.
  factory Product.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final name = data['name'] as String? ?? '';
    final description = data['description'] as String? ?? '';
    final unit = data['unit'] as String? ?? '';
    return Product(
      id: doc.id,
      nameGetter: (_) => name,
      descriptionGetter: (_) => description,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviews: (data['reviews'] as num?)?.toInt() ?? 0,
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      unitGetter: (_) => unit,
      imagePath: data['imagePath'] as String? ?? '',
      tag: data['tag'] as String? ?? '',
      isVerified: data['isVerified'] as bool? ?? false,
    );
  }

  /// Serializes this product to a Firestore-compatible map.
  Map<String, dynamic> toFirestore() {
    return {
      'rating': rating,
      'reviews': reviews,
      'price': price,
      'imagePath': imagePath,
      'tag': tag,
      'isVerified': isVerified,
      // Localized fields (name, description, unit) must be serialized by
      // the caller once the locale is resolved.
    };
  }

  /// Returns a new [Product] with the specified fields replaced.
  Product copyWith({
    String? id,
    String Function(AppLocalizations l)? nameGetter,
    String Function(AppLocalizations l)? descriptionGetter,
    double? rating,
    int? reviews,
    double? price,
    String Function(AppLocalizations l)? unitGetter,
    String? imagePath,
    String? tag,
    bool? isVerified,
  }) {
    return Product(
      id: id ?? this.id,
      nameGetter: nameGetter ?? this.nameGetter,
      descriptionGetter: descriptionGetter ?? this.descriptionGetter,
      rating: rating ?? this.rating,
      reviews: reviews ?? this.reviews,
      price: price ?? this.price,
      unitGetter: unitGetter ?? this.unitGetter,
      imagePath: imagePath ?? this.imagePath,
      tag: tag ?? this.tag,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
