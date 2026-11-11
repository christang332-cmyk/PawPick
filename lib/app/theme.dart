import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'button_styles.dart';
import '../core/colors.dart';
import '../core/typography.dart';

export '../core/colors.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.blue,
      onPrimary: AppColors.white,
      surface: AppColors.white,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.muted,
      outline: AppColors.line,
      outlineVariant: AppColors.line,
      surfaceTint: Colors.transparent,
      surfaceContainerLowest: AppColors.white,
      surfaceContainerLow: AppColors.white,
      surfaceContainer: AppColors.white,
      surfaceContainerHigh: AppColors.white,
      surfaceContainerHighest: AppColors.white,
    );
    final text = AppTypography.textTheme;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.white,
      fontFamily: AppTypography.notoSans,
      fontFamilyFallback: AppTypography.kPesoFallback,
      textTheme: text,
      primaryTextTheme: text,
      iconTheme: const IconThemeData(color: AppColors.ink),
      cardTheme: const CardThemeData(
        color: AppColors.white,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: AppColors.white,
        surfaceTintColor: Colors.transparent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: AppButtonStyles.buttonStyle(PawButtonVariant.filled),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: AppButtonStyles.buttonStyle(PawButtonVariant.filled),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: AppButtonStyles.buttonStyle(PawButtonVariant.outline),
      ),
      textButtonTheme: TextButtonThemeData(
        style: AppButtonStyles.buttonStyle(PawButtonVariant.text),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: AppButtonStyles.buttonStyle(PawButtonVariant.outline),
      ),
      toggleButtonsTheme: ToggleButtonsThemeData(
        color: AppButtonStyles.foreground(PawButtonVariant.outline),
        selectedColor: AppButtonStyles.foreground(PawButtonVariant.filled),
        fillColor: AppButtonStyles.background(PawButtonVariant.filled),
        borderColor: AppButtonStyles.border(PawButtonVariant.outline),
        selectedBorderColor: AppButtonStyles.background(PawButtonVariant.filled),
        borderRadius: BorderRadius.circular(999),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppButtonStyles.foreground(PawButtonVariant.outline),
          disabledForegroundColor: AppButtonStyles.disabledForeground,
          shape: const CircleBorder(),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.ink,
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: AppColors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: text.headlineSmall?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.blue, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.palePink,
        labelTextStyle: WidgetStatePropertyAll(
          text.bodySmall?.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  static ThemeData get dark {
    final text = AppTypography.textTheme;
    final scheme = light.colorScheme.copyWith(brightness: Brightness.dark);
    return light.copyWith(
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.white,
      textTheme: text,
      primaryTextTheme: text,
      filledButtonTheme: FilledButtonThemeData(
        style: AppButtonStyles.buttonStyle(PawButtonVariant.filled),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: AppButtonStyles.buttonStyle(PawButtonVariant.filled),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: AppButtonStyles.buttonStyle(PawButtonVariant.outline),
      ),
      textButtonTheme: TextButtonThemeData(
        style: AppButtonStyles.buttonStyle(PawButtonVariant.text),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: AppButtonStyles.buttonStyle(PawButtonVariant.outline),
      ),
      toggleButtonsTheme: ToggleButtonsThemeData(
        color: AppButtonStyles.foreground(PawButtonVariant.outline),
        selectedColor: AppButtonStyles.foreground(PawButtonVariant.filled),
        fillColor: AppButtonStyles.background(PawButtonVariant.filled),
        borderColor: AppButtonStyles.foreground(PawButtonVariant.outline),
        selectedBorderColor: AppButtonStyles.background(PawButtonVariant.filled),
        borderRadius: BorderRadius.circular(999),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppButtonStyles.foreground(PawButtonVariant.outline),
          disabledForegroundColor: AppButtonStyles.disabledForeground,
          shape: const CircleBorder(),
        ),
      ),
      appBarTheme: light.appBarTheme.copyWith(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.ink,
        titleTextStyle: text.headlineSmall?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.ink),
      cardTheme: light.cardTheme,
      dialogTheme: light.dialogTheme,
      bottomSheetTheme: light.bottomSheetTheme,
      popupMenuTheme: light.popupMenuTheme,
      inputDecorationTheme: light.inputDecorationTheme,
      navigationBarTheme: light.navigationBarTheme,
    );
  }
}
