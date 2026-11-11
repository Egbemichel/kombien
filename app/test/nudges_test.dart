import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kombien/app/app_state.dart';
import 'package:kombien/components/k_layout.dart';
import 'package:kombien/data/city_pack.dart';
import 'package:kombien/data/fare_repository.dart';
import 'package:kombien/data/landmark_repository.dart';
import 'package:kombien/data/report_repository.dart';
import 'package:kombien/main.dart';
import 'package:kombien/services/location_service.dart';
import 'package:kombien/services/update.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fakes.dart';

// Eyang, as a city pack and OpenStreetMap place it.
const _eyang = (3.7860, 11.5450);

CityPacks _packs() => CityPacks()
  ..saved.value = {
    'Yaoundé': CityPack(
      city: 'Yaoundé',
      savedAt: DateTime.now(),
      places: [
        PackPlace('poste', 'Poste Centrale', const [], 3.8666, 11.5167),
        PackPlace('eyang', 'Eyang', const [], _eyang.$1, _eyang.$2),
      ],
      fares: const {},
    ),
  };

/// A trip looked up [ago], as the app remembers it.
String _trip(Duration ago) => jsonEncode(
  Trip(
    from: 'Poste Centrale',
    fromId: 'poste',
    to: 'Eyang',
    toId: 'eyang',
    lat: _eyang.$1,
    lng: _eyang.$2,
    at: DateTime.now().subtract(ago),
    low: 400,
    high: 500,
  ).toJson(),
);

const _report = FareReport(
  from: Landmark(id: 'poste', name: 'Poste Centrale'),
  to: Landmark(id: 'eyang', name: 'Eyang'),
  amountXaf: 450,
);

KAppState _state({(double, double)? at, FareRepository? fares}) => KAppState(
  location: FakeLocation(current: LocationAccess.granted, at: at),
  packs: _packs(),
  fares: fares,
);

/// Fares with no range until [reports] reach 3 (as on the server).
class _Unlocking implements FareRepository {
  int reports = 2;
  @override
  Future<FareRange?> range(Landmark from, Landmark to) async =>
      reports >= 3 ? const FareRange(low: 400, high: 500, reports: 3) : null;
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('Arrived? What did you pay?', () {
    test('asks at the destination of a route looked up 20 min ago', () async {
      SharedPreferences.setMockInitialValues({
        'last_trip': _trip(const Duration(minutes: 20)),
      });
      final state = _state(at: (3.7865, 11.5452)); // ~60 m from Eyang
      await state.load();
      await state.lookAround();
      expect(state.arrival.value?.to, 'Eyang');
      expect(state.arrival.value!.amounts, [400, 450, 500]);
    });

    test('stays quiet: far away, too soon, too late, asked today, or '
        'turned down twice', () async {
      Future<Trip?> asks(
        Map<String, Object> prefs, {
        (double, double) at = (3.7865, 11.5452),
      }) async {
        SharedPreferences.setMockInitialValues(prefs);
        final state = _state(at: at);
        await state.load();
        await state.lookAround();
        return state.arrival.value;
      }

      final trip = _trip(const Duration(minutes: 20));
      final today = DateTime.now().toIso8601String().substring(0, 10);
      expect(await asks({'last_trip': trip}, at: (3.8666, 11.5167)), isNull);
      expect(
        await asks({'last_trip': _trip(const Duration(seconds: 30))}),
        isNull,
      );
      expect(
        await asks({'last_trip': _trip(const Duration(hours: 3))}),
        isNull,
      );
      expect(await asks({'last_trip': trip, 'nudge_day': today}), isNull);
      expect(await asks({'last_trip': trip, 'arrival_declined': 2}), isNull);
    });

    test('one tap reports the amount; Not now counts as turned down', () async {
      SharedPreferences.setMockInitialValues({
        'last_trip': _trip(const Duration(minutes: 20)),
      });
      final state = _state(at: (3.7865, 11.5452));
      await state.load();
      await state.lookAround();
      await state.answerArrival(450);
      final r = state.reportHistory.value.single;
      expect((r.from, r.to, r.amountXaf), ('Poste Centrale', 'Eyang', 450));
      expect(state.arrival.value, isNull);

      SharedPreferences.setMockInitialValues({
        'last_trip': _trip(const Duration(minutes: 20)),
      });
      final other = _state(at: (3.7865, 11.5452));
      await other.load();
      await other.lookAround();
      await other.answerArrival(null);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('arrival_declined'), 1);
      expect(prefs.getString('last_trip'), isNull);
    });

    test(
      'a looked-up route is remembered only with a known destination',
      () async {
        SharedPreferences.setMockInitialValues({});
        final state = _state();
        await state.load();
        await state.rememberTrip(
          const Landmark(id: 'poste', name: 'Poste Centrale'),
          const Landmark(id: 'eyang', name: 'Eyang'),
          const FareRange(low: 300, high: 400),
        );
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('last_trip'), contains('Eyang'));

        await prefs.remove('last_trip');
        await state.rememberTrip(
          const Landmark(id: 'poste', name: 'Poste Centrale'),
          const Landmark(name: 'Somewhere unknown'),
          null,
        );
        expect(prefs.getString('last_trip'), isNull);
      },
    );

