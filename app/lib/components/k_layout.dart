import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hugeicons/hugeicons.dart';

import '../app/app_state.dart';
import '../data/problem_repository.dart';
import '../data/report_repository.dart';
import '../design/k_text.dart';
import '../design/k_tokens.dart';
import 'k_animated.dart';
import 'k_cards.dart';
import 'k_controls.dart';

/// Keeps content clear of the status bar (time, battery, signal) and the
/// home indicator / gesture bar.
///
/// Uses the phone's real insets, and never less than [top] / [bottom]: some
/// phones, browsers and older Android versions report no insets, and the
/// designs always leave this room.
class KSafeArea extends StatelessWidget {
  const KSafeArea({
    super.key,
    required this.child,
    this.top = true,
    this.bottom = true,
  });
  final Widget child;
  final bool top;
  final bool bottom;

  static const minTop = 44.0, minBottom = 20.0;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: top,
    bottom: bottom,
    minimum: EdgeInsets.only(
      top: top ? minTop : 0,
      bottom: bottom ? minBottom : 0,
    ),
    child: child,
  );
}

/// The page layout every screen shares.
///
/// - The wordmark (and an optional [header] under it, like a back row) stays
///   pinned at the top; everything else scrolls under it, fading out as it
///   passes.
/// - [children] scroll. [footer] comes after them: pushed to the bottom of
///   the screen when the page is short, and scrolling along with the content
///   when it is long (never pinned over it).
/// - [bottomBar] (a main action) is the one thing pinned at the bottom; it
///   rides up just above the keyboard.
/// - The keyboard only shortens the scrolling area, so the focused field
///   scrolls into view and nothing is squeezed. [background] (the skyline)
///   stays anchored to the screen's bottom edge, under the keyboard.
/// - [overlay] floats above everything (toasts).
class KPage extends StatelessWidget {
  const KPage({
    super.key,
    this.header,
    required this.children,
    this.footer = const [],
    this.bottomBar,
    this.background,
    this.overlay,
    this.showLogo = true,
  });

  final Widget? header;
  final List<Widget> children;
  final List<Widget> footer;
  final Widget? bottomBar;
  final Widget? background;
  final Widget? overlay;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final open = keyboard > 0;
    return ColoredBox(
      color: KColors.background,
      child: Stack(
        children: [
          if (background != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(child: RepaintBoundary(child: background)),
            ),
          Padding(
            padding: EdgeInsets.only(bottom: keyboard),
            child: KSafeArea(
              // The keyboard covers the home indicator.
              bottom: !open,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      KSpace.page,
                      10,
                      KSpace.page,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showLogo)
                          SvgPicture.asset(
                            'assets/brand/kombien-wordmark-light.svg',
                            width: 114,
                            semanticsLabel: 'Kombien',
                          ),
                        ?header,
                      ],
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => FocusScope.of(context).unfocus(),
                      child: Stack(
                        children: [
                          CustomScrollView(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            slivers: [
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(
                                  KSpace.page,
                                  16,
                                  KSpace.page,
                                  0,
                                ),
                                sliver: SliverList.list(children: children),
                              ),
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    KSpace.page,
                                    24,
                                    KSpace.page,
                                    16,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: footer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Content fades as it slides under the logo.
                          const Positioned(
                            left: 0,
                            right: 0,
                            top: 0,
                            height: 16,
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      KColors.background,
                                      Color(0x00F4EEE3),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (bottomBar != null)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        KSpace.page,
                        8,
                        KSpace.page,
                        open ? 10 : 4,
                      ),
                      child: bottomBar,
                    ),
                ],
              ),
            ),
          ),
          if (overlay != null)
            Positioned(
              left: KSpace.page,
              right: KSpace.page,
              bottom: keyboard + 24,
              child: KSafeArea(top: false, child: overlay!),
            ),
        ],
      ),
    );
  }
}

/// A bottom sheet that is the empty/edge-state card: stickers breaking the
/// top edge, a title, a few lines, an optional action and a quiet dismiss.
/// Used for information and confirmations.
Future<T?> showKCardSheet<T>({
  required BuildContext context,
  required KStickerStack stack,
  required String title,
  String? body,
  String? action,
  VoidCallback? onAction,
  String? dismiss,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  barrierColor: KColors.charcoal.withValues(alpha: .35),
  builder: (context) => KSafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: KSpace.page),
      child: SingleChildScrollView(
        child: KPromptCard(
          compact: true,
          stack: stack,
          title: title,
          body: body,
          action: action,
          onAction: onAction,
          skip: dismiss ?? context.l10n.close,
          onSkip: () => Navigator.of(context).pop(),
        ),
      ),
    ),
  ),
);

