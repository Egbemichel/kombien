import 'package:flutter/material.dart';

import 'kombien_colors.dart';
import 'kombien_typography.dart';

/// Everything ThemeData doesn't have a built-in slot for: the mono
/// (data/price/timestamp) text styles and the semantic status colors.
/// Access via `Theme.of(context).extension<KombienThemeExtension>()!`.
class KombienThemeExtension extends ThemeExtension<KombienThemeExtension> {
  const KombienThemeExtension({
    required this.dataValue,
    required this.dataValueEmphasis,
    required this.success,
    required this.warning,
    required this.error,
    required this.backgroundSecondary,
    required this.border,
  });

  final TextStyle dataValue;
  final TextStyle dataValueEmphasis;
  final Color success;
  final Color warning;
  final Color error;
  final Color backgroundSecondary;
  final Color border;

  static KombienThemeExtension light({required Color textPrimary}) =>
      KombienThemeExtension(
        dataValue: KombienTypography.mono(
          weight: KombienTypography.monoRegular,
          color: textPrimary,
        ),
        dataValueEmphasis: KombienTypography.mono(
          weight: KombienTypography.monoMedium,
          color: textPrimary,
        ),
        success: KombienColors.success,
        warning: KombienColors.warning,
        error: KombienColors.error,
        backgroundSecondary: KombienColors.lightBackgroundSecondary,
        border: KombienColors.lightBorder,
      );

  static KombienThemeExtension dark({required Color textPrimary}) =>
      KombienThemeExtension(
        dataValue: KombienTypography.mono(
          weight: KombienTypography.monoRegular,
          color: textPrimary,
        ),
        dataValueEmphasis: KombienTypography.mono(
          weight: KombienTypography.monoMedium,
          color: textPrimary,
        ),
        success: KombienColors.success,
        warning: KombienColors.warning,
        error: KombienColors.error,
        backgroundSecondary: KombienColors.darkBackgroundSecondary,
        border: KombienColors.darkBorder,
      );

  @override
  KombienThemeExtension copyWith({
    TextStyle? dataValue,
    TextStyle? dataValueEmphasis,
    Color? success,
    Color? warning,
    Color? error,
    Color? backgroundSecondary,
    Color? border,
  }) {
    return KombienThemeExtension(
      dataValue: dataValue ?? this.dataValue,
      dataValueEmphasis: dataValueEmphasis ?? this.dataValueEmphasis,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      backgroundSecondary: backgroundSecondary ?? this.backgroundSecondary,
      border: border ?? this.border,
    );
  }

  @override
  KombienThemeExtension lerp(
    covariant ThemeExtension<KombienThemeExtension>? other,
    double t,
  ) {
    if (other is! KombienThemeExtension) return this;
    return KombienThemeExtension(
      dataValue: TextStyle.lerp(dataValue, other.dataValue, t)!,
      dataValueEmphasis: TextStyle.lerp(
        dataValueEmphasis,
        other.dataValueEmphasis,
        t,
      )!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      backgroundSecondary: Color.lerp(
        backgroundSecondary,
        other.backgroundSecondary,
        t,
      )!,
      border: Color.lerp(border, other.border, t)!,
    );
  }
}