    testWidgets('the sheet: tap an amount, the report is added and thanked', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(402, 874);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({
        'last_trip': _trip(const Duration(minutes: 20)),
      });
      final state = _state(at: (3.7865, 11.5452));
      await state.load();
      await tester.pumpWidget(KombienApp(showSplash: false, state: state));
      await tester.pumpAndSettle();
      await state.lookAround();
      await tester.pumpAndSettle();

      expect(find.text('Arrived at Eyang?'), findsOneWidget);
      await tester.tap(find.text('450 FCFA'));
      await tester.pumpAndSettle();
      expect(find.text('Fare added'), findsOneWidget);
      expect(state.reportHistory.value.single.amountXaf, 450);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });
  });

  group('Your report unlocked a range', () {
    test('reported before any range: credited once a range appears, '
        'then forgotten', () async {
      SharedPreferences.setMockInitialValues({});
      final fares = _Unlocking()..reports = 2;
      final state = _state(fares: fares)..online = () => true;
      await state.load();
      await state.submitReport(_report);
      await state.checkUnlocks();
      expect(state.unlocked.value, isNull); // still too few

      fares.reports = 3; // this report, counted on the server
      await state.checkUnlocks();
      expect(state.unlocked.value, ('Poste Centrale', 'Eyang'));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('pending_unlock'), isEmpty);
    });

    test('no credit when a range already existed', () async {
      SharedPreferences.setMockInitialValues({});
      final fares = _Unlocking()..reports = 5;
      final state = _state(fares: fares)..online = () => true;
      await state.load();
      await state.submitReport(_report);
      await state.checkUnlocks();
      expect(state.unlocked.value, isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('pending_unlock'), isNull);
    });

    test('offline (no server): nothing is claimed', () async {
      SharedPreferences.setMockInitialValues({});
      final fares = _Unlocking()..reports = 3;
      final state = _state(fares: fares); // online() is false in tests
      await state.load();
      await state.submitReport(_report);
      await state.checkUnlocks();
      expect(state.unlocked.value, isNull);
    });
  });

  group('My city follows the rider', () {
    test('in Douala with My city Yaoundé: switches, Undo switches back '
        'for good', () async {
      SharedPreferences.setMockInitialValues({'my_city': 'Yaoundé'});
      final state = _state(at: (4.0500, 9.7000)); // Akwa, Douala
      await state.load();
      await state.lookAround();
      expect(state.myCity.value, 'Douala');
      expect(state.cityMoved.value, ('Yaoundé', 'Douala'));

      await state.undoCityMove();
      expect(state.myCity.value, 'Yaoundé');

      await state.detectCity(); // still in Douala: not switched again
      expect(state.myCity.value, 'Yaoundé');
    });

    test('outside every covered city: nothing changes', () async {
      SharedPreferences.setMockInitialValues({'my_city': 'Yaoundé'});
      final state = _state(at: (5.4700, 10.4200)); // Bafoussam
      await state.load();
      await state.lookAround();
      expect(state.myCity.value, 'Yaoundé');
      expect(state.cityMoved.value, isNull);
    });
  });

  testWidgets('a new version ready shows a toast with Restart', (tester) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final state = fakeState();
    await state.load();
    await tester.pumpWidget(KombienApp(showSplash: false, state: state));
    await tester.pumpAndSettle();

    updateReady.value = true;
    addTearDown(() => updateReady.value = false);
    await tester.pumpAndSettle();
    expect(find.text('Kombien has been updated'), findsOneWidget);
    expect(find.text('Restart'), findsOneWidget);
  });

  test('ArrivalAnswer types', () {
    expect(const PaidAmount(450).xaf, 450);
    expect(const OtherAmount(), isA<ArrivalAnswer>());
  });
}
