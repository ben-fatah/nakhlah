import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/seller_profile.dart';
import '../repositories/user_repository.dart';

/// Firestore-backed repository for marketplace seller profiles.
///
/// Manages the `sellers/{uid}` collection that records shop-level information
/// for users who have been upgraded to the "seller" role.
///
/// This is separate from the legacy [SellerRepository] (static home-screen
/// data) which will be retired in Phase 5 when the Market screen is replaced.
class MarketplaceSellerRepository {
  MarketplaceSellerRepository._();
  static final instance = MarketplaceSellerRepository._();

  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _auth = FirebaseAuth.instance;
  final _userRepo = UserRepository();

  CollectionReference<Map<String, dynamic>> get _sellersRef =>
      _firestore.collection('sellers');

  // ── Registration ──────────────────────────────────────────────────────────

  /// Register the currently signed-in user as a seller.
  ///
  /// Flow:
  /// 1. Upload [avatarFile] → `seller_avatars/{uid}/avatar.<ext>`.
  /// 2. Write `sellers/{uid}` document via merge (safe to re-run).
  /// 3. Flip `users/{uid}.role` → "seller" (atomic merge, non-destructive).
  ///
  /// Returns the created [SellerProfile] on success.
  Future<SellerProfile> registerSeller({
    required String displayName,
    required String bio,
    required String location,
    File? avatarFile,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // 1. Upload avatar (optional)
    String avatarUrl = '';
    if (avatarFile != null) {
      avatarUrl = await _uploadAvatar(uid: user.uid, file: avatarFile);
    }

    // 2. Write seller profile document
    final profile = SellerProfile(
      uid: user.uid,
      displayName: displayName.trim(),
      bio: bio.trim(),
      location: location.trim(),
      avatarUrl: avatarUrl,
      createdAt: DateTime.now(), // server timestamp applied by toFirestore()
    );

    await _sellersRef
        .doc(user.uid)
        .set(profile.toFirestore(), SetOptions(merge: true));

    // 3. Upgrade role (merge — will not touch other user fields)
    await _userRepo.upgradeToSeller(user.uid);

    return profile;
  }

  // ── Storage ───────────────────────────────────────────────────────────────

  Future<String> _uploadAvatar({
    required String uid,
    required File file,
  }) async {
    final ext = file.path.split('.').last.toLowerCase();
    final contentType = ext == 'png' ? 'image/png' : 'image/jpeg';
    final ref = _storage
        .ref()
        .child('seller_avatars')
        .child(uid)
        .child('avatar.$ext');

    final task = await ref.putFile(
      file,
      SettableMetadata(contentType: contentType),
    );
    return task.ref.getDownloadURL();
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Fetch a seller profile once. Returns null when the document does not exist.
  Future<SellerProfile?> getSeller(String uid) async {
    final doc = await _sellersRef.doc(uid).get();
    if (!doc.exists) return null;
    return SellerProfile.fromFirestore(doc);
  }

  /// Real-time stream of a seller's profile.
  Stream<SellerProfile?> watchSeller(String uid) {
    return _sellersRef.doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return SellerProfile.fromFirestore(snap);
    });
  }

  /// Real-time stream of the current authenticated user's seller profile.
  /// Emits null when not signed in or not yet a seller.
  Stream<SellerProfile?> watchCurrentSeller() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value(null);
      return watchSeller(user.uid);
    });
  }

  // ── Update ────────────────────────────────────────────────────────────────

  /// Partial update of the seller's profile fields.
  Future<void> updateSeller(String uid, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _sellersRef.doc(uid).set(data, SetOptions(merge: true));
  }
}
