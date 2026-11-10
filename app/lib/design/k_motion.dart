import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/physics.dart';

/// Kombien's one motion language: a damped spring.
///
/// Everything that moves, draws or changes colour runs on [spring] (things
/// arriving) or [settle] (things leaving / colour and opacity, which must not
/// overshoot). Interrupted animations keep their current velocity, so a tap
/// mid-flight redirects the motion instead of restarting it.
///
/// Spring (mass m, stiffness k, damping c), released from 0 towards 1:
///
///   ω₀ = √(k/m)            natural frequency
///   ζ  = c / (2√(km))      damping ratio
///   ω_d = ω₀·√(1 − ζ²)     damped frequency
///   x(t) = 1 − e^(−ζω₀t)·(cos ω_d·t + (ζω₀/ω_d)·sin ω_d·t)        (ζ < 1)
///   x(t) = 1 − (1 + ω₀t)·e^(−ω₀t)                                  (ζ = 1)
abstract final class KMotion {
  /// Arrivals: m 1, k 200, c 20.4 → ζ ≈ 0.72, ~3.8 % overshoot, settles
  /// (±2 %) in ~0.39 s.
  static const spring = SpringDescription(
    mass: 1,
    stiffness: 200,
    damping: 20.4,
  );

  /// Exits, colours and opacities: m 1, k 300, c 34.6 → ζ ≈ 1 (critically
  /// damped), no overshoot, settles in ~0.34 s.
  static const settle = SpringDescription(
    mass: 1,
    stiffness: 300,
    damping: 34.6,
  );

  /// Error wiggle: m 1, k 1500, c 16 → ζ ≈ 0.21, ~6 Hz, rests in ~0.5 s.
  /// Released at rest with a sideways kick ([shakeKick] pt/s), it swings a
  /// few times either side of its place and settles: "no", not a jolt.
  static const shake = SpringDescription(mass: 1, stiffness: 1500, damping: 16);
  static const shakeKick = 520.0;

  /// Starts the error wiggle on an unbounded controller (value = x offset).
  static TickerFuture shakeNow(AnimationController c) {
    c.value = 0;
    return c.animateWith(SpringSimulation(shake, 0, 0, shakeKick));
  }

  /// Drives an unbounded controller to [target] on [spec], carrying over
  /// whatever velocity it already has.
  static TickerFuture springTo(
    AnimationController c,
    double target, {
    SpringDescription spec = spring,
  }) => c.animateWith(SpringSimulation(spec, c.value, target, c.velocity));

  /// The spring as a [Curve] for implicit animations: pair with
  /// [springDuration].
  static const Curve springCurve = _SpringCurve(spring, springDuration);

  /// Overshoot-free twin of [springCurve] for colours and opacity.
  static const Curve settleCurve = _SpringCurve(settle, springDuration);

  /// Long enough for either spring to come to rest within 0.1 %.
  static const springDuration = Duration(milliseconds: 520);

  // Derived figures, shown in the style guide.
  static double omega0(SpringDescription s) => math.sqrt(s.stiffness / s.mass);
  static double zeta(SpringDescription s) =>
      s.damping / (2 * math.sqrt(s.stiffness * s.mass));
  static double omegaD(SpringDescription s) =>
      omega0(s) * math.sqrt(math.max(0, 1 - zeta(s) * zeta(s)));
  static double overshoot(SpringDescription s) => zeta(s) >= 1
      ? 0
      : math.exp(-math.pi * zeta(s) / math.sqrt(1 - zeta(s) * zeta(s)));
  static double settleTime(SpringDescription s) => 4 / (zeta(s) * omega0(s));

  /// x(t) for a release from rest at 0 towards 1, t in seconds.
  static double position(SpringDescription s, double t) {
    final w0 = omega0(s), z = zeta(s);
    if (z >= 1) {
      // Critically damped (treat ζ ≈ 1 as exactly 1).
      return 1 - (1 + w0 * t) * math.exp(-w0 * t);
    }
    final wd = omegaD(s);
    return 1 -
        math.exp(-z * w0 * t) *
            (math.cos(wd * t) + (z * w0 / wd) * math.sin(wd * t));
  }
}

class _SpringCurve extends Curve {
  const _SpringCurve(this.spec, this.duration);
  final SpringDescription spec;
  final Duration duration;
  @override
  double transformInternal(double t) {
    if (t >= 1) return 1;
    return KMotion.position(spec, t * duration.inMicroseconds / 1e6);
  }
}
