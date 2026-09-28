import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../models/monitoring_history.dart';
import '../../../../shared/widgets/sensor_summary_row.dart';

class HistorySummaryCard extends StatelessWidget {
  const HistorySummaryCard({super.key, required this.history});

  final MonitoringHistory history;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ringkasan', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            _InfoRow(label: 'Jumlah data', value: '${history.dataPointCount}'),
            const SizedBox(height: AppSpacing.xs),
            _InfoRow(
              label: 'Dari',
              value: formatter.format(history.firstTimestamp!),
            ),
            const SizedBox(height: AppSpacing.xs),
            _InfoRow(
              label: 'Sampai',
              value: formatter.format(history.lastTimestamp!),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Divider(),
            ),
            _MetricBlock(
              title: 'pH',
              child: SensorSummaryRow(summary: history.ph, decimalDigits: 2),
            ),
            const SizedBox(height: AppSpacing.md),
            _MetricBlock(
              title: 'TDS',
              child: SensorSummaryRow(
                summary: history.tds,
                decimalDigits: 1,
                unit: 'ppm',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _MetricBlock(
              title: 'Suhu',
              child: SensorSummaryRow(
                summary: history.temperature,
                decimalDigits: 1,
                unit: '°C',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}
