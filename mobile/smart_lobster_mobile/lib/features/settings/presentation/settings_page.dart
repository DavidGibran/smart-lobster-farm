import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const _items = [
    (
      title: 'Perangkat IoT',
      subtitle: 'Informasi perangkat dan koneksi sensor',
      icon: Icons.memory_outlined,
    ),
    (
      title: 'Parameter & Baseline',
      subtitle: 'Lihat acuan kondisi air yang digunakan',
      icon: Icons.tune_rounded,
    ),
    (
      title: 'Informasi Farm',
      subtitle: 'Profil Kampoeng Oase Ondomohen',
      icon: Icons.location_on_outlined,
    ),
    (
      title: 'Tentang Aplikasi',
      subtitle: 'Informasi Smart Lobster Farming',
      icon: Icons.info_outline_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey('settings-scroll'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: [
        Text('Pengaturan', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Kelola informasi aplikasi dan perangkat.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        for (var index = 0; index < _items.length; index++) ...[
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Icon(
                  _items[index].icon,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              title: Text(_items[index].title),
              subtitle: Text(_items[index].subtitle),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showPlaceholderMessage(context),
            ),
          ),
          if (index != _items.length - 1) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  void _showPlaceholderMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Konfigurasi belum tersedia pada versi ini.'),
      ),
    );
  }
}
