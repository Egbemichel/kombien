import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/k_motion.dart';
import '../design/k_tokens.dart';

// Shared animated primitives. Every one runs on KMotion's springs.

/// Press response: the child sinks to [pressedScale] while a finger is down
/// and springs back on release. No ripple; the movement is the feedback.
class KPressable extends StatefulWidget {
  const KPressable({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = .96,
  });
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  @override
  State<KPressable> createState() => _KPressableState();
}

class _KPressableState extends State<KPressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _s;

  @override
  void initState() {
    super.initState();
    _s = AnimationController.unbounded(vsync: this, value: 1);
  }

  @override
  void dispose() {
    _s.dispose();
    super.dispose();
  }

  void _to(double v) => KMotion.springTo(_s, v);

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _to(widget.pressedScale),
      onTapUp: (_) => _to(1),
      onTapCancel: () => _to(1),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _s,
        builder: (context, child) =>
            Transform.scale(scale: _s.value, child: child),
        child: widget.child,
      ),
    );
  }
}

/// A rounded-rect outline that starts at 12 o'clock and runs clockwise.
Path kOutline(RRect r) {
  final midX = r.left + r.width / 2;
  return Path()
    ..moveTo(midX, r.top)
    ..lineTo(r.right - r.trRadiusX, r.top)
    ..arcToPoint(Offset(r.right, r.top + r.trRadiusY), radius: r.trRadius)
    ..lineTo(r.right, r.bottom - r.brRadiusY)
    ..arcToPoint(Offset(r.right - r.brRadiusX, r.bottom), radius: r.brRadius)
    ..lineTo(r.left + r.blRadiusX, r.bottom)
    ..arcToPoint(Offset(r.left, r.bottom - r.blRadiusY), radius: r.blRadius)
    ..lineTo(r.left, r.top + r.tlRadiusY)
    ..arcToPoint(Offset(r.left + r.tlRadiusX, r.top), radius: r.tlRadius)
    ..lineTo(midX, r.top);
}

/// Paints a border in [base], then [trace] over the first [progress] of the
/// outline (12 o'clock, clockwise).
class KTracePainter extends CustomPainter {
  const KTracePainter({
    required this.radius,
    required this.base,
    required this.trace,
    required this.progress,
    this.width = 1.2,
  });
  final double radius;
  final Color base;
  final Color trace;
  final double progress;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(width / 2),
      Radius.circular(math.max(0, radius - width / 2)),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    if (base.a > 0) canvas.drawRRect(rrect, paint..color = base);
    final p = progress.clamp(0.0, 1.0);
    if (p <= 0 || trace == base) {
      if (p >= 1) canvas.drawRRect(rrect, paint..color = trace);
      return;
    }
    if (p >= 1) {
      canvas.drawRRect(rrect, paint..color = trace);
      return;
    }
    final metric = kOutline(rrect).computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * p),
      paint..color = trace,
    );
  }

  @override
  bool shouldRepaint(KTracePainter old) =>
      old.progress != progress ||
      old.base != base ||
      old.trace != trace ||
      old.radius != radius ||
      old.width != width;
}

/// The body every chip shares.
///
/// Selecting: the new border colour traces once round the chip from 12
/// o'clock; as it closes the loop, the fill and label colours change.
/// Deselecting runs the same in the idle border colour, erasing the old one.
/// [retraceOnTap] redraws the border on every tap (action chips, which have
/// no selected state). A non-null [progress] turns the border into a
/// determinate progress ring over [progressBase].
class KChipFrame extends StatefulWidget {
  const KChipFrame({
    super.key,
    required this.selected,
    required this.builder,
    this.onTap,
    this.height,
    this.width,
    this.padding = EdgeInsets.zero,
    this.alignment,
    this.radius = KRadius.option,
    this.borderWidth = 1.2,
    this.selectedFill = KColors.chipBackground,
    this.idleFill = KColors.dustGrey,
    this.selectedBorder = KColors.mango,
    this.idleBorder = KColors.dustGrey,
    this.retraceOnTap = false,
    this.progress,
    this.progressBase = KColors.surfaceBorder,
  });

  final bool selected;

