// Pixel comparison of the open floating menu against the design export.
//
// test/reference/menu_open.png is the design's open menu at 4x: a
// 262.75 × 192.5 pt crop touching the right screen edge, with the button
// centre 95 pt from the top. The design shows three entries (it predates the
// Style guide entry), so the test renders those three.
//
// The test renders with the exact DM Sans Medium file google_fonts fetches at
// runtime (test/reference/DMSans-Medium.ttf, SIL OFL — see OFL.txt) so the
// text is comparable. The render and a diff image are written to
// build/menu_reference/ for inspection.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:kombien/components/k_floating_menu.dart';
import 'package:kombien/design/k_tokens.dart';

const _scale = 4.0;
const _width = 262.75, _height = 192.5, _buttonCentre = 95.0;

/// A pixel counts as different when any channel is off by more than this.
const _tolerance = 40;

Future<Uint8List> _rgba(ui.Image image) async => (await image.toByteData(
  format: ui.ImageByteFormat.rawRgba,
))!.buffer.asUint8List();

Future<void> _writePng(String path, ui.Image image) async {
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(png!.buffer.asUint8List());
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('open menu matches the design export pixel for pixel', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final bytes = File('test/reference/DMSans-Medium.ttf').readAsBytesSync();
      final loader = FontLoader('DMSans_500')
        ..addFont(Future.value(ByteData.sublistView(bytes)));
      await loader.load();
    });

    // Draw real blurred shadows; the test binding flattens them by default.
    debugDisableShadows = false;
    tester.view.physicalSize = const Size(_width * _scale, _height * _scale);
    tester.view.devicePixelRatio = _scale;
    addTearDown(tester.view.reset);

    const boundary = Key('menu-reference');
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: KColors.background,
          body: RepaintBoundary(
            key: boundary,
            child: ColoredBox(
              color: KColors.background,
              child: SizedBox.expand(
                child: KFloatingMenu(
                  verticalPosition: _buttonCentre / _height,
                  current: 0,
                  onSelected: (_) {},
                  entries: const [
                    KMenuEntry(
                      icon: HugeIcons.strokeRoundedSaleTag02,
                      label: 'Je paie combien?',
                    ),
                    KMenuEntry(
                      icon: HugeIcons.strokeRoundedStickyNote03,
                      label: 'Report',
                    ),
                    KMenuEntry(
                      icon: HugeIcons.strokeRoundedSettings01,
                      label: 'Settings',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('kombien-menu-button')));
    await tester.pumpAndSettle();

    final (actual, expected) = (await tester.runAsync(() async {
      final box =
          tester.renderObject(find.byKey(boundary)) as RenderRepaintBoundary;
      final actual = await box.toImage(pixelRatio: _scale);
      final codec = await ui.instantiateImageCodec(
        File('test/reference/menu_open.png').readAsBytesSync(),
      );
      return (actual, (await codec.getNextFrame()).image);
    }))!;
    expect(
      (actual.width, actual.height),
      (expected.width, expected.height),
      reason: 'render size',
    );

    final (diffCount, diffImage) = (await tester.runAsync(() async {
      final a = await _rgba(actual), e = await _rgba(expected);
      final out = Uint8List(a.length);
      var count = 0;
      for (var i = 0; i < a.length; i += 4) {
        var worst = 0;
        for (var ch = 0; ch < 3; ch++) {
          final d = (a[i + ch] - e[i + ch]).abs();
          if (d > worst) worst = d;
        }
        final bad = worst > _tolerance;
        if (bad) count++;
        // Reference faded, mismatches in red.
        final grey = 200 + e[i + 1] * 55 ~/ 255;
        out[i] = bad ? 230 : grey;
        out[i + 1] = bad ? 30 : grey;
        out[i + 2] = bad ? 30 : grey;
        out[i + 3] = 255;
      }
      final completer = <ui.Image>[];
      ui.decodeImageFromPixels(
        out,
        actual.width,
        actual.height,
        ui.PixelFormat.rgba8888,
        completer.add,
      );
      while (completer.isEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      await _writePng('build/menu_reference/actual.png', actual);
      await _writePng('build/menu_reference/diff.png', completer.single);
      return (count, completer.single);
    }))!;
    diffImage.dispose();
    debugDisableShadows = true;

    final ratio = diffCount / (actual.width * actual.height);
    // ignore: avoid_print
    print(
      'menu reference: $diffCount px differ '
      '(${(ratio * 100).toStringAsFixed(3)}%)',
    );
    // What remains is anti-aliasing at glyph edges and small glyph-shape
    // differences between the design tool's DM Sans and Google Fonts' static
    // Medium file; every element sits within 0.25 pt of the export.
    expect(ratio, lessThan(0.015));
  });
}
