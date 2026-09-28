enum MonitoringPeriod { day24, days7, days30 }

extension MonitoringPeriodDetails on MonitoringPeriod {
  String get label => switch (this) {
    MonitoringPeriod.day24 => '24 Jam',
    MonitoringPeriod.days7 => '7 Hari',
    MonitoringPeriod.days30 => '30 Hari',
  };

  String get debugLabel => switch (this) {
    MonitoringPeriod.day24 => '24h',
    MonitoringPeriod.days7 => '7d',
    MonitoringPeriod.days30 => '30d',
  };

  Duration get duration => switch (this) {
    MonitoringPeriod.day24 => const Duration(hours: 24),
    MonitoringPeriod.days7 => const Duration(days: 7),
    MonitoringPeriod.days30 => const Duration(days: 30),
  };

  bool get usesHourlyHistory => this != MonitoringPeriod.day24;
}
