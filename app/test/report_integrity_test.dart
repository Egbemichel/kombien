import 'package:flutter_test/flutter_test.dart';
import 'package:kombien/data/report_repository.dart';
import 'package:kombien/services/device_hint.dart';

void main() {
  test('a fare is between 50 and 50 000, in steps of 50', () {
    for (final ok in [50, 100, 650, 50000]) {
      expect(FareReport.validAmount(ok), isTrue, reason: '$ok');
    }
    for (final bad in [null, 0, 20, 60, 625, 725, 50050, 100000]) {
      expect(FareReport.validAmount(bad), isFalse, reason: '$bad');
    }
  });

  String hint({int w = 360, int h = 800, double dpr = 3, int cores = 8}) =>
      deviceHintOf(
        screenWidth: w,
        screenHeight: h,
        pixelRatio: dpr,
        cores: cores,
        utcOffsetMinutes: 60,
      );

  test('the same device gives the same hint, in any browser or rotation', () {
    expect(hint(), hint());
    expect(hint(w: 800, h: 360), hint()); // rotated
    expect(hint(), matches(RegExp(r'^[0-9a-f]{32}$')));
  });

  test('a different device gives a different hint', () {
    expect(hint(w: 412, h: 915), isNot(hint()));
    expect(hint(dpr: 2), isNot(hint()));
    expect(hint(cores: 4), isNot(hint()));
  });

  test('off the web there is no hint', () {
    expect(deviceHint(), isNull);
  });
}
