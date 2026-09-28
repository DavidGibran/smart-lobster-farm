import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../models/sensor_condition.dart';
import '../../../models/sensor_reading.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/empty_state_card.dart';
import '../../../shared/widgets/info_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/sensor_card.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.sensorStream});

  final Stream<SensorReading> sensorStream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SensorReading>(
      stream: sensorStream,
      builder: (context, snapshot) {
        final reading = snapshot.data;
        final isOnline = reading != null && !snapshot.hasError;

        return ListView(
          key: const PageStorageKey('dashboard-scroll'),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          children: [
            AppHeader(
              title: 'Smart Lobster Farming',
              subtitle: 'Kampoeng Oase Ondomohen',
              deviceLabel: 'Perangkat Oase 01',
              statusLabel: isOnline ? 'Sistem Online' : 'Menghubungkan',
              statusLevel: isOnline
                  ? SensorStatusLevel.ideal
                  : SensorStatusLevel.neutral,
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(
              title: 'Kondisi Air',
              description: 'Data terbaru dari perangkat Oase 01',
            ),
            const SizedBox(height: AppSpacing.md),
            if (snapshot.hasError)
              const EmptyStateCard(
                icon: Icons.cloud_off_outlined,
                title: 'Data sensor tidak dapat dibaca',
                description:
                    'Periksa koneksi perangkat. Pembacaan realtime akan '
                    'dilanjutkan secara otomatis.',
              )
            else if (reading == null)
              const _SensorLoadingCard()
            else ...[
              _SensorGrid(reading: reading),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: 'Ringkasan Kondisi'),
              const SizedBox(height: AppSpacing.md),
              _ConditionSummary(reading: reading),
            ],
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(title: 'Prediksi AI'),
            const SizedBox(height: AppSpacing.md),
            const EmptyStateCard(
              icon: Icons.insights_outlined,
              title: 'Prediksi belum tersedia',
              description:
                  'Model akan aktif setelah histori sensor yang cukup telah '
                  'terkumpul.',
              badge: 'Random Forest',
            ),
          ],
        );
      },
    );
  }
}

class _SensorGrid extends StatelessWidget {
  const _SensorGrid({required this.reading});

  final SensorReading reading;

  @override
  Widget build(BuildContext context) {
    final cards = [
      SensorCard(
        icon: Icons.science_outlined,
        label: 'pH Air',
        value: reading.ph.toStringAsFixed(2),
        condition: SensorConditionEvaluator.ph(reading.ph),
        subtitle: 'Ideal 7.0–8.0',
      ),
      SensorCard(
        icon: Icons.water_drop_outlined,
        label: 'TDS',
        value: reading.tds.toStringAsFixed(0),
        unit: 'ppm',
        condition: SensorConditionEvaluator.tds(reading.tds),
        subtitle: 'Referensi RAS 320–400 ppm',
      ),
      SensorCard(
        icon: Icons.thermostat_outlined,
        label: 'Suhu Air',
        value: reading.temperature.toStringAsFixed(1),
        unit: '°C',
        condition: SensorConditionEvaluator.temperature(reading.temperature),
        subtitle: 'Ideal 26–29°C',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = constraints.maxWidth >= 840
            ? 3
            : constraints.maxWidth >= 520
            ? 2
            : 1;
        const gap = AppSpacing.sm;
        final cardWidth =
            (constraints.maxWidth - (gap * (columnCount - 1))) / columnCount;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards) SizedBox(width: cardWidth, child: card),
          ],
        );
      },
    );
  }
}

class _ConditionSummary extends StatelessWidget {
  const _ConditionSummary({required this.reading});

  final SensorReading reading;

  @override
  Widget build(BuildContext context) {
    final conditions = [
      SensorConditionEvaluator.ph(reading.ph),
      SensorConditionEvaluator.tds(reading.tds),
      SensorConditionEvaluator.temperature(reading.temperature),
    ];
    final needsAttention = conditions.any(
      (condition) => condition.needsAttention,
    );

    return InfoCard(
      icon: needsAttention
          ? Icons.info_outline_rounded
          : Icons.check_circle_outline_rounded,
      title: needsAttention
          ? 'Beberapa parameter membutuhkan perhatian'
          : 'Kondisi air saat ini stabil',
      description: needsAttention
          ? 'Tinjau parameter yang ditandai sebelum melakukan tindakan.'
          : 'Seluruh parameter berada dalam baseline yang digunakan.',
      footer: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.schedule_outlined, size: 16),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              'Terakhir diperbarui: ${_formatTimestamp(reading.timestamp)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${DateFormat('dd MMM yyyy, HH.mm', 'id_ID').format(timestamp)} WIB';
  }
}

class _SensorLoadingCard extends StatelessWidget {
  const _SensorLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(child: Text('Menghubungkan ke sensor realtime...')),
          ],
        ),
      ),
    );
  }
}
