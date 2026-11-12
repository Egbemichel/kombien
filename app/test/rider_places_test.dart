import 'package:flutter_test/flutter_test.dart';
import 'package:kombien/data/landmark_repository.dart';
import 'package:kombien/data/rider_places.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('the name a rider gives', () {
    test('is tidied, and kept as their own words', () {
      expect(RiderPlaces.cleanLabel('  Sino   Mart '), 'Sino Mart');
    });

    test('too short, too long or personal is refused', () {
      expect(RiderPlaces.cleanLabel('a'), isNull);
      expect(RiderPlaces.cleanLabel('x' * 101), isNull);
      expect(RiderPlaces.cleanLabel('call joe@example.com'), isNull);
      expect(RiderPlaces.cleanLabel('https://example.com'), isNull);
      expect(RiderPlaces.cleanLabel('677 12 34 56'), isNull);
      expect(RiderPlaces.cleanLabel('Carrefour 4 chemins'), isNotNull);
    });
  });

  group('adding a place found through Google', () {
    test('sends the city, the rider\'s name for it and the Google place ID, '
        'and returns the landmark to report against', () async {
      late (String, String, String) sent;
      final places = RiderPlaces(
        addOnServer: (city, label, placeId) async {
          sent = (city, label, placeId);
          return Landmark(id: 'landmark-1', name: label);
        },
      );
      final landmark = await places.add(
        city: 'Yaoundé',
        label: '  Cinemat ',
        placeId: 'ChIJabcdefghijk1',
      );
      expect(sent, ('Yaoundé', 'Cinemat', 'ChIJabcdefghijk1'));
      expect(landmark.id, 'landmark-1');
      expect(landmark.name, 'Cinemat');
    });

    test('a bad name never reaches the server', () async {
      var asked = false;
      final places = RiderPlaces(
        addOnServer: (_, _, _) async {
          asked = true;
          return const Landmark(id: 'x', name: 'x');
        },
      );
      await expectLater(
        places.add(
          city: 'Yaoundé',
          label: '677123456',
          placeId: 'ChIJabcdefghijk1',
        ),
        throwsArgumentError,
      );
      expect(asked, isFalse);
    });

    test('when the server cannot be reached the error reaches the caller, so '
        'the rider can be told to try again', () async {
      final places = RiderPlaces(
        addOnServer: (_, _, _) async => throw StateError('offline'),
      );
      await expectLater(
        places.add(
          city: 'Yaoundé',
          label: 'Cinemat',
          placeId: 'ChIJabcdefghijk1',
        ),
        throwsStateError,
      );
    });
  });

  group('finding places other riders added', () {
    test('asks the server, and offline is simply nothing', () async {
      final found = RiderPlaces(
        findOnServer: (q, city) async => [Landmark(id: 'l1', name: 'Cinemat')],
      );
      expect(
        (await found.find('cinemat', city: 'Yaoundé')).single.name,
        'Cinemat',
      );

      final offline = RiderPlaces(
        findOnServer: (q, city) async => throw StateError('offline'),
      );
      expect(await offline.find('cinemat', city: 'Yaoundé'), isEmpty);
    });
  });

  group('this phone remembers what it added', () {
    test(
      'and finds it again, words in any order, without a connection',
      () async {
        final places = RiderPlaces(
          addOnServer: (city, label, placeId) async =>
              Landmark(id: 'id-$label', name: label),
        );
        await places.add(
          city: 'Yaoundé',
          label: 'Sino Mart Elig-Edzoa',
          placeId: 'ChIJabcdefghijk1',
        );
        await places.add(
          city: 'Yaoundé',
          label: 'Cinemat',
          placeId: 'ChIJabcdefghijk2',
        );

        expect(
          (await places.mine('edzoa sino')).single.name,
          'Sino Mart Elig-Edzoa',
        );
        expect((await places.mine('CINEMAT')).single.name, 'Cinemat');
        expect(await places.mine('bastos'), isEmpty);
        expect(await places.mine(' '), isEmpty);
      },
    );

    test('adding the same place again does not duplicate it', () async {
      final places = RiderPlaces();
      await places.remember(const Landmark(id: 'a', name: 'Cinemat'));
      await places.remember(const Landmark(id: 'a', name: 'Cinemat'));
      expect(await places.mine('cinemat'), hasLength(1));
    });

    test('keeps only the latest ${RiderPlaces.maxRemembered}', () async {
      final places = RiderPlaces();
      for (var i = 0; i < RiderPlaces.maxRemembered + 5; i++) {
        await places.remember(Landmark(id: 'id$i', name: 'Place number $i'));
      }
      final all = await places.mine('place', limit: 1000);
      expect(all, hasLength(RiderPlaces.maxRemembered));
      expect(all.any((l) => l.id == 'id0'), isFalse);
      expect(
        all.any((l) => l.id == 'id${RiderPlaces.maxRemembered + 4}'),
        isTrue,
      );
    });

    test('it survives closing the app: loaded again at start-up', () async {
      await RiderPlaces().remember(const Landmark(id: 'a', name: 'Cinemat'));

      final reopened = RiderPlaces();
      expect(await reopened.mine('cinemat'), isEmpty); // not loaded yet
      await reopened.load();
      expect((await reopened.mine('cinemat')).single.id, 'a');
    });

    test('a place without an id is not remembered', () async {
      final places = RiderPlaces();
      await places.remember(const Landmark(name: 'My location'));
      expect(await places.mine('location'), isEmpty);
    });
  });
}
