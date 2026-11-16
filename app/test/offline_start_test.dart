import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kombien/theme/kombien_theme.dart';
import 'package:kombien/theme/kombien_theme_extension.dart';

/// Nothing the first screen needs may come from a server we do not run.
///
/// Flutter's web engine waits for Roboto before drawing anything, and the
/// google_fonts package downloads any font it does not find in the assets.
/// On a weak connection either request can stall for minutes and the app
/// never opens; with no connection the text falls back to a plain font.
void main() {
  test('Roboto ships with the app, so the engine never downloads it', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('family: Roboto'));
    expect(pubspec, contains('assets/fonts/Roboto-Regular.ttf'));
    expect(File('assets/fonts/Roboto-Regular.ttf').existsSync(), isTrue);
  });

  test('the theme uses only the bundled DM Sans', () {
    final bundled = Directory('assets/google_fonts')
        .listSync()
        .map((f) => f.uri.pathSegments.last)
        .where((n) => n.endsWith('.ttf'))
        .toSet();
    expect(bundled, contains('DMSans-Regular.ttf'));

    for (final theme in [KombienTheme.light, KombienTheme.dark]) {
      final styles = <String, String?>{
        for (final e in {
          'displayLarge': theme.textTheme.displayLarge,
          'headlineMedium': theme.textTheme.headlineMedium,
          'titleMedium': theme.textTheme.titleMedium,
          'bodyLarge': theme.textTheme.bodyLarge,
          'bodyMedium': theme.textTheme.bodyMedium,
          'labelLarge': theme.textTheme.labelLarge,
          'appBar title': theme.appBarTheme.titleTextStyle,
          'button': theme.elevatedButtonTheme.style?.textStyle?.resolve({}),
          'dataValue': theme.extension<KombienThemeExtension>()!.dataValue,
        }.entries)
          e.key: e.value?.fontFamily,
      };
      for (final MapEntry(:key, :value) in styles.entries) {
        expect(
          value,
          isNotNull,
          reason: '$key has no font family (would use a system default)',
        );
        expect(value, startsWith('DMSans'), reason: '$key uses $value');
      }
    }
  });
}
