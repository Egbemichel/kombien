import 'package:flutter/physics.dart';

/// Mirrors `brand/tokens/motion.json`. Spring presets for morph/settle
/// animations — see brand/motion/README.md for when (and when not) to use
/// them. These are a starting point, not tuned/final; adjust by feel on a
/// real device.
///
/// Usage:
/// ```dart
/// final simulation = SpringSimulation(
///   KombienSprings.standard,
///   controller.value,
///   1.0,
///   controller.velocity, // carry over velocity on interruption/re-trigger
/// );
/// controller.animateWith(simulation);
/// ```
class KombienSprings {
  KombienSprings._();

  /// Default for most morphs — containers resizing, cards expanding.
  static const standard = SpringDescription(
    mass: 1,
    stiffness: 180,
    damping: 20,
  );

  /// Content reveals (e.g. fare results appearing) — minimal overshoot.
  static const gentle = SpringDescription(mass: 1, stiffness: 120, damping: 26);

  /// Small controls — toggles, buttons, checkmarks.
  static const snappy = SpringDescription(mass: 1, stiffness: 300, damping: 30);

  /// Duration for a content swap's own cross-fade inside a morphing
  /// container (text/icon changing while the container is still resizing).
  static const contentSwapFade = Duration(milliseconds: 130);
}
