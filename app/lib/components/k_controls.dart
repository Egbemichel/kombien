import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import '../app/app_state.dart';
import 'k_animated.dart';

import '../design/k_motion.dart';
import '../design/k_text.dart';
import '../design/k_tokens.dart';

// ---------------------------------------------------------------- buttons

enum KButtonShape { rounded, pill }

/// Full-width mango action ("Continue", "Add report", "Get the dev a coffee").
/// Disabled renders dust grey, as on the empty report form; the colour change
/// animates. [loading] swaps the label for [KLoadingDots] and ignores taps.
class KButton extends StatelessWidget {
  const KButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.shape = KButtonShape.rounded,
    this.height = 44,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final List<List<dynamic>>? icon;
  final KButtonShape shape;
  final double height;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final radius = shape == KButtonShape.pill ? height / 2 : KRadius.button;
    final fg = enabled ? KColors.charcoal : KColors.onDust;
    return Semantics(
      button: true,
      enabled: enabled && !loading,
      label: loading ? '$label, in progress' : null,
      child: KPressable(
        pressedScale: .97,
        onTap: enabled && !loading ? onPressed : null,
        child: AnimatedContainer(
          duration: KMotion.springDuration,
          curve: KMotion.settleCurve,
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: enabled ? KColors.mango : KColors.dustGrey,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: KMotion.springCurve,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: ScaleTransition(
                scale: Tween(begin: .86, end: 1.0).animate(a),
                child: child,
              ),
            ),
            child: loading
                ? KLoadingDots(key: const ValueKey('loading'), color: fg)
                : Row(
                    key: const ValueKey('label'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        HugeIcon(
                          icon: icon!,
                          size: 22,
                          color: fg,
                          strokeWidth: 1.5,
                        ),
                        const SizedBox(width: 12),
                      ],
                      Flexible(
                        child: AnimatedDefaultTextStyle(
                          duration: KMotion.springDuration,
                          curve: KMotion.settleCurve,
                          style: KText.button.dm(
                            color: fg,
                            fontSize: icon != null ? 17 : 15,
                          ),
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Underlined bold italic mango link ("Report it here"). A tap redraws the
/// underline left to right on the spring.
class KLink extends StatefulWidget {
  const KLink(this.label, {super.key, this.onTap});
  final String label;
  final VoidCallback? onTap;
  @override
  State<KLink> createState() => _KLinkState();
}

class _KLinkState extends State<KLink> with SingleTickerProviderStateMixin {
  late final _draw = AnimationController.unbounded(vsync: this, value: 1);

  @override
  void dispose() {
    _draw.dispose();
    super.dispose();
  }

  void _tap() {
    _draw.value = 0;
    KMotion.springTo(_draw, 1);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: _tap,
    child: Stack(
      children: [
        Text(
          widget.label,
          style: KText.link.dm(decoration: TextDecoration.none),
        ),
        // The same text, invisible, carrying only the underline, revealed
        // from the left. Keeps the underline exactly where the font puts it.
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _draw,
            builder: (context, child) => ClipRect(
              clipper: _RevealClipper(_draw.value.clamp(0.0, 1.0)),
              child: child,
            ),
            child: Text(
              widget.label,
              style: KText.link.dm(
                color: Colors.transparent,
                decorationColor: KColors.mango,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _RevealClipper extends CustomClipper<Rect> {
  const _RevealClipper(this.t);
  final double t;
  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(-4, -4, size.width * t + (t >= 1 ? 4 : 0), size.height + 6);
  @override
  bool shouldReclip(_RevealClipper old) => old.t != t;
}

/// Quiet italic dismiss ("Skip for now", "Skip").
class KSkip extends StatelessWidget {
  const KSkip(this.label, {super.key, this.onTap, this.color});
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Text(label, style: KText.skip.dm(color: color)),
  );
}

// ---------------------------------------------------------------- inputs

/// "Where are you leaving from?" + the starting-point input.
///
/// With location permission it opens on the blue "My location" token. The
/// token is one unit: a backspace (or any keystroke) anywhere in it removes
/// the whole thing at once, and it fades and slides away; a typed character
/// replaces it. What the rider then types is a landmark search, in charcoal.
/// Tapping Gps01, or leaving the field empty, brings "My location" back.
///
/// [locationDenied]: no permission. The field is a landmark search from the
/// start, hinting "Can't see where you are. Search a landmark instead", with
/// a danger-red GpsOff01 that asks for location again when tapped.
class KLocationField extends StatefulWidget {
  const KLocationField({
    super.key,
    this.label,
    this.myLocation,
    this.hint,
    this.hasLocation = true,
    this.locationDenied = false,
    this.onRequestLocation,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.errorText,
    this.shakeSignal = 0,
  });

  /// Defaults to the app language's "Where are you leaving from?".
  final String? label;

  /// Location permission refused or unavailable.
  final bool locationDenied;
  final VoidCallback? onRequestLocation;

  /// The token shown when the phone's location is available.
  final String? myLocation;
  final String? hint;

  /// Location permission granted: open on, and fall back to, [myLocation].
  final bool hasLocation;
  final TextEditingController? controller;
  final FocusNode? focusNode;

  /// The landmark query as the rider types; '' while on [myLocation].
  final ValueChanged<String>? onChanged;

  /// Shown under the field in danger red, with a danger border, until the
  /// rider types. Null: no error.
  final String? errorText;

  /// Bump to wiggle the field (KMotion.shake), e.g. on each failed attempt.
  final int shakeSignal;

  @override
  State<KLocationField> createState() => _KLocationFieldState();
}

class _KLocationFieldState extends State<KLocationField>
    with TickerProviderStateMixin {
  late final TextEditingController _text =
      widget.controller ??
      TextEditingController(text: _tokenAllowed ? _token : '');

  /// "My location" in the app language.
  String get _token => widget.myLocation ?? context.l10n.myLocation;
  String? _lastToken;
  late final FocusNode _focus = widget.focusNode ?? FocusNode();

  /// 1 → 0 as a removed "My location" fades out.
  late final _ghost = AnimationController.unbounded(vsync: this, value: 0);

  /// Sideways offset of the error wiggle.
  late final _shake = AnimationController.unbounded(vsync: this, value: 0);

  @override
  void didUpdateWidget(KLocationField old) {
    super.didUpdateWidget(old);
    if (widget.shakeSignal != old.shakeSignal) KMotion.shakeNow(_shake);
  }

  bool get _tokenAllowed => widget.hasLocation && !widget.locationDenied;
  bool get _onToken => _tokenAllowed && _text.text == _token;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final token = _token, last = _lastToken;
    _lastToken = token;
    // Edit the text after this frame: a caller's controller may still feed
    // a field that is being replaced (e.g. when location access changes),
    // and it must not hear about edits mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (last == null) {
        // First build: a caller's empty controller opens on the token too,
        // and a stale token goes when location is not available.
        if (_tokenAllowed && _text.text.isEmpty) {
          _text.text = token;
        } else if (!_tokenAllowed && _text.text == token) {
          _text.clear();
        }
      } else if (last != token && _text.text == last) {
        // The language changed while the token showed: rename it in place.
        _text.value = TextEditingValue(
          text: token,
          selection: TextSelection.collapsed(offset: token.length),
        );
      }
      setState(() {}); // restyle: the token is blue, typed text charcoal
    });
  }

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    if (widget.controller == null) _text.dispose();
    if (widget.focusNode == null) _focus.dispose();
    _ghost.dispose();
    _shake.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (_focus.hasFocus && _onToken) {
      // Park the caret after the token so a single backspace takes it.
      _text.selection = TextSelection.collapsed(offset: _text.text.length);
    }
    if (!_focus.hasFocus && _tokenAllowed && _text.text.trim().isEmpty) {
      _restore();
    }
  }

  void _restore() {
    if (!_tokenAllowed || _onToken) return;
    _text.value = TextEditingValue(
      text: _token,
      selection: TextSelection.collapsed(offset: _token.length),
    );
    widget.onChanged?.call('');
    setState(() {});
  }

  /// Treats "My location" as one atom: any edit inside it removes it whole
  /// and keeps only what was typed.
  TextEditingValue _atomic(TextEditingValue old, TextEditingValue now) {
    final token = _token;
    if (!_tokenAllowed || old.text != token || now.text == token) {
      return now;
    }
    var start = 0;
    while (start < old.text.length &&
        start < now.text.length &&
        old.text[start] == now.text[start]) {
      start++;
    }
    var endOld = old.text.length, endNew = now.text.length;
    while (endOld > start &&
        endNew > start &&
        old.text[endOld - 1] == now.text[endNew - 1]) {
      endOld--;
      endNew--;
    }
    final typed = now.text.substring(start, endNew);
    _ghost.value = 1;
    KMotion.springTo(_ghost, 0, spec: KMotion.settle);
    return TextEditingValue(
      text: typed,
      selection: TextSelection.collapsed(offset: typed.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onToken = _onToken;
    final typed = KText.location.dm(color: KColors.charcoal);
    final error = widget.errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Text(
            widget.label ?? context.l10n.whereFrom,
            style: KText.label,
          ),
        ),
        const SizedBox(height: 9),
        AnimatedBuilder(
          animation: _shake,
          builder: (context, child) => Transform.translate(
            offset: Offset(_shake.value, 0),
            child: child,
          ),
          child: AnimatedContainer(
            duration: KMotion.springDuration,
            curve: KMotion.settleCurve,
            height: 36,
            padding: const EdgeInsets.only(left: 18, right: 11),
            decoration: BoxDecoration(
              color: KColors.field,
              borderRadius: BorderRadius.circular(KRadius.field),
              // Always 1.2 wide so the error border never shifts the content.
              border: Border.all(
                color: error
                    ? KColors.danger
                    : KColors.danger.withValues(alpha: 0),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      TextField(
                        controller: _text,
                        focusNode: _focus,
                        inputFormatters: [
                          TextInputFormatter.withFunction(_atomic),
                        ],
                        onChanged: (v) {
                          setState(() {});
                          widget.onChanged?.call(_onToken ? '' : v);
                        },
                        onTapOutside: (_) => _focus.unfocus(),
                        style: onToken ? KText.location : typed,
                        cursorColor: KColors.charcoal,
                        cursorWidth: 1.5,
                        cursorHeight: 16,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration.collapsed(
                          hintText: widget.locationDenied
                              ? context.l10n.locationDenied
                              : widget.hint ?? context.l10n.searchLandmark,
                          hintStyle: widget.locationDenied
                              ? KText.label.dm(color: KColors.textSubtle)
                              : typed.dm(color: KColors.placeholder),
                        ),
                      ),
                      // The removed token, fading and drifting left as one piece.
                      IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _ghost,
                          builder: (context, _) {
                            final g = _ghost.value.clamp(0.0, 1.0);
                            if (g == 0) return const SizedBox.shrink();
                            return Transform.translate(
                              offset: Offset(-10 * (1 - g), 0),
                              child: Opacity(
                                opacity: g,
                                child: Text(_token, style: KText.location),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                KPressable(
                  pressedScale: .85,
                  onTap: widget.locationDenied
                      ? widget.onRequestLocation
                      : widget.hasLocation
                      ? () {
                          _restore();
                          _focus.unfocus();
                        }
                      : null,
                  child: Semantics(
                    button: widget.locationDenied || widget.hasLocation,
                    label: widget.locationDenied
                        ? context.l10n.turnOnLocation
                        : context.l10n.useMyLocation,
                    child: HugeIcon(
                      icon: widget.locationDenied
                          ? HugeIcons.strokeRoundedGpsOff01
                          : HugeIcons.strokeRoundedGps01,
                      size: 21,
                      color: widget.locationDenied
                          ? KColors.danger
                          : onToken
                          ? KColors.locationBlue
                          : widget.hasLocation
                          ? KColors.charcoal
                          : KColors.textFaint,
                      strokeWidth: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // The message eases open under the field and away once it is fixed.
        AnimatedSize(
          duration: KMotion.springDuration,
          curve: KMotion.settleCurve,
          alignment: Alignment.topLeft,
          child: !error
              ? const SizedBox(width: double.infinity)
              : Semantics(
                  liveRegion: true,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6, left: 2),
                    child: Row(
                      children: [
                        const HugeIcon(
                          icon: HugeIcons.strokeRoundedAlert02,
                          size: 14,
                          color: KColors.danger,
                          strokeWidth: 1.5,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.errorText!,
                            style: KText.label.dm(color: KColors.danger),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

/// FCFA amounts as riders write them: digits grouped in threes with a space,
/// live as they type (1500 → 1 500, 10000 → 10 000). Anything but digits is
/// dropped, leading zeros go, and the caret stays after the same digit.
/// The space is a no-break space so an amount never splits across lines.
class KMoneyFormatter extends TextInputFormatter {
  const KMoneyFormatter({this.maxDigits = 7});

  /// 7 digits: up to 9 999 999 FCFA.
  final int maxDigits;

  static const separator = '\u00A0';

  /// The plain number in a formatted amount ('1 500' → 1500).
  static int? parse(String text) =>
      int.tryParse(text.replaceAll(RegExp(r'\D'), ''));

  /// Groups [digits] in threes from the right.
  static String format(String digits) {
    final b = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) b.write(separator);
      b.write(digits[i]);
    }
    return b.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;
    // Backspace right after a separator removes the digit before it too.
    if (oldValue.text.length - text.length == 1 &&
        newValue.selection.isCollapsed &&
        oldValue.selection.isCollapsed &&
        oldValue.selection.baseOffset > 0 &&
        oldValue.text[oldValue.selection.baseOffset - 1] == separator) {
      final at = newValue.selection.baseOffset - 1;
      if (at >= 0) text = text.substring(0, at) + text.substring(at + 1);
    }
    final caret = newValue.selection.baseOffset.clamp(0, newValue.text.length);
    final before = newValue.text
        .substring(0, caret)
        .replaceAll(RegExp(r'\D'), '')
        .length;
    var digits = text.replaceAll(RegExp(r'\D'), '');
    final trimmed = digits.replaceFirst(RegExp(r'^0+'), '');
    final dropped = digits.length - trimmed.length;
    digits = trimmed;
    if (digits.length > maxDigits) return oldValue;
    final out = format(digits);
    // Put the caret after the same count of digits it followed.
    var want = (before - dropped).clamp(0, digits.length), offset = 0;
    while (want > 0 && offset < out.length) {
      if (out[offset] != separator) want--;
      offset++;
    }
    return TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}

/// Title + large italic entry with a mic button ("Tu go où?", "To",
/// "Paid something else?"). The placeholder is grey; typed text is charcoal.
class KEntryField extends StatelessWidget {
  const KEntryField({
    super.key,
    this.title,
    this.placeholder,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.keyboardType,
    this.inputFormatters,
  });

  /// Defaults to "Tu go où?".
  final String? title;

  /// Defaults to the app language's "Start typing...".
  final String? placeholder;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title ?? context.l10n.whereTo, style: KText.title),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: onChanged,
                keyboardType: keyboardType,
                inputFormatters: inputFormatters,
                style: KText.entry,
                cursorColor: KColors.charcoal,
                cursorWidth: 1.5,
                decoration: InputDecoration.collapsed(
                  hintText: placeholder ?? context.l10n.startTyping,
                  hintStyle: KText.entryPlaceholder,
                ),
              ),
            ),
            const HugeIcon(
              icon: HugeIcons.strokeRoundedMic01,
              size: 22,
              color: KColors.charcoal,
              strokeWidth: 1.5,
            ),
            const SizedBox(width: 10),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- chips

/// Saved destination ("Home", "School", "Work"): chip background, mango
/// outline, italic mango label. A tap redraws the outline (it is an action,
/// not a selection).
class KSavedChip extends StatelessWidget {
  const KSavedChip(this.label, {super.key, this.onTap});
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => KChipFrame(
    selected: true,
    retraceOnTap: true,
    onTap: onTap ?? () {},
    height: 38,
    radius: KRadius.chip,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    builder: (context, t) =>
        Center(widthFactor: 1, child: Text(label, style: KText.chip)),
  );
}

/// Selectable option on the report form (price, time of day, weather).
/// Selected: outlined mango. Unselected: filled dust grey.
class KOptionChip extends StatelessWidget {
  const KOptionChip(
    this.label, {
    super.key,
    this.selected = false,
    this.italic = true,
    this.onTap,
    this.leading,
    this.trailing,
    this.height = 36,
    this.fontSize = 14,
    this.selectedText = KColors.mango,
  });
  final String label;
  final bool selected;
  final bool italic;
  final VoidCallback? onTap;
  final Widget? leading;
  final Widget? trailing;
  final double height;
  final double fontSize;
  final Color selectedText;

  @override
  Widget build(BuildContext context) => KChipFrame(
    selected: selected,
    onTap: onTap,
    height: height,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    builder: (context, t) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 6)],
        Flexible(
          child: Text(
            label,
            style: KText.chip.dm(
              fontStyle: italic ? FontStyle.italic : FontStyle.normal,
              fontWeight: italic ? FontWeight.w500 : FontWeight.w400,
              fontSize: fontSize,
              color: Color.lerp(KColors.onDust, selectedText, t),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    ),
  );
}

/// Square icon option (vehicle type).
class KIconChip extends StatelessWidget {
  const KIconChip({
    super.key,
    required this.icon,
    this.selected = false,
    this.onTap,
  });
  final List<List<dynamic>> icon;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => KChipFrame(
    selected: selected,
    onTap: onTap,
    width: 44,
    height: 44,
    alignment: Alignment.center,
    builder: (context, t) => HugeIcon(
      icon: icon,
      size: 24,
      color: Color.lerp(KColors.onDust, KColors.mango, t),
      strokeWidth: 1.5,
    ),
  );
}

/// Two-line segmented option in Settings ("Wi-Fi and mobile data").
class KSegmentOption extends StatelessWidget {
  const KSegmentOption(
    this.label, {
    super.key,
    this.selected = false,
    this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => KChipFrame(
    selected: selected,
    onTap: onTap,
    height: 46,
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    builder: (context, t) => Text(
      label,
      textAlign: TextAlign.center,
      style: KText.chip.dm(
        fontSize: 13 - 2 * t,
        fontWeight: FontWeight.w400,
        height: 1.1,
        color: Color.lerp(KColors.onDust, KColors.mango, t),
      ),
    ),
  );
}

/// Count bubble next to "Reports from this phone".
class KCountBadge extends StatelessWidget {
  const KCountBadge(this.count, {super.key});
  final int count;
  @override
  Widget build(BuildContext context) => Container(
    width: 22,
    height: 22,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: KColors.chipBackground,
      border: Border.all(color: KColors.mango, width: 1.2),
    ),
    child: Text(
      '$count',
      style: KText.label.dm(
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
        color: KColors.charcoal,
      ),
    ),
  );
}
