import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_links/app_links.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'providers/user_provider.dart';
import 'domain/favorites_notifier.dart';
import 'domain/cart_notifier.dart';
import 'domain/scan_history_notifier.dart';
import 'repositories/onboarding_repository.dart';
import 'repositories/scan_repository.dart';
import 'repositories/user_repository.dart';
import 'services/date_metadata.dart';
import 'services/local_inference_service.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'screens/sign_in_screen.dart';
import 'screens/home_page.dart';
import 'screens/onboarding_screen.dart';
import 'screens/new_password_screen.dart';
import 'core/logger.dart';

/// Stores the oobCode from a cold-start deep link so that the app can navigate
/// to [NewPasswordScreen] once the navigator is ready. Set in [main] before
/// [runApp] is called, consumed by [_NakhlahAppState].
String? _pendingOobCode;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final onboardingRepo = await OnboardingRepository.create();

  if (onboardingRepo.savedLocale != null) {
    localeProvider.setLocale(Locale(onboardingRepo.savedLocale!));
  }

  final prefs = await SharedPreferences.getInstance();
  favoritesNotifier.init(prefs);
  cartNotifier.init(prefs);
  scanHistoryNotifier.init(prefs);

  // ── Load date metadata from bundled JSON (fast, synchronous after first load)
  await DateMetadataLoader.instance.load();

  // ── Warm up the ONNX inference isolate in the background
  // so it's ready before the user opens the scan screen.
  LocalInferenceService.instance.init(); // fire-and-forget

  // ── Sync Firestore scan history in background (after local state is ready)
  ScanRepository.instance.syncFromFirestore(); // fire-and-forget

  // ── Check for a cold-start deep link BEFORE runApp ─────────────────────
  // getInitialLink() must be called before runApp so we don't lose the URL.
  try {
    final appLinks = AppLinks();
    final initialUri = await appLinks.getInitialLink();
    if (initialUri != null) {
      AppLogger.d('[DeepLink] Cold start link: $initialUri');
      _pendingOobCode = _extractOobCode(initialUri);
    }
  } catch (e) {
    AppLogger.e('[DeepLink] getInitialLink error: $e');
  }

  // Load the current user profile if signed in before running the app
  final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
  final isOtpVerified = prefs.getBool('isOtpVerified') ?? false;
  final verifiedPhone = prefs.getString('verifiedPhone');

  if (currentUserUid != null && isOtpVerified && verifiedPhone != null && verifiedPhone.isNotEmpty) {
    AppLogger.d('[Init] Fetching user profile manually by phone $verifiedPhone');
    final repo = UserRepository();
    final user = await repo.getUserByPhone(verifiedPhone);
    if (user != null) {
       userProvider.setCurrentUser(user);
       userProvider.setOtpVerified(true);
    } else {
       await FirebaseAuth.instance.signOut();
    }
  } else if (currentUserUid != null) {
    await FirebaseAuth.instance.signOut();
  }

  runApp(NakhlahApp(onboardingRepo: onboardingRepo));
}

/// Extract the oobCode from a Firebase Auth action URL.
///
/// Firebase password-reset links can have TWO formats:
///
/// 1. Direct: `https://domain/__/auth/action?mode=resetPassword&oobCode=ABC`
/// 2. Nested (when `handleCodeInApp: true`):
///    `https://domain/__/auth/links?link=https://domain/__/auth/action?
///    apiKey%3D...%26mode%3DresetPassword%26oobCode%3DABC%26...`
///
/// This function handles both.
String? _extractOobCode(Uri uri) {
  // ── Try top-level query parameters first ──
  var mode = uri.queryParameters['mode'];
  var oobCode = uri.queryParameters['oobCode'];
  if (mode == 'resetPassword' && oobCode != null && oobCode.isNotEmpty) {
    AppLogger.d('[DeepLink] oobCode found at top level');
    return oobCode;
  }

  // ── Try nested 'link' parameter (Firebase wraps action URL here) ──
  final nestedLink = uri.queryParameters['link'];
  if (nestedLink != null) {
    try {
      final innerUri = Uri.parse(nestedLink);
      mode = innerUri.queryParameters['mode'];
      oobCode = innerUri.queryParameters['oobCode'];
      if (mode == 'resetPassword' && oobCode != null && oobCode.isNotEmpty) {
        AppLogger.d('[DeepLink] oobCode found in nested link parameter');
        return oobCode;
      }
    } catch (e) {
      AppLogger.e('[DeepLink] Failed to parse nested link: $e');
    }
  }

  // ── Fallback: regex search across the entire URL ──
  final raw = uri.toString();
  final match = RegExp(r'oobCode[=%3D]+([A-Za-z0-9_-]+)').firstMatch(raw);
  if (match != null) {
    AppLogger.d('[DeepLink] oobCode found via regex fallback');
    return match.group(1);
  }

  return null;
}

/// Global navigator key used for deep-link navigation from outside the
/// widget tree (e.g. the [_NakhlahAppState] deep-link listener).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NakhlahApp extends StatefulWidget {
  final OnboardingRepository onboardingRepo;
  const NakhlahApp({super.key, required this.onboardingRepo});

  @override
  State<NakhlahApp> createState() => _NakhlahAppState();
}

class _NakhlahAppState extends State<NakhlahApp> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _initWarmStartListener();

    // Handle cold-start deep link after the very first frame (navigator ready).
    if (_pendingOobCode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToNewPassword(_pendingOobCode!);
        _pendingOobCode = null;
      });
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  // ── Warm-start deep link listener ──────────────────────────────────────────
  void _initWarmStartListener() {
    _linkSub = _appLinks.uriLinkStream.listen(
      (uri) {
        AppLogger.d('[DeepLink] Warm start link: $uri');
        final oobCode = _extractOobCode(uri);
        if (oobCode != null) {
          _navigateToNewPassword(oobCode);
        }
      },
      onError: (err) {
        AppLogger.e('[DeepLink] uriLinkStream error: $err');
      },
    );
  }

  /// Push [NewPasswordScreen] onto the navigator stack.
  ///
  /// Uses a retry loop for cold-start scenarios where the navigator may not
  /// be fully mounted on the very first post-frame callback.
  void _navigateToNewPassword(String oobCode) {
    void tryNavigate() {
      final nav = navigatorKey.currentState;
      if (nav != null) {
        nav.push(
          MaterialPageRoute(
            builder: (_) => NewPasswordScreen(oobCode: oobCode),
          ),
        );
      } else {
        // Navigator not ready yet — retry after next frame.
        AppLogger.d('[DeepLink] Navigator not ready, retrying next frame...');
        WidgetsBinding.instance.addPostFrameCallback((_) => tryNavigate());
      }
    }

    tryNavigate();
  }

  // ── UI ──────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: localeProvider,
      builder: (context, locale, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Nakhlah',
          debugShowCheckedModeBanner: false,
          locale: locale,
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.light(context),
          home: !widget.onboardingRepo.isOnboardingDone
              ? OnboardingScreen(repository: widget.onboardingRepo)
              : StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Scaffold(
                        backgroundColor: AppColors.palmGreen,
                        body: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.eco_rounded,
                                size: 80,
                                color: AppColors.goldenDate,
                              ),
                              SizedBox(height: 16),
                              CircularProgressIndicator(
                                color: AppColors.goldenDate,
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    if (snapshot.hasData) return const HomePage();
                    return const SignInScreen();
                  },
                ),
        );
      },
    );
  }
}
