import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:smart_lobster_mobile/core/theme/app_theme.dart';
import 'package:smart_lobster_mobile/features/activities/presentation/activities_page.dart';
import 'package:smart_lobster_mobile/features/activities/models/farm_event.dart';
import 'package:smart_lobster_mobile/features/activities/models/farm_event_type.dart';
import 'package:smart_lobster_mobile/features/activities/services/event_service.dart';
import 'package:smart_lobster_mobile/features/dashboard/presentation/dashboard_page.dart';
import 'package:smart_lobster_mobile/features/history/presentation/history_page.dart';
import 'package:smart_lobster_mobile/features/history/presentation/widgets/history_state_cards.dart';
import 'package:smart_lobster_mobile/features/monitoring/presentation/monitoring_page.dart';
import 'package:smart_lobster_mobile/features/monitoring/models/monitoring_chart_series.dart';
import 'package:smart_lobster_mobile/features/monitoring/presentation/widgets/monitoring_history_content.dart';
import 'package:smart_lobster_mobile/features/settings/presentation/settings_page.dart';
import 'package:smart_lobster_mobile/models/hourly_sensor_summary.dart';
import 'package:smart_lobster_mobile/models/monitoring_history.dart';
import 'package:smart_lobster_mobile/models/monitoring_period.dart';
import 'package:smart_lobster_mobile/models/sensor_condition.dart';
import 'package:smart_lobster_mobile/models/sensor_reading.dart';
import 'package:smart_lobster_mobile/shared/widgets/app_header.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  group('SensorReading', () {
    test('memetakan nilai sensor dan timestamp epoch', () {
      final reading = SensorReading.fromMap({
        'ph': 7.4,
        'tds': 356,
        'temperature': 27.5,
        'timestamp': 1720000000000,
        'sample_count': 4,
      });

      expect(reading.ph, 7.4);
      expect(reading.tds, 356);
      expect(reading.temperature, 27.5);
      expect(reading.timestamp.millisecondsSinceEpoch, 1720000000000);
      expect(reading.sampleCount, 4);
    });
  });

  group('FarmEventType', () {
    test('memetakan stable Firebase value', () {
      expect(FarmEventType.feeding.firebaseValue, 'feeding');
      expect(FarmEventType.waterChange.firebaseValue, 'water_change');
      expect(FarmEventType.waterAddition.firebaseValue, 'water_addition');
      expect(
        FarmEventType.tryFromFirebaseValue('maintenance'),
        FarmEventType.maintenance,
      );
      expect(FarmEventType.tryFromFirebaseValue('tidak_valid'), isNull);
    });
  });

  group('FarmEvent', () {
    test('mem-parsing Firebase dengan metadata opsional', () {
      final event = FarmEvent.tryFromFirebase(
        id: '-event-1',
        value: {
          'type': 'feeding',
          'timestamp': 1790580900000,
          'occurred_at': 1790580600000,
          'note': 'Pakan pagi',
          'cell_id': 'A-07',
          'metadata': {'amount_gram': 50},
        },
      );
      final withoutMetadata = FarmEvent.tryFromFirebase(
        id: '-event-2',
        value: {'type': 'maintenance', 'timestamp': 1790580900000},
      );

      expect(event, isNotNull);
      expect(event!.id, '-event-1');
      expect(event.type, FarmEventType.feeding);
      expect(event.cellId, 'A-07');
      expect(event.metadata, {'amount_gram': 50});
      expect(event.timestamp.millisecondsSinceEpoch, 1790580600000);
      expect(withoutMetadata, isNotNull);
      expect(withoutMetadata!.metadata, isNull);
    });
  });

  group('EventService helpers', () {
    test('membentuk partition key dan rentang tanggal', () {
      expect(
        EventService.datePartitionKey(DateTime(2026, 9, 28, 18)),
        '2026-09-28',
      );
      expect(
        EventService.datePartitionKeys(
          from: DateTime(2026, 9, 28, 18),
          to: DateTime(2026, 9, 29, 18),
        ),
        ['2026-09-28', '2026-09-29'],
      );
    });

    test('mem-parsing record valid dan melewati record rusak', () {
      final events = EventService.parsePartition({
        '-valid': {
          'type': 'molting',
          'timestamp': 1790580900000,
          'cell_id': 'B-03',
        },
        '-invalid': {'type': 'tidak_valid'},
      });

      expect(events, hasLength(1));
      expect(events.single.id, '-valid');
      expect(events.single.type, FarmEventType.molting);
    });
  });

  group('HourlySensorSummary', () {
    test('mendukung field agregat snake_case', () {
      final summary = HourlySensorSummary.fromMap({
        'ph_avg': 7.4,
        'ph_min': 7.1,
        'ph_max': 7.8,
        'tds_avg': 350,
        'tds_min': 330,
        'tds_max': 370,
        'temperature_avg': 27.2,
        'temperature_min': 26.8,
        'temperature_max': 27.8,
        'sample_count': 12,
      }, fallbackTimestamp: DateTime(2026, 9, 28, 10));

      expect(summary.phAvg, 7.4);
      expect(summary.tdsMax, 370);
      expect(summary.temperatureMin, 26.8);
      expect(summary.sampleCount, 12);
    });
  });

  group('MonitoringHistory', () {
    test('menghitung rata-rata hourly berdasarkan sample count', () {
      final summaries = [
        _hourlySummary(timestamp: DateTime(2026, 9, 28, 9), ph: 7, count: 2),
        _hourlySummary(timestamp: DateTime(2026, 9, 28, 10), ph: 8, count: 8),
      ];
      final history = MonitoringHistory.hourly(
        period: MonitoringPeriod.days7,
        from: DateTime(2026, 9, 21),
        to: DateTime(2026, 9, 28, 10),
        summaries: summaries,
      );

      expect(history.dataPointCount, 2);
      expect(history.ph.average, closeTo(7.8, 0.001));
      expect(history.firstTimestamp, summaries.first.timestamp);
      expect(history.lastTimestamp, summaries.last.timestamp);

      final series = MonitoringChartSeries.fromHistory(
        history,
        MonitoringMetric.ph,
      );
      expect(series.points.first.value, 7);
      expect(series.summary.minimum, 6.8);
      expect(series.summary.maximum, 8.2);
    });
  });

  group('SensorConditionEvaluator', () {
    test('menggunakan baseline pH sesuai batas', () {
      expect(SensorConditionEvaluator.ph(7).level, SensorStatusLevel.ideal);
      expect(
        SensorConditionEvaluator.ph(6.8).level,
        SensorStatusLevel.attention,
      );
      expect(SensorConditionEvaluator.ph(9.1).level, SensorStatusLevel.danger);
    });

    test('menandai rentang TDS sebagai referensi, bukan optimum', () {
      final condition = SensorConditionEvaluator.tds(350);

      expect(condition.label, 'Reference Range');
      expect(condition.level, SensorStatusLevel.reference);
    });
  });

  testWidgets('dashboard menampilkan data dari stream sensor', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final reading = SensorReading(
      ph: 7.25,
      tds: 350,
      temperature: 27.4,
      timestamp: DateTime(2026, 9, 28, 10),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: DashboardPage(sensorStream: Stream.value(reading)),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Sistem Online'), findsOneWidget);
    expect(find.text('Perangkat Oase 01'), findsOneWidget);
    expect(find.text('7.25'), findsOneWidget);
    expect(find.text('350'), findsOneWidget);
    expect(find.text('27.4'), findsOneWidget);
    expect(find.text('Reference Range'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Prediksi belum tersedia'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Prediksi belum tersedia'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('header tetap readable pada layar sangat sempit', (tester) async {
    tester.view.physicalSize = const Size(280, 560);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: AppHeader(
                title: 'Smart Lobster Farming',
                subtitle: 'Kampoeng Oase Ondomohen',
                deviceLabel: 'Perangkat Oase 01',
                statusLabel: 'Sistem Online',
                statusLevel: SensorStatusLevel.ideal,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Smart Lobster Farming'), findsOneWidget);
    expect(find.text('Sistem Online'), findsOneWidget);
    expect(find.text('Kampoeng Oase Ondomohen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('halaman prototipe tidak overflow pada layar kecil', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final page in <Widget>[
      MonitoringPage(
        historyLoader: _emptyHistoryLoader,
        latestStream: const Stream<SensorReading>.empty(),
        isActive: false,
      ),
      ActivitiesPage(
        eventLoader: _emptyEventLoader,
        eventCreator: _noopEventCreator,
        isActive: false,
      ),
      const SettingsPage(),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(body: page),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('selector monitoring memilih sumber periode yang benar', (
    tester,
  ) async {
    final requestedPeriods = <MonitoringPeriod>[];

    Future<MonitoringHistory> loader(MonitoringPeriod period) async {
      requestedPeriods.add(period);
      return _emptyHistory(period);
    }

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: MonitoringPage(
            historyLoader: loader,
            latestStream: const Stream<SensorReading>.empty(),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(requestedPeriods, [MonitoringPeriod.day24]);

    await tester.tap(find.text('7 Hari'));
    await tester.pump();
    expect(requestedPeriods, [MonitoringPeriod.day24, MonitoringPeriod.days7]);

    await tester.scrollUntilVisible(
      find.text('Lihat Riwayat Sensor'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Lihat Riwayat Sensor'));
    await tester.pumpAndSettle();
    expect(find.text('Riwayat Sensor'), findsOneWidget);
  });

  testWidgets('monitoring merender tiga chart sensor terpisah', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final from = DateTime(2026, 9, 28, 9);
    final history = MonitoringHistory.raw(
      period: MonitoringPeriod.day24,
      from: from,
      to: from.add(const Duration(minutes: 5)),
      readings: [
        SensorReading(ph: 7.2, tds: 345, temperature: 27.1, timestamp: from),
        SensorReading(
          ph: 7.4,
          tds: 355,
          temperature: 27.6,
          timestamp: from.add(const Duration(minutes: 5)),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: MonitoringHistoryContent(history: history),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LineChart), findsNWidgets(3));
    expect(find.text('Rentang ideal 7.0–8.0'), findsOneWidget);
    expect(find.text('Reference range 320–400 ppm'), findsOneWidget);
    expect(find.text('Rentang ideal 26–29°C'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('history memakai future yang sama dan menampilkan terbaru dulu', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final from = DateTime(2026, 9, 28, 14, 30);
    final history = MonitoringHistory.raw(
      period: MonitoringPeriod.day24,
      from: from,
      to: from.add(const Duration(minutes: 5)),
      readings: [
        SensorReading(ph: 7.21, tds: 356, temperature: 27.9, timestamp: from),
        SensorReading(
          ph: 7.18,
          tds: 358,
          temperature: 28,
          timestamp: from.add(const Duration(minutes: 5)),
        ),
      ],
    );
    var loaderCalls = 0;

    Future<MonitoringHistory> loader(MonitoringPeriod period) async {
      loaderCalls++;
      return _emptyHistory(period);
    }

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: HistoryPage(
          historyLoader: loader,
          initialHistoryFuture: Future.value(history),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(loaderCalls, 0);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('14:35'), findsOneWidget);
    expect(find.text('14:30'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('14:35')).dy,
      lessThan(tester.getTopLeft(find.text('14:30')).dy),
    );

    await tester.tap(find.text('7 Hari'));
    await tester.pumpAndSettle();
    expect(loaderCalls, 1);
    expect(find.text('Belum ada riwayat sensor.'), findsOneWidget);
  });

  testWidgets('history menampilkan error dan tombol coba lagi', (tester) async {
    var retryCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: HistoryErrorCard(onRetry: () => retryCalls++)),
      ),
    );

    expect(find.text('Gagal memuat riwayat sensor.'), findsOneWidget);
    expect(find.text('Coba Lagi'), findsOneWidget);

    await tester.tap(find.text('Coba Lagi'));
    expect(retryCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('form pemberian pakan menyimpan metadata dan menutup sheet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    FarmEventType? submittedType;
    Map<String, dynamic>? submittedMetadata;

    Future<void> creator({
      required FarmEventType type,
      required DateTime timestamp,
      String? note,
      String? cellId,
      Map<String, dynamic>? metadata,
    }) async {
      submittedType = type;
      submittedMetadata = metadata;
    }

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: ActivitiesPage(
            eventLoader: _emptyEventLoader,
            eventCreator: creator,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Pemberian Pakan'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Pemberian Pakan'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('event-specific-value')),
      '50',
    );
    await tester.tap(find.byKey(const ValueKey('event-save')));
    await tester.pumpAndSettle();

    expect(submittedType, FarmEventType.feeding);
    expect(submittedMetadata, {'amount_gram': 50});
    expect(find.text('Aktivitas berhasil dicatat'), findsOneWidget);
    expect(find.byKey(const ValueKey('event-save')), findsNothing);
  });

  testWidgets('aktivitas tidak dimuat sebelum tab menjadi aktif', (
    tester,
  ) async {
    var loaderCalls = 0;

    Future<List<FarmEvent>> loader({
      required DateTime from,
      required DateTime to,
    }) async {
      loaderCalls++;
      return const [];
    }

    Widget buildPage(bool isActive) {
      return MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: ActivitiesPage(
            eventLoader: loader,
            eventCreator: _noopEventCreator,
            isActive: isActive,
          ),
        ),
      );
    }

    await tester.pumpWidget(buildPage(false));
    await tester.pump();
    expect(loaderCalls, 0);

    await tester.pumpWidget(buildPage(true));
    await tester.pump();
    expect(loaderCalls, 1);
  });
}

Future<MonitoringHistory> _emptyHistoryLoader(MonitoringPeriod period) async {
  return _emptyHistory(period);
}

MonitoringHistory _emptyHistory(MonitoringPeriod period) {
  final to = DateTime(2026, 9, 28, 10);
  if (period.usesHourlyHistory) {
    return MonitoringHistory.hourly(
      period: period,
      from: to.subtract(period.duration),
      to: to,
      summaries: const [],
    );
  }
  return MonitoringHistory.raw(
    period: period,
    from: to.subtract(period.duration),
    to: to,
    readings: const [],
  );
}

HourlySensorSummary _hourlySummary({
  required DateTime timestamp,
  required double ph,
  required int count,
}) {
  return HourlySensorSummary(
    timestamp: timestamp,
    phAvg: ph,
    phMin: ph - 0.2,
    phMax: ph + 0.2,
    tdsAvg: 350,
    tdsMin: 340,
    tdsMax: 360,
    temperatureAvg: 27,
    temperatureMin: 26.5,
    temperatureMax: 27.5,
    sampleCount: count,
  );
}

Future<List<FarmEvent>> _emptyEventLoader({
  required DateTime from,
  required DateTime to,
}) async {
  return const [];
}

Future<void> _noopEventCreator({
  required FarmEventType type,
  required DateTime timestamp,
  String? note,
  String? cellId,
  Map<String, dynamic>? metadata,
}) async {}
