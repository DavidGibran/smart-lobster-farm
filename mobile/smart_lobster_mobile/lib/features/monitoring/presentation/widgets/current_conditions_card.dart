import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../models/sensor_reading.dart';

class CurrentConditionsCard extends StatelessWidget {
  const CurrentConditionsCard({super.key, required this.latestStream});

  final Stream<SensorReading> latestStream;

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
                Icon(
                  Icons.sensors_outlined,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Kondisi terakhir',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            StreamBuilder<SensorReading>(
              stream: latestStream,
              builder: (context, snapshot) {
                final reading = snapshot.data;
                if (reading == null) {
                  return Row(
                    children: [
                      if (!snapshot.hasError) ...[
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      const Expanded(
                        child: Text('Data terbaru belum tersedia.'),
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    _CurrentValue(
                      label: 'pH',
                      value: reading.ph.toStringAsFixed(2),
                    ),
                    _CurrentValue(
                      label: 'TDS',
                      value: '${reading.tds.toStringAsFixed(0)} ppm',
                    ),
                    _CurrentValue(
                      label: 'Suhu',
                      value: '${reading.temperature.toStringAsFixed(1)} °C',
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentValue extends StatelessWidget {
  const _CurrentValue({required this.label, required this.value});

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
