import 'package:firebase_auth/firebase_auth.dart';

import '../core/logger.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';

/// Centralized authentication service.
///
/// Responsibilities:
/// - Sign out
/// - Token refresh on app resume
/// - Idempotent Firestore user-document creation after any sign-in method
///
/// Phone Auth verification is handled in [OtpVerificationScreen] which calls
/// [FirebaseAuth.verifyPhoneNumber] directly and relies on this service's
/// [ensureUserDocument] after successful credential sign-in.
class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _userRepo = UserRepository();

  /// Fully sign out of Firebase.
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      AppLogger.d('[AuthService] Signed out successfully.');
    } catch (e, st) {
      AppLogger.e('[AuthService] Error signing out', error: e, stackTrace: st);
    }
  }

  /// Idempotent Firestore document creation / update after any sign-in.
  ///
  /// Call this once after a successful auth event to guarantee the Firestore
  /// `users/{uid}` document exists and is up-to-date.
  ///
  /// - On first sign-in, creates the document with [createdAt].
  /// - On subsequent sign-ins, only refreshes [lastSignIn] (no overwrite).
  static Future<void> ensureUserDocument() async {
    final user = _auth.currentUser;
    if (user == null) {
      AppLogger.w('[AuthService] ensureUserDocument: no current user');
      return;
    }

    try {
      final appUser = AppUser(
        uid: user.uid,
        fullName: user.displayName ?? '',
        email: user.email ?? '',
        phone: user.phoneNumber ?? '',
        provider: _resolveProvider(user),
      );

      await _userRepo.ensureUserExists(appUser);
      AppLogger.d('[AuthService] User document ensured: ${user.uid}');
    } catch (e, st) {
      // Non-fatal — user might be offline; Firestore will retry when online.
      AppLogger.e('[AuthService] ensureUserDocument failed (non-fatal)', error: e, stackTrace: st);
    }
  }

  /// Force a Firebase ID token refresh.
  ///
  /// Call on app foreground resume to prevent stale tokens from causing
  /// silent auth failures in Firestore / Storage permission checks.
  static Future<void> refreshToken() async {
    try {
      await _auth.currentUser?.getIdToken(true);
      AppLogger.d('[AuthService] Token refreshed.');
    } catch (e) {
      AppLogger.w('[AuthService] Token refresh failed (non-fatal): $e');
    }
  }

  /// Returns true if a Firebase user session is currently active.
  static bool get isSignedIn => _auth.currentUser != null;

  /// The UID of the currently signed-in user, or null.
  static String? get currentUid => _auth.currentUser?.uid;

  // ── Private helpers ───────────────────────────────────────────────────────

  static String _resolveProvider(User user) {
    if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) return 'phone';
    for (final info in user.providerData) {
      if (info.providerId == 'password') return 'email';
      if (info.providerId == 'phone') return 'phone';
    }
    return 'email';
  }
}
