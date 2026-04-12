// Basic smoke test — verifies NakhlahApp builds without throwing.
//
// We create an OnboardingRepository from an in-memory SharedPreferences
// instance (no file I/O) and pass it to NakhlahApp exactly like main() does.
//
// onboarding_done=false means OnboardingScreen is shown, which does not
// require FirebaseAuth — so the test runs cleanly with no Firebase mocking.



void main() {
<<<<<<< HEAD
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Set up mock SharedPreferences with onboarding already completed
    SharedPreferences.setMockInitialValues({'onboarding_done': true});
    final prefs = await SharedPreferences.getInstance();
    final onboardingRepo = OnboardingRepository(prefs: prefs);

    // Build our app and trigger a frame.
    await tester.pumpWidget(NakhlahApp(onboardingRepo: onboardingRepo));
=======
  testWidgets('NakhlahApp builds without throwing', (WidgetTester tester) async {
    // In-memory prefs — no file system access needed in tests.
    SharedPreferences.setMockInitialValues({'onboarding_done': false});
    final prefs = await SharedPreferences.getInstance();
>>>>>>> 002b4c0 (fix: resolve navigation issues and improve UI consistency across home, explore, and market screens)


    // Bypasses the SharedPreferences singleton and FirebaseAuth entirely —
    // onboarding_done=false routes to OnboardingScreen, not the auth stream.
    final repo = OnboardingRepository(prefs: prefs);

    await tester.pumpWidget(NakhlahApp(onboardingRepo: repo));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
