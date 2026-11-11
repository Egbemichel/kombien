import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import '../design/k_motion.dart';
import '../design/k_tokens.dart';
import 'k_bits.dart';

/// One destination in the floating menu.
class KMenuEntry {
  const KMenuEntry({required this.icon, required this.label});
  final List<List<dynamic>> icon;
  final String label;
}

/// The app's only navigation: a button docked to the right edge that fans its
/// entries out on a half-circle to its left.
///
/// Rest layout (pt, from the button centre / the right screen edge):
/// entries[0] sits level with the button, its right edge 84.5 in; entries[1]
/// rests ~59.4 above and entries[2] ~58.6 below, right edges 50 in; further
/// entries continue down that column every 58.25.
///
/// Opening: the first entry springs out of the button (fast, then settling,
/// with a small horizontal overshoot); the rest then spring out of that first
/// entry. Closing — the button, a tap outside, or picking an entry — runs the
/// same sequence backwards.
///
/// Moving it: touch and hold the button (the standard long-press time, so
/// it is never moved by accident). It lifts, the phone ticks, and small
/// up/down chevrons appear: drag it anywhere up or down the right edge. It
/// stays where it is let go ([onMoved] reports the spot to remember), kept
/// far enough from the edges for the open menu to fit.
class KFloatingMenu extends StatefulWidget {
  const KFloatingMenu({
    super.key,
    required this.entries,
    required this.current,
    required this.onSelected,
    this.verticalPosition = .6,
    this.onMoved,
  });

  /// entries[0] comes out of the button; the others come out of entries[0].
  final List<KMenuEntry> entries;
  final int current;
  final ValueChanged<int> onSelected;

  /// Button centre as a fraction of the available height.
  final double verticalPosition;

  /// The rider moved the button: its new centre, as a fraction of the
  /// height. Null: the button cannot be moved.
  final ValueChanged<double>? onMoved;

  @override
  State<KFloatingMenu> createState() => _KFloatingMenuState();
}

