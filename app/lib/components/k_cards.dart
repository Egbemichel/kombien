import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hugeicons/hugeicons.dart';

import '../app/app_state.dart';
import '../design/k_motion.dart';
import '../design/k_text.dart';
import '../design/k_tokens.dart';
import 'k_animated.dart';
import 'k_controls.dart';

/// The shared warm surface: pale mango fill with a hairline mango border.
class KSurfaceCard extends StatelessWidget {
  const KSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.radius = KRadius.card,
    this.shadow = false,
  });
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final bool shadow;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: KColors.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: KColors.surfaceBorder, width: 1.2),
      boxShadow: shadow ? kFloatShadow : null,
    ),
    child: child,
  );
}

/// Destination suggestions under the search input.
class KSuggestionsCard extends StatelessWidget {
  const KSuggestionsCard({
    super.key,
    required this.items,
    this.onSelected,
    this.onSeeAll,
    this.showSeeAll = true,
  });

  /// (place, distance) pairs.
  final List<(String, String)> items;
  final ValueChanged<int>? onSelected;

  /// "See all suggestions": show more matches.
  final VoidCallback? onSeeAll;

  /// Off once everything is already listed.
  final bool showSeeAll;
  @override
  Widget build(BuildContext context) => KSurfaceCard(
    radius: 18,
    padding: const EdgeInsets.fromLTRB(22, 4, 22, 12),
    child: Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          // A raw pointer listener, not a tap gesture: while the search field
          // is focused, the first tap on web goes to dismissing focus and a
          // tap recognizer never fires, so the pick would need two taps.
          Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (_) => onSelected?.call(i),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: Text(items[i].$1, style: KText.rowName)),
                  const SizedBox(width: 12),
                  Text(items[i].$2, style: KText.rowDistance),
                ],
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: KColors.divider),
        ],
        if (showSeeAll)
          Listener(
            // Pointer-down, like the rows: one tap even while a field has focus.
            behavior: HitTestBehavior.opaque,
            onPointerDown: onSeeAll == null ? null : (_) => onSeeAll!(),
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.seeAllSuggestions,
                      style: KText.chip.dm(
                        color: KColors.mango.withValues(alpha: .75),
                      ),
                    ),
                  ),
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowDownRight01,
                    size: 20,
                    color: KColors.mango.withValues(alpha: .85),
                    strokeWidth: 1.5,
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

/// The fare range result.
class KFareCard extends StatelessWidget {
  const KFareCard({super.key, required this.range, this.label});
  final String range;

  /// Defaults to "Based on past rider reports"; demo data says so instead.
  final String? label;
  @override
  Widget build(BuildContext context) => KSurfaceCard(
    radius: KRadius.fareCard,
    padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label ?? context.l10n.fareBasedOn,
          style: KText.mangoLabel.dm(
            color: KColors.mango.withValues(alpha: .8),
          ),
        ),
        const SizedBox(height: 10),
        Text(range, style: KText.fare),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedInformationCircle,
                size: 14,
                color: KColors.textFaint,
                strokeWidth: 1.5,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(context.l10n.fareDisclaimer, style: KText.caption),
            ),
          ],
        ),
      ],
    ),
  );
}

/// Route summary at the top of the report form.
class KRouteCard extends StatelessWidget {
  const KRouteCard({super.key, required this.from, required this.to});
  final String from;
  final String to;
  @override
  Widget build(BuildContext context) {
    Widget col(String label, String value) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: KText.label.dm(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: KColors.charcoal,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: KText.routeValue,
          ),
        ],
      ),
    );
    return KSurfaceCard(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.reportingFor,
            style: KText.mangoLabel.dm(
              color: KColors.mango.withValues(alpha: .8),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              col(context.l10n.routeFrom, from),
              const SizedBox(width: 16),
              col(context.l10n.routeTo, to),
            ],
          ),
        ],
      ),
    );
  }
}

