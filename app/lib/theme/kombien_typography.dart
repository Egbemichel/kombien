import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Mirrors `brand/tokens/typography.json`. Space Grotesk for display/UI,
/// JetBrains Mono for data (fares, timestamps, route labels, code).
/// Fonts are fetched via google_fonts rather than bundled as asset files —
/// see brand/typography/font-licensing.md for why we link instead of
/// redistributing font binaries.
class KombienTypography {
  KombienTypography._();

  static TextStyle display({
    FontWeight weight = FontWeight.w400,
    double? fontSize,
    Color? color,
  }) => GoogleFonts.spaceGrotesk(
    fontWeight: weight,
    fontSize: fontSize,
    color: color,
  );

  static TextStyle mono({
    FontWeight weight = FontWeight.w400,
    double? fontSize,
    Color? color,
  }) => GoogleFonts.jetBrainsMono(
    fontWeight: weight,
    fontSize: fontSize,
    color: color,
  );

  static const displayRegular = FontWeight.w400;
  static const displayMedium = FontWeight.w500;
  static const displayBold = FontWeight.w700;
  static const monoRegular = FontWeight.w400;
  static const monoMedium = FontWeight.w500;
}
