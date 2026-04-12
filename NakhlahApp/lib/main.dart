import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'domain/favorites_notifier.dart';
import 'repositories/onboarding_repository.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'screens/sign_in_screen.dart';
import 'screens/home_page.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // OnboardingRepository loads SharedPreferences once — no duplicate instances
  final onboardingRepo = await OnboardingRepository.create();

  // Restore persisted locale before the app renders anything
  if (onboardingRepo.savedLocale != null) {
    localeProvider.setLocale(Locale(onboardingRepo.savedLocale!));
  }

  // Restore persisted favorites — SharedPreferences.getInstance() is cached
  // internally so this returns the same instance created inside OnboardingRepository.create().
  final prefs = await SharedPreferences.getInstance();
  favoritesNotifier.init(prefs);

  runApp(
    NakhlahApp(
      onboardingRepo: onboardingRepo,
    ),
  );
}

class NakhlahApp extends StatelessWidget {
  final OnboardingRepository onboardingRepo;
  const NakhlahApp({super.key, required this.onboardingRepo});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: localeProvider,
      builder: (context, locale, _) {
        return MaterialApp(
          title: 'Nakhlah',
          debugShowCheckedModeBanner: false,

          // ── Localisation ──────────────────────────────────────────────
          locale: locale,
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // ── Global Theme ──────────────────────────────────────────────
          theme: AppTheme.light(context),

          // ── Auth-Gated Root ───────────────────────────────────────
          home: !onboardingRepo.isOnboardingDone
              ? OnboardingScreen(repository: onboardingRepo)
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