/// Confirmation toast ("Feedback recorded!", "Report added!").
class KToast extends StatelessWidget {
  const KToast({
    super.key,
    required this.label,
    required this.title,
    required this.body,
    this.onClose,
    this.action,
    this.onAction,
  });
  final String label;
  final String title;
  final String body;
  final VoidCallback? onClose;

  /// An optional button under the body ("Restart", "Undo").
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 237,
    child: KSurfaceCard(
      radius: KRadius.toast,
      shadow: true,
      padding: const EdgeInsets.fromLTRB(18, 8, 10, 12),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: KText.mangoLabel.dm(
                  fontSize: 12.5,
                  color: KColors.mango.withValues(alpha: .8),
                ),
              ),
              const SizedBox(height: 2),
              Text(title, style: KText.toastTitle),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(body, style: KText.captionDark),
              ),
              if (action case final a?) ...[
                const SizedBox(height: 8),
                Semantics(
                  button: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onAction,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        a,
                        style: KText.mangoLabel.dm(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: KColors.mango,
                          decoration: TextDecoration.underline,
                          decorationColor: KColors.mango,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          Positioned(
            right: 0,
            top: 2,
            child: GestureDetector(
              onTap: onClose,
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedCancel01,
                size: 20,
                color: Color(0xFF2E2D2B),
                strokeWidth: 1.5,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// "Was this information helpful?" with thumbs.
class KFeedbackRow extends StatelessWidget {
  const KFeedbackRow({super.key, this.onUp, this.onDown});
  final VoidCallback? onUp;
  final VoidCallback? onDown;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Flexible(
        child: Text(
          context.l10n.feedbackQuestion,
          style: KText.bodySmall.dm(color: const Color(0xFF3B3935)),
        ),
      ),
      const SizedBox(width: 30),
      KPressable(
        pressedScale: .82,
        onTap: onUp ?? () {},
        child: const HugeIcon(
          icon: HugeIcons.strokeRoundedThumbsUp,
          size: 24,
          color: KColors.success,
          strokeWidth: 1.5,
        ),
      ),
      const SizedBox(width: 34),
      KPressable(
        pressedScale: .82,
        onTap: onDown ?? () {},
        child: const HugeIcon(
          icon: HugeIcons.strokeRoundedThumbsDown,
          size: 24,
          color: KColors.danger,
          strokeWidth: 1.5,
        ),
      ),
    ],
  );
}

// ------------------------------------------------------------ sticker cards

/// A rounded, tilted card holding one object illustration, with a white rim
/// and soft shadow (the stacks on the location and empty-state cards).
class KStickerCard extends StatelessWidget {
  const KStickerCard({
    super.key,
    required this.asset,
    required this.color,
    this.angle = 0,
    this.width = 104,
    this.height = 124,
    this.objectScale = .78,
  });
  final String asset;
  final Color color;
  final double angle;
  final double width;
  final double height;
  final double objectScale;
  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: angle,
    child: Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(KRadius.sticker),
        border: Border.all(
          color: Colors.white.withValues(alpha: .9),
          width: 2.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: FractionallySizedBox(
        widthFactor: objectScale,
        child: Image.asset(
          asset,
          fit: BoxFit.contain,
          // Decode at the drawn size, not the file's 480 px.
          cacheWidth:
              (width * objectScale * MediaQuery.devicePixelRatioOf(context))
                  .round(),
        ),
      ),
    ),
  );
}

/// Three overlapping sticker cards: left (grey), middle (mango, raised), right (dust).
class KStickerStack extends StatelessWidget {
  const KStickerStack({
    super.key,
    required this.left,
    required this.middle,
    required this.right,
  });
  final String left;
  final String middle;
  final String right;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 260,
    height: 190,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 22,
          top: 34,
          child: KStickerCard(
            asset: left,
            color: KColors.stickerGrey,
            angle: -0.10,
          ),
        ),
        Positioned(
          left: 86,
          top: 0,
          child: KStickerCard(
            asset: middle,
            color: KColors.stickerMango,
            angle: 0.02,
            width: 112,
            height: 132,
          ),
        ),
        Positioned(
          left: 150,
          top: 46,
          child: KStickerCard(
            asset: right,
            color: KColors.stickerDust,
            angle: 0.10,
          ),
        ),
      ],
    ),
  );
}

