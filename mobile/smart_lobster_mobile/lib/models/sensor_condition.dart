enum SensorStatusLevel { ideal, attention, danger, reference, neutral }

class SensorCondition {
  const SensorCondition(this.label, this.level);

  final String label;
  final SensorStatusLevel level;

  bool get needsAttention =>
      level == SensorStatusLevel.attention || level == SensorStatusLevel.danger;
}

abstract final class SensorConditionEvaluator {
  static SensorCondition ph(double value) {
    if (value >= 7 && value <= 8) {
      return const SensorCondition('Ideal', SensorStatusLevel.ideal);
    }
    if ((value >= 6.5 && value < 7) || (value > 8 && value <= 9)) {
      return const SensorCondition(
        'Perlu perhatian',
        SensorStatusLevel.attention,
      );
    }
    return const SensorCondition(
      'Di luar rentang toleransi',
      SensorStatusLevel.danger,
    );
  }

  static SensorCondition tds(double value) {
    if (value >= 320 && value <= 400) {
      return const SensorCondition(
        'Reference Range',
        SensorStatusLevel.reference,
      );
    }
    return const SensorCondition(
      'Di luar Reference Range',
      SensorStatusLevel.attention,
    );
  }

  static SensorCondition temperature(double value) {
    if (value >= 26 && value <= 29) {
      return const SensorCondition('Ideal', SensorStatusLevel.ideal);
    }
    if (value > 29 && value <= 32) {
      return const SensorCondition(
        'Perlu perhatian',
        SensorStatusLevel.attention,
      );
    }
    if (value > 32) {
      return const SensorCondition('Suhu tinggi', SensorStatusLevel.danger);
    }
    return const SensorCondition('Suhu rendah', SensorStatusLevel.danger);
  }
}
