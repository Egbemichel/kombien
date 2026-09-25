import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'report_fare_screen.dart';

/// Bottom-nav shell for the two core flows from brand/strategy/brand-strategy.md:
/// search a route's reported fares, or report the fare you paid.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  static const _tabs = [HomeScreen(), ReportFareScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            label: 'Report',
          ),
        ],
      ),
    );
  }
}
