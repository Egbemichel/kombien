import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/backend.dart';
import 'fare_repository.dart';
import 'landmark_repository.dart';
import 'sample_landmarks.dart';

/// One landmark as a city pack keeps it.
class PackPlace {
  PackPlace(this.id, this.name, this.aliases, this.lat, this.lng, [this.kind]);
  final String? id;
  final String name;
  final List<String> aliases;
  final double? lat, lng;

  /// The OpenStreetMap tag that made it a landmark (place=suburb...).
  final String? kind;

  /// Lower case, accents off: what search compares.
  late final String _text = fold('$name ${aliases.join(' ')}');
  late final String _name = fold(name);
  late final List<String> _words = tokens(_text, keepStops: true);

  /// Metres of "distance" added when ranking the place I am at: the centre
  /// of a neighbourhood is no more than the middle of an area, a junction
  /// or market is where riders say they are.
  double get areaPenalty => switch (kind) {
    'place=quarter' || 'place=suburb' || 'place=neighbourhood' => 250,
    null => 0,
    final k
        when k.startsWith('place=') ||
            k.startsWith('highway=') ||
            k == 'amenity=marketplace' =>
      0,
    _ => 120,
  };

  List<Object?> toJson() => [id, name, aliases, lat, lng, kind];
  factory PackPlace.fromJson(List<dynamic> j) => PackPlace(
    j[0] as String?,
    j[1] as String,
    (j[2] as List).cast<String>(),
    (j[3] as num?)?.toDouble(),
    (j[4] as num?)?.toDouble(),
    j.length > 5 ? j[5] as String? : null,
  );
}

/// A city's landmarks and known fare ranges, kept on the phone so search
/// and fares work with no connection ("Saved fares and map" in Settings).
class CityPack {
  CityPack({
    required this.city,
    required this.savedAt,
    required this.places,
    required this.fares,
    this.version = current,
  });

  /// 2: places carry their kind (before: no kind, ranking by distance only).
  static const current = 2;
  final int version;

  final String city;
  final DateTime savedAt;
  final List<PackPlace> places;

  /// "fromId→toId" → (low, high, reports).
  final Map<String, (int, int, int)> fares;

  String toJson() => jsonEncode({
    'v': version,
    'city': city,
    'at': savedAt.toIso8601String(),
    'places': [for (final p in places) p.toJson()],
    'fares': {
      for (final e in fares.entries)
        e.key: [e.value.$1, e.value.$2, e.value.$3],
    },
  });

  factory CityPack.fromJson(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    return CityPack(
      version: (j['v'] as int?) ?? 1,
      city: j['city'] as String,
      savedAt: DateTime.parse(j['at'] as String),
      places: [
        for (final p in j['places'] as List) PackPlace.fromJson(p as List),
      ],
      fares: {
        for (final e in (j['fares'] as Map).entries)
          e.key as String: (
            (e.value as List)[0] as int,
            (e.value as List)[1] as int,
            (e.value as List)[2] as int,
          ),
      },
    );
  }
}

/// Lower case, no accents, single spaces.
String fold(String s) {
  const from = 'àâäáãåçéèêëíìîïñóòôöõúùûüýÿœæ';
  const to = 'aaaaaaceeeeiiiinooooouuuuyyoa';
  final b = StringBuffer();
  for (final c in s.toLowerCase().split('')) {
    final i = from.indexOf(c);
    b.write(i < 0 ? c : to[i]);
  }
  return b.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

const _stopWords = {
  'de',
  'du',
  'des',
  'la',
  'le',
  'les',
  'l',
  'd',
  'et',
  'a',
  'au',
  'aux',
  'en',
  'sur',
  'the',
  'of',
  'and',
};

/// The words of an already folded text, without the filler words riders and
/// names put between them ("Dispensaire de Messassi" -> dispensaire,
/// messassi), unless [keepStops].
List<String> tokens(String folded, {bool keepStops = false}) => [
  for (final w in folded.split(RegExp(r'[^a-z0-9]+')))
    if (w.isNotEmpty && (keepStops || !_stopWords.contains(w))) w,
];

/// Edits (insert, delete, change) between two words; gives up past [max].
int editDistance(String a, String b, int max) {
  if ((a.length - b.length).abs() > max) return max + 1;
  var prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final cur = List<int>.filled(b.length + 1, 0)..[0] = i;
    var best = cur[0];
    for (var j = 1; j <= b.length; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      var v = prev[j - 1] + cost;
      if (prev[j] + 1 < v) v = prev[j] + 1;
      if (cur[j - 1] + 1 < v) v = cur[j - 1] + 1;
      cur[j] = v;
      if (v < best) best = v;
    }
    if (best > max) return max + 1;
    prev = cur;
  }
  return prev[b.length];
}

