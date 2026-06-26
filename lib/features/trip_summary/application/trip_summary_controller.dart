import 'package:flutter/foundation.dart';

import '../../../storage/hazard_event_entity.dart';
import '../../../storage/hazard_event_store.dart';
import '../../../storage/trip_event_entity.dart';
import '../../../storage/trip_event_store.dart';

class TripSummaryData {
  const TripSummaryData({
    required this.tripId,
    required this.tripDuration,
    required this.totalHazardsDetected,
    required this.potholes,
    required this.roadHumps,
    required this.pedestrianAlerts,
    required this.vehicleAlerts,
    required this.criticalAlerts,
    required this.timeline,
    required this.tripStartedAt,
    required this.tripEndedAt,
  });

  final String tripId;
  final Duration tripDuration;
  final int totalHazardsDetected;
  final int potholes;
  final int roadHumps;
  final int pedestrianAlerts;
  final int vehicleAlerts;
  final int criticalAlerts;
  final List<TripTimelineItem> timeline;
  final DateTime tripStartedAt;
  final DateTime tripEndedAt;

  static const TripSummaryData empty = TripSummaryData(
    tripId: '',
    tripDuration: Duration.zero,
    totalHazardsDetected: 0,
    potholes: 0,
    roadHumps: 0,
    pedestrianAlerts: 0,
    vehicleAlerts: 0,
    criticalAlerts: 0,
    timeline: <TripTimelineItem>[],
    tripStartedAt: DateTime.fromMillisecondsSinceEpoch(0),
    tripEndedAt: DateTime.fromMillisecondsSinceEpoch(0),
  );
}

class TripTimelineItem {
  const TripTimelineItem({
    required this.timestamp,
    required this.title,
    required this.subtitle,
    required this.severityLabel,
  });

  final DateTime timestamp;
  final String title;
  final String subtitle;
  final String severityLabel;
}

class TripSummaryController extends ChangeNotifier {
  TripSummaryController({
    TripEventStore? tripEventStore,
    HazardEventStore? hazardEventStore,
  })  : _tripEventStore = tripEventStore ?? const TripEventStore(),
        _hazardEventStore = hazardEventStore ?? const HazardEventStore();

  final TripEventStore _tripEventStore;
  final HazardEventStore _hazardEventStore;

  TripSummaryData _summary = TripSummaryData.empty;
  bool _isLoading = false;
  bool _hasData = false;
  String? _statusMessage;

  TripSummaryData get summary => _summary;
  bool get isLoading => _isLoading;
  bool get hasData => _hasData;
  String? get statusMessage => _statusMessage;

  Future<void> load() async {
    _isLoading = true;
    _statusMessage = null;
    notifyListeners();

    try {
      final TripEventEntity? latestTripEvent =
          await _tripEventStore.getLatestTripEvent();

      if (latestTripEvent == null) {
        _summary = TripSummaryData.empty;
        _hasData = false;
        return;
      }

      final List<TripEventEntity> tripEvents = await _tripEventStore.getTripEvents(
        tripId: latestTripEvent.tripId,
      );

      if (tripEvents.isEmpty) {
        _summary = TripSummaryData.empty;
        _hasData = false;
        return;
      }

      final DateTime start = tripEvents.first.createdAt;
      final DateTime end = tripEvents.last.createdAt;
      final List<HazardEventEntity> hazards =
          await _hazardEventStore.getHazardsBetween(
        start: start,
        end: end,
      );

      _summary = TripSummaryData(
        tripId: latestTripEvent.tripId,
        tripDuration: end.difference(start),
        totalHazardsDetected: hazards.length,
        potholes: _countHazards(hazards, 'pothole'),
        roadHumps: _countHazards(hazards, 'roadHump'),
        pedestrianAlerts: _countHazards(hazards, 'person'),
        vehicleAlerts: _countVehicleHazards(hazards),
        criticalAlerts: hazards
            .where((HazardEventEntity event) => event.riskLevel == 'critical')
            .length,
        timeline: _buildTimeline(
          tripEvents: tripEvents,
          hazards: hazards,
        ),
        tripStartedAt: start,
        tripEndedAt: end,
      );
      _hasData = true;
    } catch (error) {
      _summary = TripSummaryData.empty;
      _hasData = false;
      _statusMessage = 'Trip summary could not be loaded.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearCurrentTrip() async {
    if (!_hasData || _summary.tripId.isEmpty) {
      return;
    }

    try {
      await _tripEventStore.deleteTripEvents(_summary.tripId);
      await _hazardEventStore.deleteHazardsBetween(
        start: _summary.tripStartedAt,
        end: _summary.tripEndedAt,
      );
      _summary = TripSummaryData.empty;
      _hasData = false;
      _statusMessage = 'Current trip was cleared.';
    } catch (error) {
      _statusMessage = 'Current trip could not be cleared.';
    }

    notifyListeners();
  }

  void clearStatusMessage() {
    _statusMessage = null;
  }

  int _countHazards(List<HazardEventEntity> hazards, String hazardType) {
    return hazards
        .where((HazardEventEntity event) => event.hazardType == hazardType)
        .length;
  }

  int _countVehicleHazards(List<HazardEventEntity> hazards) {
    const Set<String> vehicleTypes = <String>{
      'car',
      'bus',
      'truck',
      'motorcycle',
      'bicycle',
      'autoRickshaw',
    };

    return hazards
        .where((HazardEventEntity event) => vehicleTypes.contains(event.hazardType))
        .length;
  }

  List<TripTimelineItem> _buildTimeline({
    required List<TripEventEntity> tripEvents,
    required List<HazardEventEntity> hazards,
  }) {
    final List<TripTimelineItem> items = <TripTimelineItem>[
      ...tripEvents.map(
        (TripEventEntity event) => TripTimelineItem(
          timestamp: event.createdAt,
          title: event.eventType,
          subtitle: event.message,
          severityLabel: 'trip',
        ),
      ),
      ...hazards.map(
        (HazardEventEntity event) => TripTimelineItem(
          timestamp: event.detectedAt,
          title: event.hazardType,
          subtitle:
              '${event.riskLevel} risk at ${event.estimatedDistanceMeters.toStringAsFixed(0)} m',
          severityLabel: event.riskLevel,
        ),
      ),
    ];

    items.sort(
      (TripTimelineItem left, TripTimelineItem right) =>
          right.timestamp.compareTo(left.timestamp),
    );

    return items;
  }
}
