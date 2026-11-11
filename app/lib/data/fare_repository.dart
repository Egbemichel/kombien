import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../services/backend.dart';
import 'city_pack.dart';
import 'landmark_repository.dart';

/// What riders recently paid on a route.
class FareRange {
  const FareRange({
    required this.low,
    required this.high,
    this.reports = 0,
    this.demo = false,
    this.cached = false,
  });

  /// FCFA, the lower and upper quartile of recent reports.
  final int low;
  final int high;
  final int reports;

  /// Made-up numbers (no backend yet): the card says so.
  final bool demo;

  /// From this phone's memory of an earlier search (offline).
  final bool cached;

  FareRange asCached() => FareRange(
    low: low,
    high: high,
    reports: reports,
    demo: demo,
    cached: true,
  );
}

/// Where fare ranges come from.
abstract class FareRepository {
  /// The range for [from] → [to], or null when there are too few reports
  /// to show one.
  Future<FareRange?> range(Landmark from, Landmark to);

  /// Supabase when configured, else demo ranges; offline, the last range
  /// seen on this phone, else the saved city pack's.
  factory FareRepository.standard([CityPacks? packs]) => CachedFareRepository(
    Backend.configured ? SupabaseFareRepository() : const DemoFareRepository(),
    packs: packs,
  );
}

/// The `fare_range` database function: aggregates only, and nothing for
/// routes with fewer than 3 recent reports.
class SupabaseFareRepository implements FareRepository {
  @override
  Future<FareRange?> range(Landmark from, Landmark to) async {
    // A start without a database id ("My location" before it is matched to
    // a landmark) cannot be looked up yet.
    if (!Backend.ready || from.id == null || to.id == null) return null;
    final rows =
        await Backend.client.rpc(
              'fare_range',
              params: {'from_id': from.id, 'to_id': to.id},
            )
            as List<dynamic>;
    if (rows.isEmpty) return null;
    final r = rows.first as Map<String, dynamic>;
    return FareRange(
      low: (r['low_xaf'] as num).toInt(),
      high: (r['high_xaf'] as num).toInt(),
      reports: (r['reports'] as num).toInt(),
    );
  }
}

/// Plausible Yaoundé taxi ranges for trying the app with no backend: the
/// same route always gets the same range, rounded to 50 FCFA like real
/// fares, and is marked as demo.
class DemoFareRepository implements FareRepository {
  const DemoFareRepository();

  @override
  Future<FareRange?> range(Landmark from, Landmark to) async {
    var h = 17;
    for (final c in '${from.name}→${to.name}'.toLowerCase().codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    final low = 250 + (h % 12) * 50; // 250 … 800
    final spread = 100 + ((h ~/ 12) % 5) * 50; // 100 … 300
    return FareRange(low: low, high: low + spread, reports: 0, demo: true);
  }
}

/// Remembers the last range seen for each route on this phone, so an
/// offline search can still show it (marked as saved).
class CachedFareRepository implements FareRepository {
  CachedFareRepository(this.inner, {this.packs});
  final FareRepository inner;
  final CityPacks? packs;

  static const _key = 'fare_cache';
  static String _route(Landmark a, Landmark b) =>
      '${a.id ?? a.name}→${b.id ?? b.name}'.toLowerCase();

  @override
  Future<FareRange?> range(Landmark from, Landmark to) async {
    final key = _route(from, to);
    try {
      final r = await inner.range(from, to);
      if (r != null) {
        try {
          final p = await SharedPreferences.getInstance();
          final all = _read(p)..[key] = [r.low, r.high, r.demo ? 1 : 0];
          await p.setString(_key, jsonEncode(all));
        } catch (_) {}
      }
      return r;
    } catch (_) {
      final p = await SharedPreferences.getInstance();
      final saved = _read(p)[key];
      if (saved == null) {
        final packed = packs?.fare(from, to);
        if (packed != null) throw FaresOffline(packed);
        rethrow; // offline and nothing saved
      }
      throw FaresOffline(
        FareRange(
          low: saved[0],
          high: saved[1],
          demo: saved[2] == 1,
        ).asCached(),
      );
    }
  }

  static Map<String, List<int>> _read(SharedPreferences p) {
    final raw = p.getString(_key);
    if (raw == null) return {};
    return (jsonDecode(raw) as Map).map(
      (k, v) => MapEntry(k as String, (v as List).cast<int>()),
    );
  }
}

/// Offline, with a saved range for the route to show instead.
class FaresOffline implements Exception {
  const FaresOffline(this.saved);
  final FareRange saved;
}
