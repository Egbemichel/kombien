import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Whether Kombien may read the phone's location.
enum LocationAccess {
  /// Not checked yet.
  unknown,

  /// Allowed (while using the app, or always).
  granted,

  /// Refused, or not asked yet. Asking again shows the system prompt.
  denied,

  /// Refused for good: only the phone's settings can change it.
  blocked,

  /// The phone's location service is switched off.
  serviceOff;

  bool get isGranted => this == granted;
}

/// Thin wrapper over geolocator, so screens never touch the plugin and
/// tests can swap in a fake.
class LocationService {
  /// [browser] and [readFix] exist for tests; the defaults are the real
  /// platform and the real position read.
  LocationService({bool? browser, Future<void> Function()? readFix})
    : _browser = browser ?? kIsWeb,
      _readFix = readFix ?? _readPosition;

  final bool _browser;
  final Future<void> Function() _readFix;

  static Future<void> _readPosition() => Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
  );

  Future<LocationAccess> status() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return LocationAccess.serviceOff;
      }
      return _map(await Geolocator.checkPermission());
    } catch (_) {
      return LocationAccess.denied;
    }
  }

  /// Shows the system prompt when it can; when the rider has blocked
  /// location for good, opens the app's settings page instead.
  Future<LocationAccess> request() async {
    try {
      if (_browser) return await _askBrowser();
      if (!await Geolocator.isLocationServiceEnabled()) {
        await Geolocator.openLocationSettings();
        return LocationAccess.serviceOff;
      }
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        return LocationAccess.blocked;
      }
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
      }
      return _map(p);
    } catch (_) {
      return LocationAccess.denied;
    }
  }

  /// Browsers have no "app settings" page or separate location service.
  /// Asking means reading the position: the prompt only shows when the
  /// browser holds no answer yet. Only a refusal counts as refused; a
  /// missing fix (cold GPS, no signal indoors) means the permission is
  /// fine and the position just isn't there yet.
  ///
  /// geolocator's own web requestPermission() reports every failure as
  /// "denied for good". That is what turned a remembered grant red on
  /// launch: the quiet re-check couldn't get a fix and wiped the grant.
  Future<LocationAccess> _askBrowser() async {
    try {
      await _readFix();
      return LocationAccess.granted;
    } on PermissionDeniedException {
      return LocationAccess.blocked;
    } catch (_) {
      return LocationAccess.granted;
    }
  }

  /// The rider's position (latitude, longitude), or null when it can't be
  /// had within a few seconds. A recent fix is fine: this only picks the
  /// nearest landmark.
  Future<(double, double)?> position() async {
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      return (p.latitude, p.longitude);
    } catch (_) {
      try {
        final p = await Geolocator.getLastKnownPosition();
        return p == null ? null : (p.latitude, p.longitude);
      } catch (_) {
        return null;
      }
    }
  }

  static LocationAccess _map(LocationPermission p) => switch (p) {
    LocationPermission.always ||
    LocationPermission.whileInUse => LocationAccess.granted,
    LocationPermission.deniedForever => LocationAccess.blocked,
    LocationPermission.denied ||
    LocationPermission.unableToDetermine => LocationAccess.denied,
  };
}
