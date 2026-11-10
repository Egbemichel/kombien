import 'package:flutter/material.dart';

import '../app/app_state.dart';
import '../components/k_bits.dart';
import '../components/k_layout.dart';
import '../design/k_motion.dart';
import '../design/k_text.dart';
import '../design/k_tokens.dart';
import '../l10n/app_localizations.dart';

/// A speech bubble's words, centred on the empty bubble in the artwork.
class _Bubble {
  const _Bubble(this.text, this.centre);
  final String text;

  /// Centre of the bubble body, in art points (art drawn 402 wide).
  final Offset centre;
}

/// One onboarding page: its artwork, how it sits in the 402-pt frame, and
/// the sheet's words.
class _Page {
  const _Page({
    required this.art,
    required this.top,
    this.zoom = 1,
    this.bubbles = const [],
    required this.title,
    required this.body,
    required this.footnote,
    required this.action,
    this.terms = false,
  });
  final String art;

  /// Art top edge in the frame (negative: shifted up), in design points.
  final double top;

  /// Art width as a multiple of the frame width.
  final double zoom;
  final List<_Bubble> bubbles;
  final String title;
  final String body;
  final String footnote;
  final String action;
  final bool terms;
}

/// First run: two pages, then the app.
///
/// The artwork pages swipe; the sheet stays put and its words cross-fade.
/// Page 1 offers Skip (to the terms page: the terms still need accepting).
/// Get started stays disabled until the terms are ticked.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  /// Terms accepted and Get started tapped.
  final VoidCallback onDone;

  /// The two pages, in the app language.
  static List<_Page> _pages(AppLocalizations t) => [
    _Page(
      art: 'assets/illustrations/splash-girl.webp',
      top: -54,
      bubbles: [
        _Bubble(t.onboardingBubbleAsk, const Offset(267, 300)),
        _Bubble(t.onboardingBubbleReply, const Offset(331, 380)),
      ],
      title: t.onboardingFaresTitle,
      body: t.onboardingFaresBody,
      footnote: t.onboardingFaresFootnote,
      action: t.continueAction,
    ),
    _Page(
      art: 'assets/illustrations/splash-boy.webp',
      top: -166,
      zoom: 1.02,
      title: t.onboardingReportTitle,
      body: t.onboardingReportBody,
      footnote: t.onboardingReportFootnote,
      action: t.getStarted,
      terms: true,
    ),
  ];

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pager = PageController();
  int _page = 0;
  bool _accepted = false;

  /// Outside the app (component tests) the selector flips a local copy.
  Locale _localLanguage = const Locale('en');

  void _setLanguage(Locale next) {
    final app = KAppScope.maybeOf(context);
    if (app != null) {
      app.setLanguage(next);
    } else {
      setState(() => _localLanguage = next);
    }
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  void _goTo(int page) => _pager.animateToPage(
    page,
    duration: KMotion.springDuration,
    curve: KMotion.settleCurve,
  );

  @override
  Widget build(BuildContext context) {
    final pages = OnboardingScreen._pages(context.l10n);
    final page = pages[_page];
    final language =
        KAppScope.maybeOf(context)?.language.value ?? _localLanguage;
    return Scaffold(
      backgroundColor: KColors.background,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // The artwork swipes; everything else stays.
          Positioned.fill(
            child: PageView(
              controller: _pager,
              onPageChanged: (i) => setState(() => _page = i),
              children: [for (final p in pages) _Art(page: p)],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            // The sheet's cream continues under the home indicator.
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: KColors.background,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(KRadius.sheet),
                ),
              ),
              child: KSafeArea(
                top: false,
                child: KOnboardingSheet(
                  index: _page,
                  count: pages.length,
                  title: page.title,
                  body: page.body,
                  footnote: page.footnote,
                  action: page.action,
                  terms: page.terms,
                  termsAccepted: _accepted,
                  onTermsChanged: (v) => setState(() => _accepted = v),
                  onAction: page.terms ? widget.onDone : () => _goTo(_page + 1),
                ),
              ),
            ),
          ),
          KSafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    KLanguageSelector(
                      current: language,
                      onSelected: _setLanguage,
                    ),
                    const SizedBox(height: 12),
                    AnimatedOpacity(
                      duration: KMotion.springDuration,
                      curve: KMotion.settleCurve,
                      opacity: _page == 0 ? 1 : 0,
                      child: IgnorePointer(
                        ignoring: _page != 0,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _goTo(pages.length - 1),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              context.l10n.skip,
                              style: KText.skip.dm(
                                fontStyle: FontStyle.normal,
                                color: KColors.charcoal,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A page's artwork, scaled with the screen width the way the design places
/// it in its 402-pt frame, with the bubble words laid on top.
class _Art extends StatelessWidget {
  const _Art({required this.page});
  final _Page page;

  static const _frame = 402.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final k = box.maxWidth / _frame; // design points → screen points
      final width = _frame * page.zoom * k;
      final artScale = page.zoom * k; // art points → screen points
      final bubble = KText.body.dm(
        fontSize: 15 * k,
        fontWeight: FontWeight.w500,
        color: KColors.charcoal,
        height: 1.15,
      );
      return ClipRect(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              top: page.top * k,
              width: width,
              child: Image.asset(
                page.art,
                width: width,
                cacheWidth: (width * MediaQuery.devicePixelRatioOf(context))
                    .round(),
                fit: BoxFit.fitWidth,
                gaplessPlayback: true,
              ),
            ),
            for (final b in page.bubbles)
              Positioned(
                left: b.centre.dx * artScale - 80 * k,
                top: page.top * k + b.centre.dy * artScale - 30 * k,
                width: 160 * k,
                height: 60 * k,
                child: Center(
                  child: Text(
                    b.text,
                    textAlign: TextAlign.center,
                    style: bubble,
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}
