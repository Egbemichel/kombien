import 'package:flutter/material.dart';

/// App design tokens for the Kombien UI (the screens shared on 2026-11-08).
///
/// The named colors come straight from the product owner; the tints between
/// them were sampled from the design screenshots, so they're the values the
/// screens actually render, not guesses.
class KColors {
  KColors._();

  // Named colors
  static const mango = Color(0xFFF4A340);
  static const charcoal = Color(0xFF202020);
  static const dustGrey = Color(0xFFA7A18E);
  static const background = Color(0xFFF4EEE3);
  static const chipBackground = Color(0xFFFBF0E3);
  static const locationBlue = Color(0xFF1A8FEE);
  static const success = Color(0xFF03A709);
  static const danger = Color(0xFFC70C0C);

  // Surfaces (sampled)
  /// Cards, toasts, the floating menu button and the menu's highlighted row.
  static const surface = Color(0xFFFFF1D8);

  /// Hairline border around [surface] cards.
  static const surfaceBorder = Color(0xFFFADDA8);

  /// Rim of the docked menu button.
  static const menuRim = Color(0xFFFDD896);

  /// The "My location" field.
  static const field = Color(0xFFFDF5E7);

  /// Dividers between suggestion rows.
  static const divider = Color(0xFFF2DDB8);

  // Text ladder (sampled)
  static const textPrimary = charcoal;
  static const textBody = Color(0xFF4A4640);
  static const textMuted = Color(0xFF6E6B66);
  static const textSubtle = Color(0xFFA5A199);
  static const textFaint = Color(0xFFC4BEAD);
  static const placeholder = Color(0xFF8B8882);

  /// Text on an unselected (dust-grey) chip.
  static const onDust = Color(0xFF6B6862);

  /// Inactive page-indicator dot.
  static const dotInactive = Color(0xFFD9D3C5);

  // Sticker-card backgrounds behind the object illustrations
  static const stickerGrey = Color(0xFF8E8B87);
  static const stickerMango = Color(0xFFF6BB5C);
  static const stickerDust = Color(0xFFB0A994);
}

class KRadius {
  KRadius._();
  static const field = 10.0;
  static const chip = 11.0;
  static const option = 12.0;
  static const button = 14.0;
  static const toast = 14.0;
  static const fab = 18.0;
  static const card = 20.0;
  static const sticker = 20.0;
  static const fareCard = 22.0;
  static const sheet = 28.0;
}

class KSpace {
  KSpace._();

  /// Left/right page margin.
  static const page = 18.0;
}

/// Soft drop shadow used by floating elements (toast, menu button, sticker cards).
/// Drop shadow under the docked menu button: a tight contact shadow plus a
/// soft tail below (σ 1.5 pt at +2, σ 2 pt at +7), none above.
const kMenuShadow = [
  BoxShadow(color: Color(0x24000000), blurRadius: 1.73, offset: Offset(0, 2)),
  BoxShadow(color: Color(0x0F000000), blurRadius: 2.6, offset: Offset(0, 7)),
];

const kFloatShadow = [
  BoxShadow(color: Color(0x1A6B4A1A), blurRadius: 16, offset: Offset(0, 4)),
];
