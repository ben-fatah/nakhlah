import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'screens/sign_in_screen.dart';
import 'screens/home_page.dart';
import 'screens/onboarding_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  Nakhlah — Palm & Date Color Palette
// ═══════════════════════════════════════════════════════════════════════════════
const Color kPalmGreen = Color(0xFF2E5B3E);
const Color kGoldenDate = Color(0xFFD4A373);
const Color kOffWhite = Color(0xFFF9F7F3);
const Color kCardWhite = Color(0xFFFFFFFF);
const Color kBorderLight = Color(0xFFE5DFD8);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final prefs = await SharedPreferences.getInstance();
  final onboardingDone = prefs.getBool('onboarding_done') ?? false;
  runApp(NakhlahApp(onboardingDone: onboardingDone));
}

class NakhlahApp extends StatelessWidget {
  final bool onboardingDone;
  const NakhlahApp({super.key, required this.onboardingDone});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: localeProvider,
      builder: (context, locale, _) {
        final textTheme = GoogleFonts.cairoTextTheme(
          Theme.of(context).textTheme,
        );

        return MaterialApp(
          title: 'Nakhlah',
          debugShowCheckedModeBanner: false,

          // ── Localisation ──────────────────────────────────────────────
          locale: locale,
          supportedLocales: const [Locale('en'), Locale('ar')],
          // Use only the app's delegate here to avoid SDK delegate resolution
          // issues during analysis. If you need the Material/Cupertino
          // delegates, re-add `package:flutter_localizations` after
          // ensuring your IDE's Dart/Flutter plugin recognizes the SDK.
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // ── Global Theme ──────────────────────────────────────────────
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: kPalmGreen,
              primary: kPalmGreen,
              secondary: kGoldenDate,
              surface: kCardWhite,
              onPrimary: Colors.white,
            ),
            scaffoldBackgroundColor: kOffWhite,
            textTheme: textTheme,
            appBarTheme: AppBarTheme(
              backgroundColor: kPalmGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPalmGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor: kPalmGreen.withValues(alpha: 0.4),
                textStyle: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                shadowColor: kPalmGreen.withValues(alpha: 0.35),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: kGoldenDate,
                textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: kCardWhite,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
              labelStyle: GoogleFonts.cairo(color: kPalmGreen),
              hintStyle: GoogleFonts.cairo(color: Colors.grey.shade400),
              prefixIconColor: kGoldenDate,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kBorderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kBorderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kPalmGreen, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red.shade400),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red.shade400, width: 2),
              ),
            ),
            drawerTheme: const DrawerThemeData(backgroundColor: kOffWhite),
            snackBarTheme: SnackBarThemeData(
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentTextStyle: GoogleFonts.cairo(color: Colors.white),
            ),
          ),

          // ── Auth-Gated Root ───────────────────────────────────────────
          home: !onboardingDone
              ? const OnboardingScreen()
              : StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Scaffold(
                        backgroundColor: kPalmGreen,
                        body: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.eco_rounded,
                                size: 80,
                                color: kGoldenDate,
                              ),
                              SizedBox(height: 16),
                              CircularProgressIndicator(color: kGoldenDate),
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
