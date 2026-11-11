import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pawpick/core/typography.dart';
import 'package:pawpick/core/utils/money.dart';

void main() {
  test('formats Philippine peso with separators and cents', () {
    expect(Money.format(129900), '₱1,299.00');
  });

  test('renders the peso glyph with the bundled fallback font', () {
    const style = TextStyle(fontSize: 18, fontWeight: FontWeight.w500);
    final span = Money.span(129900, style) as TextSpan;
    final symbol = span.children!.first as TextSpan;

    expect(symbol.text, '₱');
    expect(symbol.style?.fontFamily, AppTypography.notoSans);
    expect(symbol.style?.fontFamilyFallback, AppTypography.kPesoFallback);
  });
}
