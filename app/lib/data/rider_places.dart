import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../services/backend.dart';
import 'google_places.dart';
import 'landmark_repository.dart';

/// What can be offered for a place Kombien's own list does not have: places
/// other riders already added (found by name, no Google involved), or else
/// Google's suggestions. Both empty: nothing to offer.
class MissingPlaceHelp {
  const MissingPlaceHelp({this.known = const [], this.suggestions = const []});

  final List<Landmark> known;
  final List<PlaceSuggestion> suggestions;

  bool get isEmpty => known.isEmpty && suggestions.isEmpty;
}

/// Places riders add through Google, and how they are found again.
///
/// A place found through Google is saved on Kombien's side as a landmark named
/// with the rider's own words and tied to the Google place ID. Every rider who
/// picks the same Google place in the same city lands on the same landmark, so
/// their fares add up. Other riders find it by name, with no Google involved.
class RiderPlaces {
  RiderPlaces({
    Future<Landmark> Function(String city, String label, String placeId)?
    addOnServer,
    Future<List<Landmark>> Function(String query, String city)? findOnServer,
  }) : _add = addOnServer ?? _addRpc,
       _find = findOnServer ?? _findRpc;

  static const _key = 'rider_places';

  /// The most this phone remembers having added.
  static const maxRemembered = 60;

  final Future<Landmark> Function(String city, String label, String placeId)
  _add;
  final Future<List<Landmark>> Function(String query, String city) _find;

  /// Cleans a name before it is sent, or null when it should not be (too
  /// short or long, or something personal). The database checks the same.
  static String? cleanLabel(String raw) {
    final text = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (text.length < 2 || text.length > 100) return null;
    final lower = text.toLowerCase();
    if (lower.contains('@') ||
        lower.contains('http') ||
        lower.contains('www.')) {
      return null;
    }
    if (RegExp(r'\d{6,}').hasMatch(text.replaceAll(RegExp(r'[\s.\-]'), ''))) {
      return null;
    }
    return text;
  }

  /// Adds the place Google suggested (or finds the one already added) and
  /// returns the landmark to report against. Throws when it cannot: the
  /// caller tells the rider to try again.
  Future<Landmark> add({
    required String city,
    required String label,
    required String placeId,
  }) async {
    final clean = cleanLabel(label);
    if (clean == null) throw ArgumentError('bad name');
    final landmark = await _add(city, clean, placeId);
    await remember(landmark);
    return landmark;
  }

  /// Places other riders added that match [query]; empty when offline.
  Future<List<Landmark>> find(String query, {required String city}) async {
    try {
      return await _find(query, city);
    } catch (_) {
      return const [];
    }
  }

  // --------------------------------------------------- this phone's own list

  /// The places this phone added, oldest first. Held in memory once loaded, so
  /// searching never waits on the phone's storage.
  List<Landmark>? _remembered;

  /// Reads what this phone remembers (at start-up). Never throws.
  Future<void> load() async {
    _remembered ??= await _read();
  }

  Future<List<Landmark>> _read() async {
    try {
      final p = await SharedPreferences.getInstance();
      return [
        for (final s in p.getStringList(_key) ?? const <String>[])
          Landmark(
            id: (jsonDecode(s) as Map<String, dynamic>)['id'] as String,
            name: (jsonDecode(s) as Map<String, dynamic>)['name'] as String,
          ),
      ];
    } catch (_) {
      return [];
    }
  }

  /// Remembers a place on this phone, so it can be found again offline.
  Future<void> remember(Landmark place) async {
    final id = place.id;
    if (id == null) return;
    final items = [
      for (final l in _remembered ??= await _read())
        if (l.id != id) l,
      Landmark(id: id, name: place.name),
    ];
    _remembered = items.length > maxRemembered
        ? items.sublist(items.length - maxRemembered)
        : items;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setStringList(_key, [
        for (final l in _remembered!) jsonEncode({'id': l.id, 'name': l.name}),
      ]);
    } catch (_) {}
  }

  /// The places this phone added that match [query] (words in any order),
  /// newest first. Answers from memory at once.
  Future<List<Landmark>> mine(String query, {int limit = 3}) {
    final words = _words(query);
    if (words.isEmpty) return Future.value(const []);
    final found = <Landmark>[];
    for (final l in (_remembered ?? const <Landmark>[]).reversed) {
      final hay = _words(l.name).join(' ');
      if (words.every(hay.contains)) {
        found.add(l);
        if (found.length == limit) break;
      }
    }
    return Future.value(found);
  }

  static List<String> _words(String text) => text
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
      .split(' ')
      .where((w) => w.isNotEmpty)
      .toList();

  // ------------------------------------------------------------- the server

  static Future<Landmark> _addRpc(
    String city,
    String label,
    String placeId,
  ) async {
    if (!Backend.ready) throw StateError('no backend');
    await Backend.ensureSignedIn();
    final rows =
        await Backend.client.rpc(
              'add_google_place',
              params: {'p_city': city, 'p_label': label, 'p_place_id': placeId},
            )
            as List<dynamic>;
    final row = rows.first as Map<String, dynamic>;
    return Landmark(
      id: row['landmark_id'] as String,
      name: row['landmark_name'] as String,
    );
  }

  static Future<List<Landmark>> _findRpc(String query, String city) async {
    if (!Backend.ready) return const [];
    final rows =
        await Backend.client.rpc(
              'find_rider_places',
              params: {'p_query': query, 'p_city': city, 'p_max': 5},
            )
            as List<dynamic>;
    return [
      for (final r in rows.cast<Map<String, dynamic>>())
        Landmark(id: r['id'] as String, name: r['name'] as String),
    ];
  }
}
