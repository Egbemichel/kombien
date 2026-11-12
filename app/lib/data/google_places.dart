import 'dart:convert';

import 'package:http/http.dart' as http;

import 'city_pack.dart';

/// One place Google suggests for what the rider typed.
///
/// Only [placeId] may be kept (Google lets it be stored indefinitely). The
/// [title] and [subtitle] are Google's text: shown to the rider while they
/// choose, never saved.
class PlaceSuggestion {
  const PlaceSuggestion({
    required this.placeId,
    required this.title,
    this.subtitle = '',
  });

  final String placeId;
  final String title;
  final String subtitle;
}

/// Google Places Autocomplete (New), asked only when Kombien's own places have
/// nothing for what the rider typed.
///
/// Off unless the build has a key (`--dart-define=GOOGLE_PLACES_KEY=...`), so
/// the app behaves exactly as before without one. The key ships in the app,
/// as Supabase's publishable key does: restrict it to the site's address and
/// to the Places API in Google Cloud, and put a daily quota on it there.
///
/// Google's terms apply to what comes back: show its attribution next to the
/// suggestions, and keep only the place ID.
class GooglePlaces {
  GooglePlaces({String? key, http.Client? client})
    : _key = key ?? const String.fromEnvironment('GOOGLE_PLACES_KEY'),
      _client = client ?? http.Client();

  final String _key;
  final http.Client _client;

  /// Whether a key is configured.
  bool get enabled => _key.isNotEmpty;

  /// The most suggestions asked for (and shown).
  static const maxSuggestions = 5;

  /// Suggestions for [input] inside [city] (Cameroon only), or an empty list:
  /// nothing typed worth asking about, no key, offline, over quota, or no
  /// match. Never throws.
  Future<List<PlaceSuggestion>> suggest(
    String input, {
    required String city,
    String languageCode = 'en',
  }) async {
    final text = input.trim();
    if (!enabled || text.length < 3 || text.length > 100) return const [];
    final area = kCityAreas[city];
    try {
      final response = await _client
          .post(
            Uri.https('places.googleapis.com', '/v1/places:autocomplete'),
            headers: {
              'Content-Type': 'application/json',
              'X-Goog-Api-Key': _key,
            },
            body: jsonEncode({
              'input': text,
              'languageCode': languageCode,
              'includedRegionCodes': const ['cm'],
              if (area != null)
                'locationRestriction': {
                  'rectangle': {
                    'low': {'latitude': area.$1, 'longitude': area.$2},
                    'high': {'latitude': area.$3, 'longitude': area.$4},
                  },
                },
            }),
          )
          .timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) return const [];
      return parse(response.body);
    } catch (_) {
      return const [];
    }
  }

  /// Reads an Autocomplete (New) response into suggestions.
  static List<PlaceSuggestion> parse(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final out = <PlaceSuggestion>[];
      for (final s in (json['suggestions'] as List<dynamic>? ?? const [])) {
        final p = (s as Map<String, dynamic>)['placePrediction'];
        if (p is! Map<String, dynamic>) continue;
        final id = p['placeId'];
        if (id is! String || id.isEmpty) continue;
        final format = p['structuredFormat'] as Map<String, dynamic>?;
        final main = (format?['mainText'] as Map<String, dynamic>?)?['text'];
        final secondary =
            (format?['secondaryText'] as Map<String, dynamic>?)?['text'];
        final full = (p['text'] as Map<String, dynamic>?)?['text'];
        final title = (main ?? full) as String?;
        if (title == null || title.trim().isEmpty) continue;
        out.add(
          PlaceSuggestion(
            placeId: id,
            title: title.trim(),
            subtitle: ((secondary as String?) ?? '').trim(),
          ),
        );
        if (out.length == maxSuggestions) break;
      }
      return out;
    } catch (_) {
      return const [];
    }
  }
}
