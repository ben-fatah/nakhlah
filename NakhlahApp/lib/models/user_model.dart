import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a user in the Nakhlah application.
///
/// Maps to the `users` Firestore collection.
class AppUser {
  final String uid;
  final String fullName;
  final String email;
  final String photoUrl;
  final String provider;
  final DateTime? lastSignIn;
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    this.photoUrl = '',
    this.provider = 'email',
    this.lastSignIn,
    this.createdAt,
  });

  /// Create an [AppUser] from a Firestore document snapshot.
  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AppUser(
      uid: doc.id,
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      photoUrl: data['photoUrl'] as String? ?? '',
      provider: data['provider'] as String? ?? 'email',
      lastSignIn: (data['lastSignIn'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Serialize to a Firestore-compatible map.
  ///
  /// Uses [SetOptions(merge: true)] friendly format — timestamps are
  /// replaced with server timestamps.
  Map<String, dynamic> toFirestore() {
    return {
      'fullName': fullName,
      'email': email,
      'photoUrl': photoUrl,
      'provider': provider,
      'lastSignIn': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Returns a copy with selected fields overridden.
  AppUser copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? photoUrl,
    String? provider,
    DateTime? lastSignIn,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      provider: provider ?? this.provider,
      lastSignIn: lastSignIn ?? this.lastSignIn,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
