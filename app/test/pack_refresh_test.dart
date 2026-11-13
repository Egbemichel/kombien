import 'package:flutter_test/flutter_test.dart';
import 'package:kombien/data/city_pack.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'a place added since the pack was saved makes the pack outdated',
    () async {
      var stamp = '4767:100';
      final packs = CityPacks(fetchStamp: (_) async => stamp);
      expect(await packs.download('Yaoundé'), isTrue);
      expect(packs.saved.value['Yaoundé']!.stamp, '4767:100');

      expect(await packs.outdated('Yaoundé'), isFalse); // nothing new

      stamp = '4770:200'; // three places added
      expect(await packs.outdated('Yaoundé'), isTrue);
      expect(await packs.download('Yaoundé'), isTrue); // refreshed
      expect(await packs.outdated('Yaoundé'), isFalse);
    },
  );

  test('offline (no answer) never forces a download', () async {
    String? stamp = '1:1';
    final packs = CityPacks(fetchStamp: (_) async => stamp);
    await packs.download('Douala');
    stamp = null;
    expect(await packs.outdated('Douala'), isFalse);
  });

  test('a pack saved before stamps existed is refreshed once', () async {
    String? stamp;
    final packs = CityPacks(fetchStamp: (_) async => stamp);
    await packs.download('Yaoundé'); // no stamp then
    expect(packs.saved.value['Yaoundé']!.stamp, isNull);
    stamp = '4770:200'; // the database now answers
    expect(await packs.outdated('Yaoundé'), isTrue);
    await packs.download('Yaoundé');
    expect(await packs.outdated('Yaoundé'), isFalse);
  });

  test('the stamp survives being saved and loaded', () async {
    final a = CityPacks(fetchStamp: (_) async => '9:9');
    await a.download('Yaoundé');
    final b = CityPacks(fetchStamp: (_) async => '9:9');
    await b.load();
    expect(b.saved.value['Yaoundé']!.stamp, '9:9');
  });
}
