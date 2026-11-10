import 'dart:convert';

import '../services/backend.dart';
import 'push_bridge_stub.dart'
    if (dart.library.js_interop) 'push_bridge_web.dart'
    as bridge;

/// Push notifications, as the app sees them: whether this phone can get
/// them, turning them on and off, and telling the server when a report
/// went out. Behind one class so the app logic can be tested with a fake.
abstract class PushClient {
  /// This browser can receive notifications (Android; iPhone only from the
  /// Home Screen), and the server has keys.
  bool get supported;

  /// 'granted', 'denied' or 'default' (not asked yet).
  String get permission;

  /// Asks the browser (must run inside a tap), subscribes, and saves the
  /// subscription on the server. True when notifications are on.
  Future<bool> enable(String locale);

  /// Unsubscribes and forgets the subscription on the server.
  Future<void> disable();

  /// The app language changed: notifications follow it.
  Future<void> setLocale(String locale);

  /// A report for this route reached the server: maybe it unlocked fares.
  Future<void> routeReported(String fromId, String toId);

  /// Sends what quiet hours or the daily limit held back.
  Future<void> flush();

  /// A test notification to this phone, now. 'sent', or why not.
  Future<String> sendTest();

  factory PushClient.standard() => const KombienPush();
}

/// The real thing: the browser (web/index.html's kombienPush) and the
/// notify-unlocked function.
class KombienPush implements PushClient {
  const KombienPush();

  static const _function = 'notify-unlocked';

  @override
  bool get supported => Backend.ready && bridge.supported();

  @override
  String get permission => bridge.permission();

  @override
  Future<bool> enable(String locale) async {
    final raw = await bridge.enable(); // first: the browser's own prompt
    if (raw.isEmpty || !Backend.ready) return false;
    try {
      final sub = jsonDecode(raw) as Map<String, dynamic>;
      final keys = sub['keys'] as Map<String, dynamic>;
      await Backend.ensureSignedIn();
      await Backend.client.from('push_subscriptions').upsert({
        'endpoint': sub['endpoint'],
        'p256dh': keys['p256dh'],
        'auth': keys['auth'],
        'locale': locale,
      }, onConflict: 'endpoint');
      return true;
    } catch (_) {
      await bridge.disable(); // not saved: don't leave it half on
      return false;
    }
  }

  @override
  Future<void> disable() async {
    final endpoint = await bridge.disable();
    if (endpoint.isEmpty || !Backend.ready) return;
    try {
      await Backend.client
          .from('push_subscriptions')
          .delete()
          .eq('endpoint', endpoint);
    } catch (_) {}
  }

  @override
  Future<void> setLocale(String locale) async {
    if (!Backend.ready) return;
    try {
      final user = Backend.client.auth.currentUser?.id;
      if (user == null) return;
      await Backend.client
          .from('push_subscriptions')
          .update({'locale': locale})
          .eq('user_id', user);
    } catch (_) {}
  }

  @override
  Future<void> routeReported(String fromId, String toId) =>
      _call({'from_id': fromId, 'to_id': toId});

  @override
  Future<void> flush() => _call({'flush': true});

  @override
  Future<String> sendTest() async {
    if (!Backend.ready) return 'no backend';
    try {
      await Backend.ensureSignedIn();
      final res = await Backend.client.functions.invoke(
        _function,
        body: {'test': true},
      );
      final data = res.data;
      return data is Map ? '${data['test']}' : 'no answer';
    } catch (e) {
      return 'offline';
    }
  }

  Future<void> _call(Map<String, Object> body) async {
    if (!Backend.ready) return;
    try {
      await Backend.client.functions.invoke(_function, body: body);
    } catch (_) {
      // Notifications never get in the rider's way.
    }
  }
}
