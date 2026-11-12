import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kombien/app/app_state.dart';
import 'package:kombien/data/city_pack.dart';
import 'package:kombien/data/google_places.dart';
import 'package:kombien/data/landmark_repository.dart';
import 'package:kombien/data/rider_places.dart';
import 'package:kombien/data/search_miss_log.dart';
import 'package:kombien/main.dart';
import 'package:kombien/services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fakes.dart';

/// Real Yaoundé places from OpenStreetMap, as the packs hold them.
List<PackPlace> _yaounde() => [
  PackPlace(
    'mendong',
    'Camp SIC de Mendong',
    const [],
    3.834651,
    11.469043,
    'place=neighbourhood',
  ),
  PackPlace(
    'tkc',
    'Carrefour Chapelle TKC',
    const [],
    3.837687,
    11.474792,
    'place=locality',
  ),
  PackPlace(
    'messassi',
    'Carrefour Messassi',
    const [],
    3.941935,
    11.518456,
    'place=locality',
  ),
  PackPlace(
    'pharm',
    'Pharmacie de Messassi',
    const [],
    3.942258,
    11.519064,
    'amenity=pharmacy',
  ),
  PackPlace(
    'onu',
    "Dispensaire de l'ONU",
    const [],
    3.891917,
    11.506174,
    'amenity=clinic',
  ),
  PackPlace(
    'warda',
    'Carrefour Warda',
    const [],
    3.8716,
    11.5146,
    'place=locality',
  ),
];

CityPacks _packs({bool douala = true}) => CityPacks()
  ..saved.value = {
    'Yaoundé': CityPack(
      city: 'Yaoundé',
      savedAt: DateTime.now(),
      places: _yaounde(),
      fares: const {},
    ),
    if (douala)
      'Douala': CityPack(
        city: 'Douala',
        savedAt: DateTime.now(),
        places: [
          PackPlace('akwa', 'Akwa', const [], 4.054, 9.704, 'place=quarter'),
        ],
        fares: const {},
      ),
  };

