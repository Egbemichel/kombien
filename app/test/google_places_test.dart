import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kombien/data/google_places.dart';

const _response = '''
{
  "suggestions": [
    {"placePrediction": {
      "place": "places/ChIJabc",
      "placeId": "ChIJabcdefghijk1",
      "text": {"text": "Sino Mart, Elig-Edzoa, Yaoundé, Cameroun"},
      "structuredFormat": {
        "mainText": {"text": "Sino Mart"},
        "secondaryText": {"text": "Elig-Edzoa, Yaoundé, Cameroun"}
      }
    }},
    {"queryPrediction": {"text": {"text": "sino mart yaounde"}}},
    {"placePrediction": {
      "placeId": "ChIJabcdefghijk2",
      "text": {"text": "Sino Mart Bastos"}
    }}
  ]
}
''';

void main() {
  group('reading Google\'s answer', () {
    test('place suggestions become an ID, a title and an area', () {
      final s = GooglePlaces.parse(_response);
      expect(s.map((e) => e.placeId), ['ChIJabcdefghijk1', 'ChIJabcdefghijk2']);
      expect(s[0].title, 'Sino Mart');
      expect(s[0].subtitle, 'Elig-Edzoa, Yaoundé, Cameroun');
      // No structured text: the full text stands in for the title.
      expect(s[1].title, 'Sino Mart Bastos');
      expect(s[1].subtitle, '');
    });

    test('query suggestions and broken answers are ignored', () {
      expect(GooglePlaces.parse('{"suggestions": []}'), isEmpty);
      expect(GooglePlaces.parse('{}'), isEmpty);
      expect(GooglePlaces.parse('not json'), isEmpty);
    });

    test('at most five suggestions', () {
      final many = jsonEncode({
        'suggestions': [
          for (var i = 0; i < 9; i++)
            {
              'placePrediction': {
                'placeId':
                    'ChIJplace$i'
                    'xxxxx',
                'text': {'text': 'Place $i'},
              },
            },
        ],
      });
      expect(GooglePlaces.parse(many), hasLength(GooglePlaces.maxSuggestions));
    });
  });

  group('asking Google', () {
    test('without a key it never asks', () async {
      var calls = 0;
      final g = GooglePlaces(
        key: '',
        client: MockClient((_) async {
          calls++;
          return http.Response(_response, 200);
        }),
      );
      expect(g.enabled, isFalse);
      expect(await g.suggest('sino mart', city: 'Yaoundé'), isEmpty);
      expect(calls, 0);
    });

    test('too little typed is not worth a request', () async {
      var calls = 0;
      final g = GooglePlaces(
        key: 'k',
        client: MockClient((_) async {
          calls++;
          return http.Response(_response, 200);
        }),
      );
      expect(await g.suggest('si', city: 'Yaoundé'), isEmpty);
      expect(await g.suggest('   ', city: 'Yaoundé'), isEmpty);
      expect(calls, 0);
    });

    test('one request, restricted to Cameroon and the rider\'s city, with the '
        'key in a header and nothing about the rider', () async {
      late http.Request seen;
      final g = GooglePlaces(
        key: 'test-key',
        client: MockClient((request) async {
          seen = request;
          return http.Response(_response, 200);
        }),
      );
      final found = await g.suggest(
        '  Sino Mart ',
        city: 'Yaoundé',
        languageCode: 'fr',
      );
      expect(found, hasLength(2));

      expect(seen.method, 'POST');
      expect(seen.url.host, 'places.googleapis.com');
      expect(seen.url.path, '/v1/places:autocomplete');
      expect(seen.headers['X-Goog-Api-Key'], 'test-key');

      final body = jsonDecode(seen.body) as Map<String, dynamic>;
      expect(body['input'], 'Sino Mart');
      expect(body['languageCode'], 'fr');
      expect(body['includedRegionCodes'], ['cm']);
      final rect =
          (body['locationRestriction'] as Map<String, dynamic>)['rectangle']
              as Map<String, dynamic>;
      expect(rect['low'], {'latitude': 3.70, 'longitude': 11.40});
      expect(rect['high'], {'latitude': 3.98, 'longitude': 11.62});
      // Only the typed words, the language and the area leave the phone.
      expect(body.keys.toSet(), {
        'input',
        'languageCode',
        'includedRegionCodes',
        'locationRestriction',
      });
    });

    test(
      'over quota, offline, or a bad answer: nothing, and no error',
      () async {
        for (final client in [
          MockClient((_) async => http.Response('{"error": {}}', 429)),
          MockClient((_) async => http.Response('oops', 500)),
          MockClient((_) async => throw http.ClientException('offline')),
        ]) {
          final g = GooglePlaces(key: 'k', client: client);
          expect(await g.suggest('sino mart', city: 'Yaoundé'), isEmpty);
        }
      },
    );
  });
}