  /// Builds the content for a selection amount t (0 idle … 1 selected).
  final Widget Function(BuildContext context, double t) builder;
  final VoidCallback? onTap;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry padding;
  final AlignmentGeometry? alignment;
  final double radius;
  final double borderWidth;
  final Color selectedFill;
  final Color idleFill;
  final Color selectedBorder;
  final Color idleBorder;
  final bool retraceOnTap;
  final double? progress;
  final Color progressBase;

  @override
  State<KChipFrame> createState() => _KChipFrameState();
}

class _KChipFrameState extends State<KChipFrame> with TickerProviderStateMixin {
  /// Fraction of the loop the incoming border colour has drawn.
  late final _trace = AnimationController.unbounded(vsync: this, value: 1)
    ..addListener(_onTrace);

  /// 0 idle look … 1 selected look (fill and label).
  late final _fill = AnimationController.unbounded(
    vsync: this,
    value: widget.selected ? 1 : 0,
  );

  /// Smoothed download progress.
  late final _progress = AnimationController.unbounded(
    vsync: this,
    value: widget.progress ?? 0,
  );

  late Color _from = _border(widget.selected), _to = _from;
  bool _fillPending = false;

  Color _border(bool selected) =>
      selected ? widget.selectedBorder : widget.idleBorder;

  void _onTrace() {
    // The fill follows the moment the loop closes, not when the spring rests.
    if (_fillPending && _trace.value >= .96) {
      _fillPending = false;
      KMotion.springTo(_fill, widget.selected ? 1 : 0, spec: KMotion.settle);
    }
  }

  void _traceTo(Color from, Color to) {
    _from = from;
    _to = to;
    _trace.value = 0;
    KMotion.springTo(_trace, 1);
  }

  @override
  void didUpdateWidget(KChipFrame old) {
    super.didUpdateWidget(old);
    if (old.selected != widget.selected) {
      _fillPending = true;
      _traceTo(_to, _border(widget.selected));
    }
    if (widget.progress != null) {
      if (old.progress == null) _progress.value = 0;
      KMotion.springTo(_progress, widget.progress!, spec: KMotion.settle);
    }
  }

  @override
  void dispose() {
    _trace.dispose();
    _fill.dispose();
    _progress.dispose();
    super.dispose();
  }

  void _tap() {
    if (widget.retraceOnTap) _traceTo(widget.selectedFill, _to);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return KPressable(
      onTap: widget.onTap == null ? null : _tap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_trace, _fill, _progress]),
        builder: (context, _) {
          final t = _fill.value.clamp(0.0, 1.0);
          final ring = widget.progress != null;
          return CustomPaint(
            foregroundPainter: KTracePainter(
              radius: widget.radius,
              width: widget.borderWidth,
              base: ring ? widget.progressBase : _from,
              trace: ring ? widget.selectedBorder : _to,
              progress: ring ? _progress.value : _trace.value,
            ),
            child: Container(
              height: widget.height,
              width: widget.width,
              padding: widget.padding,
              alignment: widget.alignment,
              decoration: BoxDecoration(
                color: Color.lerp(widget.idleFill, widget.selectedFill, t),
                borderRadius: BorderRadius.circular(widget.radius),
              ),
              child: widget.builder(context, t),
            ),
          );
        },
      ),
    );
  }
}

/// Three dots rising in a travelling wave: the "someone is on it" signal
/// riders already know from their chat apps. Loops until removed.
class KLoadingDots extends StatefulWidget {
  const KLoadingDots({super.key, this.color = KColors.charcoal, this.size = 6});
  final Color color;
  final double size;
  @override
  State<KLoadingDots> createState() => _KLoadingDotsState();
}

class _KLoadingDotsState extends State<KLoadingDots>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, _) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Builder(
            builder: (context) {
              // Each dot lifts during the first half of its own phase.
              final phase = (_c.value - i * .16) % 1;
              final b = phase < .5 ? math.sin(phase / .5 * math.pi) : 0.0;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: widget.size * .45),
                child: Transform.translate(
                  offset: Offset(0, -widget.size * .7 * b),
                  child: Opacity(
                    opacity: .35 + .65 * b,
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        color: widget.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    ),
  );
}
