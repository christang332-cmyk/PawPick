import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/colors.dart';

/// Single source of truth for every [TextStyle] in PawPick.
///
/// Every style applies [kPesoFallback] (the bundled Noto Sans) so the peso sign
/// (U+20B1) and any glyph missing from DM Sans / Fredoka always resolve to a
/// font that actually contains it.
///
/// Never build text styles with `GoogleFonts.*` or a raw [TextStyle.fontFamily]
/// outside this class.
abstract class AppTypography {
  static const String notoSans = 'NotoSans';

  /// Bundled font guaranteed to contain U+20B1 (₱). Applied as the fallback on
  /// every text style so no price ever renders as a square "▯".
  static const List<String> kPesoFallback = [notoSans];

  /// The one [TextTheme] used by the whole app. Every style here carries
  /// [kPesoFallback].
  static TextTheme get textTheme {
    final body = GoogleFonts.dmSansTextTheme().apply(
      fontFamilyFallback: kPesoFallback,
    );
    final display = GoogleFonts.fredokaTextTheme().apply(
      fontFamilyFallback: kPesoFallback,
    );
    return body.copyWith(
      displayLarge: display.displayLarge?.copyWith(
        color: AppColors.ink,
        fontWeight: FontWeight.w600,
        letterSpacing: -1.5,
        fontFamilyFallback: kPesoFallback,
      ),
      displayMedium: display.displayMedium?.copyWith(
        color: AppColors.ink,
        fontWeight: FontWeight.w600,
        fontFamilyFallback: kPesoFallback,
      ),
      headlineLarge: display.headlineLarge?.copyWith(
        color: AppColors.ink,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.8,
        fontFamilyFallback: kPesoFallback,
      ),
      headlineSmall: display.headlineSmall?.copyWith(
        color: AppColors.ink,
        fontWeight: FontWeight.w600,
        fontFamilyFallback: kPesoFallback,
      ),
      titleLarge: display.titleLarge?.copyWith(
        color: AppColors.ink,
        fontWeight: FontWeight.w600,
        fontFamilyFallback: kPesoFallback,
      ),
      bodyLarge: body.bodyLarge?.copyWith(
        color: AppColors.ink,
        fontFamilyFallback: kPesoFallback,
      ),
      bodyMedium: body.bodyMedium?.copyWith(
        color: AppColors.ink,
        fontFamilyFallback: kPesoFallback,
      ),
      labelLarge: body.labelLarge?.copyWith(
        color: AppColors.ink,
        fontWeight: FontWeight.w700,
        fontFamilyFallback: kPesoFallback,
      ),
    );
  }
}
