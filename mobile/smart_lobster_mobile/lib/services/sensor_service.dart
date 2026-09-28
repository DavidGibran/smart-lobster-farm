import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../models/hourly_sensor_summary.dart';
import '../models/monitoring_history.dart';
import '../models/monitoring_period.dart';
import '../models/sensor_reading.dart';

class SensorService {
  SensorService({FirebaseDatabase? database})
    : _database = database ?? FirebaseDatabase.instance;

  static const databasePath = 'devices/oase-01/latest';
  static const rawHistoryPath = 'devices/oase-01/history_raw';
  static const hourlyHistoryPath = 'devices/oase-01/history_hourly';
  static const historyCacheDuration = Duration(minutes: 5);

  final FirebaseDatabase _database;
  final Map<MonitoringPeriod, _HistoryCacheEntry> _historyCache = {};
  final Map<MonitoringPeriod, Future<MonitoringHistory>> _historyRequests = {};

  Stream<SensorReading> watchLatest() {
    return _database.ref(databasePath).onValue.map((event) {
      final rawValue = event.snapshot.value;
      if (rawValue is! Map) {
        throw const FormatException('Data sensor belum tersedia.');
      }

      return SensorReading.fromMap(Map<Object?, Object?>.from(rawValue));
    });
  }

  Future<List<SensorReading>> getRawHistory({
    required DateTime from,
    required DateTime to,
  }) async {
    _validateRange(from, to);
    final partitions = await _getDatePartitions(
      basePath: rawHistoryPath,
      from: from,
      to: to,
    );
    final readings = <SensorReading>[];

    for (final partition in partitions) {
      for (final child in partition.snapshot.children) {
        final value = child.value;
        if (value is! Map) continue;

        try {
          final reading = SensorReading.fromMap(
            Map<Object?, Object?>.from(value),
            fallbackTimestamp: SensorReading.tryParseTimestamp(child.key),
          );
          if (_isWithinRange(reading.timestamp, from, to)) {
            readings.add(reading);
          }
        } on FormatException {
          // Abaikan record yang tidak memiliki timestamp valid.
        }
      }
    }

    readings.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return readings;
  }

  Future<List<HourlySensorSummary>> getHourlyHistory({
    required DateTime from,
    required DateTime to,
  }) async {
    _validateRange(from, to);
    final partitions = await _getDatePartitions(
      basePath: hourlyHistoryPath,
      from: from,
      to: to,
    );
    final summaries = <HourlySensorSummary>[];

    for (final partition in partitions) {
      for (final child in partition.snapshot.children) {
        final value = child.value;
        final fallbackTimestamp = _hourTimestamp(partition.dateKey, child.key);
        if (value is! Map || fallbackTimestamp == null) continue;

        final summary = HourlySensorSummary.fromMap(
          Map<Object?, Object?>.from(value),
          fallbackTimestamp: fallbackTimestamp,
        );
        if (_isWithinRange(summary.timestamp, from, to)) {
          summaries.add(summary);
        }
      }
    }

    summaries.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return summaries;
  }

  Future<MonitoringHistory> getMonitoringHistory(
    MonitoringPeriod period, {
    DateTime? now,
  }) {
    final requestedAt = now ?? DateTime.now();
    final cached = _historyCache[period];
    if (cached != null) {
      final cacheAge = requestedAt.difference(cached.fetchedAt);
      if (!cacheAge.isNegative && cacheAge < historyCacheDuration) {
        _debugHistory(period, cached.data, source: 'cache');
        return Future.value(cached.data);
      }
    }

    final activeRequest = _historyRequests[period];
    if (activeRequest != null) return activeRequest;

    final request = _loadMonitoringHistory(
      period,
      requestedAt,
    ).whenComplete(() => _historyRequests.remove(period));
    _historyRequests[period] = request;
    return request;
  }

  Future<MonitoringHistory> _loadMonitoringHistory(
    MonitoringPeriod period,
    DateTime requestedAt,
  ) async {
    final from = requestedAt.subtract(period.duration);
    final MonitoringHistory data;

    if (period.usesHourlyHistory) {
      final summaries = await getHourlyHistory(from: from, to: requestedAt);
      data = MonitoringHistory.hourly(
        period: period,
        from: from,
        to: requestedAt,
        summaries: summaries,
      );
    } else {
      final readings = await getRawHistory(from: from, to: requestedAt);
      data = MonitoringHistory.raw(
        period: period,
        from: from,
        to: requestedAt,
        readings: readings,
      );
    }

    _historyCache[period] = _HistoryCacheEntry(
      fetchedAt: requestedAt,
      data: data,
    );
    _debugHistory(period, data, source: 'firebase');
    return data;
  }

  void _debugHistory(
    MonitoringPeriod period,
    MonitoringHistory data, {
    required String source,
  }) {
    if (!kDebugMode) return;
    debugPrint(
      '[HISTORY]\n'
      'period=${period.debugLabel}\n'
      'records=${data.dataPointCount}\n'
      'source=$source',
    );
  }

  Future<List<_DatedSnapshot>> _getDatePartitions({
    required String basePath,
    required DateTime from,
    required DateTime to,
  }) {
    final dateKeys = _dateKeysBetween(from, to);
    return Future.wait(
      dateKeys.map((dateKey) async {
        final snapshot = await _database.ref('$basePath/$dateKey').get();
        return _DatedSnapshot(dateKey: dateKey, snapshot: snapshot);
      }),
    );
  }

  List<String> _dateKeysBetween(DateTime from, DateTime to) {
    final localFrom = from.toLocal();
    final localTo = to.toLocal();
    var date = DateTime(localFrom.year, localFrom.month, localFrom.day);
    final lastDate = DateTime(localTo.year, localTo.month, localTo.day);
    final keys = <String>[];

    while (!date.isAfter(lastDate)) {
      keys.add(_dateKey(date));
      date = DateTime(date.year, date.month, date.day + 1);
    }
    return keys;
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  DateTime? _hourTimestamp(String dateKey, String? hourKey) {
    final dateParts = dateKey.split('-');
    final hour = int.tryParse(hourKey ?? '');
    if (dateParts.length != 3 || hour == null || hour < 0 || hour > 23) {
      return null;
    }

    final year = int.tryParse(dateParts[0]);
    final month = int.tryParse(dateParts[1]);
    final day = int.tryParse(dateParts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day, hour);
  }

  bool _isWithinRange(DateTime timestamp, DateTime from, DateTime to) {
    return !timestamp.isBefore(from) && !timestamp.isAfter(to);
  }

  void _validateRange(DateTime from, DateTime to) {
    if (from.isAfter(to)) {
      throw ArgumentError.value(
        from,
        'from',
        'Harus sebelum atau sama dengan to.',
      );
    }
  }
}

class _DatedSnapshot {
  const _DatedSnapshot({required this.dateKey, required this.snapshot});

  final String dateKey;
  final DataSnapshot snapshot;
}

class _HistoryCacheEntry {
  const _HistoryCacheEntry({required this.fetchedAt, required this.data});

  final DateTime fetchedAt;
  final MonitoringHistory data;
}
