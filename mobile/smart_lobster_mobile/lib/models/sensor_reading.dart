class SensorReading {
  const SensorReading({
    required this.ph,
    required this.tds,
    required this.temperature,
    required this.timestamp,
    this.sampleCount,
  });

  final double ph;
  final double tds;
  final double temperature;
  final DateTime timestamp;
  final int? sampleCount;

  factory SensorReading.fromMap(
    Map<Object?, Object?> data, {
    DateTime? fallbackTimestamp,
  }) {
    final timestamp = tryParseTimestamp(data['timestamp']) ?? fallbackTimestamp;
    if (timestamp == null) {
      throw const FormatException('Timestamp data sensor tidak tersedia.');
    }

    return SensorReading(
      ph: parseDouble(data['ph']),
      tds: parseDouble(data['tds']),
      temperature: parseDouble(data['temperature']),
      timestamp: timestamp,
      sampleCount: parseInt(data['sampleCount'] ?? data['sample_count']),
    );
  }

  static double parseDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? parseInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static DateTime? tryParseTimestamp(Object? value) {
    if (value == null) return null;

    final number = value is num
        ? value.toInt()
        : int.tryParse(value.toString());
    if (number != null) {
      final milliseconds = number.abs() < 100000000000 ? number * 1000 : number;
      return DateTime.fromMillisecondsSinceEpoch(milliseconds);
    }

    return DateTime.tryParse(value.toString())?.toLocal();
  }
}
