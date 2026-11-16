import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kombien/app/app_state.dart';
import 'package:kombien/components/k_cards.dart';
import 'package:kombien/data/fare_repository.dart';
import 'package:kombien/data/place_requests.dart';
import 'package:kombien/main.dart';
import 'package:kombien/services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fakes.dart';

/// A server for place requests that records what it is asked.
class _Server {
  final suggestions = <Map<String, Object?>>[];
  final watches = <Map<String, Object?>>[];
  var forgets = 0;
  var offline = false;

  PlaceRequests requests() => PlaceRequests(
    send: (row) async {
      if (offline) throw StateError('offline');
      suggestions.add(row);
    },
    sendWatch: (row) async {
      if (offline) throw StateError('offline');
      watches.add(row);
    },
    forgetOnServer: () async => forgets++,
  );
}

Future<(KAppState, FakePush, _Server)> _app({
  bool pushOn = false,
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final server = _Server();
  final push = FakePush(permission: pushOn ? 'granted' : 'default');
  final state = KAppState(
    location: FakeLocation(),
    push: push,
    placeRequests: server.requests(),
  );
  await state.load();
  if (pushOn) await state.enablePush();
  return (state, push, server);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('what may be sent', () {
    test('a place name: 3 to 80 letters, nothing personal', () {
      expect(
        PlaceRequests.cleanName('  Ancien   Troisième '),
        'Ancien Troisième',
      );
      expect(PlaceRequests.cleanName('ab'), isNull);
      expect(PlaceRequests.cleanName('x' * 81), isNull);
      expect(PlaceRequests.cleanName('me@example.com'), isNull);
      expect(PlaceRequests.cleanName('https://example.com'), isNull);
      expect(PlaceRequests.cleanName('677 12 34 56'), isNull); // a phone number
    });

    test('the note: optional, cut at 120, dropped when personal', () {
      expect(PlaceRequests.cleanNote(null), isNull);
      expect(PlaceRequests.cleanNote('   '), isNull);
      expect(
        PlaceRequests.cleanNote(' behind  the market '),
        'behind the market',
      );
      expect(PlaceRequests.cleanNote('x' * 200)!.length, 120);
      expect(PlaceRequests.cleanNote('call 677123456'), isNull);
    });
  });

  group('Tell us about it', () {
    test('is sent with the city and language, note included', () async {
      final (state, _, server) = await _app();
      expect(
        await state.suggestPlace('Ancien Troisième', note: 'near Akwa'),
        isTrue,
      );
      expect(server.suggestions, [
        {
          'name': 'Ancien Troisième',
          'note': 'near Akwa',
          'city': 'Yaoundé',
          'locale': 'en',
        },
      ]);
    });

    test('a name that cannot be sent is refused, and nothing leaves', () async {
      final (state, _, server) = await _app();
      expect(await state.suggestPlace('me@example.com'), isFalse);
      expect(server.suggestions, isEmpty);
      expect(await state.placeRequests.waiting(), 0);
    });

    test(
      'offline it waits on the phone (the newest 20) and goes later',
      () async {
        final (state, _, server) = await _app();
        server.offline = true;
        for (var i = 0; i < 25; i++) {
          await state.suggestPlace('Place number $i');
        }
        expect(await state.placeRequests.waiting(), PlaceRequests.maxQueued);

        server.offline = false;
        await state.sync();
        expect(server.suggestions.length, PlaceRequests.maxQueued);
        expect(
          server.suggestions.first['name'],
          'Place number 5',
        ); // oldest dropped
        expect(server.suggestions.last['name'], 'Place number 24');
        expect(await state.placeRequests.waiting(), 0);
      },
    );
  });

  group('searches kept to tell the rider (notifications on only)', () {
    test('with notifications on, a search that found nothing is kept for the '
        'rider, once', () async {
      final (state, _, server) = await _app(pushOn: true);
      await state.logSearchMiss('Ancien Troisième');
      await state.logSearchMiss('ancien  troisième'); // the same, retyped
      expect(server.watches, [
        {'q': 'ancien troisième', 'city': 'Yaoundé', 'locale': 'en'},
      ]);
    });

    test('with notifications off, nothing about the rider is kept (the '
        'anonymous count is separate)', () async {
      final (state, _, server) = await _app();
      await state.logSearchMiss('Ancien Troisième');
      expect(server.watches, isEmpty);
    });

    test('turning notifications off makes the server forget them', () async {
      final (state, _, server) = await _app(pushOn: true);
      await state.disablePush();
      await Future<void>.delayed(Duration.zero);
      expect(server.forgets, 1);
    });

    test('a failing server never gets in the way', () async {
      final (state, _, server) = await _app(pushOn: true);
      server.offline = true;
      await state.logSearchMiss('Ancien Troisième'); // does not throw
      expect(server.watches, isEmpty);
    });
  });

  group('👍 on a fare range', () {
    Future<(KAppState, FakePush)> home(
      WidgetTester tester, {
      required bool pushOn,
    }) async {
      tester.view.physicalSize = const Size(402, 874);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final push = FakePush(permission: pushOn ? 'granted' : 'default');
      final state = fakeState(
        current: LocationAccess.granted,
        fares: FakeFares(answer: const FareRange(low: 300, high: 400)),
        push: push,
      );
      await state.load();
      if (pushOn) await state.enablePush();
      await tester.pumpWidget(KombienApp(showSplash: false, state: state));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(1), 'eya');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eyang').last);
      await tester.pumpAndSettle();
      expect(find.byType(KFeedbackRow), findsOneWidget);
      return (state, push);
    }

    Finder thumb(int i) => find
        .descendant(
          of: find.byType(KFeedbackRow),
          matching: find.byType(GestureDetector),
        )
        .at(i);

    testWidgets('a toast that just says thank you, and a thank-you on the '
        'phone when notifications are on', (tester) async {
      final (_, push) = await home(tester, pushOn: true);
      await tester.tap(thumb(0));
      await tester.pumpAndSettle();
      expect(find.text('Thank you!'), findsOneWidget);
      expect(find.text('Glad the fare range helped.'), findsOneWidget);
      expect(push.calls, contains('thanks'));
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('notifications off: the toast only', (tester) async {
      final (_, push) = await home(tester, pushOn: false);
      await tester.tap(thumb(0));
      await tester.pumpAndSettle();
      expect(find.text('Thank you!'), findsOneWidget);
      expect(push.calls, isNot(contains('thanks')));
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('👎 keeps its own note and sends no thank-you', (tester) async {
      final (_, push) = await home(tester, pushOn: true);
      await tester.tap(thumb(1));
      await tester.pumpAndSettle();
      expect(find.text('Feedback recorded!'), findsOneWidget);
      expect(push.calls, isNot(contains('thanks')));
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });
  });
}
