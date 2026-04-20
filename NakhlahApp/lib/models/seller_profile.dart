import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents the marketplace seller profile stored in `sellers/{uid}`.
///
/// The [uid] is identical to the Firebase Auth UID and the `users/{uid}`
/// document — there is exactly one seller profile per seller account.
class SellerProfile {
  final String uid;
  final String displayName; // shop / brand name shown in the market
  final String bio;
  final String location; // free-text city / region
  final String avatarUrl; // Firebase Storage download URL
  final double rating; // denormalized average (updated on each review write)
  final int reviewCount; // denormalized count
  final DateTime createdAt;

  const SellerProfile({
    required this.uid,
    required this.displayName,
    required this.bio,
    required this.location,
    required this.avatarUrl,
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.createdAt,
  });

  bool get isSeller => true; // convenience flag

  /// Human-readable rating string, e.g. "4.3".
  String get ratingFormatted =>
      reviewCount == 0 ? '–' : rating.toStringAsFixed(1);

  factory SellerProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    return SellerProfile(
      uid: doc.id,
      displayName: d['displayName'] as String? ?? '',
      bio: d['bio'] as String? ?? '',
      location: d['location'] as String? ?? '',
      avatarUrl: d['avatarUrl'] as String? ?? '',
      rating: (d['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (d['reviewCount'] as num?)?.toInt() ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'uid': uid,
    'displayName': displayName,
    'bio': bio,
    'location': location,
    'avatarUrl': avatarUrl,
    'rating': rating,
    'reviewCount': reviewCount,
    'createdAt': FieldValue.serverTimestamp(),
  };

  SellerProfile copyWith({
    String? displayName,
    String? bio,
    String? location,
    String? avatarUrl,
    double? rating,
    int? reviewCount,
  }) {
    return SellerProfile(
      uid: uid,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt,
    );
  }
}
