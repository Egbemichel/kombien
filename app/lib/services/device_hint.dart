/// A coarse "same device" hint, so one person opening Kombien in three
/// browsers is not counted as three people.
///
/// It is a hash of traits the browsers on one phone share: screen size, pixel
/// ratio, processor cores and time zone. It says nothing about who anyone is,
/// is never shown, and is only compared with other hints on fare reports.
/// Off the web, there is none.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

export 'device_hint_stub.dart'
    if (dart.library.js_interop) 'device_hint_web.dart';

/// The hint for a device with these traits: 32 hex characters.
/// The screen's two sides are ordered, so rotating the phone changes nothing.
String deviceHintOf({
  required int screenWidth,
  required int screenHeight,
  required double pixelRatio,
  required int cores,
  required int utcOffsetMinutes,
}) {
  final long = screenWidth > screenHeight ? screenWidth : screenHeight;
  final short = screenWidth > screenHeight ? screenHeight : screenWidth;
  final traits =
      'kombien-device-v1|$long|$short|${pixelRatio.toStringAsFixed(2)}|'
      '$cores|$utcOffsetMinutes';
  return sha256.convert(utf8.encode(traits)).toString().substring(0, 32);
}
