import 'dart:math' as math;

import 'hourly_sensor_summary.dart';
import 'monitoring_period.dart';
import 'sensor_reading.dart';

class SensorMetricSummary {
  const SensorMetricSummary({
    required this.minimum,
    required this.average,
    required this.maximum,
  });

  final double minimum;
  final double average;
  final double maximum;
}

class MonitoringHistory {
  const MonitoringHistory.raw({
    required this.period,
    required this.from,
    required this.to,
    required List<SensorReading> readings,
  }) : rawReadings = readings,
       hourlySummaries = const [];

  const MonitoringHistory.hourly({
    required this.period,
    required this.from,
    required this.to,
    required List<HourlySensorSummary> summaries,
  }) : rawReadings = const [],
       hourlySummaries = summaries;

  final MonitoringPeriod period;
  final DateTime from;
  final DateTime to;
  final List<SensorReading> rawReadings;
  final List<HourlySensorSummary> hourlySummaries;

  bool get isEmpty => rawReadings.isEmpty && hourlySummaries.isEmpty;

  int get dataPointCount =>
      period.usesHourlyHistory ? hourlySummaries.length : rawReadings.length;

  DateTime? get firstTimestamp => isEmpty
      ? null
      : period.usesHourlyHistory
      ? hourlySummaries.first.timestamp
      : rawReadings.first.timestamp;

  DateTime? get lastTimestamp => isEmpty
      ? null
      : period.usesHourlyHistory
      ? hourlySummaries.last.timestamp
      : rawReadings.last.timestamp;

  SensorMetricSummary get ph => period.usesHourlyHistory
      ? _summarizeHourly(
          averages: hourlySummaries.map((item) => item.phAvg),
          minima: hourlySummaries.map((item) => item.phMin),
          maxima: hourlySummaries.map((item) => item.phMax),
        )
      : _summarizeRaw(rawReadings.map((item) => item.ph));

  SensorMetricSummary get tds => period.usesHourlyHistory
      ? _summarizeHourly(
          averages: hourlySummaries.map((item) => item.tdsAvg),
          minima: hourlySummaries.map((item) => item.tdsMin),
          maxima: hourlySummaries.map((item) => item.tdsMax),
        )
      : _summarizeRaw(rawReadings.map((item) => item.tds));

  SensorMetricSummary get temperature => period.usesHourlyHistory
      ? _summarizeHourly(
          averages: hourlySummaries.map((item) => item.temperatureAvg),
          minima: hourlySummaries.map((item) => item.temperatureMin),
          maxima: hourlySummaries.map((item) => item.temperatureMax),
        )
      : _summarizeRaw(rawReadings.map((item) => item.temperature));

  SensorMetricSummary _summarizeRaw(Iterable<double> values) {
    final items = values.toList(growable: false);
    final total = items.fold<double>(0, (sum, value) => sum + value);
    return SensorMetricSummary(
      minimum: items.reduce(math.min),
      average: total / items.length,
      maximum: items.reduce(math.max),
    );
  }

  SensorMetricSummary _summarizeHourly({
    required Iterable<double> averages,
    required Iterable<double> minima,
    required Iterable<double> maxima,
  }) {
    final averageItems = averages.toList(growable: false);
    final minimumItems = minima.toList(growable: false);
    final maximumItems = maxima.toList(growable: false);

    var weightedTotal = 0.0;
    var totalWeight = 0;
    for (var index = 0; index < averageItems.length; index++) {
      final weight = hourlySummaries[index].sampleCount;
      if (weight > 0) {
        weightedTotal += averageItems[index] * weight;
        totalWeight += weight;
      }
    }

    final average = totalWeight > 0
        ? weightedTotal / totalWeight
        : averageItems.fold<double>(0, (sum, value) => sum + value) /
              averageItems.length;

    return SensorMetricSummary(
      minimum: minimumItems.reduce(math.min),
      average: average,
      maximum: maximumItems.reduce(math.max),
    );
  }
}
