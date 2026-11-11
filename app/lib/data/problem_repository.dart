import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../services/backend.dart';

enum ProblemKind { wrongFare, placeMissing, bug, other }

enum ProblemArea { fares, report, settings, other }

/// "Report a problem": up to three answers from the rider.
class ProblemReport {
  const ProblemReport({required this.kind, this.area, this.details = ''});

  final ProblemKind kind;
  final ProblemArea? area;

  /// Free text, at most [maxDetails] characters.
  final String details;

  static const maxDetails = 280;

  Map<String, Object?> toJson({
    required String appVersion,
    required String locale,
    required String platform,
  }) => {
    'kind': switch (kind) {
      ProblemKind.wrongFare => 'wrong_fare',
      ProblemKind.placeMissing => 'place_missing',
      ProblemKind.bug => 'bug',
      ProblemKind.other => 'other',
    },
    'area': area?.name,
    'details': details.trim().isEmpty ? null : details.trim(),
    'app_version': appVersion,
    'locale': locale,
    'platform': platform,
  };
}

/// Sends problem reports to Supabase when it can; otherwise keeps them on
/// the phone and sends them the next time it can.
class ProblemRepository {
  static const _key = 'problem_queue';

  Future<void> submit(Map<String, Object?> row) async {
    final p = await SharedPreferences.getInstance();
    final queue = [...?p.getStringList(_key), jsonEncode(row)];
    await p.setStringList(_key, await _flush(queue));
  }

  /// Sends what is waiting (at start-up too).
  Future<void> sendWaiting() async {
    final p = await SharedPreferences.getInstance();
    final queue = p.getStringList(_key);
    if (queue == null || queue.isEmpty) return;
    await p.setStringList(_key, await _flush(queue));
  }

  /// Returns what could not be sent.
  Future<List<String>> _flush(List<String> queue) async {
    if (!Backend.ready) return queue;
    final left = <String>[];
    for (final item in queue) {
      try {
        await Backend.ensureSignedIn();
        await Backend.client
            .from('problem_reports')
            .insert(jsonDecode(item) as Map<String, dynamic>);
      } catch (_) {
        left.add(item);
      }
    }
    return left;
  }
}
