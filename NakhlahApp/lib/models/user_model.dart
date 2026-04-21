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
  final String phone;
  /// "buyer" (default) or "seller" — upgraded via [SellerRepository].
  final String role;
  final DateTime? lastSignIn;
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    this.photoUrl = '',
    this.provider = 'email',
    this.phone = '',
    this.role = 'buyer',
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
      phone: data['phone'] as String? ?? '',
      role: data['role'] as String? ?? 'buyer',
      lastSignIn: (data['lastSignIn'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Full serialization for NEW user document creation.
  ///
  /// Only call this on first write — includes [createdAt] as a server
  /// timestamp. Subsequent updates must use [toFirestoreUpdate()] to avoid
  /// overwriting the original creation time.
  Map<String, dynamic> toFirestoreCreate() {
    return {
      'fullName': fullName,
      'email': email,
      'photoUrl': photoUrl,
      'provider': provider,
      'phone': phone,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
      'lastSignIn': FieldValue.serverTimestamp(),
    };
  }

  /// Partial serialization for UPDATES to an existing user document.
  ///
  /// Deliberately omits [createdAt] so the original timestamp is never
  /// overwritten. Safe to call with [SetOptions(merge: true)].
  Map<String, dynamic> toFirestoreUpdate() {
    return {
      'fullName': fullName,
      'email': email,
      'photoUrl': photoUrl,
      'provider': provider,
      'phone': phone,
      'role': role,
      'lastSignIn': FieldValue.serverTimestamp(),
    };
  }

  /// Returns a copy with selected fields overridden.
  AppUser copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? photoUrl,
    String? provider,
    String? phone,
    String? role,
    DateTime? lastSignIn,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      provider: provider ?? this.provider,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      lastSignIn: lastSignIn ?? this.lastSignIn,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
