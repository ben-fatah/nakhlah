import 'package:cloud_firestore/cloud_firestore.dart';

/// A product listing created by a seller, stored in `items/{id}`.
///
/// Follows the Haraj model — no cart, no checkout.
/// The [price] is nullable: null means "price on request / negotiate".
class MarketItem {
  final String id;
  final String sellerId;
  final String sellerName; // denormalized for list display
  final String sellerAvatarUrl; // denormalized for list/detail display
  final String title;
  final String description;
  final double? price; // null → "Contact for price"
  final String imageUrl; // Firebase Storage download URL
  final String variety; // tag: "ajwa" | "medjool" | etc. | "" = other
  final bool isActive; // soft delete — false hides from market
  final DateTime createdAt;
  final DateTime updatedAt;

  const MarketItem({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    this.sellerAvatarUrl = '',
    required this.title,
    required this.description,
    this.price,
    required this.imageUrl,
    this.variety = '',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Formatted price string. Shows "Contact for price" / "اتفق على السعر" when null.
  String priceLabel(bool isAr) {
    if (price == null) return isAr ? 'اتفق على السعر' : 'Price on request';
    return isAr
        ? 'ر.س ${price!.toStringAsFixed(0)}'
        : 'SAR ${price!.toStringAsFixed(0)}';
  }

  factory MarketItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    return MarketItem(
      id: doc.id,
      sellerId: d['sellerId'] as String? ?? '',
      sellerName: d['sellerName'] as String? ?? '',
      sellerAvatarUrl: d['sellerAvatarUrl'] as String? ?? '',
      title: d['title'] as String? ?? '',
      description: d['description'] as String? ?? '',
      price: (d['price'] as num?)?.toDouble(),
      imageUrl: d['imageUrl'] as String? ?? '',
      variety: d['variety'] as String? ?? '',
      isActive: d['isActive'] as bool? ?? true,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'sellerId': sellerId,
    'sellerName': sellerName,
    'sellerAvatarUrl': sellerAvatarUrl,
    'title': title,
    'description': description,
    'price': price, // null is valid Firestore value
    'imageUrl': imageUrl,
    'variety': variety,
    'isActive': isActive,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  /// Partial update map — does not overwrite createdAt.
  Map<String, dynamic> toUpdateMap() => {
    'title': title,
    'description': description,
    'price': price,
    'imageUrl': imageUrl,
    'variety': variety,
    'isActive': isActive,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  MarketItem copyWith({
    String? title,
    String? description,
    double? price,
    bool clearPrice = false,
    String? imageUrl,
    String? variety,
    bool? isActive,
  }) {
    return MarketItem(
      id: id,
      sellerId: sellerId,
      sellerName: sellerName,
      sellerAvatarUrl: sellerAvatarUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      price: clearPrice ? null : (price ?? this.price),
      imageUrl: imageUrl ?? this.imageUrl,
      variety: variety ?? this.variety,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
