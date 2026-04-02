import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'screens/sign_in_screen.dart';
import 'screens/home_page.dart';
import 'screens/onboarding_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  Nakhlah — Palm & Date Color Palette
// ═══════════════════════════════════════════════════════════════════════════════

/// Primary "Palm Green" — AppBars, primary buttons, major surfaces.
const Color kPalmGreen = Color(0xFF2E5B3E);

/// Accent "Golden Date" — text buttons, icons, highlights, active states.
const Color kGoldenDate = Color(0xFFD4A373);

/// Background "Off-White" — scaffold / page backgrounds.
const Color kOffWhite = Color(0xFFF9F7F3);

/// Surface card white — cards & input fields that sit on top of kOffWhite.
const Color kCardWhite = Color(0xFFFFFFFF);

/// Subtle border / divider colour derived from the palette.
const Color kBorderLight = Color(0xFFE5DFD8);

// ═══════════════════════════════════════════════════════════════════════════════

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const NakhlahApp());
}

class NakhlahApp extends StatelessWidget {
  const NakhlahApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.cairoTextTheme(Theme.of(context).textTheme);

    return MaterialApp(
      title: 'Nakhlah',
      debugShowCheckedModeBanner: false,

      // ── Global Theme ────────────────────────────────────────────────────
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

        // AppBar
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

        // Elevated Buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPalmGreen,
            foregroundColor: Colors.white,
            disabledBackgroundColor: kPalmGreen.withValues(alpha: 0.4),
            textStyle: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
            shadowColor: kPalmGreen.withValues(alpha: 0.35),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),

        // Text Buttons (accent colour)
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: kGoldenDate,
            textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600),
          ),
        ),

        // Input fields
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

        // Drawer
        drawerTheme: const DrawerThemeData(backgroundColor: kOffWhite),

        // SnackBar
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentTextStyle: GoogleFonts.cairo(color: Colors.white),
        ),
      ),

      // ── Root: onboarding gate → auth gate ──────────────────────────────
      home: const _AppRoot(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  _AppRoot — decides whether to show onboarding or go straight to auth
// ═══════════════════════════════════════════════════════════════════════════════

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  // null = still loading prefs, true = done, false = first time
  bool? _onboardingDone;

  @override
  void initState() {
    super.initState();
    _loadOnboardingFlag();
  }

  Future<void> _loadOnboardingFlag() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool('onboarding_done') ?? false;
    if (mounted) setState(() => _onboardingDone = done);
  }

  @override
  Widget build(BuildContext context) {
    // ── Still reading SharedPreferences → branded splash ─────────────────
    if (_onboardingDone == null) {
      return const Scaffold(
        backgroundColor: kPalmGreen,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.eco_rounded, size: 80, color: kGoldenDate),
              SizedBox(height: 16),
              CircularProgressIndicator(color: kGoldenDate),
            ],
          ),
        ),
      );
    }

    // ── First install → show onboarding ──────────────────────────────────
    if (!_onboardingDone!) {
      return const OnboardingScreen();
    }

    // ── Returning user → Firebase auth gate ──────────────────────────────
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Firebase still initialising → branded splash
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: kPalmGreen,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.eco_rounded, size: 80, color: kGoldenDate),
                  SizedBox(height: 16),
                  CircularProgressIndicator(color: kGoldenDate),
                ],
              ),
            ),
          );
        }

        // Signed in → Home
        if (snapshot.hasData) return const HomePage();

        // Not signed in → Sign In
        return const SignInScreen();
      },
    );
  }
}
