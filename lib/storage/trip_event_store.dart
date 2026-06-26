import 'package:hive/hive.dart';

import 'local_db.dart';
import 'trip_event_entity.dart';

class TripEventStore {
  const TripEventStore();

  Future<void> saveTripEvent(TripEventEntity event) async {
    final Box<TripEventEntity> box = await LocalDb.tripEventsBox();
    await box.put(event.id, event);
  }

  Future<List<TripEventEntity>> getTripEvents({
    String? tripId,
  }) async {
    final Box<TripEventEntity> box = await LocalDb.tripEventsBox();

    final Iterable<TripEventEntity> events = tripId == null
        ? box.values
        : box.values.where((TripEventEntity event) => event.tripId == tripId);

    return events.toList()..sort(_sortByCreatedAtAscending);
  }

  Future<TripEventEntity?> getLatestTripEvent() async {
    final List<TripEventEntity> events = await getTripEvents();
    if (events.isEmpty) {
      return null;
    }

    return events.last;
  }

  Future<void> deleteTripEvents(String tripId) async {
    final Box<TripEventEntity> box = await LocalDb.tripEventsBox();
    final List<String> idsToDelete = box.values
        .where((TripEventEntity event) => event.tripId == tripId)
        .map((TripEventEntity event) => event.id)
        .toList(growable: false);

    await box.deleteAll(idsToDelete);
  }

  int _sortByCreatedAtAscending(
    TripEventEntity left,
    TripEventEntity right,
  ) {
    return left.createdAt.compareTo(right.createdAt);
  }
}
