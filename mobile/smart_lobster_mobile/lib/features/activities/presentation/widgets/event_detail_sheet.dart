import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../models/farm_event.dart';
import '../farm_event_ui.dart';

class EventDetailSheet extends StatelessWidget {
  const EventDetailSheet({super.key, required this.event});

  final FarmEvent event;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                  child: Icon(
                    event.type.icon,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Detail Aktivitas',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _DetailRow(label: 'Jenis Aktivitas', value: event.type.label),
            _DetailRow(
              label: 'Tanggal',
              value: DateFormat(
                'dd MMMM yyyy',
                'id_ID',
              ).format(event.timestamp),
            ),
            _DetailRow(
              label: 'Waktu',
              value: DateFormat('HH:mm', 'id_ID').format(event.timestamp),
            ),
            if (event.cellId != null)
              _DetailRow(label: 'Cell / Apartemen', value: event.cellId!),
            if (event.metadata != null)
              for (final entry in event.metadata!.entries)
                _DetailRow(
                  label: _metadataLabel(entry.key),
                  value: _metadataValue(entry.key, entry.value),
                ),
            if (event.note != null)
              _DetailRow(label: 'Catatan', value: event.note!),
          ],
        ),
      ),
    );
  }

  String _metadataLabel(String key) {
    return switch (key) {
      'amount_gram' => 'Jumlah Pakan',
      'percentage' => 'Persentase Ganti Air',
      'volume_liter' => 'Volume Tambah Air',
      _ => key.replaceAll('_', ' '),
    };
  }

  String _metadataValue(String key, Object? value) {
    return switch (key) {
      'amount_gram' => '$value gram',
      'percentage' => '$value%',
      'volume_liter' => '$value liter',
      _ => '$value',
    };
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xxs),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