/// Card with a sticker stack breaking out of its top edge, headline, copy, action.
class KPromptCard extends StatelessWidget {
  const KPromptCard({
    super.key,
    required this.stack,
    required this.title,
    this.body,
    this.action,
    this.onAction,
    this.actionLoading = false,
    this.skip,
    this.onSkip,
    this.compact = false,
  });
  final Widget stack;
  final String title;
  final String? body;

  /// Button label; null for a card that only informs (no match found).
  final String? action;
  final VoidCallback? onAction;
  final bool actionLoading;
  final String? skip;
  final VoidCallback? onSkip;

  /// Edge-case cards (offline, no match): 22 pt title, no body.
  final bool compact;
  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    alignment: Alignment.topCenter,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 86),
        child: KSurfaceCard(
          padding: const EdgeInsets.fromLTRB(22, 96, 22, 18),
          child: Column(
            // Full width even without a button (the no-match card).
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FractionallySizedBox(
                widthFactor: .7,
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: compact
                      ? KText.title.dm(height: 1.15, fontSize: 23)
                      : KText.headline,
                ),
              ),
              if (body != null) ...[
                const SizedBox(height: 8),
                Text(body!, style: KText.body),
              ],
              if (action != null) ...[
                const SizedBox(height: 16),
                KButton(
                  label: action!,
                  loading: actionLoading,
                  onPressed: onAction ?? () {},
                ),
              ] else
                const SizedBox(height: 8),
              if (skip != null) ...[
                const SizedBox(height: 10),
                Center(child: KSkip(skip!, onTap: onSkip)),
              ],
            ],
          ),
        ),
      ),
      Positioned(top: 0, child: stack),
    ],
  );
}

// ------------------------------------------------------------ developer card

class KDevCard extends StatelessWidget {
  const KDevCard({
    super.key,
    this.onCoffee,
    this.onWebsite,
    this.onGithub,
    this.onLinkedin,
    this.onInstagram,
    this.onX,
  });

