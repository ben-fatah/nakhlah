import 'package:firebase_auth/firebase_auth.dart';

import '../core/logger.dart';

/// Centralized authentication service for general Auth logic.
/// Phone Auth is primarily handled directly in the OtpVerificationScreen.
class AuthService {
  static final _auth = FirebaseAuth.instance;

  /// Fully sign out of Firebase.
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      AppLogger.d('[AuthService] Signed out of Firebase successfully.');
    } catch (e, st) {
      AppLogger.e('[AuthService] Error signing out: $e', error: e, stackTrace: st);
    }
  }
}
