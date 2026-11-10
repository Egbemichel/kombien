import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kombien/components/k_bits.dart';
import 'package:kombien/components/k_controls.dart';
import 'package:kombien/app/app_state.dart';
import 'package:kombien/main.dart';
import 'package:kombien/screens/location_prompt_screen.dart';
import 'package:kombien/screens/onboarding_screen.dart';
import 'package:kombien/screens/root_shell.dart';
import 'package:kombien/screens/splash_screen.dart';
import 'package:kombien/services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fakes.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  KButton action(WidgetTester tester) => tester.widget<KButton>(
    find.descendant(
      of: find.byType(KOnboardingSheet),
      matching: find.byType(KButton),
    ),
  );

  testWidgets('onboarding: Continue, then Get started waits for the terms', (
    tester,
  ) async {
    phone(tester);
    var done = false;
    await tester.pumpWidget(
      MaterialApp(home: OnboardingScreen(onDone: () => done = true)),
    );
    expect(find.text('Je paie combien?'), findsOneWidget);
    expect(find.text('Post Centrale,\nXAF 500'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Paid? Say so.'), findsOneWidget);
    expect(action(tester).onPressed, isNull);

    await tester.tap(find.byType(KTermsCheckbox));
    await tester.pumpAndSettle();
    expect(action(tester).onPressed, isNotNull);
    await tester.tap(find.text('Get started'));
    expect(done, isTrue);
  });

  testWidgets('onboarding: Skip goes to the terms page; the flag switches', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(MaterialApp(home: OnboardingScreen(onDone: () {})));
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('Paid? Say so.'), findsOneWidget);

    expect(find.text('En'), findsOneWidget);

    // A tap opens the dropdown; it does not switch by itself.
    await tester.tap(find.byType(KLanguageSelector));
    await tester.pumpAndSettle();
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Français'), findsOneWidget);
    expect(find.text('En'), findsOneWidget);

    // Tapping outside closes it, unchanged.
    await tester.tapAt(const Offset(40, 300));
    await tester.pumpAndSettle();
    expect(find.text('Français'), findsNothing);
    expect(find.text('En'), findsOneWidget);

    // Picking a language applies it and closes the menu.
    await tester.tap(find.byType(KLanguageSelector));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Français'));
    await tester.pumpAndSettle();
    expect(find.text('Fr'), findsOneWidget);
    expect(find.text('English'), findsNothing);
  });

  Future<void> launch(WidgetTester tester, KAppState state) async {
    phone(tester);
    await tester.pumpWidget(KombienApp(state: state));
    // The launch reads its flags (first run or returning) before choosing
    // the splash or the app.
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    // Splash layers decode for real, then the timeline runs frame by frame.
    await tester.runAsync(() => Future.delayed(const Duration(seconds: 1)));
    for (var t = 0; t < 4000; t += 16) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pumpAndSettle();
  }

  Future<void> finishOnboarding(WidgetTester tester) async {
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(KTermsCheckbox));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
  }

  testWidgets('first launch: allowing location opens home on My location', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final state = fakeState(answer: LocationAccess.granted);
    await launch(tester, state);
    expect(find.byType(OnboardingScreen), findsOneWidget);

    await finishOnboarding(tester);
    expect(find.byType(LocationPromptScreen), findsOneWidget);
    expect(
      find.text('Hey there! Worried about what fare to propose?'),
      findsOneWidget,
    );

    await tester.tap(find.text('Get started from where I am'));
    await tester.pumpAndSettle();
    expect(find.byType(RootShell), findsOneWidget);
    expect(find.text('My location'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('onboarded'), isTrue);
    expect(prefs.getBool('location_asked'), isTrue);
  });

  testWidgets('first launch: Skip for now opens home on the landmark search', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final state = fakeState();
    await launch(tester, state);
    await finishOnboarding(tester);

    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();
    expect(find.byType(RootShell), findsOneWidget);
    expect(
      find.text("Can't see where you are. Search a landmark instead"),
      findsOneWidget,
    );
    expect((state.location as FakeLocation).requests, 0);
  });

  testWidgets('later launches skip the splash and open the app', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'onboarded': true,
      'location_asked': true,
    });
    await launch(tester, fakeState(current: LocationAccess.granted));
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(LocationPromptScreen), findsNothing);
    expect(find.text('My location'), findsOneWidget);
  });

  test('location allowed before stays on, even when the browser reports '
      '"not decided"; checked again quietly', () async {
    SharedPreferences.setMockInitialValues({'location_granted': true});
    final location = FakeLocation(answer: LocationAccess.granted);
    final state = KAppState(location: location);
    await state.load();
    expect(state.locationAccess.value, LocationAccess.granted);
    await Future<void>.delayed(Duration.zero);
    expect(location.requests, 1); // the quiet re-check
  });

  test(
    'the re-check failing turns location off and forgets the grant',
    () async {
      SharedPreferences.setMockInitialValues({'location_granted': true});
      final location = FakeLocation(answer: LocationAccess.blocked);
      final state = KAppState(location: location);
      await state.load();
      await Future<void>.delayed(Duration.zero);
      expect(state.locationAccess.value, LocationAccess.blocked);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('location_granted'), isFalse);
    },
  );

  test('Off in Settings wins over a remembered grant', () async {
    SharedPreferences.setMockInitialValues({
      'location_granted': true,
      'location_off': true,
    });
    final location = FakeLocation(answer: LocationAccess.granted);
    final state = KAppState(location: location);
    await state.load();
    expect(state.locationAccess.value, LocationAccess.denied);
    expect(location.requests, 0);
  });

  testWidgets('language: switching on onboarding changes the whole app', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final state = fakeState();
    await launch(tester, state);

    await tester.tap(find.byType(KLanguageSelector));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Français'));
    await tester.pumpAndSettle();
    expect(find.text('Fr'), findsOneWidget);
    expect(find.text('Passer'), findsOneWidget);
    expect(find.text('Continuer'), findsOneWidget);

    await tester.tap(find.text('Passer'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(KTermsCheckbox));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();
    expect(find.text('Plus tard'), findsOneWidget);
    await tester.tap(find.text('Plus tard'));
    await tester.pumpAndSettle();
    expect(find.text("Tu pars d'où?"), findsOneWidget);

    // Remembered for next time.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('language'), 'fr');
  });

  testWidgets('language: Settings switches it back, live', (tester) async {
    SharedPreferences.setMockInitialValues({'language': 'fr'});
    phone(tester);
    final state = fakeState();
    await state.load();
    await tester.pumpWidget(KombienApp(showSplash: false, state: state));
    await tester.pumpAndSettle();
    expect(find.text("Tu pars d'où?"), findsOneWidget);

    await tester.tap(find.byKey(const Key('kombien-menu-button')).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Paramètres'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsWidgets);
    expect(state.language.value.languageCode, 'en');
  });
}
