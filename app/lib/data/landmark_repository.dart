import '../services/backend.dart';
import 'city_pack.dart';
import 'sample_landmarks.dart';

/// A named place riders use as a start or destination.
class Landmark {
  const Landmark({this.id, required this.name, this.distanceM});

  /// Database id; null for sample data.
  final String? id;
  final String name;

  /// Metres from the rider (or from the point it was matched to).
  final double? distanceM;

  /// "~3km", "~800m", or '' when the distance is unknown.
  String get distanceLabel {
    final d = distanceM;
    if (d == null) return '';
    if (d < 1000) return '~${(d / 100).round() * 100}m';
    return '~${(d / 1000).round()}km';
  }
}

/// Where landmark search comes from.
abstract class LandmarkRepository {
  /// Landmarks matching [query], best first; nearest first when the
  /// rider's position ([lat], [lng]) is known.
  Future<List<Landmark>> search(
    String query, {
    double? lat,
    double? lng,
    int limit = 3,
  });

  /// Supabase when configured, else the built-in sample list; either way
  /// the city packs saved on the phone answer first.
  factory LandmarkRepository.standard(CityPacks packs) =>
      OfflineFirstLandmarkRepository(
        packs,
        Backend.configured
            ? SupabaseLandmarkRepository()
            : const SampleLandmarkRepository(),
      );
}

/// Saved city packs first: instant, and works with no connection.
///
/// When every covered city is saved on the phone the pack is the whole
/// answer: a place it does not know is "not found" at once, with no wait
/// on the network. Otherwise (a city not saved yet) the database is asked
/// too, but never for longer than a couple of seconds.
class OfflineFirstLandmarkRepository implements LandmarkRepository {
  OfflineFirstLandmarkRepository(
    this.packs,
    this.remote, {
    this.remoteTimeout = const Duration(seconds: 2),
  });
  final CityPacks packs;
  final LandmarkRepository remote;

  /// The longest the database is waited for when the packs are not enough.
  final Duration remoteTimeout;

  @override
  Future<List<Landmark>> search(
    String query, {
    double? lat,
    double? lng,
    int limit = 3,
  }) async {
    final local = packs.search(query, lat: lat, lng: lng, limit: limit);
    if (local.length >= limit) return local;
    if (kCityAreas.keys.every(packs.has)) return local; // the whole answer
    try {
      final more = await remote
          .search(query, lat: lat, lng: lng, limit: limit)
          .timeout(remoteTimeout);
      final seen = {for (final l in local) l.name};
      return [
        ...local,
        ...more.where((l) => seen.add(l.name)),
      ].take(limit).toList();
    } catch (_) {
      // Slow or offline: what the phone has (nothing at all: the error).
      if (local.isNotEmpty || packs.saved.value.isNotEmpty) return local;
      rethrow;
    }
  }
}

/// The `search_landmarks` database function.
class SupabaseLandmarkRepository implements LandmarkRepository {
  @override
  Future<List<Landmark>> search(
    String query, {
    double? lat,
    double? lng,
    int limit = 3,
  }) async {
    if (query.trim().length < 2 || !Backend.ready) return const [];
    final rows =
        await Backend.client.rpc(
              'search_landmarks',
              params: {
                'query': query,
                'near_lat': lat,
                'near_lng': lng,
                'max_results': limit,
              },
            )
            as List<dynamic>;
    return [
      for (final r in rows.cast<Map<String, dynamic>>())
        Landmark(
          id: r['id'] as String,
          name: r['name'] as String,
          distanceM: (r['distance_m'] as num?)?.toDouble(),
        ),
    ];
  }
}

/// Offline stand-in: the sample Yaoundé list, distances as written there.
class SampleLandmarkRepository implements LandmarkRepository {
  const SampleLandmarkRepository();

  @override
  Future<List<Landmark>> search(
    String query, {
    double? lat,
    double? lng,
    int limit = 3,
  }) async => [
    for (final (name, distance) in searchLandmarks(query, limit: limit))
      _SampleLandmark(name, distance),
  ];
}

class _SampleLandmark extends Landmark {
  const _SampleLandmark(String name, this._label) : super(name: name);
  final String _label;
  @override
  String get distanceLabel => _label;
}