/// A database that never answers (a slow connection), or answers [found].
class _Remote implements LandmarkRepository {
  _Remote({this.found = const [], this.never = false});
  final List<Landmark> found;
  final bool never;
  int calls = 0;
  @override
  Future<List<Landmark>> search(
    String query, {
    double? lat,
    double? lng,
    int limit = 3,
  }) {
    calls++;
    if (never) return Completer<List<Landmark>>().future;
    return Future.value(found);
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('finding places', () {
    final packs = _packs();
    List<String> find(String q) => [
      for (final l in packs.search(q, limit: 5)) l.name,
    ];

    test('a slip of a letter still finds it ("Messasi" for Messassi)', () {
      expect(find('messasi'), ['Carrefour Messassi', 'Pharmacie de Messassi']);
    });

    test('every word counts, in any order, filler words ignored', () {
      expect(find('messassi pharmacie'), ['Pharmacie de Messassi']);
      expect(find('pharmacie messassi'), ['Pharmacie de Messassi']);
      expect(find('pharmacie du messassi'), ['Pharmacie de Messassi']);
    });

    test('a place that is not there finds nothing (not a near miss on '
        'one word)', () {
      expect(find('dispensaire messasi'), isEmpty);
      expect(find('zzzz'), isEmpty);
    });

    test('exact text first, then every-word, then slips', () {
      expect(find('carrefour messassi'), ['Carrefour Messassi']);
      expect(find('onu'), ["Dispensaire de l'ONU"]);
    });

    test('short words are never guessed at', () {
      expect(find('wad'), isEmpty); // not Warda: too short to slip
    });
  });

  group('the place I am at', () {
    final packs = _packs();

    test('a junction beats the centre of a neighbourhood nearby '
        '(Chapelle TKC, not Mendong)', () {
      // Standing at the junction, a little closer to Mendong's centre.
      final here = packs.nearest(3.8362, 11.4730)!;
      expect(here.name, 'Carrefour Chapelle TKC');
    });

    test('with only a neighbourhood around, it is the neighbourhood', () {
      expect(packs.nearest(3.8346, 11.4692)!.name, 'Camp SIC de Mendong');
    });

    test('nowhere near anything: nothing', () {
      expect(packs.nearest(3.70, 11.40), isNull);
    });
  });

  group('not found is decided on the phone', () {
    test('every covered city saved: no wait on the network at all', () async {
      final remote = _Remote(never: true);
      final repo = OfflineFirstLandmarkRepository(_packs(), remote);
      final found = await repo.search('dispensaire messasi');
      expect(found, isEmpty);
      expect(remote.calls, 0);
    });

    test('a city missing: the database is asked, but only briefly', () async {
      final remote = _Remote(never: true);
      final repo = OfflineFirstLandmarkRepository(
        _packs(douala: false),
        remote,
        remoteTimeout: const Duration(milliseconds: 50),
      );
      final found = await repo.search('akwa');
      expect(found, isEmpty); // answered after the short wait, not never
      expect(remote.calls, 1);
    });

    test('a city missing: what the database knows is added', () async {
      final repo = OfflineFirstLandmarkRepository(
        _packs(douala: false),
        _Remote(
          found: const [Landmark(id: 'akwa', name: 'Akwa')],
        ),
      );
      expect((await repo.search('akwa')).single.name, 'Akwa');
    });
  });

  testWidgets('searching for a place that is not there: the not-found card '
      'at once, and a way to tell us', (tester) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final state = KAppState(
      location: FakeLocation(current: LocationAccess.denied),
      packs: _packs(),
      landmarks: OfflineFirstLandmarkRepository(_packs(), _Remote(never: true)),
    );
    await state.load();
    await tester.pumpWidget(KombienApp(showSplash: false, state: state));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(1), 'Dispensaire Messasi');
    await tester.pumpAndSettle();
    expect(
      find.text("Couldn't find that place. Try a nearby landmark instead"),
      findsOneWidget,
    );

    await tester.tap(find.text('Tell us about it'));
    await tester.pumpAndSettle();
    expect(find.text('Something not right?'), findsOneWidget);
    // "A place is missing", already chosen, with what was typed.
    expect(find.text('Dispensaire Messasi'), findsWidgets);
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();
    expect(find.text('Problem reported'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  Future<(KAppState, List<Map<String, Object?>>)> missingPlaceApp(
    WidgetTester tester, {
    GooglePlaces? google,
    RiderPlaces? riders,
  }) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final logged = <Map<String, Object?>>[];
    final state = KAppState(
      location: FakeLocation(current: LocationAccess.denied),
      packs: _packs(),
      landmarks: OfflineFirstLandmarkRepository(_packs(), _Remote(never: true)),
      searchMisses: SearchMissLog(send: (row) async => logged.add(row)),
      googlePlaces: google,
      riderPlaces: riders,
    );
    await state.load();
    await tester.pumpWidget(KombienApp(showSplash: false, state: state));
    await tester.pumpAndSettle();
    return (state, logged);
  }

  // ------------------------------------------------ a place Google knows

  const sinoMart =
      '{"suggestions": [{"placePrediction": {"placeId": "ChIJsinomart0001", '
      '"text": {"text": "Sino Mart, Elig-Edzoa, Yaoundé"}, '
      '"structuredFormat": {"mainText": {"text": "Sino Mart"}, '
      '"secondaryText": {"text": "Elig-Edzoa, Yaoundé"}}}}]}';

  testWidgets('a place Kombien lacks: Google\'s suggestions appear with '
      'Google\'s credit; picking one asks what to call it, saves it as the '
      'rider\'s own words with only the Google place ID, and uses it', (
    tester,
  ) async {
    final asked = <http.Request>[];
    final google = GooglePlaces(
      key: 'test-key',
      client: MockClient((request) async {
        asked.add(request);
        return http.Response(sinoMart, 200);
      }),
    );
    (String, String, String)? saved;
    final riders = RiderPlaces(
      findOnServer: (_, _) async => const [],
      addOnServer: (city, label, placeId) async {
        saved = (city, label, placeId);
        return Landmark(id: 'landmark-sino', name: label);
      },
    );
    await missingPlaceApp(tester, google: google, riders: riders);

    await tester.enterText(find.byType(TextField).at(1), 'sino mart');
    await tester.pump(const Duration(milliseconds: 300));
    expect(asked, isEmpty); // not while they are still typing
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(asked, hasLength(1));
    expect(
      find.text('Not in Kombien yet. Is it one of these?'),
      findsOneWidget,
    );
    expect(find.text('Sino Mart'), findsOneWidget);
    expect(find.text('Elig-Edzoa, Yaoundé'), findsOneWidget);
    expect(find.text('Google Maps'), findsOneWidget); // required credit

    await tester.tapAt(tester.getCenter(find.text('Sino Mart')));
    await tester.pumpAndSettle();

    // Asks what to call it: starts as what they typed, Google's name shown
    // only for reference.
    expect(find.text('Save this place as'), findsOneWidget);
    expect(find.text('Google suggested: Sino Mart'), findsOneWidget);
    final nameField = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byType(TextField),
    );
    expect(tester.widget<TextField>(nameField).controller!.text, 'sino mart');
    await tester.enterText(nameField, 'Sino Mart Elig-Edzoa');
    await tester.pump();
    await tester.tap(find.text('Use this place'));
    await tester.pumpAndSettle();

    // What was saved: the city, the rider's words, and the Google place ID.
    expect(saved, ('Yaoundé', 'Sino Mart Elig-Edzoa', 'ChIJsinomart0001'));
    // The place is now chosen like any other.
    expect(
      find.widgetWithText(TextField, 'Sino Mart Elig-Edzoa'),
      findsOneWidget,
    );
    expect(find.text('Not in Kombien yet. Is it one of these?'), findsNothing);
  });

  testWidgets('a place another rider already added is found by name, with no '
      'Google involved', (tester) async {
    var googleAsked = 0;
    final google = GooglePlaces(
      key: 'test-key',
      client: MockClient((_) async {
        googleAsked++;
        return http.Response(sinoMart, 200);
      }),
    );
    final riders = RiderPlaces(
      findOnServer: (query, city) async => [
        const Landmark(id: 'landmark-cinemat', name: 'Cinemat'),
      ],
    );
    await missingPlaceApp(tester, google: google, riders: riders);

    await tester.enterText(find.byType(TextField).at(1), 'cinemat');
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Cinemat'), findsWidgets); // offered like any result
    expect(find.text('Not in Kombien yet. Is it one of these?'), findsNothing);
    expect(googleAsked, 0);
  });

  testWidgets('when saving the place fails the rider is told, and the '
      'suggestions stay', (tester) async {
    final google = GooglePlaces(
      key: 'test-key',
      client: MockClient((_) async => http.Response(sinoMart, 200)),
    );
    final riders = RiderPlaces(
      findOnServer: (_, _) async => const [],
      addOnServer: (_, _, _) async => throw StateError('offline'),
    );
    await missingPlaceApp(tester, google: google, riders: riders);

    await tester.enterText(find.byType(TextField).at(1), 'sino mart');
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await tester.tapAt(tester.getCenter(find.text('Sino Mart')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use this place'));
    await tester.pumpAndSettle();

    expect(
      find.text("Couldn't add that place. Check your connection and try again"),
      findsOneWidget,
    );
    expect(find.text('Sino Mart'), findsOneWidget);
  });

  testWidgets('without a Google key nothing changes: the not-found card, '
      'and nothing is asked', (tester) async {
    await missingPlaceApp(tester); // default GooglePlaces: no key
    await tester.enterText(find.byType(TextField).at(1), 'sino mart');
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(
      find.text("Couldn't find that place. Try a nearby landmark instead"),
      findsOneWidget,
    );
    expect(find.text('Google Maps'), findsNothing);
  });

  testWidgets('a search that found nothing is noted once the rider has '
      'stopped typing: the words, the city, the language', (tester) async {
    final (_, logged) = await missingPlaceApp(tester);

    await tester.enterText(find.byType(TextField).at(1), 'Sino Mart');
    await tester.pumpAndSettle();
    expect(logged, isEmpty); // not yet: they may still be typing
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(logged, [
      {'q': 'sino mart', 'city': 'Yaoundé', 'locale': 'en'},
    ]);
  });

  testWidgets('typing on counts once, for what was finally typed', (
    tester,
  ) async {
    final (_, logged) = await missingPlaceApp(tester);

    await tester.enterText(find.byType(TextField).at(1), 'sino');
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.enterText(find.byType(TextField).at(1), 'sino mart');
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.enterText(
      find.byType(TextField).at(1),
      'sino mart elig-edzoa',
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(logged.map((r) => r['q']), ['sino mart elig-edzoa']);
  });

  testWidgets('a search that finds a place is never noted', (tester) async {
    final (_, logged) = await missingPlaceApp(tester);

    await tester.enterText(find.byType(TextField).at(1), 'Carrefour Messassi');
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(logged, isEmpty);
  });

  testWidgets('results that are not the place meant: "Not the place? Tell '
      'us" under them', (tester) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final state = KAppState(
      location: FakeLocation(current: LocationAccess.denied),
      packs: _packs(),
    );
    await state.load();
    await tester.pumpWidget(KombienApp(showSplash: false, state: state));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(1), 'messasi');
    await tester.pumpAndSettle();
    expect(find.text('Carrefour Messassi'), findsOneWidget);
    expect(find.text('Not the place? Tell us'), findsOneWidget);
  });
}
