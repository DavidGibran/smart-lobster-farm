import 'package:firebase_database/firebase_database.dart';

import '../models/farm_event.dart';
import '../models/farm_event_type.dart';

class EventService {
  EventService({FirebaseDatabase? database})
    : _database = database ?? FirebaseDatabase.instance;

  static const eventsPath = 'devices/oase-01/events';
  static const cacheDuration = Duration(minutes: 5);

  final FirebaseDatabase _database;
  final Map<String, _EventCacheEntry> _cache = {};

  Future<void> createEvent({
    required FarmEventType type,
    required DateTime timestamp,
    String? note,
    String? cellId,
    Map<String, dynamic>? metadata,
  }) async {
    final partitionKey = datePartitionKey(timestamp);
    final reference = _database.ref('$eventsPath/$partitionKey').push();
    final cleanNote = _cleanText(note);
    final cleanCellId = _cleanText(cellId);
    final cleanMetadata = metadata == null
        ? null
        : Map<String, dynamic>.fromEntries(
            metadata.entries.where((entry) => entry.value != null),
          );

    await reference.set({
      'type': type.firebaseValue,
      'timestamp': ServerValue.timestamp,
      'occurred_at': timestamp.millisecondsSinceEpoch,
      if (cleanNote != null) 'note': cleanNote,
      if (cleanCellId != null) 'cell_id': cleanCellId,
      if (cleanMetadata != null && cleanMetadata.isNotEmpty)
        'metadata': cleanMetadata,
    });
    _cache.clear();
  }

  Future<List<FarmEvent>> getEvents({
    required DateTime from,
    required DateTime to,
  }) async {
    if (from.isAfter(to)) {
      throw ArgumentError.value(
        from,
        'from',
        'Harus sebelum atau sama dengan to.',
      );
    }

    final partitionKeys = datePartitionKeys(from: from, to: to);
    final cacheKey = partitionKeys.join('|');
    final now = DateTime.now();
    final cached = _cache[cacheKey];
    final List<FarmEvent> partitionEvents;

    if (cached != null && now.difference(cached.fetchedAt) < cacheDuration) {
      partitionEvents = cached.events;
    } else {
      final snapshots = await Future.wait(
        partitionKeys.map((key) => _database.ref('$eventsPath/$key').get()),
      );
      partitionEvents = <FarmEvent>[];
      for (final snapshot in snapshots) {
        partitionEvents.addAll(parsePartition(snapshot.value));
      }
      _cache[cacheKey] = _EventCacheEntry(
        fetchedAt: now,
        events: List.unmodifiable(partitionEvents),
      );
    }

    final events = partitionEvents
        .where(
          (event) =>
              !event.timestamp.isBefore(from) && !event.timestamp.isAfter(to),
        )
        .toList(growable: false);
    events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return events;
  }

  static String datePartitionKey(DateTime timestamp) {
    final local = timestamp.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  static List<FarmEvent> parsePartition(Object? value) {
    if (value is! Map) return const [];
    final events = <FarmEvent>[];
    for (final entry in value.entries) {
      if (entry.key == null) continue;
      final event = FarmEvent.tryFromFirebase(
        id: entry.key.toString(),
        value: entry.value,
      );
      if (event != null) events.add(event);
    }
    return events;
  }

  static List<String> datePartitionKeys({
    required DateTime from,
    required DateTime to,
  }) {
    final localFrom = from.toLocal();
    final localTo = to.toLocal();
    var date = DateTime(localFrom.year, localFrom.month, localFrom.day);
    final lastDate = DateTime(localTo.year, localTo.month, localTo.day);
    final keys = <String>[];
    while (!date.isAfter(lastDate)) {
      keys.add(datePartitionKey(date));
      date = DateTime(date.year, date.month, date.day + 1);
    }
    return keys;
  }

  String? _cleanText(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }
}

class _EventCacheEntry {
  const _EventCacheEntry({required this.fetchedAt, required this.events});

  final DateTime fetchedAt;
  final List<FarmEvent> events;
}
