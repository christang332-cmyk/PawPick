import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/button_styles.dart';
import '../../app/theme.dart';
import '../utils/money.dart';

export '../../app/button_styles.dart' show AppButtonStyles, PawButtonVariant;

class PawButton extends StatefulWidget {
  const PawButton({
    this.label,
    required this.onPressed,
    this.icon,
    this.labelWidget,
    this.isOutlined = false,
    this.isSoft = false,
    this.variant,
    this.isLoading = false,
    this.height = 52,
    this.expand = true,
    super.key,
  }) : assert(label != null || labelWidget != null,
            'Provide either label or labelWidget');

  final String? label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? labelWidget;
  final bool isOutlined;
  final bool isSoft;
  final PawButtonVariant? variant;
  final bool isLoading;
  final double height;
  final bool expand;

  @override
  State<PawButton> createState() => _PawButtonState();
}

class _PawButtonState extends State<PawButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final requestedVariant = widget.variant ??
        (widget.isOutlined
            ? PawButtonVariant.outline
            : widget.isSoft
                ? PawButtonVariant.soft
                : PawButtonVariant.filled);
    final resolved = requestedVariant;
    final disabled = widget.onPressed == null;
    final interactionBlocked = disabled || widget.isLoading;

    final labelContent = widget.isLoading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppButtonStyles.foreground(resolved, disabled: disabled),
            ),
          )
        : widget.labelWidget ??
            Text(
              widget.label ?? '',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            );
    final foreground = AppButtonStyles.foreground(resolved, disabled: disabled);
    final buttonStyle = AppButtonStyles.buttonStyle(resolved).copyWith(
      minimumSize: WidgetStatePropertyAll(Size(0, widget.height)),
      maximumSize: WidgetStatePropertyAll(Size(double.infinity, widget.height)),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    final normalizedLabel = _applyForegroundColor(labelContent, foreground);
    final buttonChild =
        widget.icon == null && resolved != PawButtonVariant.google
            ? normalizedLabel
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (resolved == PawButtonVariant.google) ...[
                    SvgPicture.asset(
                      'assets/branding/google_g.svg',
                      width: 20,
                      height: 20,
                    ),
                    const SizedBox(width: 10),
                  ] else if (widget.icon != null) ...[
                    Icon(widget.icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Flexible(child: normalizedLabel),
                ],
              );

    final content = Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: DefaultTextStyle(
          style: Theme.of(context).textTheme.labelLarge!.copyWith(
                color: foreground,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
          textAlign: TextAlign.center,
          maxLines: 1,
          softWrap: false,
          child: buttonChild,
        ),
      ),
    );

    return _PawButtonHeightGuard(
      child: Listener(
        onPointerDown: interactionBlocked
            ? null
            : (_) {
                HapticFeedback.selectionClick();
                setState(() => _pressed = true);
              },
        onPointerUp:
            interactionBlocked ? null : (_) => setState(() => _pressed = false),
        onPointerCancel: interactionBlocked
            ? null
            : (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: const Duration(milliseconds: 100),
          child: SizedBox(
            width: widget.expand ? double.infinity : null,
            height: widget.height,
            child: IgnorePointer(
              ignoring: widget.isLoading,
              child: _buildMaterialButton(
                resolved,
                buttonStyle,
                content,
                disabled,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialButton(
    PawButtonVariant variant,
    ButtonStyle style,
    Widget child,
    bool disabled,
  ) {
    final callback = disabled ? null : widget.onPressed;
    return switch (variant) {
      PawButtonVariant.filled ||
      PawButtonVariant.soft ||
      PawButtonVariant.danger ||
      PawButtonVariant.dangerFilled =>
        FilledButton(onPressed: callback, style: style, child: child),
      PawButtonVariant.google => OutlinedButton(
          onPressed: callback,
          style: style.copyWith(
            elevation: const WidgetStatePropertyAll(1),
            shadowColor:
                WidgetStatePropertyAll(Colors.black.withValues(alpha: 0.10)),
          ),
          child: child,
        ),
      PawButtonVariant.outline =>
        OutlinedButton(onPressed: callback, style: style, child: child),
      PawButtonVariant.text =>
        TextButton(onPressed: callback, style: style, child: child),
      PawButtonVariant.onDark =>
        TextButton(onPressed: callback, style: style, child: child),
    };
  }

  Widget _applyForegroundColor(Widget child, Color color) {
    if (child is Text) {
      final span = child.textSpan;
      if (span != null) {
        return Text.rich(
          _applySpanColor(span, color),
          style: child.style?.copyWith(color: color) ?? TextStyle(color: color),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          textScaler: child.textScaler,
          textWidthBasis: child.textWidthBasis,
          textHeightBehavior: child.textHeightBehavior,
          semanticsLabel: child.semanticsLabel,
          locale: child.locale,
          strutStyle: child.strutStyle,
        );
      }
      return Text(
        child.data ?? '',
        style: child.style?.copyWith(color: color) ?? TextStyle(color: color),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        textScaler: child.textScaler,
        textWidthBasis: child.textWidthBasis,
        textHeightBehavior: child.textHeightBehavior,
        semanticsLabel: child.semanticsLabel,
        locale: child.locale,
        strutStyle: child.strutStyle,
      );
    }
    return child;
  }

  InlineSpan _applySpanColor(InlineSpan span, Color color) {
    if (span is! TextSpan) return span;
    return TextSpan(
      text: span.text,
      style: (span.style ?? const TextStyle()).copyWith(color: color),
      children: span.children
          ?.map((child) => _applySpanColor(child, color))
          .toList(growable: false),
    );
  }
}

class _PawButtonHeightGuard extends SingleChildRenderObjectWidget {
  const _PawButtonHeightGuard({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderPawButtonHeightGuard();
}

class _RenderPawButtonHeightGuard extends RenderProxyBox {
  @override
  void performLayout() {
    super.performLayout();
    assert(() {
      if (size.height > 64) {
        debugPrint(
          'PawButton rendered height ${size.height} exceeds 64; '
          'parent constraints: $constraints',
        );
        return false;
      }
      return true;
    }());
  }
}

class PawIconButton extends StatelessWidget {
  const PawIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.variant = PawButtonVariant.outline,
    this.size = 48,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final PawButtonVariant variant;
  final double size;

  @override
  Widget build(BuildContext context) {
    final effectiveVariant = variant;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        foregroundColor: AppButtonStyles.foreground(
          effectiveVariant,
          disabled: onPressed == null,
        ),
        backgroundColor: AppButtonStyles.background(
          effectiveVariant,
          disabled: onPressed == null,
        ),
        disabledForegroundColor: AppButtonStyles.disabledForeground,
        disabledBackgroundColor: AppButtonStyles.disabledBackground,
        minimumSize: Size(size, size),
        maximumSize: Size(size, size),
        shape: const CircleBorder(),
        overlayColor: AppButtonStyles.foreground(effectiveVariant)
            .withValues(alpha: 0.08),
      ),
      icon: Icon(icon),
    );
  }
}

class PawChip extends StatelessWidget {
  const PawChip({required this.label, this.color = AppColors.blue, super.key});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
      ),
    );
  }
}

class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
    this.min = 1,
    this.max = 10,
    super.key,
  });

  final int value;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove_rounded,
            enabled: onDecrement != null && value > min,
            onPressed: onDecrement,
            tooltip: 'Decrease quantity',
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Padding(
              key: ValueKey(value),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '$value',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
          _StepperButton(
            icon: Icons.add_rounded,
            enabled: onIncrement != null && value < max,
            onPressed: onIncrement,
            tooltip: 'Increase quantity',
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return PawIconButton(
      onPressed: enabled
          ? () {
              HapticFeedback.selectionClick();
              onPressed?.call();
            }
          : null,
      tooltip: tooltip,
      size: 44,
      icon: icon,
    );
  }
}

