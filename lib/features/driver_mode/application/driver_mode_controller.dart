import 'package:flutter/foundation.dart';

import '../../../risk/risk_level.dart';

enum GpsStatus {
  active,
  waiting,
}

enum CameraStatus {
  ready,
  notReady,
}

class DriverModeController extends ChangeNotifier {
  DriverModeController({
    bool isDetectionActive = false,
    RiskLevel currentRiskLevel = RiskLevel.low,
    GpsStatus gpsStatus = GpsStatus.waiting,
    CameraStatus cameraStatus = CameraStatus.notReady,
    double currentSpeedKmph = 0,
  })  : _isDetectionActive = isDetectionActive,
        _currentRiskLevel = currentRiskLevel,
        _gpsStatus = gpsStatus,
        _cameraStatus = cameraStatus,
        _currentSpeedKmph = currentSpeedKmph;

  bool _isDetectionActive;
  RiskLevel _currentRiskLevel;
  GpsStatus _gpsStatus;
  CameraStatus _cameraStatus;
  double _currentSpeedKmph;

  bool get isDetectionActive => _isDetectionActive;
  RiskLevel get currentRiskLevel => _currentRiskLevel;
  GpsStatus get gpsStatus => _gpsStatus;
  CameraStatus get cameraStatus => _cameraStatus;
  double get currentSpeedKmph => _currentSpeedKmph;

  void startDetection() {
    _isDetectionActive = true;
    _gpsStatus = GpsStatus.active;
    _cameraStatus = CameraStatus.ready;
    _currentRiskLevel = RiskLevel.low;
    _currentSpeedKmph = 42;
    notifyListeners();
  }

  void stopDetection() {
    _isDetectionActive = false;
    _gpsStatus = GpsStatus.waiting;
    _cameraStatus = CameraStatus.notReady;
    _currentRiskLevel = RiskLevel.low;
    _currentSpeedKmph = 0;
    notifyListeners();
  }

  void toggleDetection() {
    if (_isDetectionActive) {
      stopDetection();
    } else {
      startDetection();
    }
  }

  void setRiskLevel(RiskLevel riskLevel) {
    _currentRiskLevel = riskLevel;
    notifyListeners();
  }

  void setGpsStatus(GpsStatus status) {
    _gpsStatus = status;
    notifyListeners();
  }

  void setCameraStatus(CameraStatus status) {
    _cameraStatus = status;
    notifyListeners();
  }

  void setCurrentSpeedKmph(double speedKmph) {
    _currentSpeedKmph = speedKmph;
    notifyListeners();
  }
}