/// A one-line state message on the page: icon + text in a soft surface.
class KNotice extends StatelessWidget {
  const KNotice({
    super.key,
    required this.text,
    this.icon = HugeIcons.strokeRoundedInformationCircle,
    this.color = KColors.textBody,
  });
  final String text;
  final List<List<dynamic>> icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: KColors.surface,
        borderRadius: BorderRadius.circular(KRadius.toast),
        border: Border.all(color: KColors.surfaceBorder, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: HugeIcon(
              icon: icon,
              size: 18,
              color: color,
              strokeWidth: 1.5,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: KText.bodySmall.dm(color: color, height: 1.35),
            ),
          ),
        ],
      ),
    ),
  );
}

/// One report in My reports: the route, what was paid, when and how, and
/// whether it has reached the shared data.
class KReportTile extends StatelessWidget {
  const KReportTile({super.key, required this.report, required this.when});
  final StoredReport report;

  /// The date and time, already formatted for the app language.
  final String when;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final r = report;
    final details = [
      when,
      switch (r.dayPart) {
        DayPart.morning => t.dayMorning,
        DayPart.afternoon => t.dayDay,
        DayPart.night => t.dayNight,
      },
      if (r.raining != null) r.raining! ? t.weatherRainy : t.weatherClear,
    ].join('  ·  ');
    return KSurfaceCard(
      radius: KRadius.card,
      padding: const EdgeInsets.fromLTRB(18, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${r.from}  →  ${r.to}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: KText.rowName,
                ),
              ),
              const SizedBox(width: 10),
              HugeIcon(
                icon: r.vehicle == Vehicle.taxi
                    ? HugeIcons.strokeRoundedTaxi
                    : HugeIcons.strokeRoundedMotorbike02,
                size: 20,
                color: KColors.textMuted,
                strokeWidth: 1.5,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${KMoneyFormatter.format('${r.amountXaf}')} ${t.fareCurrency}',
            style: KText.title,
          ),
          const SizedBox(height: 4),
          Text(details, style: KText.label.dm(color: KColors.textMuted)),
          const SizedBox(height: 10),
          _Status(sent: r.sent),
        ],
      ),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.sent});
  final bool sent;
  @override
  Widget build(BuildContext context) {
    final color = sent ? KColors.success : KColors.mango;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(KRadius.chip),
        border: Border.all(color: color.withValues(alpha: .6), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: sent
                ? HugeIcons.strokeRoundedTick02
                : HugeIcons.strokeRoundedClock01,
            size: 14,
            color: color,
            strokeWidth: 2,
          ),
          const SizedBox(width: 5),
          Text(
            sent ? context.l10n.reportSent : context.l10n.reportWaiting,
            style: KText.label.dm(color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

/// "< Title" back row used on pushed pages.
class KBackRow extends StatelessWidget {
  const KBackRow({super.key, required this.title, this.onBack});
  final String title;
  final VoidCallback? onBack;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Semantics(
      button: true,
      label: context.l10n.back,
      child: KPressable(
        pressedScale: .97,
        onTap: onBack ?? () => Navigator.of(context).maybePop(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedChevronLeft,
                size: 20,
                color: KColors.charcoal,
                strokeWidth: 1.5,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: KText.body.dm(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: KColors.charcoal,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// "Report a problem": a card sheet with stickers and at most three
/// questions (what went wrong, where, and an optional note). Returns the
/// answers, or null when dismissed. Send waits for the first answer.
Future<ProblemReport?> showProblemSheet(
  BuildContext context, {
  ProblemKind? kind,
  String? note,
}) => showModalBottomSheet<ProblemReport>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  barrierColor: KColors.charcoal.withValues(alpha: .35),
  builder: (context) => _ProblemSheet(kind: kind, note: note),
);

class _ProblemSheet extends StatefulWidget {
  const _ProblemSheet({this.kind, this.note});

  /// Already answered (e.g. "A place is missing" from a search).
  final ProblemKind? kind;
  final String? note;
  @override
  State<_ProblemSheet> createState() => _ProblemSheetState();
}

class _ProblemSheetState extends State<_ProblemSheet> {
  late ProblemKind? _kind = widget.kind;
  ProblemArea? _area;
  late final _details = TextEditingController(text: widget.note);

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Widget _question(String text) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(text, style: KText.section),
  );

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      // Rides above the keyboard while typing the note.
      padding: EdgeInsets.only(bottom: keyboard),
      child: KSafeArea(
        top: false,
        bottom: keyboard == 0,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: KSpace.page),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 86),
                child: KSurfaceCard(
                  padding: const EdgeInsets.fromLTRB(20, 96, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.problemTitle,
                        style: KText.title.dm(fontSize: 23, height: 1.15),
                      ),
                      _question(t.problemWhat),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final (k, label) in [
                            (ProblemKind.wrongFare, t.problemWrongFare),
                            (ProblemKind.placeMissing, t.problemPlaceMissing),
                            (ProblemKind.bug, t.problemBug),
                            (ProblemKind.other, t.problemOther),
                          ])
                            KOptionChip(
                              label,
                              height: 32,
                              fontSize: 13,
                              selected: _kind == k,
                              onTap: () => setState(() => _kind = k),
                            ),
                        ],
                      ),
                      _question(t.problemWhere),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final (a, label) in [
                            (ProblemArea.fares, t.whereFares),
                            (ProblemArea.report, t.whereReport),
                            (ProblemArea.settings, t.whereSettings),
                            (ProblemArea.other, t.whereOther),
                          ])
                            KOptionChip(
                              label,
                              height: 32,
                              fontSize: 13,
                              selected: _area == a,
                              onTap: () =>
                                  setState(() => _area = _area == a ? null : a),
                            ),
                        ],
                      ),
                      _question(t.problemMore),
                      Container(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                        decoration: BoxDecoration(
                          color: KColors.field,
                          borderRadius: BorderRadius.circular(KRadius.field),
                        ),
                        child: TextField(
                          controller: _details,
                          minLines: 2,
                          maxLines: 4,
                          maxLength: ProblemReport.maxDetails,
                          textCapitalization: TextCapitalization.sentences,
                          style: KText.bodySmall.dm(color: KColors.charcoal),
                          cursorColor: KColors.charcoal,
                          decoration: InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            hintText: t.problemMoreHint,
                            hintStyle: KText.bodySmall.dm(
                              color: KColors.placeholder,
                            ),
                            counterStyle: KText.caption,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      KButton(
                        label: t.send,
                        onPressed: _kind == null
                            ? null
                            : () => Navigator.of(context).pop(
                                ProblemReport(
                                  kind: _kind!,
                                  area: _area,
                                  details: _details.text,
                                ),
                              ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: KSkip(
                          t.cancel,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Positioned(
                top: 0,
                child: KStickerStack(
                  left: 'assets/illustrations/chat-bubble.webp',
                  middle: 'assets/illustrations/magnifying-glass.webp',
                  right: 'assets/illustrations/sticky-note.webp',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What the rider answered on the "Arrived?" sheet.
sealed class ArrivalAnswer {
  const ArrivalAnswer();
}

/// One of the one-tap amounts.
class PaidAmount extends ArrivalAnswer {
  const PaidAmount(this.xaf);
  final int xaf;
}

/// "Another amount": the report form takes over.
class OtherAmount extends ArrivalAnswer {
  const OtherAmount();
}

/// "Arrived at Eyang? What did you pay from Poste Centrale?": one tap on
/// an amount from the range they saw reports it. Null: "Not now" (or
/// dismissed).
Future<ArrivalAnswer?> showArrivalSheet(
  BuildContext context, {
  required String from,
  required String to,
  required List<int> amounts,
}) => showModalBottomSheet<ArrivalAnswer>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  barrierColor: KColors.charcoal.withValues(alpha: .35),
  builder: (context) {
    final t = context.l10n;
    return KSafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: KSpace.page),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 86),
              child: KSurfaceCard(
                padding: const EdgeInsets.fromLTRB(20, 96, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.arrivedTitle(to),
                      style: KText.title.dm(fontSize: 23, height: 1.15),
                    ),
                    const SizedBox(height: 8),
                    Text(t.arrivedBody(from), style: KText.bodySmall),
                    const SizedBox(height: 16),
                    if (amounts.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final xaf in amounts)
                            KOptionChip(
                              '${KMoneyFormatter.format('$xaf')} '
                              '${t.fareCurrency}',
                              italic: false,
                              height: 38,
                              fontSize: 16,
                              selectedText: KColors.charcoal,
                              onTap: () =>
                                  Navigator.of(context).pop(PaidAmount(xaf)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    KButton(
                      label: t.arrivedOther,
                      onPressed: () =>
                          Navigator.of(context).pop(const OtherAmount()),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: KSkip(
                        t.notNow,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Positioned(
              top: 0,
              child: KStickerStack(
                left: 'assets/illustrations/money.webp',
                middle: 'assets/illustrations/coin-stack.webp',
                right: 'assets/illustrations/tag.webp',
              ),
            ),
          ],
        ),
      ),
    );
  },
);
