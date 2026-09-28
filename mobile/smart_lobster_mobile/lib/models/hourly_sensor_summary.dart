import 'sensor_reading.dart';

class HourlySensorSummary {
  const HourlySensorSummary({
    required this.timestamp,
    required this.phAvg,
    required this.phMin,
    required this.phMax,
    required this.tdsAvg,
    required this.tdsMin,
    required this.tdsMax,
    required this.temperatureAvg,
    required this.temperatureMin,
    required this.temperatureMax,
    required this.sampleCount,
  });

  final DateTime timestamp;

  final double phAvg;
  final double phMin;
  final double phMax;

  final double tdsAvg;
  final double tdsMin;
  final double tdsMax;

  final double temperatureAvg;
  final double temperatureMin;
  final double temperatureMax;

  final int sampleCount;

  factory HourlySensorSummary.fromMap(
    Map<Object?, Object?> data, {
    required DateTime fallbackTimestamp,
  }) {
    return HourlySensorSummary(
      timestamp:
          SensorReading.tryParseTimestamp(data['timestamp']) ??
          fallbackTimestamp,
      phAvg: _metricValue(data, 'ph', 'avg'),
      phMin: _metricValue(data, 'ph', 'min'),
      phMax: _metricValue(data, 'ph', 'max'),
      tdsAvg: _metricValue(data, 'tds', 'avg'),
      tdsMin: _metricValue(data, 'tds', 'min'),
      tdsMax: _metricValue(data, 'tds', 'max'),
      temperatureAvg: _metricValue(data, 'temperature', 'avg'),
      temperatureMin: _metricValue(data, 'temperature', 'min'),
      temperatureMax: _metricValue(data, 'temperature', 'max'),
      sampleCount:
          SensorReading.parseInt(
            data['sampleCount'] ?? data['sample_count'] ?? data['count'],
          ) ??
          0,
    );
  }

  static double _metricValue(
    Map<Object?, Object?> data,
    String metric,
    String statistic,
  ) {
    final nestedValue = data[metric];
    if (nestedValue is Map) {
      final nestedMap = Map<Object?, Object?>.from(nestedValue);
      if (nestedMap.containsKey(statistic)) {
        return SensorReading.parseDouble(nestedMap[statistic]);
      }
    }

    final camelCaseStatistic =
        '${statistic[0].toUpperCase()}${statistic.substring(1)}';
    final alternateMetric = metric == 'temperature' ? 'temp' : metric;

    return SensorReading.parseDouble(
      data['${metric}_$statistic'] ??
          data['$metric$camelCaseStatistic'] ??
          data['${alternateMetric}_$statistic'] ??
          data['$alternateMetric$camelCaseStatistic'],
    );
  }
}
