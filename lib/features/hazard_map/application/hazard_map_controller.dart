import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../networking/hazard_api.dart';
import '../../../sensors/gps_service.dart';
import '../../../sensors/location_sample.dart';
import '../../../storage/hazard_event_entity.dart';
import '../../../storage/hazard_event_store.dart';

class HazardMapController extends ChangeNotifier {
  HazardMapController({
    GpsService? gpsService,
    HazardEventStore? hazardEventStore,
    HazardApi? hazardApi,
    this.searchRadiusMeters = 1000,
  })  : _gpsService = gpsService ?? const GpsService(),
        _hazardEventStore = hazardEventStore ?? const HazardEventStore(),
        _hazardApi = hazardApi ?? HazardApi();

  final GpsService _gpsService;
  final HazardEventStore _hazardEventStore;
  final HazardApi _hazardApi;
  final double searchRadiusMeters;

  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _hasLocationPermission = false;
  String? _statusMessage;
  String? _locationErrorMessage;
  LocationSample? _currentLocation;
  Set<Marker> _markers = <Marker>{};
  List<HazardMapItem> _hazards = const <HazardMapItem>[];

  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get hasLocationPermission => _hasLocationPermission;
  String? get statusMessage => _statusMessage;
  String? get locationErrorMessage => _locationErrorMessage;
  LocationSample? get currentLocation => _currentLocation;
  Set<Marker> get markers => _markers;
  List<HazardMapItem> get hazards => _hazards;

  CameraPosition get initialCameraPosition {
    final LocationSample? location = _currentLocation;
    return CameraPosition(
      target: LatLng(
        location?.latitude ?? 37.4219999,
        location?.longitude ?? -122.0840575,
      ),
      zoom: location == null ? 11 : 15,
    );
  }

  Future<void> initialize() async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _resolveCurrentLocation();
      if (_currentLocation == null) {
        _markers = <Marker>{};
        _hazards = const <HazardMapItem>[];
        return;
      }

