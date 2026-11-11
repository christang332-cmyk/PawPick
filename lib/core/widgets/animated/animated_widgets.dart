import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/motion.dart';
import '../../../app/theme.dart';

class PressScale extends StatefulWidget {
  const PressScale({
    required this.child,
    required this.onPressed,
    this.scale = .96,
    super.key,
  });

  final Widget child;
  final VoidCallback onPressed;
  final double scale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onHighlightChanged: (value) => setState(() => pressed = value),
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onPressed();
        },
        child: AnimatedScale(
          scale: pressed ? widget.scale : 1,
          duration: AppMotion.fast,
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

class StaggeredEntrance extends StatefulWidget {
  const StaggeredEntrance({
    required this.child,
    this.index = 0,
    super.key,
  });

  final Widget child;
  final int index;

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: AppMotion.entrance)
      ..forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) return widget.child;
    return FadeTransition(
      opacity: CurvedAnimation(parent: controller, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, .08),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutCubic)),
        child: widget.child,
      ),
    );
  }
}

class CachedPawImage extends StatelessWidget {
  const CachedPawImage({
    required this.url,
    required this.width,
    required this.height,
    this.borderRadius = 18,
    super.key,
  });

  final String url;
  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : width;
        final pixelWidth =
            availableWidth.isFinite && availableWidth > 0
                ? (availableWidth * MediaQuery.devicePixelRatioOf(context))
                    .round()
                : null;
        final fallback = ColoredBox(
          color: AppColors.palePink,
          child: Center(
            child: Icon(Icons.pets_rounded, color: AppColors.blue, size: 38),
          ),
        );
        final image = url.startsWith('http')
            ? CachedNetworkImage(
                imageUrl: url,
                width: width,
                height: height,
                fit: BoxFit.cover,
                memCacheWidth: pixelWidth,
                placeholder: (_, __) => const LoadingShimmer(),
                errorWidget: (_, __, ___) => fallback,
              )
            : Image.asset(
                url,
                width: width,
                height: height,
                fit: BoxFit.cover,
                cacheWidth: pixelWidth,
                errorBuilder: (_, __, ___) => fallback,
              );
        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: image,
        );
      },
    );
  }
}

class LoadingShimmer extends StatefulWidget {
  const LoadingShimmer({super.key});

  @override
  State<LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-1 + controller.value * 2, 0),
            end: Alignment(controller.value * 2, 0),
            colors: const [
              AppColors.palePink,
              AppColors.white,
              AppColors.palePink,
            ],
          ),
        ),
      ),
    );
  }
}
