import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/seller_review.dart';

/// Handles MVP rating operations and reviews generation without Cloud Functions.
class SellerReviewRepository {
  SellerReviewRepository._();
  static final instance = SellerReviewRepository._();

  final _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _reviewsRef(String sellerId) =>
      _firestore.collection('sellers').doc(sellerId).collection('reviews');

  DocumentReference<Map<String, dynamic>> _sellerRef(String sellerId) =>
      _firestore.collection('sellers').doc(sellerId);

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Watch all reviews for a specific seller
  Stream<List<SellerReview>> watchSellerReviews(String sellerId) {
    return _reviewsRef(sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => SellerReview.fromFirestore(d)).toList(),
        );
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Add a new review and atomically update the SellerProfile's average rating.
  ///
  /// Uses a Firestore Transaction so that `rating` and `reviewCount` stay
  /// in sync safely, even with concurrent reviews. No Cloud Functions needed!
  Future<void> addReview({
    required String sellerId,
    required String itemId,
    required String reviewerId,
    required String reviewerName,
    required int rating,
    String comment = '',
  }) async {
    // Basic validation
    if (rating < 1 || rating > 5) {
      throw ArgumentError('Rating must be between 1 and 5');
    }

    final reviewRef = _reviewsRef(sellerId).doc(); // auto-id
    final sellerDocRef = _sellerRef(sellerId);

    await _firestore.runTransaction((tx) async {
      final sellerSnap = await tx.get(sellerDocRef);

      if (!sellerSnap.exists) {
        throw Exception('Seller profile not found');
      }

      final data = sellerSnap.data()!;
      final currentRating = (data['rating'] as num?)?.toDouble() ?? 0.0;
      final currentCount = (data['reviewCount'] as num?)?.toInt() ?? 0;

      // Calculate the new average safely
      final newCalculations = _calculateAverageRating(
        currentRating: currentRating,
        currentCount: currentCount,
        newRating: rating,
      );

      final review = SellerReview(
        id: reviewRef.id,
        sellerId: sellerId,
        itemId: itemId,
        reviewerId: reviewerId,
        reviewerName: reviewerName,
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(), // will hit serverTimestamp in toFirestore
      );

      // 1. Write the new review document
      tx.set(reviewRef, review.toFirestore());

      // 2. Update the seller's aggregate stats atomically
      tx.update(sellerDocRef, {
        'rating': newCalculations.newAverage,
        'reviewCount': newCalculations.newCount,
        // don't touch updated_at here if not strictly needed, but could
      });
    });
  }

  // ── Logic ─────────────────────────────────────────────────────────────────

  /// Pure logic function to calculate a new average rating
  /// Returns a record with `(newAverage, newCount)`.
  ({double newAverage, int newCount}) _calculateAverageRating({
    required double currentRating,
    required int currentCount,
    required int newRating,
  }) {
    if (currentCount == 0) {
      return (newAverage: newRating.toDouble(), newCount: 1);
    }

    final totalScore = currentRating * currentCount;
    final newCount = currentCount + 1;
    final newAverage = (totalScore + newRating) / newCount;

    return (newAverage: newAverage, newCount: newCount);
  }
}
