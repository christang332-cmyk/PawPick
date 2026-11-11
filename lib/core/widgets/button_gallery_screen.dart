import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../colors.dart';
import 'paw_widgets.dart';

class ButtonGalleryScreen extends StatelessWidget {
  const ButtonGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(title: const Text('Button gallery')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final surface in _surfaces) _SurfaceGallery(surface: surface),
        ],
      ),
    );
  }
}

class _GallerySurface {
  const _GallerySurface(this.name, this.color, {this.dark = false});

  final String name;
  final Color color;
  final bool dark;
}

const _surfaces = [
  _GallerySurface('Cream', AppColors.cream),
  _GallerySurface('White', AppColors.white),
  _GallerySurface('Tinted', AppColors.palePink),
  _GallerySurface('Dark', AppButtonStyles.darkSurface, dark: true),
];

class _SurfaceGallery extends StatelessWidget {
  const _SurfaceGallery({required this.surface});

  final _GallerySurface surface;

  @override
  Widget build(BuildContext context) {
    final variants = PawButtonVariant.values.where(
      (variant) => variant != PawButtonVariant.onDark || surface.dark,
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            surface.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: surface.dark ? AppColors.white : AppColors.ink,
                ),
          ),
          for (final variant in variants) ...[
            ..._variantGallery(context, variant),
          ],
        ],
      ),
    );
  }

  List<Widget> _variantGallery(
    BuildContext context,
    PawButtonVariant variant,
  ) {
    final effectiveVariant = surface.dark && variant == PawButtonVariant.text
        ? PawButtonVariant.onDark
        : variant;
    return [
            const SizedBox(height: 12),
            Text(
              effectiveVariant.name,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: surface.dark ? AppColors.white : AppColors.ink,
                  ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: 170,
                  child: PawButton(
                    label: 'Normal',
                    variant: effectiveVariant,
                    onPressed: () {},
                  ),
                ),
                SizedBox(
                  width: 170,
                  child: PawButton(
                    label: 'With icon',
                    icon: Icons.pets_rounded,
                    variant: effectiveVariant,
                    onPressed: () {},
                  ),
                ),
                SizedBox(
                  width: 170,
                  child: PawButton(
                    label: 'Loading',
                    variant: effectiveVariant,
                    isLoading: true,
                    onPressed: () {},
                  ),
                ),
                SizedBox(
                  width: 170,
                  child: PawButton(
                    label: 'Disabled',
                    variant: effectiveVariant,
                    onPressed: null,
                  ),
                ),
                SizedBox(
                  width: 170,
                  child: PawButton(
                    label: 'Press and hold',
                    variant: effectiveVariant,
                    onPressed: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: PawButton(
                    label: 'First',
                    variant: effectiveVariant,
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PawButton(
                    label: 'Second',
                    variant: effectiveVariant,
                    onPressed: () {},
                  ),
                ),
              ],
            ),
    ];
  }
}
