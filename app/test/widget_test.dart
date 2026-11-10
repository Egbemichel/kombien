import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kombien/app/app_state.dart';
import 'package:kombien/components/k_cards.dart';
import 'package:kombien/components/k_controls.dart';
import 'package:kombien/data/city_pack.dart';
import 'package:kombien/data/fare_repository.dart';
import 'package:kombien/main.dart';
import 'package:kombien/services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fakes.dart';

void main() {
  // google_fonts fetches font files over the network at runtime; disable
  // that in tests so CI doesn't depend on network access.
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Home asks where from and where to', (tester) async {
    await tester.pumpWidget(KombienApp(showSplash: false, state: fakeState()));
    await tester.pumpAndSettle();
    expect(find.text('Where are you leaving from?'), findsOneWidget);
    expect(find.text('Tu go où?'), findsOneWidget);
    expect(find.text('Your saved destinations'), findsOneWidget);
  });

  // The root menu is the last one in the tree (the style guide holds a demo copy).
  Finder menuButton() => find.byKey(const Key('kombien-menu-button')).last;

  testWidgets('Floating menu opens with every destination and closes again', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(KombienApp(showSplash: false, state: fakeState()));

    await tester.tap(menuButton());
    await tester.pumpAndSettle();
    for (final label in ['Je paie combien?', 'Report', 'Settings']) {
      expect(find.text(label), findsWidgets, reason: label);
    }
    expect(find.text('Style guide'), findsNothing); // never in the menu

    await tester.tap(menuButton());
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsNothing);
  });

  testWidgets('Choosing Report in the menu shows the report route step', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(KombienApp(showSplash: false, state: fakeState()));
    await tester.pumpAndSettle();

    await tester.tap(menuButton());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Report'));
    await tester.pumpAndSettle();
    expect(find.text('Where are you/did you leave from?'), findsOneWidget);
    expect(find.text('To'), findsOneWidget);
  });

  testWidgets('Picking a destination offers to save it; saved shows below', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(KombienApp(showSplash: false, state: fakeState()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'eya');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eyang'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save this place'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Work').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save as Work'));
    await tester.pumpAndSettle();

    expect(find.text('Saved as Work'), findsOneWidget);
    expect(find.byType(KSavedChip), findsOneWidget);
  });

  Future<void> openHome(WidgetTester tester, KAppState state) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    await state.load();
    await tester.pumpWidget(KombienApp(showSplash: false, state: state));
    await tester.pumpAndSettle();
  }

  Future<void> pickDestination(
    WidgetTester tester,
    String typed,
    String name,
  ) async {
    await tester.enterText(find.byType(TextField).at(1), typed);
    await tester.pumpAndSettle();
    await tester.tap(find.text(name).last);
    await tester.pumpAndSettle();
  }

  testWidgets('From My location to a destination: the fare range shows', (
    tester,
  ) async {
    await openHome(tester, fakeState(current: LocationAccess.granted));
    expect(find.byType(KFareCard), findsNothing);

    await pickDestination(tester, 'eya', 'Eyang');
    expect(find.byType(KFareCard), findsOneWidget);
    expect(find.text('Demo range, not real reports yet'), findsOneWidget);
    expect(find.textContaining('FCFA'), findsOneWidget);
    expect(find.byType(KCashHint), findsOneWidget);
  });

  testWidgets('My location is looked up as the nearest saved place', (
    tester,
  ) async {
    final packs = CityPacks()
      ..saved.value = {
        'Yaoundé': CityPack(
          city: 'Yaoundé',
          savedAt: DateTime.now(),
          places: [
            PackPlace('warda', 'Carrefour Warda', const [], 3.8716, 11.5146),
            PackPlace('eyang', 'Eyang', const [], 3.7860, 11.5450),
          ],
          fares: const {},
        ),
      };
    final fares = FakeFares(answer: const FareRange(low: 300, high: 400));
    await openHome(
      tester,
      fakeState(
        current: LocationAccess.granted,
        at: (3.8720, 11.5150), // a few metres from Warda
        packs: packs,
        fares: fares,
      ),
    );
    await pickDestination(tester, 'eya', 'Eyang');

    final (from, to) = fares.asked.last;
    expect(from.id, 'warda'); // not a nameless "My location"
    expect(to.id, 'eyang');
    expect(find.text('My location'), findsOneWidget); // the field still says so
  });

  testWidgets('No start, destination picked: the start field flags itself', (
    tester,
  ) async {
    await openHome(tester, fakeState());
    await pickDestination(tester, 'eya', 'Eyang');

    expect(find.text("Add where you're leaving from first"), findsOneWidget);
    expect(find.byType(KFareCard), findsNothing);
    final start = tester.widget<TextField>(find.byType(TextField).first);
    expect(start.focusNode!.hasFocus, isTrue);

    // Typing there clears the error; picking a start brings the range.
    await tester.enterText(find.byType(TextField).first, 'post');
    await tester.pumpAndSettle();
    expect(find.text("Add where you're leaving from first"), findsNothing);
    await tester.tap(find.text('Poste Centrale').last);
    await tester.pumpAndSettle();
    expect(find.byType(KFareCard), findsOneWidget);
  });
}
