import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../models/monitoring_history.dart';

class HistoryOverviewCard extends StatelessWidget {
  const HistoryOverviewCard({super.key, required this.history});

  final MonitoringHistory history;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd MMM yyyy, HH.mm', 'id_ID');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            _OverviewRow(
              label: 'Jumlah Data',
              value: '${history.dataPointCount}',
            ),
            const SizedBox(height: AppSpacing.xs),
            _OverviewRow(
              label: 'Waktu Awal',
              value: formatter.format(history.firstTimestamp!),
            ),
            const SizedBox(height: AppSpacing.xs),
            _OverviewRow(
              label: 'Waktu Terakhir',
              value: formatter.format(history.lastTimestamp!),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewRow extends StatelessWidget {
  const _OverviewRow({required this.label, required this.value});

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
