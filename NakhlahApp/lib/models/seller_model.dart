import 'package:cloud_firestore/cloud_firestore.dart';

/// A seller of date products (used on HomeScreen, ProductDetailScreen,
/// and the new SellerScreen).
///
/// Previously minimal (name, rating, reviews, isTop); expanded to carry
/// all data needed for a full seller profile page while remaining
/// backward-compatible — all new fields have sensible defaults.
class Seller {
  /// Stable seller identifier (Firestore document ID for backend data).
  final String id;

  final String name;
  final double rating;

  /// Human-friendly review count string (e.g. '1.2k', '850').
  final String reviews;

  /// Numeric review count — preferred for sorting/calculations.
  final int reviewCount;

  /// Whether this seller carries the "Top Seller" badge.
  final bool isTop;

  /// City / region where the seller operates (bilingual welcome).
  final String location;

  /// E.164 phone number for the "Call Seller" action.
  final String phoneNumber;

  /// List of [Product.id] values this seller carries.
  final List<String> productIds;

  /// Optional asset path or network URL for the seller's logo.
  /// Falls back to a `Icons.store_rounded` placeholder when empty.
  final String logoPath;

  /// Short bilingual description shown on the About tab.
  final String description;

  const Seller({
    required this.id,
    required this.name,
    required this.rating,
    required this.reviews,
    this.reviewCount = 0,
    required this.isTop,
    this.location = '',
    this.phoneNumber = '',
    this.productIds = const [],
    this.logoPath = '',
    this.description = '',
  });

  // ── Firestore ──────────────────────────────────────────────────────────────

  /// Creates a [Seller] from a Firestore document snapshot.
  factory Seller.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Seller(
      id: doc.id,
      name: data['name'] as String? ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviews: data['reviews'] as String? ?? '0',
      reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
      isTop: data['isTop'] as bool? ?? false,
      location: data['location'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      productIds:
          (data['productIds'] as List<dynamic>?)?.cast<String>() ?? [],
      logoPath: data['logoPath'] as String? ?? '',
      description: data['description'] as String? ?? '',
    );
  }

  /// Serializes this seller to a Firestore-compatible map.
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'rating': rating,
      'reviews': reviews,
      'reviewCount': reviewCount,
      'isTop': isTop,
      'location': location,
      'phoneNumber': phoneNumber,
      'productIds': productIds,
      'logoPath': logoPath,
      'description': description,
    };
  }

  /// Returns a new [Seller] with the specified fields replaced.
  Seller copyWith({
    String? id,
    String? name,
    double? rating,
    String? reviews,
    int? reviewCount,
    bool? isTop,
    String? location,
    String? phoneNumber,
    List<String>? productIds,
    String? logoPath,
    String? description,
  }) {
    return Seller(
      id: id ?? this.id,
      name: name ?? this.name,
      rating: rating ?? this.rating,
      reviews: reviews ?? this.reviews,
      reviewCount: reviewCount ?? this.reviewCount,
      isTop: isTop ?? this.isTop,
      location: location ?? this.location,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      productIds: productIds ?? this.productIds,
      logoPath: logoPath ?? this.logoPath,
      description: description ?? this.description,
    );
  }
}
