import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'k_tokens.dart';

/// DM Sans type scale, sizes in logical points as measured on the 402-pt-wide
/// design frames.
class KText {
  KText._();

  static TextStyle _dm(
    double size, {
    FontWeight weight = FontWeight.w400,
    bool italic = false,
    Color color = KColors.textPrimary,
    double? height,
    double? spacing,
    TextDecoration? decoration,
  }) => GoogleFonts.dmSans(
    fontSize: size,
    fontWeight: weight,
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    color: color,
    height: height,
    letterSpacing: spacing,
    decoration: decoration,
    decorationColor: color,
  );

  /// "500 - 700 FCFA"
  static final fare = _dm(
    56,
    weight: FontWeight.w700,
    height: 1.02,
    spacing: -1.6,
  );

  /// Onboarding headline, e.g. "Je paie combien?"
  static final onboardingTitle = _dm(
    30,
    weight: FontWeight.w900,
    color: KColors.mango,
    spacing: -0.3,
  );

  /// Permission/empty-state headline.
  static final headline = _dm(
    30,
    weight: FontWeight.w700,
    height: 1.08,
    spacing: -0.6,
  );

  /// "Tu go où?", "Paid something else?"
  static final title = _dm(22, weight: FontWeight.w700, spacing: -0.2);

  /// Page title in Settings — italic.
  static final pageTitle = _dm(28, italic: true, spacing: -0.4);

  /// Big italic entry text (destination, fare amount).
  static final entry = _dm(26, italic: true, spacing: -0.4);
  static final entryPlaceholder = _dm(
    26,
    italic: true,
    color: KColors.placeholder,
    spacing: -0.4,
  );

  /// Route card place names.
  static final routeValue = _dm(
    26,
    weight: FontWeight.w700,
    italic: true,
    height: 1.15,
    spacing: -0.3,
  );
  static final toastTitle = _dm(20, weight: FontWeight.w500, spacing: -0.3);
  static final onboardingBody = _dm(19, color: KColors.textBody, height: 1.3);
  static final body = _dm(16, color: KColors.textBody, height: 1.35);
  static final bodySmall = _dm(14, color: KColors.textBody, height: 1.35);
  static final button = _dm(15, weight: FontWeight.w500);
  static final label = _dm(12, color: KColors.textBody);
  static final rowName = _dm(
    14,
    weight: FontWeight.w500,
    color: Color(0xFF2E2D2B),
  );
  static final rowDistance = _dm(14, italic: true, color: Color(0xFF2E2D2B));
  static final mangoLabel = _dm(14, color: KColors.mango);
  static final chip = _dm(
    14,
    weight: FontWeight.w500,
    italic: true,
    color: KColors.mango,
  );
  static final caption = _dm(
    10,
    italic: true,
    color: KColors.textFaint,
    height: 1.35,
  );
  static final captionDark = _dm(
    10.5,
    italic: true,
    color: Color(0xFF3B3935),
    height: 1.35,
  );
  static final footnote = _dm(10, color: KColors.textFaint);
  static final link = _dm(
    18,
    weight: FontWeight.w700,
    italic: true,
    color: KColors.mango,
    decoration: TextDecoration.underline,
  );
  static final skip = _dm(15, italic: true, color: KColors.textSubtle);
  static final section = _dm(14, weight: FontWeight.w500);
  static final sectionMango = _dm(
    15,
    weight: FontWeight.w500,
    color: KColors.mango,
  );
  static final settingsRow = _dm(14, color: KColors.textSubtle);

  /// Floating menu entry label.
  static final menuItem = _dm(16.8, weight: FontWeight.w500, spacing: -.82);
  static final location = _dm(
    14,
    weight: FontWeight.w500,
    color: KColors.locationBlue,
  );
}

/// Style overrides that stay in DM Sans. google_fonts bakes the weight and
/// italic into the font family name, so `copyWith(fontStyle: …)` alone would
/// keep the old glyphs — use `.dm(…)` instead.
extension KTextStyleX on TextStyle {
  TextStyle dm({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
    Color? decorationColor,
  }) => GoogleFonts.dmSans(
    textStyle: this,
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight ?? this.fontWeight,
    fontStyle: fontStyle ?? this.fontStyle,
    height: height,
    letterSpacing: letterSpacing,
    decoration: decoration,
    decorationColor: decorationColor ?? (decoration != null ? color : null),
  );
}
