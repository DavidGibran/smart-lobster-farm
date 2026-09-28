import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../models/farm_event.dart';
import '../../models/farm_event_type.dart';
import '../farm_event_ui.dart';

class RecentEventCard extends StatelessWidget {
  const RecentEventCard({super.key, required this.event, required this.onTap});

  final FarmEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final detail = _eventDetail(event);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.type.label,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      DateFormat(
                        'dd MMM yyyy · HH:mm',
                        'id_ID',
                      ).format(event.timestamp),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (detail != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(detail),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }

  String? _eventDetail(FarmEvent event) {
    final metadata = event.metadata;
    final metadataDetail = metadata == null
        ? null
        : switch (event.type) {
            FarmEventType.feeding => _numberWithUnit(
              metadata['amount_gram'],
              'gram',
            ),
            FarmEventType.waterChange => _numberWithUnit(
              metadata['percentage'],
              '%',
              space: false,
            ),
            FarmEventType.waterAddition => _numberWithUnit(
              metadata['volume_liter'],
              'liter',
            ),
            _ => null,
          };
    final details = [
      if (metadataDetail != null) metadataDetail,
      if (event.cellId != null) 'Apartemen ${event.cellId}',
    ];
    return switch (details) {
      [] => event.note,
      _ => details.join(' • '),
    };
  }

  String? _numberWithUnit(Object? value, String unit, {bool space = true}) {
    if (value == null) return null;
    return '$value${space ? ' ' : ''}$unit';
  }
}
