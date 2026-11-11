import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kombien/app/app_state.dart';
import 'package:kombien/components/k_bits.dart';
import 'package:kombien/components/k_cards.dart';
import 'package:kombien/components/k_controls.dart';
import 'package:kombien/components/k_layout.dart';
import 'package:kombien/data/fare_repository.dart';
import 'package:kombien/main.dart';
import 'package:kombien/services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fakes.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<KAppState> open(
    WidgetTester tester, {
    FareRepository? fares,
    LocationAccess access = LocationAccess.granted,
    Map<String, Object> prefs = const {},
  }) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues(prefs);
    final state = fakeState(current: access, fares: fares);
    await state.load();
    await tester.pumpWidget(KombienApp(showSplash: false, state: state));
    await tester.pumpAndSettle();
    return state;
  }

  Future<void> type(WidgetTester tester, int field, String text) async {
    await tester.enterText(find.byType(TextField).at(field), text);
    await tester.pumpAndSettle();
  }

  Future<void> pick(WidgetTester tester, String name) async {
    await tester.tap(find.text(name).last);
    await tester.pumpAndSettle();
  }

  Finder menuButton() => find.byKey(const Key('kombien-menu-button')).last;

  testWidgets('menu: touch, hold, drag moves it; the spot is remembered', (
    tester,
  ) async {
    final state = await open(tester);
    final before = tester.getCenter(menuButton()).dy;

    final g = await tester.startGesture(tester.getCenter(menuButton()));
    await tester.pump(const Duration(milliseconds: 700)); // held: lifts
    await g.moveBy(const Offset(0, -120));
    await tester.pump();
    await g.up();
    await tester.pumpAndSettle();

    final after = tester.getCenter(menuButton()).dy;
    expect(after, lessThan(before - 100));
    expect(state.menuPosition.value, lessThan(.6));
    final saved = (await SharedPreferences.getInstance()).getDouble(
      'menu_position',
    );
    expect(saved, state.menuPosition.value);

    // A plain tap still opens it.
    await tester.tap(menuButton());
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsWidgets);
  });

  testWidgets('fares: Report it here opens the form on that route', (
    tester,
  ) async {
    await open(tester);
    await type(tester, 1, 'eya');
    await pick(tester, 'Eyang');

    expect(find.byType(KFareCard), findsOneWidget);
    // Feedback is pinned at the bottom, under the saved destinations.
    expect(
      tester.getTopLeft(find.byType(KFeedbackRow)).dy,
      greaterThan(tester.getTopLeft(find.text('Your saved destinations')).dy),
    );

    await tester.tap(find.text('Report it here').first);
    await tester.pumpAndSettle();
    expect(find.byType(KRouteCard), findsOneWidget);
    expect(find.text('Eyang'), findsWidgets);
    expect(find.text('Some suggestions (prices in FCFA)'), findsOneWidget);
  });

  testWidgets('fares: no reports yet, Add report opens the form', (
    tester,
  ) async {
    await open(tester, fares: FakeFares());
    await type(tester, 1, 'eya');
    await pick(tester, 'Eyang');

    expect(
      find.text('No reports yet for this route. Be the first.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Add report'));
    await tester.pumpAndSettle();
    expect(find.byType(KRouteCard), findsOneWidget);
  });

  testWidgets('fares: offline shows the offline card with Retry', (
    tester,
  ) async {
    await open(tester, fares: FakeFares(offline: true));
    await type(tester, 1, 'eya');
    await pick(tester, 'Eyang');
    expect(
      find.text('No connection. Check your data and try again.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('search: nothing found shows the no-match card', (tester) async {
    await open(tester);
    await type(tester, 1, 'zzqx');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(
      find.text("Couldn't find that place. Try a nearby landmark instead"),
      findsOneWidget,
    );
  });

  testWidgets('report: amount limits, then the report is added and counted', (
    tester,
  ) async {
    final state = await open(
      tester,
      fares: FakeFares(answer: const FareRange(low: 500, high: 700)),
    );
    await type(tester, 1, 'eya');
    await pick(tester, 'Eyang');
    await tester.tap(find.text('Report it here').first);
    await tester.pumpAndSettle();

    KButton add() => tester.widget<KButton>(find.byType(KButton).last);
    expect(add().onPressed, isNull);
    expect(find.text('600'), findsOneWidget); // middle of 500–700

    final amount = find.byType(TextField).last;
    await tester.enterText(amount, '20');
    await tester.pumpAndSettle();
    expect(
      find.text('Enter an amount between 50 and 50 000 FCFA'),
      findsOneWidget,
    );
    expect(add().onPressed, isNull);

    await tester.tap(find.text('600'));
    await tester.pumpAndSettle();
    expect(add().onPressed, isNotNull);
    await tester.tap(find.text('Rainy'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add report'));
    await tester.pumpAndSettle();

    // No backend in tests: kept on the phone, and counted.
    expect(find.text('Saved on this phone'), findsOneWidget);
    expect(state.reportHistory.value, hasLength(1));
    expect(state.reportHistory.value.single.sent, isFalse);
    final queue = (await SharedPreferences.getInstance()).getStringList(
      'report_history',
    );
    expect(queue, hasLength(1));
    expect(queue!.single, contains('"amount_xaf":600'));
    expect(queue.single, contains('"raining":true'));

    // While the toast shows, the form stays (and can't be sent twice).
    expect(find.byType(KRouteCard), findsOneWidget);
    expect(add().onPressed, isNull);

    // Once it has gone: a fresh report, back on step 1 with empty fields.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.byType(KRouteCard), findsNothing);
    expect(find.text('Where are you/did you leave from?'), findsOneWidget);
    final to = tester.widget<TextField>(find.byType(TextField).last);
    expect(to.controller!.text, isEmpty);
  });

  testWidgets('settings: language, location off, report count', (tester) async {
    final state = await open(tester, prefs: {'report_history': _history(14)});
    tester.view.physicalSize = const Size(402, 2600); // the whole page
    state.page.value = 2;
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsWidgets);
    expect(find.text('14'), findsOneWidget);
    expect(find.text('Mark I · version 0.1.0'), findsOneWidget);

    await tester.tap(find.text('Off'));
    await tester.pumpAndSettle();
    expect(state.locationAccess.value.isGranted, isFalse);

    await tester.tap(find.text('Français'));
    await tester.pumpAndSettle();
    expect(find.text('Paramètres'), findsWidgets);
    expect(find.byType(KLanguageChip), findsNWidgets(2));
  });

  testWidgets('my reports: the list, the waiting note, delete with a check', (
    tester,
  ) async {
    final state = await open(tester, prefs: {'report_history': _history(3)});
    state.page.value = 2;
    await tester.pumpAndSettle();

    // The waiting note shows in Settings too (2 of the 3 are not sent).
    tester.view.physicalSize = const Size(402, 2600);
    await tester.pumpAndSettle();
    expect(
      find.text(
        "2 reports waiting for a connection. They'll send automatically",
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Reports from this phone'));
    await tester.pumpAndSettle();
    expect(find.text('My reports'), findsOneWidget);
    expect(find.byType(KReportTile), findsNWidgets(3));
    expect(find.text('Sent'), findsOneWidget);
    expect(find.text('Waiting for a connection'), findsNWidgets(2));
    expect(
      find.text(
        "2 reports waiting for a connection. They'll send automatically",
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Delete reports from this phone'));
    await tester.pumpAndSettle();
    expect(
      find.text('Delete the 3 reports saved on this phone?'),
      findsOneWidget,
    );
    expect(
      find.text('Reports already sent stay in the shared data.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(state.reportHistory.value, isEmpty);
    expect(find.byType(KReportTile), findsNothing);
    expect(
      find.textContaining('No reports from this phone yet'),
      findsOneWidget,
    );
  });

  testWidgets('settings: no saved fares for my city until it is downloaded', (
    tester,
  ) async {
    final state = await open(tester);
    tester.view.physicalSize = const Size(402, 2600);
    state.page.value = 2;
    await tester.pumpAndSettle();
    expect(
      find.text(
        'No saved fares for Yaoundé yet. Download them to use Kombien without a connection.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('settings: Report a problem asks, then thanks and queues it', (
    tester,
  ) async {
    final state = await open(tester);
    tester.view.physicalSize = const Size(402, 2600);
    state.page.value = 2;
    await tester.pumpAndSettle();
    // Web only: no install row in tests.
    expect(find.text('Install Kombien'), findsNothing);

    await tester.tap(find.text('Report a problem'));
    await tester.pumpAndSettle();
    final send = find.widgetWithText(KButton, 'Send');
    expect(tester.widget<KButton>(send).onPressed, isNull); // waits for Q1

    await tester.tap(find.text('A fare looks wrong'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Too low for Mvan');
    await tester.pumpAndSettle();
    await tester.tap(send);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Problem reported'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('problem_queue'), hasLength(1));
    await tester.pumpAndSettle(const Duration(seconds: 6));
  });
}

/// [n] stored reports, the first sent, the rest waiting.
List<String> _history(int n) => [
  for (var i = 0; i < n; i++)
    jsonEncode({
      'id': '$i',
      'from': 'Poste Centrale',
      'to': 'Eyang',
      'amount_xaf': 500 + i * 50,
      'day_part': 'morning',
      'raining': false,
      'vehicle': 'taxi',
      'at': DateTime(2026, 11, 9, 8, i).toIso8601String(),
      'sent': i == 0,
    }),
];
