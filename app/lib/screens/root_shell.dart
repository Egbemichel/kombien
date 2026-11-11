import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../app/app_state.dart';
import '../components/k_cards.dart';
import '../components/k_floating_menu.dart';
import '../components/k_layout.dart';
import '../design/k_tokens.dart';
import '../services/update.dart';
import 'home_screen.dart';
import 'report_fare_screen.dart';
import 'settings_screen.dart';
import 'style_guide_screen.dart';

/// The app has no bottom bar: navigation is the floating menu docked to the
/// right edge, drawn over whichever page is showing.
///
/// The style guide is not in the menu: in debug builds it opens with the
/// ?page=3 dev link; release builds leave it out entirely.
///
/// It also shows what the app brings up by itself, whatever the page: a
/// new version ready, a report that unlocked a range, My city following
/// the rider, and "Arrived? What did you pay?".
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  final _toasts = GlobalKey<KToastHostState>();
  KAppState? _app;
  bool _asking = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = KAppScope.of(context);
    if (app == _app) return;
    _detach();
    _app = app;
    app.arrival.addListener(_onArrival);
    app.unlocked.addListener(_onUnlocked);
    app.cityMoved.addListener(_onCityMoved);
    app.pushOffer.addListener(_onPushOffer);
    updateReady.addListener(_onUpdate);
    // Anything already waiting (set before this screen was built).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _onUpdate();
      _onUnlocked();
      _onCityMoved();
      _onArrival();
    });
  }

  void _detach() {
    final app = _app;
    if (app == null) return;
    app.arrival.removeListener(_onArrival);
    app.unlocked.removeListener(_onUnlocked);
    app.cityMoved.removeListener(_onCityMoved);
    app.pushOffer.removeListener(_onPushOffer);
    updateReady.removeListener(_onUpdate);
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }

  void _onUpdate() {
    if (!updateReady.value) return;
    final t = context.l10n;
    _toasts.currentState?.show(
      t.updateLabel,
      t.updateTitle,
      t.updateBody,
      action: t.updateAction,
      onAction: applyUpdate,
      stay: true,
    );
  }

  void _onUnlocked() {
    final app = _app;
    final route = app?.unlocked.value;
    if (app == null || route == null) return;
    app.unlocked.value = null;
    final t = context.l10n;
    _toasts.currentState?.show(
      t.unlockedLabel,
      t.unlockedTitle,
      t.unlockedBody(route.$1, route.$2),
    );
  }

  void _onCityMoved() {
    final app = _app;
    final moved = app?.cityMoved.value;
    if (app == null || moved == null) return;
    final t = context.l10n;
    _toasts.currentState?.show(
      t.cityMovedLabel,
      t.cityMovedTitle(moved.$2),
      t.cityMovedBody(moved.$2),
      action: t.undo,
      onAction: app.undoCityMove,
    );
  }

  /// Right after a sent report: offer notifications, once the report's
  /// own thank-you has had its moment.
  Future<void> _onPushOffer() async {
    final app = _app;
    if (app == null || !app.pushOffer.value) return;
    await Future<void>.delayed(const Duration(milliseconds: 4500));
    if (!mounted || !app.pushOffer.value) return;
    app.pushOffer.value = false;
    final t = context.l10n;
    _toasts.currentState?.show(
      t.pushOfferLabel,
      t.pushOfferTitle,
      t.pushOfferBody,
      action: t.pushOfferAction,
      onAction: () => _turnOnPush(app),
    );
  }

  Future<void> _turnOnPush(KAppState app) async {
    final ok = await app.enablePush();
    if (!mounted) return;
    final t = context.l10n;
    if (ok) {
      _toasts.currentState?.show(t.pushOnLabel, t.pushOnTitle, t.pushOnBody);
    } else if (app.push.permission == 'denied') {
      _toasts.currentState?.show(
        t.pushBlockedLabel,
        t.pushBlockedTitle,
        t.pushBlockedBody,
      );
    }
  }

  Future<void> _onArrival() async {
    final app = _app;
    final trip = app?.arrival.value;
    if (app == null || trip == null || _asking) return;
    _asking = true;
    final answer = await showArrivalSheet(
      context,
      from: trip.from,
      to: trip.to,
      amounts: trip.amounts,
    );
    _asking = false;
    if (!mounted) return;
    final t = context.l10n;
    switch (answer) {
      case PaidAmount(:final xaf):
        await app.answerArrival(xaf);
        _toasts.currentState?.show(
          t.arrivedThanksLabel,
          t.arrivedThanksTitle,
          t.arrivedThanksBody,
        );
      case OtherAmount():
        await app.reportArrivalElsewhere();
      case null:
        await app.answerArrival(null);
    }
  }

  // Order matters: the first entry springs out of the menu button, the rest
  // out of it. Labels follow the app language.
  List<KMenuEntry> _entries(BuildContext context) => [
    KMenuEntry(
      icon: HugeIcons.strokeRoundedSaleTag02,
      label: context.l10n.menuFares,
    ),
    KMenuEntry(
      icon: HugeIcons.strokeRoundedStickyNote03,
      label: context.l10n.menuReport,
    ),
    KMenuEntry(
      icon: HugeIcons.strokeRoundedSettings01,
      label: context.l10n.menuSettings,
    ),
  ];

  static final _pages = [
    const HomeScreen(),
    const ReportFareScreen(),
    const SettingsScreen(),
    if (kDebugMode) const StyleGuideScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final app = KAppScope.of(context);
    return Scaffold(
      backgroundColor: KColors.background,
      // Pages make room for the keyboard themselves (KPage): resizing the
      // whole screen would squeeze backgrounds and pinned parts.
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: ValueListenableBuilder<int>(
              valueListenable: app.page,
              builder: (context, page, _) => RepaintBoundary(
                child: IndexedStack(index: page, children: _pages),
              ),
            ),
          ),
          // App-wide toasts, above the pages' own (bottom right).
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: KSafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: KToastHost(key: _toasts),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: KSafeArea(
              child: AnimatedBuilder(
                animation: Listenable.merge([app.page, app.menuPosition]),
                builder: (context, _) => KFloatingMenu(
                  entries: _entries(context),
                  current: app.page.value,
                  onSelected: (i) => app.page.value = i,
                  verticalPosition: app.menuPosition.value,
                  onMoved: app.moveMenu,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
