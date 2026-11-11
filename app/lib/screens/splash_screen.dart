import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../design/k_motion.dart';
import '../design/k_tokens.dart';

/// One piece of the splash artwork: a full-frame layer that rests at 0 and
/// starts [from] points lower.
class _Layer {
  const _Layer(this.asset, this.from, this.at);
  final String asset;

  /// Start offset below the rest position, in design points.
  final double from;

  /// When it starts moving, from the first frame.
  final Duration at;
}

/// The two splash screens as one continuous sunrise.
///
/// Splash 1: the sun and both clouds low in an empty sky. They rise to the
/// top (splash 2), then the city builds up from below, farthest first: the
/// far skyline, the mid skyline, the dark towers, the near buildings, then
/// the plants in two layers (back trees, front bushes). Nearer layers start
/// closer to the bottom, so they travel less, which gives the climb its
/// depth. The wordmark settles in last. Everything runs on KMotion.spring.
///
/// The artwork is a 402 × 874 design frame, covered to the screen and
/// anchored to the bottom so the city always meets the bottom edge.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.onDone, this.hold = true});

  /// Called once the scene has settled and held.
  final VoidCallback? onDone;

  /// Hold splash 1 briefly before the sunrise (off in tests).
  final bool hold;

  /// Design frame.
  static const frame = Size(402, 874);

  /// Splash 1 has the sun and clouds this much lower than splash 2.
  static const sunrise = 534.0;

  static const _dir = 'assets/splash/';
  static const sky = [
    _Layer('${_dir}sun.webp', sunrise, Duration(milliseconds: 380)),
    _Layer('${_dir}cloud-left.webp', sunrise, Duration(milliseconds: 440)),
    _Layer('${_dir}cloud-right.webp', sunrise, Duration(milliseconds: 500)),
  ];

  // Each start offset puts the layer's highest pixel just below the screen
  // (tops: far 446, mid and towers 487, near 511, plants 662 and 791 pt).
  static const city = [
    _Layer('${_dir}city-far.webp', 480, Duration(milliseconds: 820)),
    _Layer('${_dir}city-mid.webp', 420, Duration(milliseconds: 930)),
    _Layer('${_dir}city-towers.webp', 450, Duration(milliseconds: 1040)),
    _Layer('${_dir}city-near.webp', 380, Duration(milliseconds: 1150)),
    _Layer('${_dir}plants-back.webp', 230, Duration(milliseconds: 1290)),
    _Layer('${_dir}plants-front.webp', 120, Duration(milliseconds: 1400)),
  ];

  static const _wordmarkAt = Duration(milliseconds: 1560);
  static const _holdFor = Duration(milliseconds: 900);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static final _layers = [...SplashScreen.sky, ...SplashScreen.city];

  /// 0 at the start position, 1 at rest (the spring overshoots past 1).
  late final List<AnimationController> _rise = [
    for (final _ in _layers) AnimationController.unbounded(vsync: this),
  ];
  late final _wordmark = AnimationController.unbounded(vsync: this);
  final _timers = <Timer>[];
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // Decode every layer before anything moves, so nothing pops in late.
    Future.wait([
      for (final l in _layers) precacheImage(AssetImage(l.asset), context),
    ]).whenComplete(() {
      // Start on the next frame, from the framework's own clock.
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _play();
      });
      WidgetsBinding.instance.scheduleFrame();
    });
  }

  void _after(Duration d, VoidCallback f) => _timers.add(
    Timer(d, () {
      if (mounted) f();
    }),
  );

  void _play() {
    final lead = widget.hold
        ? Duration.zero
        : const Duration(milliseconds: -380);
    for (var i = 0; i < _layers.length; i++) {
      _after(_layers[i].at + lead, () => KMotion.springTo(_rise[i], 1));
    }
    _after(SplashScreen._wordmarkAt + lead, () {
      KMotion.springTo(_wordmark, 1, spec: KMotion.settle);
    });
    _after(
      SplashScreen._wordmarkAt + lead + SplashScreen._holdFor,
      () => widget.onDone?.call(),
    );
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    for (final c in _rise) {
      c.dispose();
    }
    _wordmark.dispose();
    super.dispose();
  }

  Widget _layer(int i) {
    final l = _layers[i];
    return AnimatedBuilder(
      animation: _rise[i],
      builder: (context, child) => Transform.translate(
        offset: Offset(0, l.from * (1 - _rise[i].value)),
        child: child,
      ),
      // Full-frame layer, top-aligned; the city layers run 140 px past the
      // frame so the spring's overshoot never lifts them off the bottom.
      child: Image.asset(
        l.asset,
        width: SplashScreen.frame.width,
        fit: BoxFit.fitWidth,
        alignment: Alignment.topCenter,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: KColors.background,
      child: ClipRect(
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.hardEdge,
            child: SizedBox.fromSize(
              size: SplashScreen.frame,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (var i = 0; i < _layers.length; i++)
                    Positioned(
                      left: 0,
                      top: 0,
                      width: SplashScreen.frame.width,
                      child: _layer(i),
                    ),
                  Positioned(
                    left: 101,
                    top: 319,
                    width: 203,
                    child: AnimatedBuilder(
                      animation: _wordmark,
                      builder: (context, child) {
                        final t = _wordmark.value.clamp(0.0, 1.0);
                        return Opacity(
                          opacity: t,
                          child: Transform.translate(
                            offset: Offset(0, 10 * (1 - t)),
                            child: child,
                          ),
                        );
                      },
                      child: Semantics(
                        label: 'Kombien',
                        child: SvgPicture.asset(
                          'assets/brand/kombien-wordmark-light.svg',
                          width: 203,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
