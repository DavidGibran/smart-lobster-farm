import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../models/monitoring_history.dart';
import '../../../models/monitoring_period.dart';
import '../../../shared/widgets/monitoring_period_selector.dart';
import '../../../shared/widgets/section_header.dart';
import 'widgets/history_record_card.dart';
import 'widgets/history_state_cards.dart';
import 'widgets/history_summary_card.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({
    super.key,
    required this.historyLoader,
    this.initialPeriod = MonitoringPeriod.day24,
    this.initialHistoryFuture,
  });

  final Future<MonitoringHistory> Function(MonitoringPeriod period)
  historyLoader;
  final MonitoringPeriod initialPeriod;
  final Future<MonitoringHistory>? initialHistoryFuture;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late MonitoringPeriod _selectedPeriod;
  late Future<MonitoringHistory> _historyFuture;

  @override
  void initState() {
    super.initState();
    _selectedPeriod = widget.initialPeriod;
    _historyFuture =
        widget.initialHistoryFuture ?? widget.historyLoader(_selectedPeriod);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Sensor')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: MonitoringPeriodSelector(
                selectedPeriod: _selectedPeriod,
                onChanged: _selectPeriod,
              ),
            ),
            Expanded(
              child: FutureBuilder<MonitoringHistory>(
                future: _historyFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const _StateList(child: HistoryLoadingCard());
                  }
                  if (snapshot.hasError) {
                    return _StateList(
                      child: HistoryErrorCard(onRetry: _loadHistory),
                    );
                  }

                  final history = snapshot.data;
                  if (history == null || history.isEmpty) {
                    return const _StateList(child: HistoryEmptyCard());
                  }

                  return _HistoryList(history: history);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectPeriod(MonitoringPeriod period) {
    if (period == _selectedPeriod) return;
    setState(() {
      _selectedPeriod = period;
      _historyFuture = widget.historyLoader(period);
    });
  }

  void _loadHistory() {
    setState(() {
      _historyFuture = widget.historyLoader(_selectedPeriod);
    });
  }
}

class _StateList extends StatelessWidget {
  const _StateList({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [child],
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.history});

  final MonitoringHistory history;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            0,
          ),
          sliver: SliverList.list(
            children: [
              HistorySummaryCard(history: history),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: 'Daftar Riwayat'),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          sliver: SliverList.builder(
            itemCount: history.dataPointCount,
            itemBuilder: (context, index) {
              final item = history.period.usesHourlyHistory
                  ? HistoryRecordCard.hourly(
                      history.hourlySummaries[history.hourlySummaries.length -
                          1 -
                          index],
                    )
                  : HistoryRecordCard.raw(
                      history.rawReadings[history.rawReadings.length -
                          1 -
                          index],
                    );
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: item,
              );
            },
          ),
        ),
      ],
    );
  }
}