class PriceText extends StatelessWidget {
  const PriceText({
    this.amount,
    this.originalAmount,
    this.price,
    this.originalPrice,
    this.style,
    super.key,
  });

  final int? amount;
  final int? originalAmount;
  final String? price;
  final TextStyle? style;
  final String? originalPrice;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          amount != null
              ? Money.span(
                  amount!, style ?? Theme.of(context).textTheme.titleLarge)
              : TextSpan(
                  text: price ?? '',
                  style: style ?? Theme.of(context).textTheme.titleLarge),
        ),
        if (originalPrice != null) ...[
          const SizedBox(width: 8),
          Text(
            originalPrice!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  decoration: TextDecoration.lineThrough,
                ),
          ),
        ],
        if (originalAmount != null)
          Text.rich(
            Money.span(
              originalAmount!,
              (style ?? Theme.of(context).textTheme.bodySmall)?.copyWith(
                color: AppColors.muted,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, required this.onSeeAll, super.key});

  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        PawButton(
          label: 'See all',
          variant: PawButtonVariant.text,
          expand: false,
          height: 44,
          onPressed: onSeeAll,
        ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: AppColors.blue),
          const SizedBox(height: 14),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                ),
          ),
          if (action != null) ...[
            const SizedBox(height: 16),
            action!,
          ],
        ],
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    required this.title,
    required this.message,
    super.key,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PawPick')),
      body: Center(
        child: EmptyState(
          icon: Icons.pets_rounded,
          title: title,
          message: message,
        ),
      ),
    );
  }
}
