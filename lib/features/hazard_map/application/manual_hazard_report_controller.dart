import 'package:flutter/foundation.dart';

import '../../../networking/hazard_api.dart';
import '../../../networking/api_result.dart';
import '../../../sensors/gps_service.dart';
import '../../../sensors/location_sample.dart';
import '../../../storage/hazard_event_entity.dart';
import '../../../storage/hazard_event_store.dart';

enum ManualHazardType {
  pothole,
  roadHump,
  waterLogging,
  obstacle,
  accidentRisk,
  pedestrianRisk,
  other,
}

enum ManualHazardReportStatus {
  idle,
  loadingLocation,
  ready,
  submitting,
  success,
  partialSuccess,
  failure,
}

class ManualHazardReportController extends ChangeNotifier {
  ManualHazardReportController({
    GpsService? gpsService,
    HazardEventStore? hazardEventStore,
    HazardApi? hazardApi,
    this.deviceId = 'roadguard-device',
  })  : _gpsService = gpsService ?? const GpsService(),
        _hazardEventStore = hazardEventStore ?? const HazardEventStore(),
        _hazardApi = hazardApi ?? HazardApi();

  final GpsService _gpsService;
  final HazardEventStore _hazardEventStore;
  final HazardApi _hazardApi;
  final String deviceId;

  ManualHazardType? _selectedHazardType;
  String _note = '';
  String? _photoPlaceholderLabel;
  LocationSample? _currentLocation;
  ManualHazardReportStatus _status = ManualHazardReportStatus.idle;
  String? _statusMessage;
  String? _validationMessage;

  ManualHazardType? get selectedHazardType => _selectedHazardType;
  String get note => _note;
  String? get photoPlaceholderLabel => _photoPlaceholderLabel;
  LocationSample? get currentLocation => _currentLocation;
  ManualHazardReportStatus get status => _status;
  String? get statusMessage => _statusMessage;
  String? get validationMessage => _validationMessage;
  bool get isSubmitting => _status == ManualHazardReportStatus.submitting;
  bool get isLoadingLocation =>
      _status == ManualHazardReportStatus.loadingLocation;

  Future<void> initialize() async {
    _status = ManualHazardReportStatus.loadingLocation;
    _statusMessage = null;
    _validationMessage = null;
    notifyListeners();

    await _loadCurrentLocation();

    if (_currentLocation != null) {
      _status = ManualHazardReportStatus.ready;
    } else if (_status != ManualHazardReportStatus.failure) {
      _status = ManualHazardReportStatus.idle;
    }

    notifyListeners();
  }

  void setHazardType(ManualHazardType? hazardType) {
    _selectedHazardType = hazardType;
    _validationMessage = null;
    notifyListeners();
  }

  void setNote(String value) {
    _note = value;
  }

  void setPhotoPlaceholderLabel(String? value) {
    _photoPlaceholderLabel = value;
    notifyListeners();
  }

  void clearStatusMessage() {
    _statusMessage = null;
  }

  Future<void> refreshLocation() async {
    _status = ManualHazardReportStatus.loadingLocation;
    _statusMessage = null;
    notifyListeners();

    await _loadCurrentLocation();

    if (_currentLocation != null) {
      _status = ManualHazardReportStatus.ready;
    } else if (_status != ManualHazardReportStatus.failure) {
      _status = ManualHazardReportStatus.idle;
    }

    notifyListeners();
  }

  Future<bool> submitReport() async {
    _validationMessage = _validate();
    if (_validationMessage != null) {
      notifyListeners();
      return false;
    }

    _status = ManualHazardReportStatus.submitting;
    _statusMessage = null;
    notifyListeners();

    final DateTime now = DateTime.now().toUtc();
    final LocationSample currentLocation = _currentLocation!;
    final HazardEventEntity event = HazardEventEntity(
      id: 'manual-${now.microsecondsSinceEpoch}',
      hazardType: _hazardTypeValue(_selectedHazardType!),
      riskLevel: 'medium',
      latitude: currentLocation.latitude,
      longitude: currentLocation.longitude,
      confidence: 1,
      estimatedDistanceMeters: 0,
      detectedAt: now,
      syncedToCloud: false,
      imagePath: _photoPlaceholderLabel,
    );

    try {
      await _hazardEventStore.saveHazardEvent(event);
    } catch (_) {
      _status = ManualHazardReportStatus.failure;
      _statusMessage = 'The report could not be saved locally.';
      notifyListeners();
      return false;
    }

    final ApiResult<Map<String, dynamic>> uploadResult =
        await _hazardApi.uploadHazardEvent(
      event: event,
      deviceId: deviceId,
    );

    if (uploadResult.isSuccess) {
      await _hazardEventStore.markHazardSynced(event.id);
      _status = ManualHazardReportStatus.success;
      _statusMessage = 'Hazard report saved locally and uploaded.';
      notifyListeners();
      return true;
    }

    _status = ManualHazardReportStatus.partialSuccess;
    _statusMessage =
        'Hazard report saved locally. Cloud upload will retry later.';
    notifyListeners();
    return true;
  }

  Future<void> _loadCurrentLocation() async {
    final LocationAccessState accessState =
        await _gpsService.ensureLocationAccess();

    switch (accessState) {
      case LocationAccessState.granted:
        _currentLocation = await _gpsService.getCurrentLocation();
        if (_currentLocation == null) {
          _status = ManualHazardReportStatus.failure;
          _statusMessage = 'Current GPS location is not available yet.';
        }
        return;
      case LocationAccessState.denied:
        _currentLocation = null;
        _status = ManualHazardReportStatus.failure;
        _statusMessage =
            'Location permission is required to submit a hazard report.';
        return;
      case LocationAccessState.deniedForever:
        _currentLocation = null;
        _status = ManualHazardReportStatus.failure;
        _statusMessage =
            'Location permission is permanently denied. Enable it in settings to report hazards.';
        return;
      case LocationAccessState.serviceDisabled:
        _currentLocation = null;
        _status = ManualHazardReportStatus.failure;
        _statusMessage =
            'GPS is disabled. Turn on location services to report hazards.';
        return;
    }
  }

  String? _validate() {
    if (_selectedHazardType == null) {
      return 'Select a hazard type to continue.';
    }

    if (_currentLocation == null) {
      return 'Current GPS location is required before submitting a report.';
    }

    return null;
  }

  String _hazardTypeValue(ManualHazardType hazardType) {
    switch (hazardType) {
      case ManualHazardType.pothole:
        return 'pothole';
      case ManualHazardType.roadHump:
        return 'roadHump';
      case ManualHazardType.waterLogging:
        return 'waterLogging';
      case ManualHazardType.obstacle:
        return 'unknownObstacle';
      case ManualHazardType.accidentRisk:
        return 'accidentRisk';
      case ManualHazardType.pedestrianRisk:
        return 'pedestrianRisk';
      case ManualHazardType.other:
        return 'other';
    }
  }
}
