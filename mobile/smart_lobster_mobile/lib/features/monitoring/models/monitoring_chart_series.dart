import '../../../models/monitoring_history.dart';
import '../../../models/monitoring_period.dart';

enum MonitoringMetric { ph, tds, temperature }

class SensorChartPoint {
  const SensorChartPoint({required this.timestamp, required this.value});

  final DateTime timestamp;
  final double value;
}

class MonitoringChartSeries {
  const MonitoringChartSeries({required this.points, required this.summary});

  final List<SensorChartPoint> points;
  final SensorMetricSummary summary;

  factory MonitoringChartSeries.fromHistory(
    MonitoringHistory history,
    MonitoringMetric metric,
  ) {
    final points = history.period.usesHourlyHistory
        ? history.hourlySummaries
              .map((summary) {
                final value = switch (metric) {
                  MonitoringMetric.ph => summary.phAvg,
                  MonitoringMetric.tds => summary.tdsAvg,
                  MonitoringMetric.temperature => summary.temperatureAvg,
                };
                return SensorChartPoint(
                  timestamp: summary.timestamp,
                  value: value,
                );
              })
              .toList(growable: false)
        : history.rawReadings
              .map((reading) {
                final value = switch (metric) {
                  MonitoringMetric.ph => reading.ph,
                  MonitoringMetric.tds => reading.tds,
                  MonitoringMetric.temperature => reading.temperature,
                };
                return SensorChartPoint(
                  timestamp: reading.timestamp,
                  value: value,
                );
              })
              .toList(growable: false);

    final summary = switch (metric) {
      MonitoringMetric.ph => history.ph,
      MonitoringMetric.tds => history.tds,
      MonitoringMetric.temperature => history.temperature,
    };

    return MonitoringChartSeries(points: points, summary: summary);
  }
}
