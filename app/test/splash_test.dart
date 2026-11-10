import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kombien/screens/splash_screen.dart';

/// Advances like a real screen: one frame every 16 ms.
Future<void> _run(WidgetTester tester, int ms) async {
  for (var t = 0; t < ms; t += 16) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// Vertical offset of the layer drawn from [asset].
double _offset(WidgetTester tester, String asset) {
  final image = find.byWidgetPredicate(
    (w) => w is Image && (w.image as AssetImage).assetName == asset,
  );
  final t = tester.widget<Transform>(
    find.ancestor(of: image, matching: find.byType(Transform)).first,
  );
  return t.transform.getTranslation().y;
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('splash: sunrise, city climbs in, then hands over', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    var done = false;
    await tester.pumpWidget(
      MaterialApp(home: SplashScreen(onDone: () => done = true)),
    );
    // Let the layers decode (real async), then the timeline starts.
    await tester.runAsync(() => Future.delayed(const Duration(seconds: 1)));
    await tester.pump();

    // Splash 1: sun and clouds sit 534 pt low, the city is below the screen.
    expect(_offset(tester, 'assets/splash/sun.webp'), SplashScreen.sunrise);
    expect(_offset(tester, 'assets/splash/plants-front.webp'), 120);

    // Mid-way the sky has risen while the bushes are still on their way.
    await _run(tester, 1100);
    expect(_offset(tester, 'assets/splash/sun.webp').abs(), lessThan(40));
    expect(_offset(tester, 'assets/splash/plants-front.webp'), 120);

    // Everything comes to rest, and the splash hands over once.
    await _run(tester, 3000);
    for (final asset in [
      'assets/splash/sun.webp',
      'assets/splash/city-far.webp',
      'assets/splash/plants-front.webp',
    ]) {
      expect(_offset(tester, asset).abs(), lessThan(.5), reason: asset);
    }
    expect(done, isTrue);
  });
}
