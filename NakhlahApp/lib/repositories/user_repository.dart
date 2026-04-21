import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../core/logger.dart';

/// Repository encapsulating all Firestore operations on the `users` collection.
///
/// Key design decisions:
/// - [ensureUserExists] is the primary write method — it's idempotent and
///   uses a read-before-write to avoid overwriting [createdAt].
/// - [saveUser] is an alias for [ensureUserExists] for backward compatibility.
/// - [updateUser] only updates specific fields and never touches [createdAt].
class UserRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  UserRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  /// Reference to the `users` collection.
  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  // ── Read ─────────────────────────────────────────────────────────────────

  /// Fetch the current authenticated user's profile from Firestore.
  ///
  /// Returns `null` if not signed in or document does not exist.
  Future<AppUser?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return getUser(user.uid);
  }

  /// Fetch a user profile by [uid].
  Future<AppUser?> getUser(String uid) async {
    try {
      final doc = await _usersRef.doc(uid).get();
      if (!doc.exists) return null;
      return AppUser.fromFirestore(doc);
    } catch (e, st) {
      AppLogger.e('[UserRepository] getUser failed', error: e, stackTrace: st);
      return null;
    }
  }

  /// Fetch a user profile by [phone].
  Future<AppUser?> getUserByPhone(String phone) async {
    try {
      final snapshot = await _usersRef.where('phone', isEqualTo: phone).limit(1).get();
      if (snapshot.docs.isEmpty) return null;
      return AppUser.fromFirestore(snapshot.docs.first);
    } catch (e, st) {
      AppLogger.e('[UserRepository] getUserByPhone failed', error: e, stackTrace: st);
      return null;
    }
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Idempotent user creation.
  ///
  /// Checks if the document already exists:
  /// - If **NOT** exists → writes full document including [createdAt].
  /// - If **exists** → only updates mutable fields (never overwrites [createdAt]).
  ///
  /// This is safe to call multiple times (e.g., on every sign-in) without
  /// causing duplicate documents or clobbering existing data.
  Future<void> ensureUserExists(AppUser user) async {
    try {
      final docRef = _usersRef.doc(user.uid);
      final snap = await docRef.get();

      if (!snap.exists) {
        // First time — create full document with createdAt
        AppLogger.d('[UserRepository] Creating new user document: ${user.uid}');
        await docRef.set(user.toFirestoreCreate());
      } else {
        // Already exists — only update mutable fields, preserve createdAt
        AppLogger.d('[UserRepository] Updating existing user document: ${user.uid}');
        await docRef.set(user.toFirestoreUpdate(), SetOptions(merge: true));
      }
    } catch (e, st) {
      AppLogger.e('[UserRepository] ensureUserExists failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Alias for [ensureUserExists] — kept for backward compatibility.
  Future<void> saveUser(AppUser user) => ensureUserExists(user);

  /// Partial update — merges [data] into the existing document.
  ///
  /// Never touches [createdAt]. Syncs [fullName] → Firebase Auth displayName
  /// when present.
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    // Never allow callers to overwrite createdAt via this method
    data.remove('createdAt');
    data['updatedAt'] = FieldValue.serverTimestamp();

    try {
      await _usersRef.doc(uid).set(data, SetOptions(merge: true));

      // Keep Firebase Auth displayName in sync
      if (data.containsKey('fullName')) {
        final user = _auth.currentUser;
        if (user != null && user.uid == uid) {
          final newName = data['fullName'] as String?;
          if (newName != null && newName.isNotEmpty) {
            await user.updateDisplayName(newName);
          }
        }
      }
    } catch (e, st) {
      AppLogger.e('[UserRepository] updateUser failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  // ── Streams ──────────────────────────────────────────────────────────────

  /// Real-time stream of the current authenticated user's Firestore profile.
  ///
  /// Emits `null` when not signed in or document does not exist.
  Stream<AppUser?> watchCurrentUser() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value(null);
      return watchUser(user.uid);
    });
  }

  /// Real-time stream of a user's Firestore profile by [uid].
  Stream<AppUser?> watchUser(String uid) {
    return _usersRef.doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return AppUser.fromFirestore(snap);
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Resolve the user's first name from Firebase Auth or Firestore.
  ///
  /// Priority: Auth displayName → Firestore fullName → email prefix.
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

  /// Promote the current user's role to "seller" in Firestore.
  ///
  /// Should only be called after the seller profile document is created.
  Future<void> upgradeToSeller(String uid) async {
    await _usersRef.doc(uid).set(
      {'role': 'seller', 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  /// Check whether [uid] is a seller.
  Future<bool> isSeller(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists) return false;
    return (doc.data()?['role'] as String?) == 'seller';
  }
}
