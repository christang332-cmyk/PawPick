import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../typography.dart';

abstract final class Money {
  static final NumberFormat _format = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '\u20B1',
    decimalDigits: 2,
  );

  /// Formats minor units (cents) as a Philippine peso string.
  ///
  /// Intended for non-UI uses (logs, PDF text). For UI use [PriceText],
  /// [span] or [template] so the peso sign is rendered with the bundled font.
  static String format(int minorUnits) => _format.format(minorUnits / 100);

  /// Builds an [InlineSpan] where the peso sign is rendered with the bundled
  /// [AppTypography.notoSans] font and the digits use the given [style].
  static InlineSpan span(int minorUnits, TextStyle? style) {
    final value = format(minorUnits);
    final symbol = value.startsWith('\u20B1') ? '\u20B1' : '';
    return TextSpan(
      children: [
        if (symbol.isNotEmpty)
          TextSpan(
            text: symbol,
            style: style?.copyWith(
              fontFamily: AppTypography.notoSans,
              fontFamilyFallback: AppTypography.kPesoFallback,
            ),
          ),
        TextSpan(text: value.substring(symbol.length), style: style),
      ],
    );
  }

  /// Builds an [InlineSpan] for a sentence containing a single price, e.g.
  /// `"Add {amount} more for free shipping"`. Render with [Text.rich].
  static InlineSpan template(
    String template,
    int amount, [
    TextStyle? style,
  ]) {
    final marker = '{amount}';
    final parts = template.split(marker);
    final children = <InlineSpan>[];
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        children.add(TextSpan(text: parts[i], style: style));
      }
      if (i < parts.length - 1) {
        children.add(span(amount, style));
      }
    }
    return TextSpan(children: children);
  }
}
