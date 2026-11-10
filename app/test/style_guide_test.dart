import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kombien/components/k_cards.dart';
import 'package:kombien/components/k_controls.dart';
import 'package:kombien/screens/style_guide_screen.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pumpGuide(WidgetTester tester) async {
    // Tall enough that the whole (lazily built) list is laid out at once.
    tester.view.physicalSize = const Size(402, 30000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: StyleGuideScreen())),
    );
  }

  KButton buttonLabelled(WidgetTester tester, String label) =>
      tester.widget<KButton>(find.widgetWithText(KButton, label));

  testWidgets('Atoms come before molecules', (tester) async {
    await pumpGuide(tester);
    final atoms = tester.getTopLeft(find.text('Atoms')).dy;
    final molecules = tester.getTopLeft(find.text('Molecules')).dy;
    expect(atoms, lessThan(molecules));
    expect(tester.getTopLeft(find.text('CHIPS')).dy, lessThan(molecules));
    expect(tester.getTopLeft(find.text('FIELDS')).dy, greaterThan(molecules));
  });

  testWidgets(
    'Destination search: typing opens suggestions, picking fills the field',
    (tester) async {
      await pumpGuide(tester);
      final entry = find.widgetWithText(TextField, 'Start typing...').first;
      await tester.enterText(entry, 'awa');
      await tester.pumpAndSettle();
      expect(find.byType(KSuggestionsCard), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(KSuggestionsCard),
          matching: find.text('Awae Escaliers'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(KSuggestionsCard), findsNothing);
      expect(find.widgetWithText(TextField, 'Awae Escaliers'), findsOneWidget);
    },
  );

  testWidgets('Feedback: a thumb shows the toast, which then goes away', (
    tester,
  ) async {
    await pumpGuide(tester);
    final thumbsUp = find
        .descendant(
          of: find.byType(KFeedbackRow),
          matching: find.byType(GestureDetector),
        )
        .first;
    await tester.tap(thumbsUp);
    await tester.pump();
    expect(find.byType(KToast), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.byType(KToast), findsNothing);
  });

  testWidgets(
    'Fare entry: Add report enables once there is an amount, then confirms',
    (tester) async {
      await pumpGuide(tester);
      expect(buttonLabelled(tester, 'Add report').onPressed, isNull);

      await tester.tap(find.text('600'));
      await tester.pumpAndSettle();
      expect(buttonLabelled(tester, 'Add report').onPressed, isNotNull);

      await tester.tap(find.text('Add report'));
      await tester.pump();
      expect(find.byType(KToast), findsOneWidget);
      expect(buttonLabelled(tester, 'Add report').onPressed, isNull);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'Onboarding: Continue advances; Get started waits for the terms',
    (tester) async {
      await pumpGuide(tester);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(buttonLabelled(tester, 'Get started').onPressed, isNull);
      final terms = find.descendant(
        of: find
            .ancestor(
              of: find.text('Get started'),
              matching: find.byType(Column),
            )
            .first,
        matching: find.textContaining(
          "I Agree to Kombien's",
          findRichText: true,
        ),
      );
      await tester.tap(terms);
      await tester.pumpAndSettle();
      expect(buttonLabelled(tester, 'Get started').onPressed, isNotNull);
    },
  );
}
