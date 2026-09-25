import 'package:flutter/material.dart';

import '../theme/kombien_theme_extension.dart';

/// Placeholder — shows the intended layout (range, recency, report count)
/// per brand/voice/microcopy.md. Swap in real data and a real design once
/// that screen's screenshot arrives.
class FareResultsScreen extends StatelessWidget {
  const FareResultsScreen({super.key, required this.route});

  final String route;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<KombienThemeExtension>()!;

    return Scaffold(
      appBar: AppBar(title: Text(route)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _FareRangeCard(ext: ext),
          const SizedBox(height: 16),
          Text(
            'Recent reports',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const _PlaceholderReportTile(price: '500 FCFA', when: '2 days ago'),
          const _PlaceholderReportTile(price: '450 FCFA', when: '4 days ago'),
          const _PlaceholderReportTile(price: '600 FCFA', when: '1 week ago'),
        ],
      ),
    );
  }
}

class _FareRangeCard extends StatelessWidget {
  const _FareRangeCard({required this.ext});

  final KombienThemeExtension ext;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reported fares',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(
              '450–600 FCFA',
              style: ext.dataValueEmphasis.copyWith(fontSize: 28),
            ),
            const SizedBox(height: 4),
            Text(
              '3 reports · last one 2 days ago',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Only a few reports so far — could be off.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderReportTile extends StatelessWidget {
  const _PlaceholderReportTile({required this.price, required this.when});

  final String price;
  final String when;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<KombienThemeExtension>()!;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(price, style: ext.dataValue),
      trailing: Text(when, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
