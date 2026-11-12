import 'package:flutter_test/flutter_test.dart';
import 'package:kombien/data/landmark_repository.dart';
import 'package:kombien/data/report_repository.dart';
import 'package:kombien/services/device_hint.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'a fare of 625 is refused in the app, before anything is stored',
    () async {
      SharedPreferences.setMockInitialValues({});
      final repo = LocalFirstReportRepository();
      final report = FareReport(
        from: const Landmark(name: 'A'),
        to: const Landmark(name: 'B'),
        amountXaf: 625,
      );
      expect(() => repo.submit(report), throwsArgumentError);
      expect(await repo.history(), isEmpty);
    },
  );

  test('a fare is between 50 and 50 000, in steps of 50', () {
    for (final ok in [50, 100, 650, 50000]) {
      expect(FareReport.validAmount(ok), isTrue, reason: '$ok');
    }
    for (final bad in [null, 0, 20, 60, 625, 725, 50050, 100000]) {
      expect(FareReport.validAmount(bad), isFalse, reason: '$bad');
    }
  });

  String hint({
    int w = 360,
    int h = 800,
    double dpr = 3,
    String os = 'android',
    String lang = 'fr-CM',
  }) => deviceHintOf(
    screenWidth: w,
    screenHeight: h,
    pixelRatio: dpr,
    utcOffsetMinutes: 60,
    os: os,
    language: lang,
  );

  test('the same device gives the same hint, in any browser or rotation', () {
    expect(hint(), hint());
    expect(hint(w: 800, h: 360), hint()); // rotated
    expect(hint(lang: 'fr'), hint()); // fr and fr-CM agree
    expect(hint(), matches(RegExp(r'^[0-9a-f]{32}$')));
  });

  test('a different device gives a different hint', () {
    expect(hint(w: 412, h: 915), isNot(hint()));
    expect(hint(dpr: 2), isNot(hint()));
    expect(hint(os: 'ios'), isNot(hint()));
    expect(hint(lang: 'en'), isNot(hint()));
  });

  test('browsers on one phone agree on the system', () {
    expect(
      osFamilyOf('Mozilla/5.0 (Linux; Android 13; TECNO) Chrome/120'),
      'android',
    );
    expect(
      osFamilyOf(
        'Mozilla/5.0 (Android 13; Mobile; rv:120.0) Gecko Firefox/120',
      ),
      'android',
    );
    expect(
      osFamilyOf('Mozilla/5.0 (iPhone; CPU iPhone OS 17_0) Safari'),
      'ios',
    );
    expect(osFamilyOf('Mozilla/5.0 (Windows NT 10.0) Chrome'), 'windows');
    expect(osFamilyOf('whatever'), 'other');
  });

  test('off the web there is no hint', () {
    expect(deviceHint(), isNull);
  });

  test('a fare that is not a step of 50 is rounded for arrival reports', () {
    expect(FareReport.roundToStep(625), 650);
    expect(FareReport.roundToStep(610), 600);
    expect(FareReport.roundToStep(500), 500);
  });
}
