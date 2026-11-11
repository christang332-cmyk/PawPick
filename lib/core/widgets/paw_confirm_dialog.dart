import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'paw_widgets.dart';

class PawConfirmDialog extends StatelessWidget {
  const PawConfirmDialog({
    required this.title,
    required this.message,
    this.confirmLabel = 'Remove',
    super.key,
  });

  final String title;
  final String message;
  final String confirmLabel;

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Remove',
  }) async {
    return await showModalBottomSheet<bool>(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => PawConfirmDialog(
            title: title,
            message: message,
            confirmLabel: confirmLabel,
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(message),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: PawButton(
                    label: 'Keep it',
                    isOutlined: true,
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PawButton(
                    label: confirmLabel,
                    variant: PawButtonVariant.dangerFilled,
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
