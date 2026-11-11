import 'package:flutter/material.dart';

import '../app/app_state.dart';
import '../components/k_cards.dart';
import '../components/k_controls.dart';
import '../data/fare_repository.dart';
import '../data/landmark_repository.dart';
import '../design/k_motion.dart';
import '../design/k_text.dart';
import 'route_picker.dart';

/// "Je paie combien?": pick a route, see what riders paid.
///
/// Results under the fields, by case:
/// - a range: the fare card, the cash hint, and "Paid something else?
///   Report it here" (opens the report form on this route);
/// - no range yet: "No reports yet for this route. Be the first." with Add
///   report;
/// - offline: the range saved from an earlier search, if any, and the
///   offline card with Retry.
/// "Was this information helpful?" sits at the very bottom while a range
/// shows, under the saved destinations.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum _Result { none, range, noReports, offline }

class _HomeScreenState extends State<HomeScreen> {
  Landmark? _from, _to;
  _Result _result = _Result.none;
  FareRange? _range;
  int _run = 0;
  bool _retrying = false;
  final _toasts = GlobalKey<KToastHostState>();

  void _onRoute(Landmark? from, Landmark? to) {
    _from = from;
    _to = to;
    _lookUp();
  }

  void _lookUp() {
    final from = _from, to = _to;
    final run = ++_run;
    if (from == null || to == null) {
      setState(() {
        _result = _Result.none;
        _range = null;
      });
      return;
    }
    final app = KAppScope.of(context);
    app.fares
        .range(from, to)
        .then(
          (r) {
            if (!mounted || run != _run) return;
            // Kept to ask what they paid once they get there.
            app.rememberTrip(from, to, r);
            setState(() {
              _range = r;
              _result = r == null ? _Result.noReports : _Result.range;
              _retrying = false;
            });
          },
          onError: (Object e) {
            if (!mounted || run != _run) return;
            setState(() {
              _range = e is FaresOffline ? e.saved : null;
              _result = _Result.offline;
              _retrying = false;
            });
          },
        );
  }

  void _report() {
    final from = _from, to = _to;
    if (from != null && to != null) {
      KAppScope.of(context).reportOn(from, to);
    }
  }

  /// Records the thumbs for the range showing, then thanks the rider.
  void _rate(bool helpful) {
    final from = _from, to = _to, r = _range;
    if (from != null && to != null && r != null) {
      KAppScope.of(context).rateRange(from, to, r, helpful);
    }
    _thanks();
  }

  void _thanks() => _toasts.currentState?.show(
    context.l10n.feedbackThanksLabel,
    context.l10n.feedbackThanksTitle,
    context.l10n.feedbackThanksBody,
  );

  String _rangeText(FareRange r) =>
      '${KMoneyFormatter.format('${r.low}')} - '
      '${KMoneyFormatter.format('${r.high}')}\n${context.l10n.fareCurrency}';

  Widget _fareCard(FareRange r) => KFareCard(
    range: _rangeText(r),
    label: r.cached
        ? context.l10n.savedFareNote
        : r.demo
        ? context.l10n.fareDemo
        : null,
  );

  Widget _results() {
    final t = context.l10n;
    final r = _range;
    final Widget body = switch (_result) {
      _Result.none => const SizedBox(
        key: ValueKey('none'),
        width: double.infinity,
      ),
      _Result.range => Column(
        key: ValueKey('range ${r!.low}-${r.high} ${_to?.name}'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 22),
          _fareCard(r),
          const SizedBox(height: 18),
          const KCashHint(),
          const SizedBox(height: 22),
          Text(t.paidSomethingElse, style: KText.title),
          const SizedBox(height: 2),
          KLink(t.reportItHere, onTap: _report),
          // Room for the underline and descenders: the animated area clips.
          const SizedBox(height: 10),
        ],
      ),
      _Result.noReports => Padding(
        key: ValueKey('noReports ${_to?.name}'),
        padding: const EdgeInsets.only(top: 28),
        child: KPromptCard(
          compact: true,
          stack: const KStickerStack(
            left: 'assets/illustrations/hand.webp',
            middle: 'assets/illustrations/tag.webp',
            right: 'assets/illustrations/sticky-note.webp',
          ),
          title: t.noReportsTitle,
          action: t.addReport,
          onAction: _report,
        ),
      ),
      _Result.offline => Column(
        key: const ValueKey('offline'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (r != null) ...[const SizedBox(height: 22), _fareCard(r)],
          const SizedBox(height: 28),
          KPromptCard(
            compact: true,
            stack: const KStickerStack(
              left: 'assets/illustrations/bird-house.webp',
              middle: 'assets/illustrations/empty-drawer.webp',
              right: 'assets/illustrations/no-internet.webp',
            ),
            title: r != null ? t.offlineTitle : t.offlineNoSaved,
            action: t.retry,
            actionLoading: _retrying,
            onAction: () {
              setState(() => _retrying = true);
              _lookUp();
            },
          ),
        ],
      ),
    };
    return AnimatedSize(
      duration: KMotion.springDuration,
      curve: KMotion.settleCurve,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: KMotion.springDuration,
        switchInCurve: KMotion.springCurve,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, a) => FadeTransition(
          opacity: a,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, .06),
              end: Offset.zero,
            ).animate(a),
            child: child,
          ),
        ),
        child: body,
      ),
    );
  }

  /// At the very bottom: feedback while a range shows, with its toast.
  Widget _feedback() => AnimatedSize(
    duration: KMotion.springDuration,
    curve: KMotion.settleCurve,
    alignment: Alignment.bottomCenter,
    child: _result != _Result.range
        ? const SizedBox(width: double.infinity)
        : Column(
            children: [
              KToastHost(key: _toasts),
              const SizedBox(height: 14),
              KFeedbackRow(onUp: () => _rate(true), onDown: () => _rate(false)),
            ],
          ),
  );

  @override
  Widget build(BuildContext context) =>
      KRoutePicker(onRoute: _onRoute, below: _results(), bottom: _feedback());
}
