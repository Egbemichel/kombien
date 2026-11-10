import 'package:supabase_flutter/supabase_flutter.dart';

/// The Supabase connection, configured at build time:
///
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...
///
/// (or `--dart-define-from-file=supabase.local.json`, see docs/setup).
/// The publishable key is meant to ship in apps: row-level security in the database decides
/// what it may do. Without both values the app runs on its built-in sample
/// data, so it still works with no backend at all.
abstract final class Backend {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static bool get configured => url.isNotEmpty && publishableKey.isNotEmpty;

  static bool _ready = false;

  /// True once [init] connected the client.
  static bool get ready => _ready;

  static SupabaseClient get client => Supabase.instance.client;

  /// Sets up the client (no network call). Safe to call when unconfigured.
  static Future<void> init() async {
    if (!configured || _ready) return;
    await Supabase.initialize(url: url, publishableKey: publishableKey);
    _ready = true;
  }

  /// Every phone acts as an anonymous rider: signed in once, silently, the
  /// first time it writes (a fare report). Reading needs no sign-in.
  static Future<void> ensureSignedIn() async {
    if (!_ready) return;
    if (client.auth.currentSession != null) return;
    await client.auth.signInAnonymously();
  }
}
