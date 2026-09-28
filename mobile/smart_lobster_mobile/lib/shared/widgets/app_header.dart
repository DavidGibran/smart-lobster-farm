import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../models/sensor_condition.dart';
import 'status_chip.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.deviceLabel,
    required this.statusLabel,
    required this.statusLevel,
    this.icon = Icons.water_drop_outlined,
  });

  final String title;
  final String subtitle;
  final String deviceLabel;
  final String statusLabel;
  final SensorStatusLevel statusLevel;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: Color.alphaBlend(
        colorScheme.primaryContainer.withAlpha(90),
        colorScheme.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 280) {
              return _CompactHeader(
                icon: icon,
                title: title,
                subtitle: subtitle,
                deviceLabel: deviceLabel,
                statusLabel: statusLabel,
                statusLevel: statusLevel,
              );
            }

            return _StandardHeader(
              icon: icon,
              title: title,
              subtitle: subtitle,
              deviceLabel: deviceLabel,
              statusLabel: statusLabel,
              statusLevel: statusLevel,
            );
          },
        ),
      ),
    );
  }
}

class _StandardHeader extends StatelessWidget {
  const _StandardHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.deviceLabel,
    required this.statusLabel,
    required this.statusLevel,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String deviceLabel;
  final String statusLabel;
  final SensorStatusLevel statusLevel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderIcon(icon: icon),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: _HeaderTitle(title: title)),
            const SizedBox(width: AppSpacing.sm),
            StatusChip(label: statusLabel, level: statusLevel),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.only(left: 48 + AppSpacing.sm),
          child: _HeaderDetails(subtitle: subtitle, deviceLabel: deviceLabel),
        ),
      ],
    );
  }
}

class _CompactHeader extends StatelessWidget {
  const _CompactHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.deviceLabel,
    required this.statusLabel,
    required this.statusLevel,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String deviceLabel;
  final String statusLabel;
  final SensorStatusLevel statusLevel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderIcon(icon: icon),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: _HeaderTitle(title: title)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        StatusChip(label: statusLabel, level: statusLevel),
        const SizedBox(height: AppSpacing.sm),
        _HeaderDetails(subtitle: subtitle, deviceLabel: deviceLabel),
      ],
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Icon(icon, color: Theme.of(context).colorScheme.onPrimary),
    );
  }
}

class _HeaderTitle extends StatelessWidget {
  const _HeaderTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(height: 1.2),
    );
  }
}

class _HeaderDetails extends StatelessWidget {
  const _HeaderDetails({required this.subtitle, required this.deviceLabel});

  final String subtitle;
  final String deviceLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.xxs),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sensors_outlined,
              size: 15,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.xxs),
            Flexible(
              child: Text(
                deviceLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
