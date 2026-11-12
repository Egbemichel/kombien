import 'dart:js_interop';

import 'device_hint.dart';

@JS('screen')
external _Screen? get _screen;

@JS('devicePixelRatio')
external double? get _pixelRatio;

@JS('navigator')
external _Navigator? get _navigator;

extension type _Screen(JSObject _) implements JSObject {
  external int get width;
  external int get height;
}

extension type _Navigator(JSObject _) implements JSObject {
  external int? get hardwareConcurrency;
}

String? _cached;

/// This browser's device hint, or null when it cannot be worked out.
String? deviceHint() {
  if (_cached != null) return _cached;
  try {
    final s = _screen;
    if (s == null || s.width <= 0 || s.height <= 0) return null;
    return _cached = deviceHintOf(
      screenWidth: s.width,
      screenHeight: s.height,
      pixelRatio: _pixelRatio ?? 1,
      cores: _navigator?.hardwareConcurrency ?? 0,
      utcOffsetMinutes: DateTime.now().timeZoneOffset.inMinutes,
    );
  } catch (_) {
    return null;
  }
}
