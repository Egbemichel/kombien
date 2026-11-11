import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../design/k_motion.dart';
import '../design/k_text.dart';
import '../design/k_tokens.dart';
import '../app/app_state.dart';
import 'k_animated.dart';
import 'k_controls.dart';

// ------------------------------------------------------------------ flags

enum KFlag { uk, france }

/// Round flag used in the language selector and language chips.
class KFlagIcon extends StatelessWidget {
  const KFlagIcon(this.flag, {super.key, this.size = 18});
  final KFlag flag;
  final double size;
  @override
  Widget build(BuildContext context) => ClipOval(
    child: SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _FlagPainter(flag)),
    ),
  );
}

class _FlagPainter extends CustomPainter {
  _FlagPainter(this.flag);
  final KFlag flag;
  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    if (flag == KFlag.france) {
      c.drawRect(
        Rect.fromLTWH(0, 0, w / 3, h),
        Paint()..color = const Color(0xFF002395),
      );
      c.drawRect(
        Rect.fromLTWH(w / 3, 0, w / 3, h),
        Paint()..color = Colors.white,
      );
      c.drawRect(
        Rect.fromLTWH(2 * w / 3, 0, w / 3, h),
        Paint()..color = const Color(0xFFED2939),
      );
      return;
    }
    const blue = Color(0xFF012169), red = Color(0xFFC8102E);
    c.drawRect(Offset.zero & s, Paint()..color = blue);
    final diag = Paint()
      ..color = Colors.white
      ..strokeWidth = h * .2;
    c.drawLine(Offset.zero, Offset(w, h), diag);
    c.drawLine(Offset(w, 0), Offset(0, h), diag);
    final diagR = Paint()
      ..color = red
      ..strokeWidth = h * .07;
    c.drawLine(Offset.zero, Offset(w, h), diagR);
    c.drawLine(Offset(w, 0), Offset(0, h), diagR);
    c.drawRect(
      Rect.fromLTWH(w * .4, 0, w * .2, h),
      Paint()..color = Colors.white,
    );
    c.drawRect(
      Rect.fromLTWH(0, h * .4, w, h * .2),
      Paint()..color = Colors.white,
    );
    c.drawRect(Rect.fromLTWH(w * .44, 0, w * .12, h), Paint()..color = red);
    c.drawRect(Rect.fromLTWH(0, h * .44, w, h * .12), Paint()..color = red);
  }

  @override
  bool shouldRepaint(_FlagPainter old) => old.flag != flag;
}

/// One choice in the language dropdown.
class KLanguageOption {
  const KLanguageOption(this.locale, this.flag, this.code, this.name);
  final Locale locale;
  final KFlag flag;

  /// Short code on the selector ("En").
  final String code;

  /// The language in itself ("Français"), so anyone finds theirs.
  final String name;

  static const all = [
    KLanguageOption(Locale('en'), KFlag.uk, 'En', 'English'),
    KLanguageOption(Locale('fr'), KFlag.france, 'Fr', 'Français'),
  ];
}

/// Flag | code ⌄, top-right of onboarding: a dropdown.
///
/// A tap anywhere on it opens a small menu under it, right-aligned: each
/// language with its flag, named in itself, the current one ticked. Picking
/// one closes the menu and applies it; a tap outside just closes it. The
/// menu springs open from the selector's corner and the chevron turns over.
class KLanguageSelector extends StatefulWidget {
  const KLanguageSelector({
    super.key,
    this.current = const Locale('en'),
    this.onSelected,
    this.options = KLanguageOption.all,
  });
  final Locale current;
  final ValueChanged<Locale>? onSelected;
  final List<KLanguageOption> options;

  @override
  State<KLanguageSelector> createState() => _KLanguageSelectorState();
}

