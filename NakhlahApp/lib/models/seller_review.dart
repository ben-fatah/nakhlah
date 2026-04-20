import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a review left by a buyer for a seller about a specific item.
class SellerReview {
  final String id;
  final String sellerId;
  final String itemId;
  final String reviewerId;
  final String reviewerName;

  /// The star rating given by the buyer (1 to 5).
  final int rating;

  /// Optional text comment provided by the buyer.
  final String comment;

  final DateTime createdAt;

  const SellerReview({
    required this.id,
    required this.sellerId,
    required this.itemId,
    required this.reviewerId,
    required this.reviewerName,
    required this.rating,
    this.comment = '',
    required this.createdAt,
  });

  factory SellerReview.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    return SellerReview(
      id: doc.id,
      sellerId: d['sellerId'] as String? ?? '',
      itemId: d['itemId'] as String? ?? '',
      reviewerId: d['reviewerId'] as String? ?? '',
      reviewerName: d['reviewerName'] as String? ?? '',
      rating: (d['rating'] as num?)?.toInt() ?? 0,
      comment: d['comment'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sellerId': sellerId,
      'itemId': itemId,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
