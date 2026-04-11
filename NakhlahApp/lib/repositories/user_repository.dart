import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

/// Repository encapsulating all Firestore operations on the `users` collection.
class UserRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  UserRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  /// Reference to the `users` collection.
  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  /// Fetch the current authenticated user's profile from Firestore.
  ///
  /// Returns `null` if the document does not exist.
  Future<AppUser?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return getUser(user.uid);
  }

  /// Fetch a user profile by [uid].
  Future<AppUser?> getUser(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }

  /// Save or merge a user profile.
  Future<void> saveUser(AppUser user) async {
    await _usersRef
        .doc(user.uid)
        .set(user.toFirestore(), SetOptions(merge: true));
  }

  /// Partial update — merges [data] into the existing document.
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _usersRef.doc(uid).set(data, SetOptions(merge: true));
  }

  /// Resolve the user's first name from Firebase Auth or Firestore.
  ///
  /// Tries `displayName` first, then falls back to the Firestore `fullName`
  /// field, and finally to the email prefix.
  Future<String> resolveFirstName() async {
    final user = _auth.currentUser;
    if (user == null) return '';

    // 1) Try display name from Firebase Auth
    if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
      return user.displayName!.split(' ').first;
    }

    // 2) Try Firestore
    try {
      final doc = await _usersRef.doc(user.uid).get();
      final fullName = doc.data()?['fullName'] as String? ?? '';
      if (fullName.isNotEmpty) {
        await user.updateDisplayName(fullName);
        return fullName.split(' ').first;
      }
    } catch (_) {
      // Fall through to email
    }

    // 3) Fallback to email prefix
    return (user.email ?? 'User').split('@').first;
  }
}