/// Where each city with landmark data lies: (south, west, north, east).
/// The same boxes the OpenStreetMap import uses.
const kCityAreas = <String, (double, double, double, double)>{
  'Yaoundé': (3.70, 11.40, 3.98, 11.62),
  'Douala': (3.95, 9.60, 4.15, 9.85),
};

/// The city a point is in, or null outside every covered city.
String? cityAt(double lat, double lng) {
  for (final MapEntry(key: city, value: (s, w, n, e)) in kCityAreas.entries) {
    if (lat >= s && lat <= n && lng >= w && lng <= e) return city;
  }
  return null;
}

/// Metres between two points (equirectangular: plenty within a city).
double metresBetween(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371000.0;
  final x =
      (lng2 - lng1) * math.pi / 180 * math.cos((lat1 + lat2) * math.pi / 360);
  final y = (lat2 - lat1) * math.pi / 180;
  return r * math.sqrt(x * x + y * y);
}

/// The packs saved on this phone, and getting new ones.
class CityPacks {
  CityPacks();

  static const _prefix = 'city_pack:';

  /// Saved packs by city, loaded at start.
  final saved = ValueNotifier<Map<String, CityPack>>(const {});

  /// Downloads in progress: city → 0…1.
  final progress = ValueNotifier<Map<String, double>>(const {});

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final out = <String, CityPack>{};
      for (final k in p.getKeys().where((k) => k.startsWith(_prefix))) {
        try {
          final pack = CityPack.fromJson(p.getString(k)!);
          out[pack.city] = pack;
        } catch (_) {
          await p.remove(k); // an older format: fetched again when needed
        }
      }
      // Packs already in memory (one just downloaded) are newer.
      saved.value = {...out, ...saved.value};
    } catch (_) {}
  }

  bool has(String city) => saved.value.containsKey(city);

  void _step(String city, double? v) {
    final next = Map<String, double>.from(progress.value);
    v == null ? next.remove(city) : next[city] = v;
    progress.value = next;
  }

  /// Downloads (or refreshes) [city]'s pack. True when it was saved.
  /// Without a backend, the pack holds the sample landmarks.
  Future<bool> download(String city) async {
    if (progress.value.containsKey(city)) return false;
    _step(city, .08);
    try {
      final List<PackPlace> places;
      final Map<String, (int, int, int)> fares;
      if (Backend.ready) {
        final raw =
            await Backend.client.rpc(
                  'city_landmarks',
                  params: {'city_name': city},
                )
                as List<dynamic>;
        places = [for (final r in raw) PackPlace.fromJson(r as List)];
        _step(city, .7);
        final f =
            await Backend.client.rpc('city_fares', params: {'city_name': city})
                as List<dynamic>;
        fares = {
          for (final r in f.cast<List<dynamic>>())
            '${r[0]}→${r[1]}': (
              (r[2] as num).toInt(),
              (r[3] as num).toInt(),
              (r[4] as num).toInt(),
            ),
        };
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 600));
        places = [
          for (final (name, _) in kSampleLandmarks)
            PackPlace(null, name, const [], null, null),
        ];
        fares = const {};
      }
      _step(city, 1);
      final pack = CityPack(
        city: city,
        savedAt: DateTime.now(),
        places: places,
        fares: fares,
      );
      final p = await SharedPreferences.getInstance();
      await p.setString('$_prefix$city', pack.toJson());
      saved.value = {...saved.value, city: pack};
      return true;
    } catch (_) {
      return false;
    } finally {
      _step(city, null);
    }
  }

  Future<void> delete(String city) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.remove('$_prefix$city');
    } catch (_) {}
    saved.value = Map.of(saved.value)..remove(city);
  }

  Iterable<PackPlace> get _all => saved.value.values.expand((p) => p.places);

  /// A saved landmark by database id.
  PackPlace? place(String id) {
    for (final p in _all) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Landmarks matching [query] from the saved packs, like the database's
  /// search: names starting with it first, then nearest, then A–Z.
  List<Landmark> search(
    String query, {
    double? lat,
    double? lng,
    int limit = 3,
  }) {
    final q = fold(query);
    if (q.length < 2) return const [];
    var words = tokens(q);
    if (words.isEmpty) words = tokens(q, keepStops: true);

    // Tier 0: the whole text as typed, anywhere in the name.
    // Tier 1: every word typed, in any order ("messassi dispensaire").
    // Tier 2: every word, allowing a slip of a letter ("messasi").
    final hits = <(int, bool, double, PackPlace)>[];
    final fuzzy = <PackPlace>[];
    for (final p in _all) {
      final int tier;
      if (p._text.contains(q)) {
        tier = 0;
      } else if (words.length > 1 && words.every(p._text.contains)) {
        tier = 1;
      } else {
        fuzzy.add(p);
        continue;
      }
      hits.add((tier, _starts(p, q), _metres(p, lat, lng), p));
    }
    if (hits.length < limit) {
      for (final p in fuzzy) {
        if (_slips(p, words)) {
          hits.add((2, false, _metres(p, lat, lng), p));
        }
      }
    }
    hits.sort((a, b) {
      if (a.$1 != b.$1) return a.$1.compareTo(b.$1);
      if (a.$2 != b.$2) return a.$2 ? -1 : 1;
      final c = a.$3.compareTo(b.$3);
      return c != 0 ? c : a.$4.name.compareTo(b.$4.name);
    });
    return [
      for (final h in hits.take(limit))
        Landmark(
          id: h.$4.id,
          name: h.$4.name,
          distanceM: h.$3.isFinite ? h.$3 : null,
        ),
    ];
  }

  static bool _starts(PackPlace p, String q) =>
      p._name.startsWith(q) || p._text.startsWith(q);

  static double _metres(PackPlace p, double? lat, double? lng) =>
      lat != null && lng != null && p.lat != null
      ? metresBetween(lat, lng, p.lat!, p.lng!)
      : double.infinity;

  /// Every word typed is in the place, or one letter off a word of it
  /// (two letters for long words), and at least one is the "one off".
  static bool _slips(PackPlace p, List<String> typed) {
    var slipped = false;
    for (final t in typed) {
      if (p._text.contains(t)) continue;
      if (t.length < 4) return false;
      final room = t.length >= 8 ? 2 : 1;
      var close = false;
      for (final w in p._words) {
        if (editDistance(t, w, room) <= room) {
          close = true;
          break;
        }
      }
      if (!close) return false;
      slipped = true;
    }
    return slipped;
  }

  /// The saved landmark nearest to a point, within [maxM] metres. The
  /// centre of a whole neighbourhood counts as further than a junction or
  /// market at the same distance (see [PackPlace.areaPenalty]).
  Landmark? nearest(double lat, double lng, {double maxM = 600}) {
    PackPlace? best;
    var bestScore = double.infinity, bestD = 0.0;
    for (final p in _all) {
      if (p.lat == null) continue;
      final d = metresBetween(lat, lng, p.lat!, p.lng!);
      if (d > maxM) continue;
      final score = d + p.areaPenalty;
      if (score < bestScore) (best, bestScore, bestD) = (p, score, d);
    }
    return best == null
        ? null
        : Landmark(id: best.id, name: best.name, distanceM: bestD);
  }

  /// The saved range for a route, if a pack has one.
  FareRange? fare(Landmark from, Landmark to) {
    if (from.id == null || to.id == null) return null;
    for (final pack in saved.value.values) {
      final f = pack.fares['${from.id}→${to.id}'];
      if (f != null) {
        return FareRange(low: f.$1, high: f.$2, reports: f.$3, cached: true);
      }
    }
    return null;
  }

  /// Saved over a week ago, or in an older format: worth refreshing.
  bool stale(String city) {
    final pack = saved.value[city]!;
    return pack.version < CityPack.current ||
        DateTime.now().difference(pack.savedAt).inDays >= 7;
  }
}
