import '../../sensors/device_motion_sample.dart';
import '../../sensors/location_sample.dart';
import 'detection_frame_result.dart';
import 'detected_object.dart';
import 'object_type.dart';

enum HumpConfirmationStatus {
  none,
  visualCandidate,
  sensorConfirmed,
  possibleRoadHump,
  possibleUnmarkedBump,
  confirmedRoadHump,
}

class HumpConfirmationResult {
  const HumpConfirmationResult({
    required this.status,
    required this.confidence,
    required this.reason,
    required this.timestamp,
    this.location,
  });

  final HumpConfirmationStatus status;
  final double confidence;
  final String reason;
  final DateTime timestamp;
  final LocationSample? location;
}

class HumpConfirmationService {
  HumpConfirmationService({
    this.visualConfidenceThreshold = 0.7,
    this.confirmationWindow = const Duration(seconds: 2),
  });

  final double visualConfidenceThreshold;
  final Duration confirmationWindow;

  DateTime? _lastVisualCandidateAt;
  DetectedObject? _lastVisualCandidate;
  DateTime? _lastSensorImpactAt;
  DeviceMotionSample? _lastSensorImpact;

  HumpConfirmationResult evaluate({
    required DetectionFrameResult detectionFrameResult,
    required DeviceMotionSample? motionSample,
    required double currentVehicleSpeedKmph,
    LocationSample? location,
  }) {
    final DateTime timestamp = detectionFrameResult.timestamp;
    final DetectedObject? visualHump = _findVisualHump(detectionFrameResult);

    if (visualHump != null) {
      _lastVisualCandidate = visualHump;
      _lastVisualCandidateAt = timestamp;
    }

    if (motionSample != null && motionSample.isImpactDetected) {
      _lastSensorImpact = motionSample;
      _lastSensorImpactAt = motionSample.timestamp;
    }

    final bool visualCandidate = visualHump != null;
    final bool sensorConfirmed = _hasRecentSensorImpact(referenceTime: timestamp);
    final bool combinedConfirmation = visualCandidate &&
        sensorConfirmed &&
        _isWithinConfirmationWindow(
          _lastVisualCandidateAt,
          _lastSensorImpactAt,
        );

    if (combinedConfirmation) {
      return HumpConfirmationResult(
        status: HumpConfirmationStatus.confirmedRoadHump,
        confidence: _combinedConfidence(
          visualConfidence: visualHump!.confidence,
          motionSample: _lastSensorImpact,
        ),
        reason:
            'Visual road hump detection was followed by a vertical acceleration spike within the confirmation window.',
        timestamp: timestamp,
        location: location,
      );
    }

    if (visualCandidate) {
      return HumpConfirmationResult(
        status: HumpConfirmationStatus.possibleRoadHump,
        confidence: visualHump!.confidence,
        reason:
            'Camera detected a likely road hump, but no matching motion spike has been observed yet.',
        timestamp: timestamp,
        location: location,
      );
    }

    if (motionSample != null &&
        motionSample.isImpactDetected &&
        currentVehicleSpeedKmph > 5) {
      return HumpConfirmationResult(
        status: HumpConfirmationStatus.possibleUnmarkedBump,
        confidence: _sensorOnlyConfidence(motionSample),
        reason:
            'A vertical acceleration spike was detected without visual hump confirmation.',
        timestamp: motionSample.timestamp,
        location: location,
      );
    }

    if (sensorConfirmed) {
      return HumpConfirmationResult(
        status: HumpConfirmationStatus.sensorConfirmed,
        confidence: _sensorOnlyConfidence(_lastSensorImpact),
        reason: 'A recent vertical acceleration spike was detected.',
        timestamp: _lastSensorImpactAt ?? timestamp,
        location: location,
      );
    }

    return HumpConfirmationResult(
      status: HumpConfirmationStatus.none,
      confidence: 0,
      reason: 'No road hump evidence is currently available.',
      timestamp: timestamp,
      location: location,
    );
  }

  DetectedObject? _findVisualHump(DetectionFrameResult frameResult) {
    for (final DetectedObject detection in frameResult.detections) {
      if (detection.objectType == ObjectType.roadHump &&
          detection.confidence >= visualConfidenceThreshold) {
        return detection;
      }
    }

    return null;
  }

  bool _hasRecentSensorImpact({
    required DateTime referenceTime,
  }) {
    final DateTime? sensorImpactAt = _lastSensorImpactAt;
    if (sensorImpactAt == null) {
      return false;
    }

    return referenceTime.difference(sensorImpactAt).abs() <= confirmationWindow;
  }

  bool _isWithinConfirmationWindow(
    DateTime? visualTime,
    DateTime? sensorTime,
  ) {
    if (visualTime == null || sensorTime == null) {
      return false;
    }

    return sensorTime.difference(visualTime).abs() <= confirmationWindow;
  }

  double _combinedConfidence({
    required double visualConfidence,
    required DeviceMotionSample? motionSample,
  }) {
    final double sensorConfidence = _sensorOnlyConfidence(motionSample);
    return ((visualConfidence + sensorConfidence) / 2).clamp(0, 1);
  }

  double _sensorOnlyConfidence(DeviceMotionSample? motionSample) {
    if (motionSample == null) {
      return 0;
    }

    final double scaled =
        (motionSample.verticalImpactMagnitude / 10).clamp(0, 1).toDouble();
    return scaled;
  }
}
