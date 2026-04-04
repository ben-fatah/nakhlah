import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

/// Centralized authentication service for social sign-in providers.
class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;

  /// Sign in with Google.
  /// Uses Firebase popup on web, GoogleSignIn SDK on mobile.
  /// Returns the [UserCredential] on success, or `null` if cancelled.
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        // ── Web: use Firebase Auth popup directly ──────────────────────
        final provider = GoogleAuthProvider();
        provider.addScope('email');
        provider.addScope('profile');
        userCredential = await _auth.signInWithPopup(provider);
      } else {
        // ── Mobile: use google_sign_in package ─────────────────────────
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return null; // user cancelled

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
      }

      // Persist user profile in Firestore (merge to avoid overwriting)
      final user = userCredential.user;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set(
          {
            'fullName': user.displayName ?? '',
            'email': user.email ?? '',
            'photoUrl': user.photoURL ?? '',
            'provider': 'google',
            'lastSignIn': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      return userCredential;
    } catch (e, st) {
      debugPrint('Google sign-in error: $e\n$st');
      rethrow;
    }
  }
}
