import 'package:flutter/material.dart';

/// Mirrors `brand/tokens/colors.json`. Keep both in sync by hand until
/// there's tooling to generate one from the other.
class KombienColors {
  KombienColors._();

  // Base
  static const charcoal = Color(0xFF202020);
  static const dustGrey = Color(0xFFA7A18E);
  static const mango = Color(0xFFF4A340);
  static const warmWhite = Color(0xFFF4F1E8);
  static const deepNeutral = Color(0xFF121212);
  static const mutedNeutral = Color(0xFF6F6A60);
  static const success = Color(0xFF0E6B34);
  // Warning fails contrast as foreground text/icons on warmWhite — use it as
  // a filled badge with charcoal text on top. See brand/colors/contrast-checks.md.
  static const warning = Color(0xFFD97706);
  static const error = Color(0xFFC81E1E);

  // Semantic — light
  static const lightBackgroundPrimary = warmWhite;
  static const lightBackgroundSecondary = Color(0xFFECE7D8);
  static const lightSurface = warmWhite;
  static const lightTextPrimary = charcoal;
  static const lightTextSecondary = mutedNeutral;
  static const lightBorder = dustGrey;

  // Semantic — dark
  static const darkBackgroundPrimary = charcoal;
  static const darkBackgroundSecondary = Color(0xFF262626);
  static const darkSurface = deepNeutral;
  static const darkTextPrimary = warmWhite;
  static const darkTextSecondary = dustGrey;
  static const darkBorder = mutedNeutral;

  // Shared
  static const accentPrimary = mango;
  static const accentOnAccent = charcoal;
  static const focusRing = mango;
}
