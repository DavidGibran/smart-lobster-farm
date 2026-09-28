import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/section_header.dart';
import '../models/farm_event.dart';
import '../models/farm_event_type.dart';
import 'widgets/activity_action_card.dart';
import 'widgets/activity_state_cards.dart';
import 'widgets/event_detail_sheet.dart';
import 'widgets/event_form_sheet.dart';
import 'widgets/recent_event_card.dart';

typedef EventLoader =
    Future<List<FarmEvent>> Function({
      required DateTime from,
      required DateTime to,
    });

class ActivitiesPage extends StatefulWidget {
  const ActivitiesPage({
    super.key,
    required this.eventLoader,
    required this.eventCreator,
    this.isActive = true,
  });

  final EventLoader eventLoader;
  final EventSubmitter eventCreator;
  final bool isActive;

  @override
  State<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage> {
  static const _actionTypes = [
    FarmEventType.waterChange,
    FarmEventType.waterAddition,
    FarmEventType.feeding,
    FarmEventType.molting,
    FarmEventType.mating,
    FarmEventType.maintenance,
  ];

  Future<List<FarmEvent>>? _eventsFuture;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) _eventsFuture = _loadRecentEvents();
  }

  @override
  void didUpdateWidget(covariant ActivitiesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _eventsFuture = _loadRecentEvents();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey('activities-scroll'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: [
        Text(
          'Aktivitas Budidaya',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Pilih aktivitas untuk pencatatan operasional.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final columnCount = constraints.maxWidth >= 720 ? 3 : 2;
            const gap = AppSpacing.sm;
            final itemWidth =
                (constraints.maxWidth - (gap * (columnCount - 1))) /
                columnCount;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final type in _actionTypes)
                  SizedBox(
                    width: itemWidth,
                    child: ActivityActionCard(
                      type: type,
                      onTap: () => _openEventForm(type),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Aktivitas Terbaru'),
        const SizedBox(height: AppSpacing.md),
        _buildRecentEvents(),
      ],
    );
  }

  Widget _buildRecentEvents() {
    final future = _eventsFuture;
    if (future == null) return const ActivityLoadingCard();

    return FutureBuilder<List<FarmEvent>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const ActivityLoadingCard();
        }
        if (snapshot.hasError) {
          return ActivityErrorCard(onRetry: _refreshEvents);
        }

        final events = snapshot.data ?? const <FarmEvent>[];
        if (events.isEmpty) return const ActivityEmptyCard();
        return Column(
          children: [
            for (var index = 0; index < events.length; index++) ...[
              RecentEventCard(
                event: events[index],
                onTap: () => _showEventDetail(events[index]),
              ),
              if (index != events.length - 1)
                const SizedBox(height: AppSpacing.sm),
            ],
          ],
        );
      },
    );
  }

  Future<List<FarmEvent>> _loadRecentEvents() async {
    final to = DateTime.now();
    final events = await widget.eventLoader(
      from: to.subtract(const Duration(days: 7)),
      to: to,
    );
    return events.take(20).toList(growable: false);
  }

  Future<void> _openEventForm(FarmEventType type) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) =>
          EventFormSheet(type: type, onSubmit: widget.eventCreator),
    );
    if (saved != true || !mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Aktivitas berhasil dicatat')));
    _refreshEvents();
  }

  void _showEventDetail(FarmEvent event) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => EventDetailSheet(event: event),
    );
  }

  void _refreshEvents() {
    setState(() {
      _eventsFuture = _loadRecentEvents();
    });
  }
}
