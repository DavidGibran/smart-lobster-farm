import 'farm_event_type.dart';

class FarmEvent {
  const FarmEvent({
    required this.id,
    required this.type,
    required this.timestamp,
    this.note,
    this.cellId,
    this.metadata,
  });

  final String id;
  final FarmEventType type;
  final DateTime timestamp;
  final String? note;
  final String? cellId;
  final Map<String, dynamic>? metadata;

  static FarmEvent? tryFromFirebase({
    required String id,
    required Object? value,
  }) {
    if (value is! Map) return null;
    final data = Map<Object?, Object?>.from(value);
    final type = FarmEventType.tryFromFirebaseValue(data['type']);
    final timestamp = _tryParseTimestamp(
      data['occurred_at'] ?? data['timestamp'],
    );
    if (type == null || timestamp == null) return null;

    return FarmEvent(
      id: id,
      type: type,
      timestamp: timestamp,
      note: _optionalString(data['note']),
      cellId: _optionalString(data['cell_id'] ?? data['cellId']),
      metadata: _metadata(data['metadata']),
    );
  }

  static DateTime? _tryParseTimestamp(Object? value) {
    if (value == null) return null;
    final number = value is num ? value.toInt() : int.tryParse('$value');
    if (number != null) {
      final milliseconds = number.abs() < 100000000000 ? number * 1000 : number;
      return DateTime.fromMillisecondsSinceEpoch(milliseconds);
    }
    return DateTime.tryParse('$value')?.toLocal();
  }

  static String? _optionalString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static Map<String, dynamic>? _metadata(Object? value) {
    if (value is! Map) return null;
    final result = <String, dynamic>{};
    for (final entry in value.entries) {
      if (entry.key != null) result[entry.key.toString()] = entry.value;
    }
    return result.isEmpty ? null : result;
  }
}
