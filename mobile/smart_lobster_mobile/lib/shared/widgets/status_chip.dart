import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/sensor_condition.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.level});

  final String label;
  final SensorStatusLevel level;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(level);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: palette.foreground,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.foreground,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ({Color foreground, Color background}) _paletteFor(SensorStatusLevel status) {
    return switch (status) {
      SensorStatusLevel.ideal => (
        foreground: AppColors.success,
        background: AppColors.successContainer,
      ),
      SensorStatusLevel.attention => (
        foreground: AppColors.attention,
        background: AppColors.attentionContainer,
      ),
      SensorStatusLevel.danger => (
        foreground: AppColors.danger,
        background: AppColors.dangerContainer,
      ),
      SensorStatusLevel.reference => (
        foreground: AppColors.reference,
        background: AppColors.referenceContainer,
      ),
      SensorStatusLevel.neutral => (
        foreground: AppColors.neutral,
        background: AppColors.neutralContainer,
      ),
    };
  }
}
