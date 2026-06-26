import 'package:hive/hive.dart';

import 'hazard_event_entity.dart';
import 'trip_event_entity.dart';

class LocalDb {
  LocalDb._();

  static const String hazardEventsBoxName = 'hazard_events';
  static const String tripEventsBoxName = 'trip_events';

  static bool _isInitialized = false;

  static Future<void> initialize({
    required String hiveDirectoryPath,
  }) async {
    if (!_isInitialized) {
      Hive.init(hiveDirectoryPath);
      _registerAdapters();
      _isInitialized = true;
    }

    await Future.wait(<Future<void>>[
      _openHazardEventsBox(),
      _openTripEventsBox(),
    ]);
  }

  static Future<Box<HazardEventEntity>> hazardEventsBox() async {
    _ensureInitialized();
    return _openHazardEventsBox();
  }

  static Future<Box<TripEventEntity>> tripEventsBox() async {
    _ensureInitialized();
    return _openTripEventsBox();
  }

  static Future<void> close() async {
    if (!_isInitialized) {
      return;
    }

    await Hive.close();
    _isInitialized = false;
  }

  static void _registerAdapters() {
    if (!Hive.isAdapterRegistered(HazardEventEntityAdapter.adapterTypeId)) {
      Hive.registerAdapter(HazardEventEntityAdapter());
    }

    if (!Hive.isAdapterRegistered(TripEventEntityAdapter.adapterTypeId)) {
      Hive.registerAdapter(TripEventEntityAdapter());
    }
  }

  static void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'LocalDb is not initialized. Call LocalDb.initialize() before use.',
      );
    }
  }

  static Future<Box<HazardEventEntity>> _openHazardEventsBox() {
    if (Hive.isBoxOpen(hazardEventsBoxName)) {
      return Future<Box<HazardEventEntity>>.value(
        Hive.box<HazardEventEntity>(hazardEventsBoxName),
      );
    }

    return Hive.openBox<HazardEventEntity>(hazardEventsBoxName);
  }

  static Future<Box<TripEventEntity>> _openTripEventsBox() {
    if (Hive.isBoxOpen(tripEventsBoxName)) {
      return Future<Box<TripEventEntity>>.value(
        Hive.box<TripEventEntity>(tripEventsBoxName),
      );
    }

    return Hive.openBox<TripEventEntity>(tripEventsBoxName);
  }
}
