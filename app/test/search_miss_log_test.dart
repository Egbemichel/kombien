import 'package:flutter_test/flutter_test.dart';
import 'package:kombien/data/search_miss_log.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('what may leave the phone', () {
    test('words are lower-cased and tidied', () {
      expect(
        SearchMissLog.clean('  Sino   MART near Marché Elig-Edzoa '),
        'sino mart near marché elig-edzoa',
      );
    });

    test('too short or too long to be a place is dropped', () {
      expect(SearchMissLog.clean('a'), isNull);
      expect(SearchMissLog.clean('  ab '), isNull);
      expect(SearchMissLog.clean('x' * 61), isNull);
      expect(SearchMissLog.clean('x' * 60), isNotNull);
    });

    test('anything personal is dropped: emails, links, phone numbers', () {
      expect(SearchMissLog.clean('joe@example.com'), isNull);
      expect(SearchMissLog.clean('https://x.y/z'), isNull);
      expect(SearchMissLog.clean('www.example.cm'), isNull);
      expect(SearchMissLog.clean('677 12 34 56'), isNull);
      expect(SearchMissLog.clean('6.77.12.34.56'), isNull);
      expect(SearchMissLog.clean('call 677-123-456'), isNull);
    });

    test('a number that belongs to a place name stays', () {
      expect(SearchMissLog.clean('Carrefour 4 chemins'), 'carrefour 4 chemins');
      expect(SearchMissLog.clean('Ecole 2 Messassi'), 'ecole 2 messassi');
    });
  });

  group('keeping and sending', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('a search that found nothing is sent, with only the words, the '
        'city and the language', () async {
      final sent = <Map<String, Object?>>[];
      final log = SearchMissLog(send: (row) async => sent.add(row));
      await log.record('Sino Mart', city: 'Yaoundé', locale: 'en');
      expect(sent, [
        {'q': 'sino mart', 'city': 'Yaoundé', 'locale': 'en'},
      ]);
      final p = await SharedPreferences.getInstance();
      expect(
        p.getStringList('search_miss_queue'),
        isEmpty,
      ); // nothing left waiting
    });

    test('the same words are noted once per run of the app', () async {
      final sent = <Map<String, Object?>>[];
      final log = SearchMissLog(send: (row) async => sent.add(row));
      await log.record('sino mart', city: 'Yaoundé', locale: 'en');
      await log.record('  SINO  mart ', city: 'Yaoundé', locale: 'en');
      await log.record(
        'sino mart',
        city: 'Douala',
        locale: 'en',
      ); // another city
      expect(sent.length, 2);
    });

    test('nothing personal is queued or sent', () async {
      final sent = <Map<String, Object?>>[];
      final log = SearchMissLog(send: (row) async => sent.add(row));
      await log.record('677 12 34 56', city: 'Yaoundé', locale: 'fr');
      final p = await SharedPreferences.getInstance();
      expect(sent, isEmpty);
      expect(p.getStringList('search_miss_queue'), isNull);
    });

    test('offline: kept on the phone, then sent when it can', () async {
      var online = false;
      final sent = <Map<String, Object?>>[];
      final log = SearchMissLog(
        send: (row) async {
          if (!online) throw StateError('offline');
          sent.add(row);
        },
      );
      await log.record('sino mart', city: 'Yaoundé', locale: 'en');
      await log.record('marché elig-edzoa', city: 'Yaoundé', locale: 'en');
      final p = await SharedPreferences.getInstance();
      expect(sent, isEmpty);
      expect(p.getStringList('search_miss_queue'), hasLength(2));

      online = true;
      await log.sendWaiting();
      expect(sent.map((r) => r['q']), ['sino mart', 'marché elig-edzoa']);
      expect(p.getStringList('search_miss_queue'), isEmpty);
    });

    test('a failing send never throws into the app', () async {
      final log = SearchMissLog(send: (_) async => throw StateError('down'));
      await log.record('sino mart', city: 'Yaoundé', locale: 'en');
      await log.sendWaiting();
    });

    test(
      'only the latest ${SearchMissLog.maxQueued} wait on the phone',
      () async {
        final log = SearchMissLog(
          send: (_) async => throw StateError('offline'),
        );
        for (var i = 0; i < SearchMissLog.maxQueued + 8; i++) {
          await log.record('place number $i', city: 'Yaoundé', locale: 'en');
        }
        final p = await SharedPreferences.getInstance();
        final queue = p.getStringList('search_miss_queue')!;
        expect(queue, hasLength(SearchMissLog.maxQueued));
        expect(
          queue.last,
          contains('place number ${SearchMissLog.maxQueued + 7}'),
        );
        expect(queue.first, contains('place number 8'));
      },
    );
  });
}
