import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../services/backend.dart';

/// Remembers the place searches that found nothing and sends them, without
/// any rider identity, so the people who maintain the place list can see
/// which places are really missing.
///
/// What leaves the phone: the typed words, the city and the language. Nothing
/// about the rider: no id, no location, no history. Searching never signs a
/// rider in, so this is sent anonymously.
///
/// Searches made offline (most of them, with the city saved on the phone) are
/// kept and sent the next time the phone can, like problem reports.
class SearchMissLog {
  SearchMissLog({Future<void> Function(Map<String, Object?> row)? send})
    : _send = send ?? _rpc;

  static const _key = 'search_miss_queue';

  /// The most that wait on the phone; the oldest go first.
  static const maxQueued = 40;

  final Future<void> Function(Map<String, Object?> row) _send;

  /// Asked once per run of the app, so retyping the same place does not count twice.
  final _seen = <String>{};

  /// The words as they will be sent, or null when they should not be sent at
  /// all: too short or long to be a place, or something personal (an email
  /// address, a link, a phone number). The database checks the same again.
  static String? clean(String raw) {
    final q = raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (q.length < 3 || q.length > 60) return null;
    if (q.contains('@') || q.contains('http') || q.contains('www.')) {
      return null;
    }
    if (RegExp(r'\d{6,}').hasMatch(q.replaceAll(RegExp(r'[\s.\-]'), ''))) {
      return null;
    }
    return q;
  }

  /// Notes a search that found nothing. Never throws, never blocks the rider.
  Future<void> record(
    String typed, {
    required String city,
    required String locale,
  }) async {
    try {
      final q = clean(typed);
      if (q == null || !_seen.add('$city|$q')) return;
      final p = await SharedPreferences.getInstance();
      final queue = [
        ...?p.getStringList(_key),
        jsonEncode({'q': q, 'city': city, 'locale': locale}),
      ];
      final capped = queue.length > maxQueued
          ? queue.sublist(queue.length - maxQueued)
          : queue;
      await p.setStringList(_key, await _flush(capped));
    } catch (_) {
      // Logging is a courtesy; it must never get in the rider's way.
    }
  }

  /// Sends what is waiting (at start-up and when the app comes back too).
  Future<void> sendWaiting() async {
    try {
      final p = await SharedPreferences.getInstance();
      final queue = p.getStringList(_key);
      if (queue == null || queue.isEmpty) return;
      await p.setStringList(_key, await _flush(queue));
    } catch (_) {}
  }

  /// Returns what could not be sent.
  Future<List<String>> _flush(List<String> queue) async {
    final left = <String>[];
    for (final item in queue) {
      try {
        await _send(jsonDecode(item) as Map<String, Object?>);
      } catch (_) {
        left.add(item);
      }
    }
    return left;
  }

  static Future<void> _rpc(Map<String, Object?> row) async {
    if (!Backend.ready) throw StateError('no backend');
    await Backend.client.rpc(
      'log_search_miss',
      params: {
        'p_query': row['q'],
        'p_city': row['city'],
        'p_locale': row['locale'],
      },
    );
  }
}