  /// Each link; a null one is drawn but does nothing.
  final VoidCallback? onCoffee,
      onWebsite,
      onGithub,
      onLinkedin,
      onInstagram,
      onX;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    Widget social(List<List<dynamic>> icon, VoidCallback? onTap) => KPressable(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: KColors.chipBackground,
          borderRadius: BorderRadius.circular(KRadius.option),
          border: Border.all(
            color: KColors.mango.withValues(alpha: .6),
            width: 1.2,
          ),
        ),
        child: HugeIcon(
          icon: icon,
          size: 24,
          color: KColors.charcoal,
          strokeWidth: 1.5,
        ),
      ),
    );
    return KSurfaceCard(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.devAbout,
            style: KText.sectionMango.dm(
              color: KColors.mango.withValues(alpha: .85),
            ),
          ),
          const SizedBox(height: 18),
          SvgPicture.asset(
            'assets/brand/avatar.svg',
            width: 64,
            height: 64,
            semanticsLabel: 'Egbe Michel',
          ),
          const SizedBox(height: 14),
          Text(
            t.devHello,
            style: KText.bodySmall.dm(
              fontWeight: FontWeight.w700,
              color: KColors.charcoal,
            ),
          ),
          const SizedBox(height: 4),
          Text(t.devStory, style: KText.bodySmall),
          const SizedBox(height: 10),
          Text(t.devCoffeeAsk, style: KText.bodySmall),
          const SizedBox(height: 18),
          KButton(
            label: t.devCoffee,
            icon: HugeIcons.strokeRoundedCoffee01,
            onPressed: onCoffee ?? () {},
          ),
          const SizedBox(height: 14),
          Text.rich(
            TextSpan(
              style: KText.captionDark.dm(fontSize: 12),
              children: [
                TextSpan(text: t.devThanksLead),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/illustrations/joelfah.webp',
                        width: 14,
                        height: 14,
                        cacheWidth:
                            (14 * MediaQuery.devicePixelRatioOf(context))
                                .round(),
                      ),
                    ),
                  ),
                ),
                TextSpan(
                  text: 'Joel Fah',
                  style: KText.captionDark.dm(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(text: t.devThanksTail),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            t.letsConnect,
            style: KText.title.dm(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onWebsite,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedGlobe02,
                  size: 18,
                  color: KColors.charcoal,
                  strokeWidth: 1.5,
                ),
                const SizedBox(width: 8),
                Text(
                  'egbemichel.tech',
                  style: KText.bodySmall.dm(
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.underline,
                    color: KColors.textBody,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(t.devTagline, style: KText.caption),
          const SizedBox(height: 14),
          Row(
            children: [
              social(HugeIcons.strokeRoundedGithub, onGithub),
              const SizedBox(width: 12),
              social(HugeIcons.strokeRoundedLinkedin02, onLinkedin),
              const SizedBox(width: 12),
              social(HugeIcons.strokeRoundedInstagram, onInstagram),
              const SizedBox(width: 12),
              social(HugeIcons.strokeRoundedNewTwitter, onX),
            ],
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ results extras

/// "Make sure to bring cash" with the coin stack, under the fare card.
class KCashHint extends StatelessWidget {
  const KCashHint({super.key});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Image.asset(
        'assets/illustrations/coin-stack.webp',
        width: 26,
        cacheWidth: (26 * MediaQuery.devicePixelRatioOf(context)).round(),
      ),
      const SizedBox(width: 10),
      Flexible(
        child: Text(
          context.l10n.bringCash,
          style: KText.body.dm(fontSize: 15, color: KColors.textFaint),
        ),
      ),
    ],
  );
}

/// Shows a toast for a few seconds, right-aligned, after [show] is called.
class KToastHost extends StatefulWidget {
  const KToastHost({super.key});
  @override
  State<KToastHost> createState() => KToastHostState();
}

class KToastHostState extends State<KToastHost> {
  (String, String, String, String?, VoidCallback?)? _toast;
  Timer? _timer;
  Completer<void>? _gone;

  /// Shows a toast for 4 s (or until ×); with an [action], for 10 s, or
  /// until × when [stay]. The future completes once it has gone, so a
  /// screen can move on after the rider has read it.
  Future<void> show(
    String label,
    String title,
    String body, {
    String? action,
    VoidCallback? onAction,
    bool stay = false,
  }) {
    _timer?.cancel();
    _gone?.complete(); // a newer toast replaces the old one
    final gone = _gone = Completer<void>();
    setState(() => _toast = (label, title, body, action, onAction));
    if (!stay) {
      _timer = Timer(Duration(seconds: action == null ? 4 : 10), _hide);
    }
    return gone.future;
  }

  void _hide() {
    _timer?.cancel();
    if (mounted) setState(() => _toast = null);
    final gone = _gone;
    _gone = null;
    if (gone != null && !gone.isCompleted) {
      // Let the toast's exit animation play before moving on.
      Timer(KMotion.springDuration, gone.complete);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_gone case final g? when !g.isCompleted) g.complete();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedSize(
    duration: KMotion.springDuration,
    curve: KMotion.settleCurve,
    alignment: Alignment.topCenter,
    child: AnimatedSwitcher(
      duration: KMotion.springDuration,
      switchInCurve: KMotion.springCurve,
      switchOutCurve: Curves.easeIn,
      // Toasts rise in on the spring and sink away.
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, .18),
            end: Offset.zero,
          ).animate(a),
          child: child,
        ),
      ),
      child: _toast == null
          ? const SizedBox(key: ValueKey('none'), width: double.infinity)
          : Padding(
              key: ValueKey(_toast),
              padding: const EdgeInsets.only(top: 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: KToast(
                  label: _toast!.$1,
                  title: _toast!.$2,
                  body: _toast!.$3,
                  onClose: _hide,
                  action: _toast!.$4,
                  onAction: () {
                    final act = _toast?.$5;
                    _hide();
                    act?.call();
                  },
                ),
              ),
            ),
    ),
  );
}
