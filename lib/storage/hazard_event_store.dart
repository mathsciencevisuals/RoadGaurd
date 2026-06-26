import 'package:hive/hive.dart';

import 'hazard_event_entity.dart';
import 'local_db.dart';

class HazardEventStore {
  const HazardEventStore();

  Future<void> saveHazardEvent(HazardEventEntity event) async {
    final Box<HazardEventEntity> box = await LocalDb.hazardEventsBox();
    await box.put(event.id, event);
  }

  Future<List<HazardEventEntity>> getUnsyncedHazards() async {
    final Box<HazardEventEntity> box = await LocalDb.hazardEventsBox();

    return box.values
        .where((HazardEventEntity event) => !event.syncedToCloud)
        .toList()
      ..sort(_sortByDetectedAtDescending);
  }

  Future<void> markHazardSynced(String hazardId) async {
    final Box<HazardEventEntity> box = await LocalDb.hazardEventsBox();
    final HazardEventEntity? existing = box.get(hazardId);

    if (existing == null) {
      return;
    }

    await box.put(
      hazardId,
      existing.copyWith(syncedToCloud: true),
    );
  }

  Future<List<HazardEventEntity>> getRecentHazards({int limit = 50}) async {
    final Box<HazardEventEntity> box = await LocalDb.hazardEventsBox();
    final List<HazardEventEntity> hazards = box.values.toList()
      ..sort(_sortByDetectedAtDescending);

    if (limit < 1) {
      return <HazardEventEntity>[];
    }

    if (hazards.length <= limit) {
      return hazards;
    }

    return hazards.sublist(0, limit);
  }

  Future<List<HazardEventEntity>> getHazardsBetween({
    required DateTime start,
    required DateTime end,
  }) async {
    final Box<HazardEventEntity> box = await LocalDb.hazardEventsBox();

    return box.values
        .where(
          (HazardEventEntity event) =>
              !event.detectedAt.isBefore(start) &&
              !event.detectedAt.isAfter(end),
        )
        .toList()
      ..sort(_sortByDetectedAtDescending);
  }

  Future<void> deleteHazardsBetween({
    required DateTime start,
    required DateTime end,
  }) async {
    final Box<HazardEventEntity> box = await LocalDb.hazardEventsBox();
    final List<String> idsToDelete = box.values
        .where(
          (HazardEventEntity event) =>
              !event.detectedAt.isBefore(start) &&
              !event.detectedAt.isAfter(end),
        )
        .map((HazardEventEntity event) => event.id)
        .toList(growable: false);

    await box.deleteAll(idsToDelete);
  }

  int _sortByDetectedAtDescending(
    HazardEventEntity left,
    HazardEventEntity right,
  ) {
    return right.detectedAt.compareTo(left.detectedAt);
  }
}
