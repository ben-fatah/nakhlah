// Basic smoke test — verifies NakhlahApp builds without throwing.
//
// We create an OnboardingRepository from an in-memory SharedPreferences
// instance (no file I/O) and pass it to NakhlahApp exactly like main() does.
//
// onboarding_done=false means OnboardingScreen is shown, which does not
// require FirebaseAuth — so the test runs cleanly with no Firebase mocking.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nakhlah/main.dart';
import 'package:nakhlah/repositories/onboarding_repository.dart';

void main() {
  testWidgets('NakhlahApp builds without throwing', (WidgetTester tester) async {
    // In-memory prefs — no file system access needed in tests.
    SharedPreferences.setMockInitialValues({'onboarding_done': false});
    final prefs = await SharedPreferences.getInstance();

    // Bypasses the SharedPreferences singleton and FirebaseAuth entirely —
    // onboarding_done=false routes to OnboardingScreen, not the auth stream.
    final repo = OnboardingRepository(prefs: prefs);

    await tester.pumpWidget(NakhlahApp(onboardingRepo: repo));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
