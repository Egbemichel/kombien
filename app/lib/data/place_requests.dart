import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../services/backend.dart';

/// What a rider asks Kombien to add, and how they are told when it is there.
///
/// - **Tell us about it** ([suggest]): a place the rider named and could not
///   find (with an optional note on where it is). It is saved for the people
///   who maintain the place list, who look it up and add it. Kept on the
///   phone until it can be sent, like problem reports.
/// - **Watching a search** ([watch]): only for a rider with notifications on,
///   the words they searched for and did not find, so Kombien can tell them
///   when the place is added. Anyone else's search stays anonymous (it only
///   counts in the missing list, see SearchMissLog). Turning notifications
///   off forgets them ([forget]).
///
/// Nothing here has a name, number or account: the server ties a request to
/// the phone's anonymous id, and only to tell that phone the place is there.
class PlaceRequests {
  PlaceRequests({
    Future<void> Function(Map<String, Object?> row)? send,
    Future<void> Function(Map<String, Object?> row)? sendWatch,
    Future<void> Function()? forgetOnServer,
  }) : _send = send ?? _suggestRpc,
       _sendWatch = sendWatch ?? _watchRpc,
       _forget = forgetOnServer ?? _forgetRpc;

  static const _key = 'place_suggestion_queue';

  /// The most that wait on the phone; the oldest go first.
  static const maxQueued = 20;

  final Future<void> Function(Map<String, Object?> row) _send;
  final Future<void> Function(Map<String, Object?> row) _sendWatch;
  final Future<void> Function() _forget;

  /// Watched once per run of the app, so retyping does not repeat the call.
  final _watched = <String>{};

  /// Looks like something personal: an email address, a link, a phone number.
  static bool _personal(String text) {
    final lower = text.toLowerCase();
    return lower.contains('@') ||
        lower.contains('http') ||
        lower.contains('www.') ||
        RegExp(r'\d{6,}').hasMatch(text.replaceAll(RegExp(r'[\s.\-]'), ''));
  }

  /// A place name as it will be sent, or null when it should not be (too
  /// short or long, or something personal). The database checks the same
  /// again.
  static String? cleanName(String raw) {
    final text = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (text.length < 3 || text.length > 80 || _personal(text)) return null;
    return text;
  }

  /// "Where is it?" in the rider's words, or null (left out when empty or
  /// personal; cut at 120 letters).
  static String? cleanNote(String? raw) {
    final text = (raw ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
    if (text.isEmpty || _personal(text)) return null;
    return text.length > 120 ? text.substring(0, 120) : text;
  }

  /// Saves a place the rider could not find. True when it was accepted for
  /// sending (sent now, or kept on the phone to send later); false when the
  /// name is not one that can be sent. Never throws.
  Future<bool> suggest(
    String name, {
    String? note,
    required String city,
    required String locale,
  }) async {
    final clean = cleanName(name);
    if (clean == null) return false;
    try {
      final p = await SharedPreferences.getInstance();
      final queue = [
        ...?p.getStringList(_key),
        jsonEncode({
          'name': clean,
          'note': cleanNote(note),
          'city': city,
          'locale': locale,
        }),
      ];
      final capped = queue.length > maxQueued
          ? queue.sublist(queue.length - maxQueued)
          : queue;
      await p.setStringList(_key, await _flush(capped));
    } catch (_) {
      // Kept or not, the rider has been thanked: never get in their way.
    }
    return true;
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

  /// How many suggestions still wait on the phone.
  Future<int> waiting() async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.getStringList(_key)?.length ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// A search that found nothing, for a rider with notifications on: asks the
  /// server to remember it so the rider can be told when the place arrives.
  /// Best effort: no queue, never throws.
  Future<void> watch(
    String typed, {
    required String city,
    required String locale,
  }) async {
    try {
      final q = cleanName(typed)?.toLowerCase();
      if (q == null || !_watched.add('$city|$q')) return;
      await _sendWatch({'q': q, 'city': city, 'locale': locale});
    } catch (_) {}
  }

  /// Notifications turned off: the server forgets what this phone searched.
  Future<void> forget() async {
    _watched.clear();
    try {
      await _forget();
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

  static Future<void> _suggestRpc(Map<String, Object?> row) async {
    if (!Backend.ready) throw StateError('no backend');
    await Backend.ensureSignedIn();
    await Backend.client.rpc(
      'suggest_place',
      params: {
        'p_name': row['name'],
        'p_note': row['note'],
        'p_city': row['city'],
        'p_locale': row['locale'],
      },
    );
  }

  static Future<void> _watchRpc(Map<String, Object?> row) async {
    if (!Backend.ready) throw StateError('no backend');
    await Backend.ensureSignedIn();
    await Backend.client.rpc(
      'watch_place',
      params: {
        'p_query': row['q'],
        'p_city': row['city'],
        'p_locale': row['locale'],
      },
    );
  }

  static Future<void> _forgetRpc() async {
    if (!Backend.ready) return;
    await Backend.client.rpc('forget_place_watches');
  }
}
