import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../models/hourly_sensor_summary.dart';
import '../../../../models/sensor_reading.dart';

class HistoryRecordCard extends StatelessWidget {
  const HistoryRecordCard._({
    required this.timestamp,
    required this.ph,
    required this.tds,
    required this.temperature,
    required this.isHourly,
    this.sampleCount,
  });

  factory HistoryRecordCard.raw(SensorReading reading) {
    return HistoryRecordCard._(
      timestamp: reading.timestamp,
      ph: reading.ph,
      tds: reading.tds,
      temperature: reading.temperature,
      isHourly: false,
      sampleCount: reading.sampleCount,
    );
  }

  factory HistoryRecordCard.hourly(HourlySensorSummary summary) {
    return HistoryRecordCard._(
      timestamp: summary.timestamp,
      ph: summary.phAvg,
      tds: summary.tdsAvg,
      temperature: summary.temperatureAvg,
      isHourly: true,
      sampleCount: summary.sampleCount,
    );
  }

  final DateTime timestamp;
  final double ph;
  final double tds;
  final double temperature;
  final bool isHourly;
  final int? sampleCount;

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
                Text(
                  DateFormat('HH:mm', 'id_ID').format(timestamp),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  DateFormat('dd MMM yyyy', 'id_ID').format(timestamp),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (isHourly) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Rata-rata per jam${_sampleCountLabel()}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Divider(),
            ),
            Row(
              children: [
                _SensorValue(label: 'pH', value: ph.toStringAsFixed(2)),
                _SensorValue(
                  label: 'TDS',
                  value: '${tds.toStringAsFixed(0)} ppm',
                ),
                _SensorValue(
                  label: 'Suhu',
                  value: '${temperature.toStringAsFixed(1)} °C',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _sampleCountLabel() {
    final count = sampleCount;
    return count == null || count <= 0 ? '' : ' • $count sampel';
  }
}

class _SensorValue extends StatelessWidget {
  const _SensorValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
