import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralises all onboarding-related state and navigation decisions.
///
/// Keeps SharedPreferences and FirebaseAuth calls out of Widget code so the
/// screen stays a pure-UI layer and the logic can be unit-tested independently.
class OnboardingRepository {
  static const _kOnboardingDone = 'onboarding_done';
  static const _kLocale = 'app_locale';

  final SharedPreferences _prefs;
  final FirebaseAuth _auth;

  OnboardingRepository({SharedPreferences? prefs, FirebaseAuth? auth})
    : _prefs = prefs ?? _syncPrefs(),
      _auth = auth ?? FirebaseAuth.instance;

  // ── Factory / async constructor ─────────────────────────────────────────────

  /// Creates an [OnboardingRepository] with a freshly loaded [SharedPreferences]
  /// instance. Call this from async contexts (e.g. `main()`).
  static Future<OnboardingRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return OnboardingRepository(prefs: prefs);
  }

  // ── Onboarding completion flag ───────────────────────────────────────────────

  /// Returns `true` when the user has already completed onboarding.
  bool get isOnboardingDone => _prefs.getBool(_kOnboardingDone) ?? false;

  /// Persists the onboarding-complete flag so this screen never shows again.
  Future<void> markOnboardingDone() =>
      _prefs.setBool(_kOnboardingDone, true);

  // ── Locale ───────────────────────────────────────────────────────────

  /// Returns the saved locale language code (e.g. `'ar'` or `'en'`),
  /// or `null` if no preference has been persisted yet.
  String? get savedLocale => _prefs.getString(_kLocale);

  // ── Post-onboarding routing decision ────────────────────────────────────────

  /// Returns `true` when a Firebase user session is already active.
  ///
  /// Used to decide whether to go straight to [HomePage] or [SignInScreen]
  /// after onboarding finishes.
  bool get isUserLoggedIn => _auth.currentUser != null;

  // ── Combined finish action ───────────────────────────────────────────────────

  /// Marks onboarding as done and returns the post-onboarding routing decision.
  ///
  /// Returns `true` → navigate to [HomePage].
  /// Returns `false` → navigate to [SignInScreen].
  Future<bool> finishOnboarding() async {
    await markOnboardingDone();
    return isUserLoggedIn;
  }
}

// ── Private helpers ──────────────────────────────────────────────────────────

/// Synchronous fallback used only when the caller did not supply a
/// [SharedPreferences] instance (shouldn't happen at runtime — use
/// [OnboardingRepository.create()] in main()).
SharedPreferences _syncPrefs() {
  throw StateError(
    'OnboardingRepository: SharedPreferences not initialised. '
    'Use OnboardingRepository.create() instead of the default constructor.',
  );
}
