import 'package:flutter_test/flutter_test.dart';
import 'package:kombien/data/city_pack.dart';
import 'package:kombien/data/fare_repository.dart';
import 'package:kombien/data/landmark_repository.dart';
import 'package:kombien/services/backend.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A pack holding a few real Yaoundé places (positions from OpenStreetMap).
CityPacks _packs() {
  final packs = CityPacks();
  packs.saved.value = {
    'Yaoundé': CityPack(
      city: 'Yaoundé',
      savedAt: DateTime.now(),
      places: [
        PackPlace('w', 'Carrefour Warda', const [], 3.8716, 11.5146),
        PackPlace('m', 'Marché Mokolo', const ['Mokolo'], 3.8771, 11.4987),
        PackPlace('o', 'Carrefour Obili', const [], 3.8573, 11.4993),
        PackPlace('e', 'Emana Pont', const [], 3.9300, 11.5260),
      ],
      fares: {'w→m': (300, 400, 5)},
    ),
  };
  return packs;
}

/// A database that is unreachable, or answers [found].
class _Remote implements LandmarkRepository {
  _Remote({this.found = const [], this.offline = false});
  final List<Landmark> found;
  final bool offline;
  int calls = 0;
  @override
  Future<List<Landmark>> search(
    String query, {
    double? lat,
    double? lng,
    int limit = 3,
  }) async {
    calls++;
    if (offline) throw Exception('offline');
    return found;
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('distance labels round the way riders say them', () {
    expect(const Landmark(name: 'a', distanceM: 640).distanceLabel, '~600m');
    expect(const Landmark(name: 'a', distanceM: 2600).distanceLabel, '~3km');
    expect(const Landmark(name: 'a').distanceLabel, '');
  });

  test('with no Supabase configured, search runs on the sample list', () async {
    expect(Backend.configured, isFalse);
    final repo = LandmarkRepository.standard(CityPacks());
    final found = await repo.search('ngoa');
    expect(found.single.name, 'Ngoa-Ekellé');
    expect(await repo.search(''), isEmpty);
  });

  test('pack search: accents and case ignored, aliases count, '
      'names starting with the query first', () {
    final packs = _packs();
    expect(packs.search('MARCHE').single.name, 'Marché Mokolo');
    expect(packs.search('mokolo').single.id, 'm');
    expect(packs.search('carrefour', limit: 5).map((l) => l.name), [
      'Carrefour Obili',
      'Carrefour Warda',
    ]);
    // Near Warda: Warda first, with its distance.
    final near = packs.search('carrefour', lat: 3.8720, lng: 11.5150);
    expect(near.first.name, 'Carrefour Warda');
    expect(near.first.distanceLabel, '~100m');
  });

  test('nearest saved place, within 600 m only', () {
    final packs = _packs();
    expect(packs.nearest(3.8720, 11.5150)!.id, 'w');
    expect(packs.nearest(3.80, 11.60), isNull); // nowhere near
  });

  test('offline with no memory of the route: the pack range shows', () async {
    final fares = CachedFareRepository(_Down(), packs: _packs());
    const w = Landmark(id: 'w', name: 'Carrefour Warda');
    const m = Landmark(id: 'm', name: 'Marché Mokolo');
    await expectLater(
      fares.range(w, m),
      throwsA(
        isA<FaresOffline>()
            .having((e) => e.saved.low, 'low', 300)
            .having((e) => e.saved.cached, 'cached', isTrue),
      ),
    );
  });

  test(
    'search: the pack answers offline; the database fills the rest',
    () async {
      final offline = _Remote(offline: true);
      final repo = OfflineFirstLandmarkRepository(_packs(), offline);
      expect((await repo.search('warda')).single.name, 'Carrefour Warda');

      final online = _Remote(
        found: const [Landmark(id: 'x', name: 'Warda Hotel')],
      );
      final both = OfflineFirstLandmarkRepository(_packs(), online);
      expect((await both.search('warda')).map((l) => l.name), [
        'Carrefour Warda',
        'Warda Hotel',
      ]);

      // No pack at all and offline: the error reaches the screen.
      final none = OfflineFirstLandmarkRepository(CityPacks(), offline);
      await expectLater(none.search('warda'), throwsException);
    },
  );
}

class _Down implements FareRepository {
  @override
  Future<FareRange?> range(Landmark from, Landmark to) async =>
      throw Exception('offline');
}
