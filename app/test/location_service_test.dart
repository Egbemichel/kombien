import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kombien/services/location_service.dart';

void main() {
  group('in a browser, asking for location', () {
    test('a position means granted', () async {
      final service = LocationService(browser: true, readFix: () async {});
      expect(await service.request(), LocationAccess.granted);
    });

    test('only a refusal counts as refused', () async {
      final service = LocationService(
        browser: true,
        readFix: () async => throw const PermissionDeniedException('no'),
      );
      expect(await service.request(), LocationAccess.blocked);
    });

    test('no fix yet is not a refusal (cold GPS, indoors)', () async {
      for (final failure in <Object>[
        const PositionUpdateException('unavailable'),
        TimeoutException('slow'),
      ]) {
        final service = LocationService(
          browser: true,
          readFix: () async => throw failure,
        );
        expect(await service.request(), LocationAccess.granted);
      }
    });
  });
}
