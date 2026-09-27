import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kombien/main.dart';

void main() {
  // google_fonts fetches font files over the network at runtime; disable
  // that in tests so CI doesn't depend on network access.
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Home tab shows the search flow', (WidgetTester tester) async {
    await tester.pumpWidget(const KombienApp());

    expect(find.text('Je paie combien?'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Route'), findsOneWidget);
  });

  testWidgets('Bottom nav switches to the report tab', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const KombienApp());

    await tester.tap(find.text('Report'));
    await tester.pumpAndSettle();

    expect(find.text('What did you pay for this ride?'), findsOneWidget);
  });

  testWidgets('Searching a route opens fare results', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const KombienApp());

    await tester.enterText(find.byType(TextField), 'Mvan -> Poste Centrale');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Search'));
    await tester.pumpAndSettle();

    expect(find.text('Reported fares'), findsOneWidget);
  });
}