class _KFloatingMenuState extends State<KFloatingMenu>
    with TickerProviderStateMixin {
  /// While held for moving: the live centre (fraction) and the lift.
  double? _dragFraction;
  double _dragStartFraction = 0;
  late final _lift = AnimationController.unbounded(vsync: this, value: 0);

  /// Room the open menu needs above and below the button centre.
  static const _roomAbove = 96.0, _roomBelow = 156.0;

  double _clampFraction(double f, double height) {
    // Too short to keep the whole open menu on screen: leave it be.
    if (height <= _roomAbove + _roomBelow) return f;
    return f.clamp(_roomAbove / height, 1 - _roomBelow / height);
  }

  void _holdStart() {
    if (_open || widget.onMoved == null) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _dragStartFraction = widget.verticalPosition;
      _dragFraction = widget.verticalPosition;
    });
    KMotion.springTo(_lift, 1);
  }

  void _holdMove(LongPressMoveUpdateDetails d, double height) {
    if (_dragFraction == null) return;
    setState(
      () => _dragFraction = _clampFraction(
        _dragStartFraction + d.offsetFromOrigin.dy / height,
        height,
      ),
    );
  }

  void _holdEnd() {
    final f = _dragFraction;
    if (f == null) return;
    KMotion.springTo(_lift, 0, spec: KMotion.settle);
    widget.onMoved?.call(f);
    setState(() => _dragFraction = null);
  }

  static const _openSpring = KMotion.spring;
  static const _closeSpring = KMotion.settle;
  static const _itemHeight = KMenuItem.height;

  /// Grid icon centre, in from the right edge.
  static const _buttonInset = KMenuButton.iconInset;

  /// Per entry, measured off the design export: vertical offset from the
  /// button centre, right edge inset from the screen edge, the row's
  /// left/right padding and the icon-to-label gap.
  static const _slots = [
    (
      dy: .125,
      right: 84.5,
      pad: EdgeInsets.only(left: 6.25, right: 6.75),
      gap: 8.25,
    ),
    (
      dy: -59.5,
      right: 50.0,
      pad: EdgeInsets.only(left: 8.75, right: 8.25),
      gap: 9.25,
    ),
    (
      dy: 58.625,
      right: 50.0,
      pad: EdgeInsets.only(left: 12.75, right: 13.5),
      gap: 8.5,
    ),
  ];

  ({double dy, double right, EdgeInsets pad, double gap}) _slot(int i) =>
      i < _slots.length
      ? _slots[i]
      : (
          dy: _slots[2].dy + 58.25 * (i - 2),
          right: _slots[2].right,
          pad: _slots[2].pad,
          gap: _slots[2].gap,
        );

  late final List<AnimationController> _c = [
    for (final _ in widget.entries) AnimationController.unbounded(vsync: this),
  ];

  /// Frosted veil over the page while the menu is open.
  late final AnimationController _veil = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    reverseDuration: const Duration(milliseconds: 260),
  );
  late final Animation<double> _veilT = CurvedAnimation(
    parent: _veil,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  bool _open = false;
  int _run = 0; // bumps on every open/close so a superseded sequence stops

  @override
  void dispose() {
    for (final c in _c) {
      c.dispose();
    }
    _veil.dispose();
    _lift.dispose();
    super.dispose();
  }

  void _spring(AnimationController c, double to, SpringDescription s) =>
      c.animateWith(SpringSimulation(s, c.value, to, c.velocity));

  Future<bool> _wait(int run, int ms) async {
    await Future<void>.delayed(Duration(milliseconds: ms));
    return mounted && run == _run;
  }

  Future<void> _openMenu() async {
    final run = ++_run;
    setState(() => _open = true);
    _veil.forward();
    _spring(_c[0], 1, _openSpring);
    if (!await _wait(run, 90)) return;
    for (var i = 1; i < _c.length; i++) {
      _spring(_c[i], 1, _openSpring);
      if (!await _wait(run, 40)) return;
    }
  }

  /// Runs the close sequence; true once it has fully finished (false if a
  /// newer open/close took over).
  Future<bool> _closeMenu() async {
    final run = ++_run;
    setState(() => _open = false);
    _veil.reverse();
    for (var i = _c.length - 1; i >= 1; i--) {
      _spring(_c[i], 0, _closeSpring);
      if (!await _wait(run, 35)) return false;
    }
    if (!await _wait(run, 70)) return false;
    try {
      await _c[0]
          .animateWith(
            SpringSimulation(_closeSpring, _c[0].value, 0, _c[0].velocity),
          )
          .orCancel;
    } on TickerCanceled {
      return false;
    }
    return mounted && run == _run;
  }

  /// Picking an entry swaps the screen at once, under the veil, so the new
  /// page is what clears into view as the blur falls away.
  void _select(int i) {
    if (!_open) return; // already closing: ignore taps on outgoing entries
    widget.onSelected(i);
    _closeMenu();
  }

  /// Where each entry's right-centre anchor rests, relative to the grid icon.
  Offset _restFor(int i) {
    final slot = _slot(i);
    return Offset(_buttonInset - slot.right, slot.dy);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final fraction = _clampFraction(
          _dragFraction ?? widget.verticalPosition,
          box.maxHeight,
        );
        final centre = Offset(
          box.maxWidth - _buttonInset,
          box.maxHeight * fraction,
        );
        final first = _restFor(0);
        return Stack(
          children: [
            // Frosted veil: blurs and washes the page in the background
            // colour so the entries read cleanly over anything beneath, with
            // a little extra density on the menu's side. Tapping it closes.
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _veilT,
                builder: (context, _) {
                  final t = _veilT.value;
                  if (t <= 0.001 && !_open) return const SizedBox.shrink();
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _open ? _closeMenu : null,
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(
                          sigmaX: 7 * t,
                          sigmaY: 7 * t,
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                KColors.background.withValues(alpha: .62 * t),
                                KColors.background.withValues(alpha: .86 * t),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            for (var i = widget.entries.length - 1; i >= 0; i--)
              AnimatedBuilder(
                animation: Listenable.merge([_c[i], _c[0]]),
                builder: (context, _) {
                  final v = _c[i].value;
                  if (v <= 0.001 && !_open) return const SizedBox.shrink();
                  // entries[0] leaves the button; the rest leave entries[0]'s current spot.
                  final from = i == 0
                      ? Offset.zero
                      : Offset.lerp(
                          Offset.zero,
                          first,
                          _c[0].value.clamp(0.0, 1.0),
                        )!;
                  final to = _restFor(i);
                  // The overshoot is horizontal only; vertical travel settles without bounce.
                  final x = from.dx + (to.dx - from.dx) * v;
                  final y = from.dy + (to.dy - from.dy) * v.clamp(0.0, 1.0);
                  final t = v.clamp(0.0, 1.0);
                  return Positioned(
                    right: box.maxWidth - (centre.dx + x),
                    top: centre.dy + y - _itemHeight / 2,
                    height: _itemHeight,
                    child: Opacity(
                      opacity: Curves.easeOut.transform(
                        (t * 1.4).clamp(0.0, 1.0),
                      ),
                      child: Transform.scale(
                        scale: 0.88 + 0.12 * t,
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () => _select(i),
                          child: KMenuItem(
                            icon: widget.entries[i].icon,
                            label: widget.entries[i].label,
                            highlighted: i == widget.current,
                            padding: _slot(i).pad,
                            gap: _slot(i).gap,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            // Hold-to-move hint: chevrons above and below the lifted button.
            for (final up in [true, false])
              Positioned(
                right: _buttonInset - 9,
                top:
                    centre.dy +
                    (up
                        ? -KMenuButton.height / 2 - 26
                        : KMenuButton.height / 2 + 8),
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _lift,
                    builder: (context, child) {
                      final t = _lift.value.clamp(0.0, 1.0);
                      return Opacity(
                        opacity: t,
                        child: Transform.translate(
                          offset: Offset(0, (up ? 6 : -6) * (1 - t)),
                          child: child,
                        ),
                      );
                    },
                    child: HugeIcon(
                      icon: up
                          ? HugeIcons.strokeRoundedChevronUp
                          : HugeIcons.strokeRoundedChevronDown,
                      size: 18,
                      color: KColors.charcoal.withValues(alpha: .55),
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
            Positioned(
              right: 0,
              top: centre.dy - KMenuButton.height / 2,
              child: GestureDetector(
                onLongPressStart: (_) => _holdStart(),
                onLongPressMoveUpdate: (d) => _holdMove(d, box.maxHeight),
                onLongPressEnd: (_) => _holdEnd(),
                onLongPressCancel: _holdEnd,
                child: AnimatedBuilder(
                  animation: _lift,
                  builder: (context, child) => Transform.scale(
                    // Lifted: a touch bigger, anchored to the screen edge.
                    scale: 1 + .08 * _lift.value,
                    alignment: Alignment.centerRight,
                    child: child,
                  ),
                  child: Semantics(
                    hint: widget.onMoved == null
                        ? null
                        : 'Touch and hold, then drag, to move',
                    child: KMenuButton(
                      key: const Key('kombien-menu-button'),
                      open: _open,
                      onTap: () => _open ? _closeMenu() : _openMenu(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
