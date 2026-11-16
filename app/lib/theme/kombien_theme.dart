import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'kombien_colors.dart';
import 'kombien_theme_extension.dart';

/// Light/dark ThemeData built from the brand tokens in
/// `brand/tokens/colors.json` and `brand/tokens/typography.json`.
/// The app's type is DM Sans (bundled in assets/google_fonts), also for what
/// Material draws by itself. The theme used to ask for Space Grotesk and
/// JetBrains Mono, which are not bundled: five font downloads on every
/// launch, and a plain fallback font whenever the connection was gone.
class KombienTheme {
  KombienTheme._();

  static ThemeData get light {
    const textPrimary = KombienColors.lightTextPrimary;
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: KombienColors.lightBackgroundPrimary,
      colorScheme: base.colorScheme.copyWith(
        brightness: Brightness.light,
        primary: KombienColors.mango,
        onPrimary: KombienColors.accentOnAccent,
        surface: KombienColors.lightSurface,
        onSurface: textPrimary,
        error: KombienColors.error,
      ),
      textTheme: GoogleFonts.dmSansTextTheme(
        base.textTheme,
      ).apply(bodyColor: textPrimary, displayColor: textPrimary),
      appBarTheme: AppBarTheme(
        backgroundColor: KombienColors.lightBackgroundPrimary,
        foregroundColor: textPrimary,
        elevation: 0,
        titleTextStyle: GoogleFonts.dmSans(
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: textPrimary,
        ),
      ),
      dividerColor: KombienColors.lightBorder,
      focusColor: KombienColors.focusRing,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: KombienColors.mango,
          foregroundColor: KombienColors.accentOnAccent,
          textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
        ),
      ),
      extensions: [KombienThemeExtension.light(textPrimary: textPrimary)],
    );
  }

  static ThemeData get dark {
    const textPrimary = KombienColors.darkTextPrimary;
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: KombienColors.darkBackgroundPrimary,
      colorScheme: base.colorScheme.copyWith(
        brightness: Brightness.dark,
        primary: KombienColors.mango,
        onPrimary: KombienColors.accentOnAccent,
        surface: KombienColors.darkSurface,
        onSurface: textPrimary,
        error: KombienColors.error,
      ),
      textTheme: GoogleFonts.dmSansTextTheme(
        base.textTheme,
      ).apply(bodyColor: textPrimary, displayColor: textPrimary),
      appBarTheme: AppBarTheme(
        backgroundColor: KombienColors.darkBackgroundPrimary,
        foregroundColor: textPrimary,
        elevation: 0,
        titleTextStyle: GoogleFonts.dmSans(
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: textPrimary,
        ),
      ),
      dividerColor: KombienColors.darkBorder,
      focusColor: KombienColors.focusRing,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: KombienColors.mango,
          foregroundColor: KombienColors.accentOnAccent,
          textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
        ),
      ),
      extensions: [KombienThemeExtension.dark(textPrimary: textPrimary)],
    );
  }
}
