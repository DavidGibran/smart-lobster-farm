import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../history/presentation/history_page.dart';
import '../../../models/monitoring_history.dart';
import '../../../models/monitoring_period.dart';
import '../../../models/sensor_reading.dart';
import '../../../shared/widgets/monitoring_period_selector.dart';
import 'widgets/current_conditions_card.dart';
import 'widgets/monitoring_history_content.dart';
import 'widgets/monitoring_state_cards.dart';

typedef MonitoringHistoryLoader =
    Future<MonitoringHistory> Function(MonitoringPeriod period);

class MonitoringPage extends StatefulWidget {
  const MonitoringPage({
    super.key,
    required this.historyLoader,
    required this.latestStream,
    this.isActive = true,
  });

  final MonitoringHistoryLoader historyLoader;
  final Stream<SensorReading> latestStream;
  final bool isActive;

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  MonitoringPeriod _selectedPeriod = MonitoringPeriod.day24;
  Future<MonitoringHistory>? _historyFuture;
  late bool _hasBeenActivated;

  @override
  void initState() {
    super.initState();
    _hasBeenActivated = widget.isActive;
    if (widget.isActive) {
      _historyFuture = widget.historyLoader(_selectedPeriod);
    }
  }

  @override
  void didUpdateWidget(covariant MonitoringPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _hasBeenActivated = true;
      _historyFuture = widget.historyLoader(_selectedPeriod);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey('monitoring-scroll'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: [
        Text('Monitoring', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Pantau perubahan parameter air dari waktu ke waktu.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        MonitoringPeriodSelector(
          selectedPeriod: _selectedPeriod,
          onChanged: _selectPeriod,
        ),
        if (_hasBeenActivated) ...[
          const SizedBox(height: AppSpacing.lg),
          CurrentConditionsCard(latestStream: widget.latestStream),
        ],
        const SizedBox(height: AppSpacing.xl),
        _buildHistoryState(),
        const SizedBox(height: AppSpacing.lg),
        Card(
          child: ListTile(
            leading: const Icon(Icons.history_rounded),
            title: const Text('Lihat Riwayat Sensor'),
            subtitle: const Text('Ringkasan dan grafik ditampilkan di atas'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _openHistory(context),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryState() {
    final future = _historyFuture;
    if (future == null) return const MonitoringLoadingCard();

    return FutureBuilder<MonitoringHistory>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MonitoringLoadingCard();
        }
        if (snapshot.hasError) {
          return MonitoringErrorCard(onRetry: _loadHistory);
        }

        final history = snapshot.data;
        if (history == null || history.dataPointCount < 2) {
          return const MonitoringEmptyCard();
        }

        return MonitoringHistoryContent(history: history);
      },
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

  void _openHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => HistoryPage(
          historyLoader: widget.historyLoader,
          initialPeriod: _selectedPeriod,
          initialHistoryFuture: _historyFuture,
        ),
      ),
    );
  }
}