      await _loadNearbyHazards();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshNearbyHazards() async {
    if (_isRefreshing) {
      return;
    }

    _isRefreshing = true;
    _statusMessage = null;
    notifyListeners();

    try {
      await _resolveCurrentLocation();
      if (_currentLocation == null) {
        _markers = <Marker>{};
        _hazards = const <HazardMapItem>[];
        return;
      }

      await _loadNearbyHazards();
      _statusMessage = 'Nearby hazards refreshed.';
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  void clearStatusMessage() {
    _statusMessage = null;
  }

  Future<void> _resolveCurrentLocation() async {
    final LocationAccessState accessState =
        await _gpsService.ensureLocationAccess();

    switch (accessState) {
      case LocationAccessState.granted:
        _hasLocationPermission = true;
        _locationErrorMessage = null;
        _currentLocation = await _gpsService.getCurrentLocation();
        if (_currentLocation == null) {
          _locationErrorMessage = 'Current location is not available yet.';
        }
        return;
      case LocationAccessState.denied:
        _hasLocationPermission = false;
        _locationErrorMessage =
            'Location permission is required to show nearby hazards.';
        _currentLocation = null;
        return;
      case LocationAccessState.deniedForever:
        _hasLocationPermission = false;
        _locationErrorMessage =
            'Location permission is permanently denied. Enable it in settings to use the hazard map.';
        _currentLocation = null;
        return;
      case LocationAccessState.serviceDisabled:
        _hasLocationPermission = false;
        _locationErrorMessage =
            'GPS is disabled. Turn on location services to load nearby hazards.';
        _currentLocation = null;
        return;
    }
  }

  Future<void> _loadNearbyHazards() async {
    final LocationSample currentLocation = _currentLocation!;
    final List<HazardMapItem> localHazards = await _loadLocalHazards(
      currentLocation: currentLocation,
    );

    _hazards = localHazards;
    _markers = _buildMarkers(localHazards);
    notifyListeners();

    final backendResult = await _hazardApi.fetchNearbyHazards(
      latitude: currentLocation.latitude,
      longitude: currentLocation.longitude,
      radiusMeters: searchRadiusMeters,
    );

    if (backendResult.isFailure) {
      if (_hazards.isEmpty) {
        _statusMessage =
            backendResult.message ?? 'Backend hazards are unavailable.';
      }
      return;
    }

    final List<HazardMapItem> mergedHazards = _mergeHazards(
      localHazards,
      _mapBackendHazards(backendResult.data ?? const <Map<String, dynamic>>[]),
    );
    _hazards = mergedHazards;
    _markers = _buildMarkers(mergedHazards);
  }

  Future<List<HazardMapItem>> _loadLocalHazards({
    required LocationSample currentLocation,
  }) async {
    final List<HazardEventEntity> hazards =
        await _hazardEventStore.getRecentHazards(limit: 200);

    return hazards
        .where(
          (HazardEventEntity event) => _distanceMeters(
                startLatitude: currentLocation.latitude,
                startLongitude: currentLocation.longitude,
                endLatitude: event.latitude,
                endLongitude: event.longitude,
              ) <=
              searchRadiusMeters,
        )
        .map(HazardMapItem.fromEntity)
        .toList(growable: false);
  }

  List<HazardMapItem> _mapBackendHazards(List<Map<String, dynamic>> items) {
    return items
        .map(HazardMapItem.fromBackendMap)
        .whereType<HazardMapItem>()
        .toList(growable: false);
  }

  List<HazardMapItem> _mergeHazards(
    List<HazardMapItem> localHazards,
    List<HazardMapItem> backendHazards,
  ) {
    final Map<String, HazardMapItem> merged = <String, HazardMapItem>{};

    for (final HazardMapItem item in localHazards) {
      merged[_hazardKey(item)] = item;
    }

    for (final HazardMapItem item in backendHazards) {
      merged[_hazardKey(item)] = item;
    }

    final List<HazardMapItem> values = merged.values.toList()
      ..sort(
        (HazardMapItem left, HazardMapItem right) =>
            right.detectedAt.compareTo(left.detectedAt),
      );
    return values;
  }

  String _hazardKey(HazardMapItem item) {
    return [
      item.hazardType,
      item.latitude.toStringAsFixed(5),
      item.longitude.toStringAsFixed(5),
      item.detectedAt.toUtc().toIso8601String().substring(0, 16),
    ].join('|');
  }

  Set<Marker> _buildMarkers(List<HazardMapItem> hazards) {
    return hazards.map((HazardMapItem item) {
      return Marker(
        markerId: MarkerId(item.id),
        position: LatLng(item.latitude, item.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _markerHueFor(item.hazardType),
        ),
        infoWindow: InfoWindow(
          title: _labelForHazardType(item.hazardType),
          snippet:
              'Risk: ${item.riskLevel.toUpperCase()}  •  Confidence: ${(item.confidence * 100).toStringAsFixed(0)}%  •  ${_formatDetectedTime(item.detectedAt)}',
        ),
      );
    }).toSet();
  }

  double _markerHueFor(String hazardType) {
    switch (hazardType) {
      case 'pothole':
        return BitmapDescriptor.hueOrange;
      case 'roadHump':
      case 'waterLogging':
        return BitmapDescriptor.hueYellow;
      case 'person':
      case 'pedestrianRisk':
        return BitmapDescriptor.hueAzure;
      case 'car':
      case 'bus':
      case 'truck':
      case 'motorcycle':
      case 'bicycle':
      case 'autoRickshaw':
      case 'vehicleRisk':
        return BitmapDescriptor.hueViolet;
      default:
        return BitmapDescriptor.hueRed;
    }
  }

  String _labelForHazardType(String hazardType) {
    switch (hazardType) {
      case 'roadHump':
        return 'Road Hump';
      case 'waterLogging':
        return 'Water Logging';
      case 'pedestrianRisk':
        return 'Pedestrian Risk';
      case 'vehicleRisk':
        return 'Vehicle Risk';
      default:
        if (hazardType.isEmpty) {
          return 'Unknown Hazard';
        }
        return hazardType
            .replaceAllMapped(
              RegExp(r'([A-Z])'),
              (Match match) => ' ${match.group(1)}',
            )
            .trim()
            .split(' ')
            .map(
              (String part) =>
                  '${part.substring(0, 1).toUpperCase()}${part.substring(1)}',
            )
            .join(' ');
    }
  }

  String _formatDetectedTime(DateTime detectedAt) {
    final DateTime utc = detectedAt.toLocal();
    final String hour = utc.hour.toString().padLeft(2, '0');
    final String minute = utc.minute.toString().padLeft(2, '0');
    return '${utc.year}-${utc.month.toString().padLeft(2, '0')}-${utc.day.toString().padLeft(2, '0')} $hour:$minute';
  }

  double _distanceMeters({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    const double earthRadiusMeters = 6371000;
    final double startLatRadians = _degreesToRadians(startLatitude);
    final double endLatRadians = _degreesToRadians(endLatitude);
    final double deltaLat = _degreesToRadians(endLatitude - startLatitude);
    final double deltaLon = _degreesToRadians(endLongitude - startLongitude);

    final double a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(startLatRadians) *
            math.cos(endLatRadians) *
            math.sin(deltaLon / 2) *
            math.sin(deltaLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }
}

class HazardMapItem {
  const HazardMapItem({
    required this.id,
    required this.hazardType,
    required this.riskLevel,
    required this.latitude,
    required this.longitude,
    required this.confidence,
    required this.detectedAt,
  });

  final String id;
  final String hazardType;
  final String riskLevel;
  final double latitude;
  final double longitude;
  final double confidence;
  final DateTime detectedAt;

  factory HazardMapItem.fromEntity(HazardEventEntity entity) {
    return HazardMapItem(
      id: entity.id,
      hazardType: entity.hazardType,
      riskLevel: entity.riskLevel,
      latitude: entity.latitude,
      longitude: entity.longitude,
      confidence: entity.confidence,
      detectedAt: entity.detectedAt,
    );
  }

  static HazardMapItem? fromBackendMap(Map<String, dynamic> map) {
    final double? latitude = _asDouble(map['latitude']);
    final double? longitude = _asDouble(map['longitude']);
    final double? confidence = _asDouble(map['confidence']);
    final String? detectedAtRaw = map['detected_at'] as String?;

    if (latitude == null ||
        longitude == null ||
        confidence == null ||
        detectedAtRaw == null) {
      return null;
    }

    return HazardMapItem(
      id: (map['id'] as String?) ?? 'backend-${latitude}_$longitude',
      hazardType: (map['hazard_type'] as String?) ?? 'unknownObstacle',
      riskLevel: (map['risk_level'] as String?) ?? 'low',
      latitude: latitude,
      longitude: longitude,
      confidence: confidence,
      detectedAt: DateTime.tryParse(detectedAtRaw) ?? DateTime.now(),
    );
  }

  static double? _asDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }
}
