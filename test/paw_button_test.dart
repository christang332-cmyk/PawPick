import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawpick/core/colors.dart';
import 'package:pawpick/core/utils/money.dart';
import 'package:pawpick/core/widgets/paw_widgets.dart';

void main() {
  double contrastRatio(Color foreground, Color background) {
    final first = foreground.computeLuminance();
    final second = background.computeLuminance();
    final lighter = first > second ? first : second;
    final darker = first > second ? second : first;
    return (lighter + 0.05) / (darker + 0.05);
  }

  test('button variants meet WCAG AA contrast', () {
    for (final brightness in Brightness.values) {
      for (final variant in PawButtonVariant.values) {
        final effectiveVariant = variant;
        final style = AppButtonStyles.buttonStyle(effectiveVariant);
        for (final states in [
          <WidgetState>{},
          <WidgetState>{WidgetState.pressed},
          <WidgetState>{WidgetState.focused},
          <WidgetState>{WidgetState.hovered},
        ]) {
          final foreground = style.foregroundColor!.resolve(states)!;
          final background = style.backgroundColor!.resolve(states)!;
          final overlay = style.overlayColor!.resolve(states)!;
          final surface = AppButtonStyles.contrastSurface(effectiveVariant);
          final effectiveBackground = Color.alphaBlend(
            overlay,
            Color.alphaBlend(background, surface),
          );
          expect(
            contrastRatio(foreground, effectiveBackground),
            greaterThanOrEqualTo(4.5),
            reason: '$brightness $effectiveVariant $states',
          );
          expect(
            foreground,
            AppButtonStyles.foreground(effectiveVariant),
            reason: '$effectiveVariant foreground changes in $states',
          );
        }

        final disabledStates = <WidgetState>{WidgetState.disabled};
        final disabledForeground =
            style.foregroundColor!.resolve(disabledStates)!;
        final disabledBackground =
            style.backgroundColor!.resolve(disabledStates)!;
        expect(
          contrastRatio(disabledForeground, disabledBackground),
          greaterThanOrEqualTo(3),
          reason: '$brightness $effectiveVariant disabled',
        );
        if (variant == PawButtonVariant.outline ||
            variant == PawButtonVariant.text ||
            variant == PawButtonVariant.google) {
          final foreground = AppButtonStyles.foreground(effectiveVariant);
          for (final surface in [AppColors.cream, AppColors.white]) {
            expect(
              contrastRatio(foreground, surface),
              greaterThanOrEqualTo(4.5),
              reason: '$effectiveVariant on surface $surface',
            );
          }
        }
      }
    }
  });

  testWidgets('text and icon buttons stay readable in system dark mode',
      (tester) async {
    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.white,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.blue,
        onPrimary: AppColors.white,
        surface: AppColors.white,
        onSurface: AppColors.ink,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: darkTheme,
        themeMode: ThemeMode.dark,
        home: Scaffold(
          body: Column(
            children: [
              PawButton(
                label: 'Text action',
                variant: PawButtonVariant.text,
                onPressed: () {},
              ),
              const PawIconButton(
                icon: Icons.arrow_back,
                tooltip: 'Back',
                onPressed: null,
              ),
            ],
          ),
        ),
      ),
    );

    expect(darkTheme.scaffoldBackgroundColor, AppColors.white);
    final buttonText = tester.widget<RichText>(find.byType(RichText).first);
    expect((buttonText.text as TextSpan).style?.color, AppColors.blue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PawButton keeps long labels centered and single-line',
      (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 220,
                child: PawButton(
                  label: 'Add to cart · ₱1,500.00',
                  onPressed: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('Add to cart · ₱1,500.00'));
    expect(text.textAlign, TextAlign.center);
    expect(text.maxLines, 1);
    expect(text.softWrap, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('variant foreground overrides explicit rich price colors',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PawButton(
            label: 'Price button',
            labelWidget: Text.rich(
              Money.span(150000, const TextStyle(color: AppColors.ink)),
            ),
            onPressed: () {},
          ),
        ),
      ),
    );

    final text = tester.widget<RichText>(find.byType(RichText).first);
    final root = text.text as TextSpan;
    expect(root.style?.color, AppColors.white);
    for (final span in root.children!.whereType<TextSpan>()) {
      expect(span.style?.color, AppColors.white);
    }
  });

  testWidgets('PawButton stays compact in tall and unbounded parents',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<void> expectHeight(Widget app) async {
      await tester.pumpWidget(app);
      final buttons = find.byType(PawButton);
      expect(buttons, findsWidgets);
      for (var index = 0; index < buttons.evaluate().length; index++) {
        expect(
          tester.getSize(buttons.at(index)).height,
          inInclusiveRange(44, 64),
        );
      }
      expect(tester.takeException(), isNull);
    }

    await expectHeight(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: SafeArea(
            child: Row(
              children: [
                const SizedBox(width: 120, height: 52),
                const SizedBox(width: 12),
                Expanded(
                  child: PawButton(label: 'Add to cart', onPressed: () {}),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await expectHeight(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: PawButton(
                      label: 'Keep order',
                      isOutlined: true,
                      onPressed: () {},
                    ),
                  ),
                  Expanded(
                    child: PawButton(label: 'Cancel order', onPressed: () {}),
                  ),
                ],
              ),
              PawButton(label: 'Stacked', onPressed: () {}),
            ],
          ),
        ),
      ),
    );

    await expectHeight(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned(
                left: 16,
                right: 16,
                bottom: 0,
                child: PawButton(label: 'Bottom action', onPressed: () {}),
              ),
            ],
          ),
        ),
      ),
    );

    await expectHeight(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              SizedBox(
                height: 800,
                child: Center(
                  child: PawButton(label: 'Tall parent', onPressed: () {}),
                ),
              ),
              PawButton(label: 'Unbounded list item', onPressed: () {}),
            ],
          ),
        ),
      ),
    );
  });

  testWidgets('PawButton stays compact in sheets and dialogs', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                TextButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    builder: (_) => const SizedBox(
                      height: 240,
                      child: Center(
                        child:
                            PawButton(label: 'Sheet action', onPressed: null),
                      ),
                    ),
                  ),
                  child: const Text('Open sheet'),
                ),
                TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => AlertDialog(
                      actions: [
                        PawButton(label: 'Dialog action', onPressed: null),
                      ],
                    ),
                  ),
                  child: const Text('Open dialog'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(PawButton)).height,
        inInclusiveRange(44, 64));

    Navigator.of(tester.element(find.byType(PawButton))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open dialog'));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(PawButton)).height,
        inInclusiveRange(44, 64));
    expect(tester.takeException(), isNull);
  });

  testWidgets('PawButton stays compact at 1.5x on phone-sized screens',
      (tester) async {
    for (final size in [const Size(360, 640), const Size(412, 915)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 240,
                  child: PawButton(
                    label: 'Add to cart · ₱1,500.00',
                    onPressed: null,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(PawButton)).height,
          inInclusiveRange(44, 64));
      expect(tester.takeException(), isNull);
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