class _KLanguageSelectorState extends State<KLanguageSelector>
    with SingleTickerProviderStateMixin {
  final _link = LayerLink();
  final _portal = OverlayPortalController();

  /// 0 closed … 1 open (springs).
  late final _open = AnimationController.unbounded(vsync: this, value: 0);

  KLanguageOption get _current => widget.options.firstWhere(
    (o) => o.locale.languageCode == widget.current.languageCode,
    orElse: () => widget.options.first,
  );

  @override
  void dispose() {
    _open.dispose();
    super.dispose();
  }

  void _show() {
    if (widget.onSelected == null) return;
    _portal.show();
    KMotion.springTo(_open, 1);
  }

  Future<void> _hide() async {
    await KMotion.springTo(_open, 0, spec: KMotion.settle);
    if (mounted && _open.value < .01) _portal.hide();
  }

  void _pick(KLanguageOption o) {
    _hide();
    if (o.locale.languageCode != widget.current.languageCode) {
      widget.onSelected?.call(o.locale);
    }
  }

  Widget _menu(BuildContext context) => Stack(
    children: [
      // Tap outside: close.
      Positioned.fill(
        child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _hide),
      ),
      CompositedTransformFollower(
        link: _link,
        targetAnchor: Alignment.bottomRight,
        followerAnchor: Alignment.topRight,
        offset: const Offset(0, 6),
        child: Align(
          alignment: Alignment.topRight,
          child: AnimatedBuilder(
            animation: _open,
            builder: (context, child) {
              final t = _open.value;
              return Opacity(
                opacity: t.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: .9 + .1 * t,
                  alignment: Alignment.topRight,
                  child: child,
                ),
              );
            },
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                width: 168,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: KColors.surface,
                  borderRadius: BorderRadius.circular(KRadius.toast),
                  border: Border.all(color: KColors.surfaceBorder, width: 1.2),
                  boxShadow: kFloatShadow,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final o in widget.options)
                      Semantics(
                        button: true,
                        selected: o == _current,
                        child: KPressable(
                          pressedScale: .97,
                          onTap: () => _pick(o),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                KFlagIcon(o.flag, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    o.name,
                                    style: KText.bodySmall.dm(
                                      fontSize: 15,
                                      fontWeight: o == _current
                                          ? FontWeight.w500
                                          : FontWeight.w400,
                                      color: KColors.charcoal,
                                    ),
                                  ),
                                ),
                                if (o == _current)
                                  const HugeIcon(
                                    icon: HugeIcons.strokeRoundedTick02,
                                    size: 16,
                                    color: KColors.mango,
                                    strokeWidth: 2,
                                  ),
                              ],
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
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final current = _current;
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: _menu,
        child: Semantics(
          button: widget.onSelected != null,
          label: 'Language: ${current.name}',
          child: KPressable(
            onTap: widget.onSelected == null ? null : _show,
            child: Padding(
              // A comfortable touch target around a small control.
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  KFlagIcon(current.flag, size: 16),
                  Container(
                    width: 1,
                    height: 14,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    color: const Color(0xFFC8C2B3),
                  ),
                  Text(
                    current.code,
                    style: KText.bodySmall.dm(
                      fontSize: 15,
                      color: KColors.charcoal,
                    ),
                  ),
                  const SizedBox(width: 2),
                  AnimatedBuilder(
                    animation: _open,
                    builder: (context, child) => Transform.rotate(
                      angle: math.pi * _open.value.clamp(0.0, 1.0),
                      child: child,
                    ),
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedChevronDown,
                      size: 16,
                      color: KColors.charcoal,
                      strokeWidth: 1.5,
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

/// Language chip in Settings: flag | label.
class KLanguageChip extends StatelessWidget {
  const KLanguageChip({
    super.key,
    required this.flag,
    required this.label,
    this.selected = false,
    this.onTap,
  });
  final KFlag flag;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => KChipFrame(
    selected: selected,
    onTap: onTap,
    height: 38,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    builder: (context, t) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        KFlagIcon(flag, size: 17),
        Container(
          width: 1,
          height: 16,
          margin: const EdgeInsets.only(left: 5, right: 6),
          color: Color.lerp(
            KColors.onDust.withValues(alpha: .5),
            const Color(0xFFC8C2B3),
            t,
          ),
        ),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: KText.chip.dm(
              fontStyle: FontStyle.normal,
              fontWeight: FontWeight.w400,
              fontSize: 17,
              color: Color.lerp(KColors.onDust, KColors.charcoal, t),
            ),
          ),
        ),
      ],
    ),
  );
}

// ------------------------------------------------------------- page dots

class KPageDots extends StatelessWidget {
  const KPageDots({super.key, required this.count, required this.index});
  final int count;
  final int index;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < count; i++)
        AnimatedContainer(
          duration: KMotion.springDuration,
          curve: KMotion.settleCurve,
          width: 7,
          height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i == index ? KColors.mango : KColors.dotInactive,
          ),
        ),
    ],
  );
}

