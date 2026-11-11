import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/motion.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../data/local_store.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: AppMotion.splashDuration,
    )..forward();
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        context.go(LocalStore.onboardingComplete ? '/home' : '/onboarding');
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      return _SplashLayout(progress: 1, logoScale: 1, textOpacity: 1);
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final value = controller.value;
        return _SplashLayout(
          progress: Curves.easeInOut.transform(value),
          logoScale: CurvedAnimation(
            parent: controller,
            curve: const Interval(0, .35, curve: AppMotion.springCurve),
          ).value,
          textOpacity: Curves.easeOut.transform(
            const Interval(.35, .65).transform(value),
          ),
        );
      },
    );
  }
}

class _SplashLayout extends StatelessWidget {
  const _SplashLayout({
    required this.progress,
    required this.logoScale,
    required this.textOpacity,
  });

  final double progress;
  final double logoScale;
  final double textOpacity;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          Positioned(
            top: -90,
            right: -80,
            child: _Blob(
              color: AppColors.sky.withValues(alpha: .55),
              size: 260,
            ),
          ),
          Positioned(
            top: 210,
            left: -100,
            child: _Blob(
              color: AppColors.pink.withValues(alpha: .4),
              size: 220,
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.rotate(
                  angle: math.sin(progress * math.pi * 8) * .035,
                  child: Transform.scale(
                    scale: logoScale.clamp(0, 1.1),
                    child: const Hero(
                      tag: 'pawpick-logo',
                      child: BrandLogo(size: 132),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Opacity(
                  opacity: textOpacity.clamp(0, 1),
                  child: Transform.translate(
                    offset: Offset(0, 18 * (1 - textOpacity)),
                    child: Column(
                      children: [
                        Text(
                          'PawPick',
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(color: AppColors.blue),
                        ),
                        const SizedBox(height: 6),
                        const Text('Little things. Big joy.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _SplashFooter(progress: progress),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: SizedBox(width: size, height: size),
    );
  }
}

class _SplashFooter extends StatelessWidget {
  const _SplashFooter({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WavePainter(progress),
      child: SizedBox(
        height: 126,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 54, 32, 28),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  4,
                  (index) => Opacity(
                    opacity: (progress * 5 - index).clamp(0, 1),
                    child: const Icon(
                      Icons.pets_rounded,
                      size: 18,
                      color: AppColors.blue,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: AppColors.white.withValues(alpha: .55),
                  color: AppColors.blue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  const _WavePainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 32)
      ..quadraticBezierTo(size.width * .25, 0, size.width * .5, 28)
      ..quadraticBezierTo(size.width * .75, 56, size.width, 22)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = AppColors.sky.withValues(alpha: .9 * progress),
    );
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) => oldDelegate.progress != progress;
}
