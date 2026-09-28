import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/empty_state_card.dart';

class ActivityLoadingCard extends StatelessWidget {
  const ActivityLoadingCard({super.key});

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
            Expanded(child: Text('Memuat aktivitas terbaru...')),
          ],
        ),
      ),
    );
  }
}

class ActivityEmptyCard extends StatelessWidget {
  const ActivityEmptyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyStateCard(
      icon: Icons.event_note_outlined,
      title: 'Belum ada aktivitas tercatat.',
      description: 'Aktivitas yang disimpan akan muncul di sini.',
    );
  }
}

class ActivityErrorCard extends StatelessWidget {
  const ActivityErrorCard({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 36,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Gagal memuat aktivitas.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
