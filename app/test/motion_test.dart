import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:kombien/components/k_animated.dart';
import 'package:kombien/components/k_bits.dart';
import 'package:kombien/components/k_controls.dart';
import 'package:kombien/components/k_places.dart';
import 'package:kombien/design/k_motion.dart';
import 'package:kombien/design/k_tokens.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

/// The fill colour a chip is currently painting, as 8-bit ARGB.
int _fill(WidgetTester tester) {
  final box = tester.widget<Container>(
    find
        .descendant(
          of: find.byType(KChipFrame),
          matching: find.byType(Container),
        )
        .first,
  );
  return (box.decoration! as BoxDecoration).color!.toARGB32();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('spring constants match the documented figures', () {
    expect(KMotion.zeta(KMotion.spring), closeTo(.721, .001));
    expect(KMotion.overshoot(KMotion.spring), closeTo(.038, .001));
    expect(KMotion.settleTime(KMotion.spring), closeTo(.392, .002));
    expect(KMotion.zeta(KMotion.settle), closeTo(1, .002));
    expect(KMotion.position(KMotion.spring, 0), 0);
    expect(KMotion.position(KMotion.spring, .6), closeTo(1, .002));
  });

  testWidgets('selecting a chip: border traces first, colours follow', (
    tester,
  ) async {
    var selected = false;
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, set) => KOptionChip(
            'Morning',
            selected: selected,
            onTap: () => set(() => selected = !selected),
          ),
        ),
      ),
    );
    expect(_fill(tester), KColors.dustGrey.toARGB32());

    await tester.tap(find.text('Morning'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    // Still tracing: the fill has not started to change.
    expect(_fill(tester), KColors.dustGrey.toARGB32());

    await tester.pumpAndSettle();
    expect(_fill(tester), KColors.chipBackground.toARGB32());

    await tester.tap(find.text('Morning'));
    await tester.pumpAndSettle();
    expect(_fill(tester), KColors.dustGrey.toARGB32());
  });

  testWidgets('loading button shows the dots and ignores taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(KButton(label: 'Go', loading: true, onPressed: () => taps++)),
    );
    expect(find.byType(KLoadingDots), findsOneWidget);
    expect(find.text('Go'), findsNothing);
    await tester.tap(find.byType(KButton));
    expect(taps, 0);
  });

  testWidgets('city chip: download icon, progress ring, then danger trash', (
    tester,
  ) async {
    Widget chip(KCityState s, double p) =>
        _host(KCityChip('Douala', state: s, progress: p, onTap: () {}));
    HugeIcon icon() => tester.widget<HugeIcon>(find.byType(HugeIcon).last);

    await tester.pumpWidget(chip(KCityState.available, 0));
    expect(icon().icon, HugeIcons.strokeRoundedDownload01);

    await tester.pumpWidget(chip(KCityState.downloading, .5));
    await tester.pumpAndSettle();
    final ring = tester
        .widgetList<CustomPaint>(
          find.descendant(
            of: find.byType(KChipFrame),
            matching: find.byType(CustomPaint),
          ),
        )
        .map((p) => p.foregroundPainter)
        .whereType<KTracePainter>()
        .single;
    expect(ring.progress, closeTo(.5, .01));
    expect(ring.base, KColors.surfaceBorder);

    await tester.pumpWidget(chip(KCityState.saved, 1));
    await tester.pumpAndSettle();
    expect(icon().icon, HugeIcons.strokeRoundedTrash);
    expect(icon().color, KColors.danger);
  });

  testWidgets('location field: My location deletes as one token', (
    tester,
  ) async {
    final c = TextEditingController(text: 'My location');
    addTearDown(c.dispose);
    await tester.pumpWidget(
      _host(SizedBox(width: 360, child: KLocationField(controller: c))),
    );
    await tester.tap(find.byType(TextField));
    await tester.pump();

    // One backspace at the end of the token clears all of it.
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'My locatio',
        selection: TextSelection.collapsed(offset: 10),
      ),
    );
    await tester.pumpAndSettle();
    expect(c.text, '');

    // Typing on the token replaces it with the letter.
    c.text = 'My location';
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'My locationP',
        selection: TextSelection.collapsed(offset: 12),
      ),
    );
    await tester.pumpAndSettle();
    expect(c.text, 'P');

    // Gps01 brings My location back.
    await tester.tap(find.byType(HugeIcon));
    await tester.pumpAndSettle();
    expect(c.text, 'My location');
  });

  testWidgets('location field denied: hint and a red GpsOff that asks again', (
    tester,
  ) async {
    var asked = 0;
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 360,
          child: KLocationField(
            locationDenied: true,
            onRequestLocation: () => asked++,
          ),
        ),
      ),
    );
    expect(
      find.text("Can't see where you are. Search a landmark instead"),
      findsOneWidget,
    );
    final icon = tester.widget<HugeIcon>(find.byType(HugeIcon));
    expect(icon.icon, HugeIcons.strokeRoundedGpsOff01);
    expect(icon.color, KColors.danger);
    await tester.tap(find.byType(HugeIcon));
    expect(asked, 1);
  });

  testWidgets('save a picked place: tap, name, save', (tester) async {
    String? saved;
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 360,
          child: KSavePlacePrompt(place: 'Eyang', onSave: (n) => saved = n),
        ),
      ),
    );
    expect(find.text('Save this place'), findsOneWidget);
    await tester.tap(find.text('Save this place'));
    await tester.pumpAndSettle();

    KButton save() => tester.widget<KButton>(find.byType(KButton));
    expect(save().onPressed, isNull);

    await tester.tap(find.text('Work'));
    await tester.pumpAndSettle();
    expect(save().label, 'Save as Work');

    // A typed name wins over the chip.
    await tester.enterText(find.byType(TextField), 'Church');
    await tester.pumpAndSettle();
    expect(save().label, 'Save as Church');
    save().onPressed!();
    expect(saved, 'Church');
  });

  testWidgets('saved places row: chips, or a hint when empty', (tester) async {
    await tester.pumpWidget(_host(const KSavedPlacesRow(places: {})));
    expect(find.textContaining('Save this place'), findsOneWidget);
    await tester.pumpWidget(
      _host(const KSavedPlacesRow(places: {'Home': 'Bastos', 'Work': 'Eyang'})),
    );
    expect(find.byType(KSavedChip), findsNWidgets(2));
  });

  test('money formatter groups thousands as you type', () {
    const f = KMoneyFormatter();
    const nb = KMoneyFormatter.separator;
    TextEditingValue type(String old, String now) => f.formatEditUpdate(
      TextEditingValue(
        text: old,
        selection: TextSelection.collapsed(offset: old.length),
      ),
      TextEditingValue(
        text: now,
        selection: TextSelection.collapsed(offset: now.length),
      ),
    );
    expect(type('150', '1500').text, '1${nb}500');
    expect(type('300', '3000').text, '3${nb}000');
    expect(type('1${nb}000', '1${nb}0000').text, '10${nb}000');
    expect(type('', '1250000').text, '1${nb}250${nb}000');
    expect(type('', '500').text, '500');
    expect(type('', '0750').text, '750');
    expect(type('', '12a3').text, '123');
    // Caret ends after the last digit.
    expect(type('150', '1500').selection.baseOffset, 5);
    // Backspace from 1 500 gives 150.
    expect(type('1${nb}500', '1${nb}50').text, '150');
    expect(KMoneyFormatter.parse('10${nb}000'), 10000);
  });
}
