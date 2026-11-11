import 'package:flutter/material.dart';

import '../../app/theme.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({
    this.size = 42,
    this.showWordmark = false,
    super.key,
  });

  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(size * .24),
      child: Image.asset(
        'assets/branding/logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        semanticLabel: 'PawPick logo',
      ),
    );
    if (!showWordmark) return image;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        image,
        const SizedBox(width: 8),
        Text(
          'PawPick',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.blue,
              ),
        ),
      ],
    );
  }
}
