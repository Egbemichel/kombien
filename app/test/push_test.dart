import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kombien/app/app_state.dart';
import 'package:kombien/data/landmark_repository.dart';
import 'package:kombien/data/report_repository.dart';
import 'package:kombien/main.dart';
import 'package:kombien/services/push.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fakes.dart';

/// A browser and server for notifications, recording what was asked.
class FakePush implements PushClient {
  FakePush({this.supported = true, this.permission = 'default'});
  @override
  bool supported;
  @override
  String permission;

  /// What the browser answers when asked.
  bool allow = true;
  final calls = <String>[];

  @override
  Future<bool> enable(String locale) async {
    calls.add('enable $locale');
    permission = allow ? 'granted' : 'denied';
    return allow;
  }

  @override
  Future<void> disable() async => calls.add('disable');

  @override
  Future<void> setLocale(String locale) async => calls.add('locale $locale');

  @override
  Future<void> routeReported(String fromId, String toId) async =>
      calls.add('reported $fromId→$toId');

  @override
  Future<void> flush() async => calls.add('flush');

  @override
  Future<String> sendTest() async {
    calls.add('test');
    return 'sent';
  }
}

/// Reports that always reach the server.
class SentReports implements ReportRepository {
  final _all = <StoredReport>[];
  @override
  Future<StoredReport> submit(FareReport report) async {
    final r = StoredReport.of(report, sent: true);
    _all.insert(0, r);
    return r;
  }

  @override
  Future<List<StoredReport>> history() async => List.of(_all);
  @override
  Future<List<StoredReport>> sendWaiting() async => List.of(_all);
  @override
  Future<void> deleteAll() async => _all.clear();
}

const _report = FareReport(
  from: Landmark(id: 'poste', name: 'Poste Centrale'),
  to: Landmark(id: 'eyang', name: 'Eyang'),
  amountXaf: 450,
);

Future<(KAppState, FakePush)> _app({
  FakePush? push,
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final p = push ?? FakePush();
  final state = KAppState(
    location: FakeLocation(),
    reports: SentReports(),
    push: p,
  );
  await state.load();
  return (state, p);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('a sent report tells the server (it may unlock fares) and offers '
      'notifications', () async {
    final (state, push) = await _app();
    await state.submitReport(_report);
    expect(push.calls, contains('reported poste→eyang'));
    expect(state.pushOffer.value, isTrue);
  });

  test('offered at most twice, never when blocked, unsupported, already '
      'on, or after another question today', () async {
    Future<bool> offered(
      FakePush push, [
      Map<String, Object> prefs = const {},
    ]) async {
      final (state, _) = await _app(push: push, prefs: prefs);
      await state.submitReport(_report);
      return state.pushOffer.value;
    }

    final today = DateTime.now().toIso8601String().substring(0, 10);
    expect(await offered(FakePush(), {'push_offers': 2}), isFalse);
    expect(await offered(FakePush(permission: 'denied')), isFalse);
    expect(await offered(FakePush(supported: false)), isFalse);
    expect(
      await offered(FakePush(permission: 'granted'), {'push_on': true}),
      isFalse,
    );
    expect(await offered(FakePush(), {'nudge_day': today}), isFalse);
  });

  test('turning on and off; on follows the browser after a restart', () async {
    final (state, push) = await _app();
    expect(await state.enablePush(), isTrue);
    expect(state.pushOn.value, isTrue);
    expect(push.calls, contains('enable en'));

    // Restart, browser still allows: on.
    final (again, _) = await _app(
      push: FakePush(permission: 'granted'),
      prefs: {'push_on': true},
    );
    expect(again.pushOn.value, isTrue);

    // Restart after the rider blocked it in the browser: off.
    final (blocked, _) = await _app(
      push: FakePush(permission: 'denied'),
      prefs: {'push_on': true},
    );
    expect(blocked.pushOn.value, isFalse);

    await state.disablePush();
    expect(state.pushOn.value, isFalse);
    expect(push.calls.last, 'disable');
  });

  test('refused in the browser: stays off', () async {
    final (state, push) = await _app(push: FakePush()..allow = false);
    expect(await state.enablePush(), isFalse);
    expect(state.pushOn.value, isFalse);
    expect(push.permission, 'denied');
  });

  test('notifications follow the app language', () async {
    final (state, push) = await _app();
    await state.enablePush();
    await state.setLanguage(const Locale('fr'));
    expect(push.calls, contains('locale fr'));
  });

  testWidgets('after a report: the offer toast, Turn on, confirmed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final (state, push) = await _app();
    await tester.pumpWidget(KombienApp(showSplash: false, state: state));
    await tester.pumpAndSettle();

    await state.submitReport(_report);
    await tester.pump(const Duration(milliseconds: 4600));
    await tester.pumpAndSettle();
    expect(find.text('Want to know when it counts?'), findsOneWidget);

    await tester.tap(find.text('Turn on'));
    await tester.pumpAndSettle();
    expect(push.calls, contains('enable en'));
    expect(find.text('Notifications on'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('Settings: a long press on the version sends a test, only '
      'with notifications on', (tester) async {
    tester.view.physicalSize = const Size(402, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final (state, push) = await _app();
    state.page.value = 2;
    await tester.pumpWidget(KombienApp(showSplash: false, state: state));
    await tester.pumpAndSettle();

    final version = find.text('Mark I · version 0.1.0');
    await tester.longPress(version);
    await tester.pumpAndSettle();
    expect(push.calls, isNot(contains('test'))); // off: nothing

    await state.enablePush();
    await tester.longPress(version);
    await tester.pumpAndSettle();
    expect(push.calls, contains('test'));
    expect(find.text('Test notification sent'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  for (final supported in [true, false]) {
    testWidgets('Settings: the switch shows only where notifications work '
        '(supported: $supported)', (tester) async {
      tester.view.physicalSize = const Size(402, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final (state, _) = await _app(push: FakePush(supported: supported));
      state.page.value = 2;
      await tester.pumpWidget(KombienApp(showSplash: false, state: state));
      await tester.pumpAndSettle();
      expect(
        find.text('Fares unlocked, updates, morning reminders'),
        supported ? findsOneWidget : findsNothing,
      );
    });
  }
}
