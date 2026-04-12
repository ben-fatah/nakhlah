import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'domain/favorites_notifier.dart';
import 'domain/cart_notifier.dart';
import 'domain/scan_history_notifier.dart';
import 'repositories/onboarding_repository.dart';
import 'services/scan_service.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'screens/sign_in_screen.dart';
import 'screens/home_page.dart';
import 'screens/onboarding_screen.dart';

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

  // Fire-and-forget warmup — wakes the Render instance so that the first
  // scan does not pay the full cold-start penalty (~30–60 s on free tier).
  // This runs in the background and never blocks or crashes the app.
  ScanService.warmup();

  runApp(NakhlahApp(onboardingRepo: onboardingRepo));
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
          locale: locale,
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.light(context),
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