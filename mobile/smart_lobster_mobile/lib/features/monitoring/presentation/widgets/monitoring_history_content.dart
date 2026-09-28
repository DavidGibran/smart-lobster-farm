import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../models/monitoring_history.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../models/monitoring_chart_series.dart';
import 'history_overview_card.dart';
import 'monitoring_chart_card.dart';

class MonitoringHistoryContent extends StatelessWidget {
  const MonitoringHistoryContent({super.key, required this.history});

  final MonitoringHistory history;

  @override
  Widget build(BuildContext context) {
    final phSeries = MonitoringChartSeries.fromHistory(
      history,
      MonitoringMetric.ph,
    );
    final tdsSeries = MonitoringChartSeries.fromHistory(
      history,
      MonitoringMetric.tds,
    );
    final temperatureSeries = MonitoringChartSeries.fromHistory(
      history,
      MonitoringMetric.temperature,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Ringkasan Data',
          description: 'Histori sensor pada periode terpilih',
        ),
        const SizedBox(height: AppSpacing.md),
        HistoryOverviewCard(history: history),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Grafik Parameter'),
        const SizedBox(height: AppSpacing.md),
        MonitoringChartCard(
          icon: Icons.science_outlined,
          title: 'pH Air',
          referenceLabel: 'Rentang ideal 7.0–8.0',
          series: phSeries,
          period: history.period,
          lineColor: AppColors.chartPh,
          referenceMinimum: 7,
          referenceMaximum: 8,
          scaleMinimum: 6.5,
          scaleMaximum: 9,
          decimalDigits: 2,
        ),
        const SizedBox(height: AppSpacing.sm),
        MonitoringChartCard(
          icon: Icons.water_drop_outlined,
          title: 'TDS',
          referenceLabel: 'Reference range 320–400 ppm',
          series: tdsSeries,
          period: history.period,
          lineColor: AppColors.chartTds,
          referenceMinimum: 320,
          referenceMaximum: 400,
          decimalDigits: 1,
          unit: 'ppm',
        ),
        const SizedBox(height: AppSpacing.sm),
        MonitoringChartCard(
          icon: Icons.thermostat_outlined,
          title: 'Suhu Air',
          referenceLabel: 'Rentang ideal 26–29°C',
          series: temperatureSeries,
          period: history.period,
          lineColor: AppColors.chartTemperature,
          referenceMinimum: 26,
          referenceMaximum: 29,
          decimalDigits: 1,
          unit: '°C',
        ),
      ],
    );
  }
}
