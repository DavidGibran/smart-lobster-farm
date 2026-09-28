import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/empty_state_card.dart';

class MonitoringLoadingCard extends StatelessWidget {
  const MonitoringLoadingCard({super.key});

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
            Expanded(child: Text('Memuat histori sensor...')),
          ],
        ),
      ),
    );
  }
}

class MonitoringErrorCard extends StatelessWidget {
  const MonitoringErrorCard({super.key, required this.onRetry});

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
              color: Theme.of(context).colorScheme.error,
              size: 36,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tidak dapat memuat histori sensor.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Periksa koneksi, lalu coba kembali.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
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

class MonitoringEmptyCard extends StatelessWidget {
  const MonitoringEmptyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyStateCard(
      icon: Icons.show_chart_rounded,
      title: 'Belum cukup data',
      description:
          'Data monitoring akan muncul setelah perangkat mulai merekam '
          'histori sensor.',
    );
  }
}
