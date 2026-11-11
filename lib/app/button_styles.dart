import 'package:flutter/material.dart';

import '../core/colors.dart';

enum PawButtonVariant {
  filled,
  google,
  outline,
  soft,
  danger,
  dangerFilled,
  text,
  onDark,
}

abstract final class AppButtonStyles {
  static const disabledBackground = Color(0xFFE9E6DF);
  static const disabledForeground = Color(0xFF6B7385);
  static const dangerBackground = Color(0xFFFDE8E8);
  static const dangerForeground = Color(0xFFB42318);
  static const googleBorder = Color(0xFFC9CEDB);
  static const darkSurface = Color(0xFF293C68);

  static Color foreground(PawButtonVariant variant, {bool disabled = false}) {
    if (disabled) return disabledForeground;
    return switch (variant) {
      PawButtonVariant.filled => AppColors.white,
      PawButtonVariant.google => AppColors.ink,
      PawButtonVariant.outline || PawButtonVariant.text => AppColors.blue,
      PawButtonVariant.soft => AppColors.ink,
      PawButtonVariant.danger => dangerForeground,
      PawButtonVariant.dangerFilled => AppColors.white,
      PawButtonVariant.onDark => AppColors.white,
    };
  }

  static Color background(PawButtonVariant variant, {bool disabled = false}) {
    if (disabled) return disabledBackground;
    return switch (variant) {
      PawButtonVariant.filled => AppColors.blue,
      PawButtonVariant.google => AppColors.white,
      PawButtonVariant.outline => AppColors.cream,
      PawButtonVariant.text => Colors.transparent,
      PawButtonVariant.soft => AppColors.palePink,
      PawButtonVariant.danger => dangerBackground,
      PawButtonVariant.dangerFilled => dangerForeground,
      PawButtonVariant.onDark => Colors.transparent,
    };
  }

  static Color? border(PawButtonVariant variant) => switch (variant) {
        PawButtonVariant.google => googleBorder,
        PawButtonVariant.outline => AppColors.blue,
        PawButtonVariant.danger => dangerForeground,
        _ => null,
      };

  static Color contrastSurface(PawButtonVariant variant) => switch (variant) {
        PawButtonVariant.text => AppColors.cream,
        PawButtonVariant.onDark => darkSurface,
        _ => background(variant),
      };

  static ButtonStyle buttonStyle(
    PawButtonVariant variant, {
    bool disabled = false,
  }) {
    final line = border(variant);
    return ButtonStyle(
      alignment: Alignment.center,
      minimumSize: const WidgetStatePropertyAll(Size(0, 52)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 20),
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => foreground(
          variant,
          disabled: disabled || states.contains(WidgetState.disabled),
        ),
      ),
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => background(
          variant,
          disabled: disabled || states.contains(WidgetState.disabled),
        ),
      ),
      side: WidgetStateProperty.resolveWith((states) {
        if (line == null) return BorderSide.none;
        return BorderSide(
          color: disabled || states.contains(WidgetState.disabled)
              ? disabledForeground
              : line,
          width: variant == PawButtonVariant.outline ? 2 : 1.5,
        );
      }),
      shape: const WidgetStatePropertyAll(StadiumBorder()),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      elevation: WidgetStatePropertyAll(
        variant == PawButtonVariant.filled ||
                variant == PawButtonVariant.dangerFilled
            ? 1
            : 0,
      ),
      shadowColor: WidgetStatePropertyAll(
        variant == PawButtonVariant.google
            ? Colors.black.withValues(alpha: 0.10)
            : variant == PawButtonVariant.danger ||
                    variant == PawButtonVariant.dangerFilled
                ? dangerForeground.withValues(alpha: 0.12)
                : AppColors.blue.withValues(alpha: 0.12),
      ),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed) ||
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return (variant == PawButtonVariant.onDark
                  ? AppColors.white
                  : Colors.black)
              .withValues(alpha: 0.08);
        }
        return Colors.transparent;
      }),
    );
  }
}
