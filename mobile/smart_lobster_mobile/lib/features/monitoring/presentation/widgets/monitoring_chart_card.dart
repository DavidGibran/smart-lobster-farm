import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../models/monitoring_period.dart';
import '../../../../shared/widgets/sensor_summary_row.dart';
import '../../models/monitoring_chart_series.dart';
import 'sensor_line_chart.dart';

class MonitoringChartCard extends StatelessWidget {
  const MonitoringChartCard({
    super.key,
    required this.icon,
    required this.title,
    required this.referenceLabel,
    required this.series,
    required this.period,
    required this.lineColor,
    required this.referenceMinimum,
    required this.referenceMaximum,
    required this.decimalDigits,
    this.unit = '',
    this.scaleMinimum,
    this.scaleMaximum,
  });

  final IconData icon;
  final String title;
  final String referenceLabel;
  final MonitoringChartSeries series;
  final MonitoringPeriod period;
  final Color lineColor;
  final double referenceMinimum;
  final double referenceMaximum;
  final double? scaleMinimum;
  final double? scaleMaximum;
  final int decimalDigits;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: lineColor),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (unit.isNotEmpty)
                  Text(unit, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Container(
                  width: 16,
                  height: 8,
                  decoration: BoxDecoration(
                    color: lineColor.withAlpha(24),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    referenceLabel,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              height: 230,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: SensorLineChart(
                points: series.points,
                period: period,
                lineColor: lineColor,
                referenceMinimum: referenceMinimum,
                referenceMaximum: referenceMaximum,
                scaleMinimum: scaleMinimum,
                scaleMaximum: scaleMaximum,
                decimalDigits: decimalDigits,
                unit: unit,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SensorSummaryRow(
              summary: series.summary,
              decimalDigits: decimalDigits,
              unit: unit,
            ),
          ],
        ),
      ),
    );
  }
}
