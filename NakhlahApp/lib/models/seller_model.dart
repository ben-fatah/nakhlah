import 'package:cloud_firestore/cloud_firestore.dart';

/// A seller displayed on the Home screen's "Featured Sellers" section.
class Seller {
  final String name;
  final double rating;
  final String reviews;
  final bool isTop;

  const Seller({
    required this.name,
    required this.rating,
    required this.reviews,
    required this.isTop,
  });

  /// Create a [Seller] from a Firestore document.
  factory Seller.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Seller(
      name: data['name'] as String? ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviews: data['reviews'] as String? ?? '0',
      isTop: data['isTop'] as bool? ?? false,
    );
  }

  /// Serialize to Firestore-compatible map.
  Map<String, dynamic> toFirestore() {
    return {'name': name, 'rating': rating, 'reviews': reviews, 'isTop': isTop};
  }

  /// Returns a copy with selected fields overridden.
  Seller copyWith({
    String? name,
    double? rating,
    String? reviews,
    bool? isTop,
  }) {
    return Seller(
      name: name ?? this.name,
      rating: rating ?? this.rating,
      reviews: reviews ?? this.reviews,
      isTop: isTop ?? this.isTop,
    );
  }
}
