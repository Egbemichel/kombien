import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../services/backend.dart';
import '../services/device_hint.dart';
import 'landmark_repository.dart';

enum DayPart { morning, afternoon, night }

enum Vehicle { taxi, moto }

/// One rider's "I paid this".
class FareReport {
  const FareReport({
    required this.from,
    required this.to,
    required this.amountXaf,
    this.dayPart,
    this.raining,
    this.vehicle = Vehicle.taxi,
  });

  final Landmark from;
  final Landmark to;
  final int amountXaf;

  /// Optional on the form; the current part of the day when left empty.
  final DayPart? dayPart;
  final bool? raining;
  final Vehicle vehicle;

  /// Fares are paid in steps of 50 FCFA.
  static const minXaf = 50, maxXaf = 50000, stepXaf = 50;
  static bool validAmount(int? xaf) =>
      xaf != null && xaf >= minXaf && xaf <= maxXaf && xaf % stepXaf == 0;

  DayPart get effectiveDayPart {
    if (dayPart != null) return dayPart!;
    final h = DateTime.now().hour;
    return h < 11
        ? DayPart.morning
        : h < 18
        ? DayPart.afternoon
        : DayPart.night;
  }
}

/// A report as this phone remembers it: what was reported, when, and
/// whether it has reached the shared data yet.
class StoredReport {
  const StoredReport({
    required this.id,
    required this.from,
    required this.to,
    this.fromId,
    this.toId,
    required this.amountXaf,
    required this.dayPart,
    this.raining,
    required this.vehicle,
    required this.at,
    required this.sent,
  });

  final String id;
  final String from, to;
  final String? fromId, toId;
  final int amountXaf;
  final DayPart dayPart;
  final bool? raining;
  final Vehicle vehicle;
  final DateTime at;
  final bool sent;

  StoredReport asSent() => StoredReport(
    id: id,
    from: from,
    to: to,
    fromId: fromId,
    toId: toId,
    amountXaf: amountXaf,
    dayPart: dayPart,
    raining: raining,
    vehicle: vehicle,
    at: at,
    sent: true,
  );

  factory StoredReport.of(FareReport r, {required bool sent}) {
    final at = DateTime.now();
    return StoredReport(
      id: at.microsecondsSinceEpoch.toString(),
      from: r.from.name,
      to: r.to.name,
      fromId: r.from.id,
      toId: r.to.id,
      amountXaf: r.amountXaf,
      dayPart: r.effectiveDayPart,
      raining: r.raining,
      vehicle: r.vehicle,
      at: at,
      sent: sent,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'from': from,
    'to': to,
    'from_id': fromId,
    'to_id': toId,
    'amount_xaf': amountXaf,
    'day_part': dayPart.name,
    'raining': raining,
    'vehicle': vehicle.name,
    'at': at.toIso8601String(),
    'sent': sent,
  };

  factory StoredReport.fromJson(Map<String, dynamic> j) => StoredReport(
    id: j['id'] as String,
    from: j['from'] as String,
    to: j['to'] as String,
    fromId: j['from_id'] as String?,
    toId: j['to_id'] as String?,
    amountXaf: j['amount_xaf'] as int,
    dayPart: DayPart.values.byName(j['day_part'] as String),
    raining: j['raining'] as bool?,
    vehicle: Vehicle.values.byName(j['vehicle'] as String),
    at: DateTime.parse(j['at'] as String),
    sent: j['sent'] as bool? ?? false,
  );
}

/// Where reports go, and this phone's memory of them.
abstract class ReportRepository {
  /// Sends [report] if it can and remembers it either way.
  Future<StoredReport> submit(FareReport report);

  /// Everything reported from this phone, newest first.
  Future<List<StoredReport>> history();

  /// Tries to send every report still waiting. Returns the new history.
  Future<List<StoredReport>> sendWaiting();

  /// Forgets every report on this phone (sent ones stay in the shared data).
  Future<void> deleteAll();

  factory ReportRepository.standard() => LocalFirstReportRepository();
}

/// Remembers every report on the phone; sends to Supabase when it can
/// (configured, online, and both landmarks known to the database), and
/// leaves the rest waiting to be sent later.
class LocalFirstReportRepository implements ReportRepository {
  static const _key = 'report_history';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<List<StoredReport>> _read() async {
    final raw = (await _prefs).getStringList(_key) ?? [];
    final out = <StoredReport>[];
    for (final s in raw) {
      try {
        out.add(StoredReport.fromJson(jsonDecode(s) as Map<String, dynamic>));
      } catch (_) {
        // A record from an older version: skip it.
      }
    }
    return out;
  }

  Future<void> _write(List<StoredReport> all) async => (await _prefs)
      .setStringList(_key, [for (final r in all) jsonEncode(r.toJson())]);

  /// True when the report reached the server.
  Future<bool> _send(StoredReport r) async {
    if (!Backend.ready || r.fromId == null || r.toId == null) return false;
    try {
      await Backend.ensureSignedIn();
      await Backend.client.from('fare_reports').insert({
        'from_landmark_id': r.fromId,
        'to_landmark_id': r.toId,
        'amount_xaf': r.amountXaf,
        'day_part': r.dayPart.name,
        'raining': r.raining ?? false,
        'vehicle': r.vehicle.name,
        'device_hint': deviceHint(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<StoredReport> submit(FareReport report) async {
    var stored = StoredReport.of(report, sent: false);
    if (await _send(stored)) stored = stored.asSent();
    await _write([stored, ...await _read()]);
    return stored;
  }

  @override
  Future<List<StoredReport>> history() async =>
      (await _read())..sort((a, b) => b.at.compareTo(a.at));

  @override
  Future<List<StoredReport>> sendWaiting() async {
    final all = await _read();
    var changed = false;
    for (var i = 0; i < all.length; i++) {
      if (!all[i].sent && await _send(all[i])) {
        all[i] = all[i].asSent();
        changed = true;
      }
    }
    if (changed) await _write(all);
    return all..sort((a, b) => b.at.compareTo(a.at));
  }

  @override
  Future<void> deleteAll() async => (await _prefs).remove(_key);
}
