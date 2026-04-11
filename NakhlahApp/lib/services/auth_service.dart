import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

import '../core/logger.dart';

/// Centralized authentication service for social sign-in providers.
class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;
  static final _googleSignIn = GoogleSignIn();

  /// Sign in with Google.
  /// Uses Firebase popup on web, GoogleSignIn SDK on mobile.
  /// Returns the [UserCredential] on success, or `null` if cancelled.
  ///
  /// Always displays the account picker by signing out of the cached
  /// Google session first, so the user can choose a different account.
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      AppLogger.d('[AuthService] signInWithGoogle called, kIsWeb: $kIsWeb');
      UserCredential userCredential;

      if (kIsWeb) {
        AppLogger.d('[AuthService] Using web-based Google Auth');
        // ── Web: use Firebase Auth popup directly ──────────────────────
        final provider = GoogleAuthProvider();
        provider.addScope('email');
        provider.addScope('profile');
        // setCustomParameters forces the account chooser even if one
        // account is already signed in on the browser.
        provider.setCustomParameters({'prompt': 'select_account'});
        userCredential = await _auth.signInWithPopup(provider);
      } else {
        AppLogger.d('[AuthService] Using mobile GoogleSignIn SDK');
        // ── Mobile: use google_sign_in package ─────────────────────────
        // Sign out first so the account picker is always shown.
        AppLogger.d('[AuthService] Signing out from cached Google session...');
        await _googleSignIn.signOut();

        AppLogger.d('[AuthService] Showing Google sign-in dialog...');
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          AppLogger.d('[AuthService] User cancelled Google sign-in');
          return null; // user cancelled
        }

        AppLogger.d('[AuthService] Got Google user, getting auth tokens...');
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        AppLogger.d('[AuthService] Creating Firebase credential...');
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        AppLogger.d('[AuthService] Signing in to Firebase with credential...');
        userCredential = await _auth.signInWithCredential(credential);
      }

      // Persist user profile in Firestore (merge to avoid overwriting)
      final user = userCredential.user;
      AppLogger.d('[AuthService] Firebase sign-in successful');
      if (user != null) {
        AppLogger.d('[AuthService] Saving user to Firestore...');
        try {
          await _firestore.collection('users').doc(user.uid).set({
            'fullName': user.displayName ?? '',
            'email': user.email ?? '',
            'photoUrl': user.photoURL ?? '',
            'provider': 'google',
            'lastSignIn': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          AppLogger.d('[AuthService] User saved to Firestore');
        } catch (e) {
          AppLogger.w('[AuthService] Error saving user to Firestore: $e');
          // Don't rethrow, Firestore error shouldn't block sign-in
        }
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      AppLogger.e('[AuthService] FirebaseAuthException: ${e.code}');
      rethrow;
    } catch (e, st) {
      AppLogger.e('[AuthService] Exception: $e', error: e, stackTrace: st);

      // Check for platform exception with API Exception 10
      if (e.toString().contains('PlatformException') &&
          e.toString().contains('10')) {
        AppLogger.w(
          '[AuthService] API Exception 10 detected - likely SHA-1 mismatch or missing Google Play Services',
        );
        AppLogger.w(
          '[AuthService] Fix: 1) Ensure Google Play Services is updated on device',
        );
        AppLogger.w(
          '[AuthService] Fix: 2) Get SHA-1 and add to Firebase Console',
        );
        AppLogger.w(
          '[AuthService] Fix: 3) Run: cd android && ./gradlew signingReport',
        );
      }

      rethrow;
    }
  }

  /// Fully sign out of both Firebase and Google.
  ///
  /// This clears the cached Google account so that the next call to
  /// [signInWithGoogle] will present the account picker again.
  static Future<void> signOut() async {
    // Sign out of Google (clears cached account)
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // GoogleSignIn may not be initialised if the user never used it;
      // safe to ignore.
    }
    // Sign out of Firebase (ends the session)
    await _auth.signOut();
  }
}
