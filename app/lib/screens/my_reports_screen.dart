import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../app/app_state.dart';
import '../components/k_cards.dart';
import '../components/k_layout.dart';
import '../data/report_repository.dart';
import '../design/k_motion.dart';
import '../design/k_text.dart';
import '../design/k_tokens.dart';

/// Settings → My reports: every fare reported from this phone, newest
/// first, each marked Sent or Waiting for a connection.
///
/// States:
/// - reports waiting: "N reports waiting for a connection. They'll send
///   automatically" above the list (they go the next time a send works);
/// - none yet: the empty-state card, with Add report;
/// - Delete reports from this phone: a card sheet asks "Delete the N reports
///   saved on this phone?" and says sent ones stay in the shared data.
class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  static Route<void> route() => PageRouteBuilder<void>(
    transitionDuration: KMotion.springDuration,
    reverseTransitionDuration: KMotion.springDuration,
    pageBuilder: (context, _, _) => const MyReportsScreen(),
    transitionsBuilder: (context, a, _, child) => SlideTransition(
      position: Tween(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: a, curve: KMotion.settleCurve)),
      child: child,
    ),
  );

  Future<void> _confirmDelete(BuildContext context, int count) async {
    final app = KAppScope.of(context);
    final t = context.l10n;
    await showKCardSheet<void>(
      context: context,
      stack: const KStickerStack(
        left: 'assets/illustrations/sticky-note.webp',
        middle: 'assets/illustrations/empty-drawer.webp',
        right: 'assets/illustrations/hand.webp',
      ),
      title: t.deleteReportsTitle(count),
      body: t.deleteReportsBody,
      action: t.delete,
      onAction: () {
        app.deleteReports();
        Navigator.of(context).pop();
      },
      dismiss: t.cancel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = KAppScope.of(context);
    final t = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final when = DateFormat.MMMd(locale).add_Hm();
    return Scaffold(
      backgroundColor: KColors.background,
      resizeToAvoidBottomInset: false,
      body: ValueListenableBuilder<List<StoredReport>>(
        valueListenable: app.reportHistory,
        builder: (context, reports, _) {
          final waiting = reports.where((r) => !r.sent).length;
          return KPage(
            header: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: KBackRow(title: t.myReportsTitle),
            ),
            children: [
              if (waiting > 0) ...[
                KNotice(
                  text: t.reportsWaiting(waiting),
                  icon: HugeIcons.strokeRoundedWifiOff01,
                  color: KColors.textBody,
                ),
                const SizedBox(height: 14),
              ],
              if (reports.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: KPromptCard(
                    compact: true,
                    stack: const KStickerStack(
                      left: 'assets/illustrations/hand.webp',
                      middle: 'assets/illustrations/tag.webp',
                      right: 'assets/illustrations/sticky-note.webp',
                    ),
                    title: t.myReportsEmpty,
                    action: t.addReport,
                    onAction: () {
                      app.page.value = 1;
                      Navigator.of(context).pop();
                    },
                  ),
                )
              else ...[
                for (final r in reports) ...[
                  KReportTile(report: r, when: when.format(r.at)),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: () => _confirmDelete(context, reports.length),
                    child: Text(
                      t.deleteReportsAction,
                      style: KText.skip.dm(color: KColors.danger),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
