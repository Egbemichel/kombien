/// A coarse "same device" hint, so one person opening Kombien in three
/// browsers is not counted as three people.
///
/// It is a hash of traits the browsers on one phone share: screen size,
/// pixel ratio, time zone, operating system and language. It says nothing
/// about who anyone is, is never shown, and is only compared with other hints
/// on fare reports. The server adds a second layer (the network the report
/// came from, never stored as an address); two sign-ins count as one person
/// only when both agree. Off the web, there is no hint.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

export 'device_hint_stub.dart'
    if (dart.library.js_interop) 'device_hint_web.dart';

/// "android", "ios", "windows", "macos", "linux" or "other", from a browser's
/// user-agent text. Browsers on one phone agree on this, whatever they call
/// themselves.
String osFamilyOf(String userAgent) {
  final ua = userAgent.toLowerCase();
  if (ua.contains('android')) return 'android';
  if (ua.contains('iphone') || ua.contains('ipad') || ua.contains('ipod')) {
    return 'ios';
  }
  if (ua.contains('windows')) return 'windows';
  if (ua.contains('mac os') || ua.contains('macintosh')) return 'macos';
  if (ua.contains('linux') || ua.contains('x11')) return 'linux';
  return 'other';
}

/// The hint for a device with these traits: 32 hex characters.
/// The screen's two sides are ordered, so rotating the phone changes nothing,
/// and the language is cut to its two letters ("fr-CM" and "fr" agree).
/// Processor cores are left out on purpose: browsers on one phone disagree
/// about them (some hide or cap the number).
String deviceHintOf({
  required int screenWidth,
  required int screenHeight,
  required double pixelRatio,
  required int utcOffsetMinutes,
  required String os,
  required String language,
}) {
  final long = screenWidth > screenHeight ? screenWidth : screenHeight;
  final short = screenWidth > screenHeight ? screenHeight : screenWidth;
  final lang = language.toLowerCase().split(RegExp('[-_]')).first;
  final traits =
      'kombien-device-v2|$long|$short|${pixelRatio.toStringAsFixed(2)}|'
      '$utcOffsetMinutes|$os|$lang';
  return sha256.convert(utf8.encode(traits)).toString().substring(0, 32);
}
