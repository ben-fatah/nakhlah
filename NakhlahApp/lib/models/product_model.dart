import 'package:cloud_firestore/cloud_firestore.dart';

import '../l10n/app_localizations.dart';

/// A market product (used on the Market screen).
///
/// Currently populated with static data; the [fromFirestore] / [toFirestore]
/// methods are ready for a future Firestore-backed catalogue.
class Product {
  final String Function(AppLocalizations l) nameGetter;
  final double rating;
  final int reviews;
  final double price;
  final String Function(AppLocalizations l) unitGetter;
  final String imagePath;
  final String tag;
  final bool isVerified;

  const Product({
    required this.nameGetter,
    required this.rating,
    required this.reviews,
    required this.price,
    required this.unitGetter,
    required this.imagePath,
    required this.tag,
    required this.isVerified,
  });

  /// Create a [Product] from a Firestore document.
  ///
  /// Localized fields fall back to a single stored string (no function getter)
  /// when coming from the server.
  factory Product.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final name = data['name'] as String? ?? '';
    final unit = data['unit'] as String? ?? '';
    return Product(
      nameGetter: (_) => name,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviews: (data['reviews'] as num?)?.toInt() ?? 0,
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      unitGetter: (_) => unit,
      imagePath: data['imagePath'] as String? ?? '',
      tag: data['tag'] as String? ?? '',
      isVerified: data['isVerified'] as bool? ?? false,
    );
  }

  /// Serialize to Firestore-compatible map.
  Map<String, dynamic> toFirestore() {
    return {
      'rating': rating,
      'reviews': reviews,
      'price': price,
      'imagePath': imagePath,
      'tag': tag,
      'isVerified': isVerified,
    };
  }

  /// Returns a copy with selected fields overridden.
  Product copyWith({
    String Function(AppLocalizations l)? nameGetter,
    double? rating,
    int? reviews,
    double? price,
    String Function(AppLocalizations l)? unitGetter,
    String? imagePath,
    String? tag,
    bool? isVerified,
  }) {
    return Product(
      nameGetter: nameGetter ?? this.nameGetter,
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