// ------------------------------------------------------------- checkbox

/// Mango checkbox with the terms sentence. Checking floods the box with
/// mango and draws the tick in from the left; unchecking runs it back.
class KTermsCheckbox extends StatefulWidget {
  const KTermsCheckbox({super.key, this.checked = true, this.onChanged});
  final bool checked;
  final ValueChanged<bool>? onChanged;
  @override
  State<KTermsCheckbox> createState() => _KTermsCheckboxState();
}

class _KTermsCheckboxState extends State<KTermsCheckbox>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController.unbounded(
    vsync: this,
    value: widget.checked ? 1 : 0,
  );

  @override
  void didUpdateWidget(KTermsCheckbox old) {
    super.didUpdateWidget(old);
    if (old.checked != widget.checked) {
      KMotion.springTo(
        _c,
        widget.checked ? 1 : 0,
        spec: widget.checked ? KMotion.spring : KMotion.settle,
      );
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final link = KText.bodySmall.dm(
      color: KColors.mango,
      decoration: TextDecoration.underline,
      decorationColor: KColors.mango,
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onChanged?.call(!widget.checked),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final v = _c.value;
              final fill = v.clamp(0.0, 1.0);
              return Container(
                width: 19,
                height: 19,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  color: KColors.mango.withValues(alpha: fill),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: KColors.mango, width: 1.5),
                ),
                child: ClipRect(
                  clipper: _TickClipper(fill),
                  child: Center(
                    child: Transform.scale(
                      // The spring's small overshoot gives the tick a settle.
                      scale: .8 + .2 * v,
                      child: const HugeIcon(
                        icon: HugeIcons.strokeRoundedTick02,
                        size: 15,
                        color: KColors.charcoal,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: KText.bodySmall.dm(color: KColors.charcoal),
                children: [
                  TextSpan(text: context.l10n.termsLead),
                  TextSpan(text: context.l10n.termsOfUse, style: link),
                  TextSpan(text: context.l10n.termsJoin),
                  TextSpan(text: context.l10n.privacyPolicy, style: link),
                  TextSpan(text: context.l10n.termsTail),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TickClipper extends CustomClipper<Rect> {
  const _TickClipper(this.t);
  final double t;
  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * t, size.height);
  @override
  bool shouldReclip(_TickClipper old) => old.t != t;
}

// ------------------------------------------------------------- settings

/// Grey label + chevron row, optionally with a leading icon or trailing badge.
class KSettingsRow extends StatelessWidget {
  const KSettingsRow(
    this.label, {
    super.key,
    this.leading,
    this.badge,
    this.chevron = true,
    this.color,
  });
  final String label;
  final List<List<dynamic>>? leading;
  final Widget? badge;
  final bool chevron;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final c = color ?? KColors.textSubtle;
    return SizedBox(
      height: 42,
      child: Row(
        children: [
          if (leading != null) ...[
            HugeIcon(icon: leading!, size: 19, color: c, strokeWidth: 1.5),
            const SizedBox(width: 8),
          ],
          // Label and badge take all the room they need, up to the chevron.
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: KText.settingsRow.dm(color: c),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (badge != null) ...[const SizedBox(width: 12), badge!],
              ],
            ),
          ),
          if (chevron)
            const HugeIcon(
              icon: HugeIcons.strokeRoundedChevronRight,
              size: 20,
              color: Color(0xFF2E2D2B),
              strokeWidth: 1.5,
            ),
        ],
      ),
    );
  }
}

enum KCityState { available, downloading, saved }

/// Outlined city chip with a trailing action.
///
/// available: Download01. downloading: the mango border becomes a progress
/// ring from 12 o'clock over a pale track, filling with [progress]. saved:
/// the icon turns into a danger-red Trash (tap to delete). [icon] overrides
/// the state icon (e.g. a chevron for a plain link chip).
class KCityChip extends StatelessWidget {
  const KCityChip(
    this.city, {
    super.key,
    this.state = KCityState.available,
    this.progress = 0,
    this.onTap,
    this.icon,
    this.iconColor,
  });
  final String city;
  final KCityState state;
  final double progress;
  final VoidCallback? onTap;
  final List<List<dynamic>>? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final saved = state == KCityState.saved;
    final glyph =
        icon ??
        (saved
            ? HugeIcons.strokeRoundedTrash
            : HugeIcons.strokeRoundedDownload01);
    final color =
        iconColor ??
        switch (state) {
          KCityState.available => KColors.charcoal,
          KCityState.downloading => KColors.mango,
          KCityState.saved => KColors.danger,
        };
    return Semantics(
      label: switch (state) {
        KCityState.available => 'Download $city',
        KCityState.downloading =>
          'Downloading $city, ${(progress * 100).round()} percent',
        KCityState.saved => 'Delete $city download',
      },
      child: KChipFrame(
        selected: true,
        onTap: state == KCityState.downloading ? null : onTap,
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        progress: state == KCityState.downloading ? progress : null,
        builder: (context, t) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                city,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: KText.chip.dm(
                  fontStyle: FontStyle.normal,
                  fontWeight: FontWeight.w400,
                  fontSize: 17,
                  color: KColors.charcoal,
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: KMotion.springDuration,
              switchInCurve: KMotion.springCurve,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: ScaleTransition(scale: a, child: child),
              ),
              child: HugeIcon(
                key: ValueKey((glyph, color)),
                icon: glyph,
                size: 18,
                color: color,
                strokeWidth: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------- floating menu

/// The docked menu button: a 72.25 × 50.2 pt stadium with a 2.2 pt
/// light-mango rim, pushed 1.25 pt past the right screen edge so 71 pt shows.
/// Four rounded squares: outlined when closed, solid when open.
class KMenuButton extends StatelessWidget {
  const KMenuButton({super.key, this.open = false, this.onTap});
  final bool open;
  final VoidCallback? onTap;

  /// Width left on screen.
  static const visibleWidth = 71.0;
  static const width = 72.25;
  static const height = 50.2;

  /// Grid centre, in from the right screen edge.
  static const iconInset = visibleWidth - width / 2;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: SizedBox(
      width: visibleWidth,
      height: height,
      child: OverflowBox(
        alignment: Alignment.centerLeft,
        minWidth: width,
        maxWidth: width,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: KColors.surface,
            borderRadius: BorderRadius.circular(height / 2),
            border: Border.all(color: KColors.menuRim, width: 2.2),
            boxShadow: kMenuShadow,
          ),
          child: AnimatedSwitcher(
            duration: KMotion.springDuration,
            switchInCurve: KMotion.springCurve,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: ScaleTransition(
                scale: Tween(begin: .7, end: 1.0).animate(a),
                child: child,
              ),
            ),
            child: SizedBox(
              key: ValueKey(open),
              width: 23.25,
              height: 23.25,
              child: CustomPaint(painter: _GridPainter(solid: open)),
            ),
          ),
        ),
      ),
    ),
  );
}

/// 2 × 2 squares of 10.5 pt, 2.25 pt apart, 3.2 pt corners.
class _GridPainter extends CustomPainter {
  const _GridPainter({required this.solid});
  final bool solid;
  @override
  void paint(Canvas c, Size s) {
    const stroke = 1.6;
    final p = Paint()
      ..color = KColors.charcoal
      ..style = solid ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = stroke;
    final w = s.width * 10.5 / 23.25, g = s.width - 2 * w;
    for (final o in [
      Offset.zero,
      Offset(w + g, 0),
      Offset(0, w + g),
      Offset(w + g, w + g),
    ]) {
      var r = o & Size(w, w);
      if (!solid) r = r.deflate(stroke / 2);
      c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3.2)), p);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.solid != solid;
}

/// One entry of the open menu: 48 pt row, 24 pt icon, 16.8 pt medium label,
/// a hairline mango underline. The current page gets the surface fill.
class KMenuItem extends StatelessWidget {
  const KMenuItem({
    super.key,
    required this.icon,
    required this.label,
    this.highlighted = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 13),
    this.gap = 8.5,
  });
  final List<List<dynamic>> icon;
  final String label;
  final bool highlighted;

  /// Inset around the icon and label (horizontal only; the row is 48 tall).
  final EdgeInsets padding;

  /// Space between the icon and the label.
  final double gap;

  static const height = 48.0;
  static const iconSize = 25.0;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    padding: padding,
    decoration: BoxDecoration(
      color: highlighted ? KColors.surface : null,
      border: const Border(bottom: BorderSide(color: KColors.mango, width: .4)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HugeIcon(
          icon: icon,
          size: iconSize,
          color: KColors.charcoal,
          strokeWidth: 1.5,
        ),
        SizedBox(width: gap),
        // DM Sans sits a touch low in a 48 pt row; lift it onto the icon's centre.
        Transform.translate(
          offset: const Offset(0, -.4),
          child: Text(label, style: KText.menuItem),
        ),
      ],
    ),
  );
}

