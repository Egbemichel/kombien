import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kombien/services/location_service.dart';

Position _position({double accuracy = 12.5}) => Position(
  longitude: 11.5342,
  latitude: 3.8871,
  timestamp: DateTime(2026, 11, 12),
  accuracy: accuracy,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

void main() {
  group('a precise position, for adding a place', () {
    test(
      'is the phone\'s own position with how accurate it says it is',
      () async {
        final service = LocationService(
          readPosition: () async => _position(accuracy: 31.4),
        );
        final fix = await service.fix();
        expect(fix, isNotNull);
        expect(fix!.lat, 3.8871);
        expect(fix.lng, 11.5342);
        expect(fix.accuracyM, 31.4);
      },
    );

    test(
      'is nothing when the phone cannot say (refused, switched off)',
      () async {
        final service = LocationService(
          readPosition: () async => throw const PermissionDeniedException('no'),
        );
        expect(await service.fix(), isNull);
      },
    );

    test(
      'is nothing when no fix arrives in time (never waits for ever)',
      () async {
        final service = LocationService(
          readPosition: () => Completer<Position>().future,
        );
        expect(
          await service.fix(timeout: const Duration(milliseconds: 50)),
          isNull,
        );
      },
    );
  });
}
