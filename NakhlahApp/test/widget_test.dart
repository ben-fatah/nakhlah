import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nakhlah/main.dart';
import 'package:nakhlah/repositories/onboarding_repository.dart';

void main() {
  testWidgets('NakhlahApp builds without throwing', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_done': false});
    final prefs = await SharedPreferences.getInstance();
    final onboardingRepo = OnboardingRepository(prefs: prefs);

    await tester.pumpWidget(NakhlahApp(onboardingRepo: onboardingRepo));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
