import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../models/monitoring_history.dart';

class SensorSummaryRow extends StatelessWidget {
  const SensorSummaryRow({
    super.key,
    required this.summary,
    required this.decimalDigits,
    this.unit = '',
  });

  final SensorMetricSummary summary;
  final int decimalDigits;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SummaryValue(label: 'Minimum', value: _format(summary.minimum)),
        _SummaryValue(label: 'Rata-rata', value: _format(summary.average)),
        _SummaryValue(label: 'Maksimum', value: _format(summary.maximum)),
      ],
    );
  }

  String _format(double value) {
    final suffix = unit.isEmpty ? '' : ' $unit';
    return '${value.toStringAsFixed(decimalDigits)}$suffix';
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