// ------------------------------------------------------------- onboarding sheet

/// Onboarding bottom sheet. With [terms], the action stays disabled until the
/// terms checkbox is ticked.
class KOnboardingSheet extends StatelessWidget {
  const KOnboardingSheet({
    super.key,
    required this.title,
    required this.body,
    required this.action,
    this.onAction,
    this.index = 0,
    this.count = 2,
    this.footnote,
    this.terms = false,
    this.termsAccepted = false,
    this.onTermsChanged,
  });
  final String title;
  final String body;
  final String action;
  final VoidCallback? onAction;
  final int index;
  final int count;
  final String? footnote;
  final bool terms;
  final bool termsAccepted;
  final ValueChanged<bool>? onTermsChanged;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
    decoration: const BoxDecoration(
      color: KColors.background,
      borderRadius: BorderRadius.vertical(top: Radius.circular(KRadius.sheet)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        KPageDots(count: count, index: index),
        const SizedBox(height: 14),
        // Page to page, the words cross-fade and the sheet eases to its new
        // height (the terms row only lives on the last page).
        AnimatedSize(
          duration: KMotion.springDuration,
          curve: KMotion.settleCurve,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: KMotion.settleCurve,
            switchOutCurve: Curves.easeIn,
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topCenter,
              children: [...previous, ?current],
            ),
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, .04),
                  end: Offset.zero,
                ).animate(a),
                child: child,
              ),
            ),
            child: Column(
              key: ValueKey(title),
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: KText.onboardingTitle,
                ),
                const SizedBox(height: 12),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: KText.onboardingBody,
                ),
                if (footnote != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    footnote!,
                    textAlign: TextAlign.center,
                    style: KText.footnote,
                  ),
                ],
                if (terms) ...[
                  const SizedBox(height: 14),
                  KTermsCheckbox(
                    checked: termsAccepted,
                    onChanged: onTermsChanged,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        KButton(
          label: action,
          shape: KButtonShape.pill,
          onPressed: terms && !termsAccepted ? null : onAction,
        ),
      ],
    ),
  );
}

/// "© Kombien • November 2026" at the bottom of Settings.
class KCopyrightFooter extends StatelessWidget {
  const KCopyrightFooter({super.key, this.date = 'November 2026'});
  final String date;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const HugeIcon(
        icon: HugeIcons.strokeRoundedCopyright,
        size: 16,
        color: KColors.textSubtle,
        strokeWidth: 1.5,
      ),
      const SizedBox(width: 8),
      Text(
        'Kombien  •  $date',
        style: KText.label.dm(color: KColors.textSubtle),
      ),
    ],
  );
}
