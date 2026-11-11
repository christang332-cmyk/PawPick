import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/animated/animated_widgets.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../core/widgets/paw_widgets.dart';
import '../../../data/local_store.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = PageController();
  int page = 0;

  static const slides = [
    (
      title: 'Little things,\nbig joy.',
      message: 'Thoughtful accessories picked for every paw and personality.',
      icon: Icons.pets_rounded,
      color: AppColors.sky,
    ),
    (
      title: 'Made for\nhappy tails.',
      message: 'Pet-safe materials, cozy comfort, and playtime-ready details.',
      icon: Icons.favorite_rounded,
      color: AppColors.pink,
    ),
    (
      title: 'Pick joy,\nshare joy.',
      message: 'Find your new favorite, then make every day a little brighter.',
      icon: Icons.shopping_bag_rounded,
      color: AppColors.yellow,
    ),
  ];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> finish() async {
    await LocalStore.completeOnboarding();
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: BrandLogo(size: 48, showWordmark: true),
              ),
              Expanded(
                child: PageView.builder(
                  controller: controller,
                  itemCount: slides.length,
                  onPageChanged: (value) => setState(() => page = value),
                  itemBuilder: (context, index) {
                    final item = slides[index];
                    return StaggeredEntrance(
                      key: ValueKey(index),
                      child: SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 340),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 88,
                                backgroundColor: item.color,
                                child: Icon(item.icon, size: 76, color: AppColors.ink),
                              ),
                              const SizedBox(height: 28),
                              Text(
                                item.title,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.displaySmall,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                item.message,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: AppColors.muted,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  slides.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: index == page ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == page ? AppColors.blue : AppColors.line,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              PawButton(
                label: page == slides.length - 1 ? 'Start exploring' : 'Next',
                onPressed: () {
                  if (page == slides.length - 1) {
                    finish();
                  } else {
                    controller.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                    );
                  }
                },
              ),
              PawButton(
                label: 'Skip',
                variant: PawButtonVariant.text,
                height: 48,
                onPressed: finish,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
