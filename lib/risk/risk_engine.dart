import '../ai/detection/detected_object.dart';
import '../ai/detection/detection_frame_result.dart';
import '../ai/detection/object_type.dart';
import 'risk_decision.dart';
import 'risk_level.dart';
import 'risk_score.dart';

class RiskEngine {
  const RiskEngine();

  RiskDecision evaluateFrame(DetectionFrameResult frameResult) {
    if (frameResult.detections.isEmpty) {
      return RiskDecision(
        riskLevel: RiskLevel.none,
        primaryMessage: 'Road clear',
        detectedObject: null,
        reason: 'No relevant hazards detected in the current frame.',
        shouldAlert: false,
        timestamp: frameResult.timestamp,
      );
    }

    DetectedObject? highestRiskObject;
    RiskScore highestRiskScore = const RiskScore(
      value: 0,
      level: RiskLevel.none,
    );
    String highestRiskReason = 'No hazard matched scoring rules.';

    for (final DetectedObject detection in frameResult.detections) {
      final _ScoredObject scored = _scoreDetection(detection);
      if (scored.score.value > highestRiskScore.value) {
        highestRiskObject = detection;
        highestRiskScore = scored.score;
        highestRiskReason = scored.reason;
      }
    }

    if (highestRiskObject == null) {
      return RiskDecision(
        riskLevel: RiskLevel.none,
        primaryMessage: 'Road clear',
        detectedObject: null,
        reason: 'No hazard exceeded the minimum alert threshold.',
        shouldAlert: false,
        timestamp: frameResult.timestamp,
      );
    }

    return RiskDecision(
      riskLevel: highestRiskScore.level,
      primaryMessage: _buildPrimaryMessage(highestRiskObject),
      detectedObject: highestRiskObject,
      reason: highestRiskReason,
      shouldAlert: highestRiskScore.level != RiskLevel.none,
      timestamp: frameResult.timestamp,
    );
  }

  _ScoredObject _scoreDetection(DetectedObject detection) {
    switch (detection.objectType) {
      case ObjectType.person:
        return _scorePerson(detection);
      case ObjectType.car:
      case ObjectType.bus:
      case ObjectType.truck:
      case ObjectType.motorcycle:
      case ObjectType.bicycle:
      case ObjectType.autoRickshaw:
        return _scoreVehicle(detection);
      case ObjectType.pothole:
        return _scorePothole(detection);
      case ObjectType.roadHump:
        return _scoreRoadHump(detection);
      case ObjectType.unknownObstacle:
      case ObjectType.animal:
      case ObjectType.unknown:
        return _scoreUnknownObstacle(detection);
    }
  }

  _ScoredObject _scorePerson(DetectedObject detection) {
    if (detection.isInDrivingPath &&
        detection.estimatedDistanceMeters < 10 &&
        detection.isHighConfidence()) {
      return const _ScoredObject(
        score: RiskScore(value: 100, level: RiskLevel.critical),
        reason: 'Person detected in driving path under 10 meters.',
      );
    }

    if (detection.isInDrivingPath &&
        detection.estimatedDistanceMeters >= 10 &&
        detection.estimatedDistanceMeters <= 25) {
      return const _ScoredObject(
        score: RiskScore(value: 85, level: RiskLevel.high),
        reason: 'Person detected in driving path between 10 and 25 meters.',
      );
    }

    if (detection.estimatedDistanceMeters > 25 &&
        detection.estimatedDistanceMeters <= 50) {
      return const _ScoredObject(
        score: RiskScore(value: 60, level: RiskLevel.medium),
        reason: 'Person detected near the road between 25 and 50 meters.',
      );
    }

    return const _ScoredObject(
      score: RiskScore(value: 15, level: RiskLevel.low),
      reason: 'Person detected outside the highest-risk distance bands.',
    );
  }

  _ScoredObject _scoreVehicle(DetectedObject detection) {
    if (detection.isInDrivingPath && detection.estimatedDistanceMeters < 20) {
      return const _ScoredObject(
        score: RiskScore(value: 80, level: RiskLevel.high),
        reason: 'Vehicle detected in driving path under 20 meters.',
      );
    }

    if (detection.isInDrivingPath && detection.estimatedDistanceMeters <= 50) {
      return const _ScoredObject(
        score: RiskScore(value: 55, level: RiskLevel.medium),
        reason: 'Vehicle detected in driving path between 20 and 50 meters.',
      );
    }

    return const _ScoredObject(
      score: RiskScore(value: 25, level: RiskLevel.low),
      reason: 'Vehicle detected outside the driving path or on the roadside.',
    );
  }

  _ScoredObject _scorePothole(DetectedObject detection) {
    if (detection.isInDrivingPath && detection.estimatedDistanceMeters < 15) {
      return const _ScoredObject(
        score: RiskScore(value: 78, level: RiskLevel.high),
        reason: 'Pothole detected in driving path under 15 meters.',
      );
    }

    if (detection.isInDrivingPath && detection.estimatedDistanceMeters <= 30) {
      return const _ScoredObject(
        score: RiskScore(value: 52, level: RiskLevel.medium),
        reason: 'Pothole detected in driving path between 15 and 30 meters.',
      );
    }

    return const _ScoredObject(
      score: RiskScore(value: 20, level: RiskLevel.low),
      reason: 'Pothole detected outside the immediate driving path.',
    );
  }

  _ScoredObject _scoreRoadHump(DetectedObject detection) {
    if (detection.isInDrivingPath && detection.estimatedDistanceMeters < 15) {
      return const _ScoredObject(
        score: RiskScore(value: 70, level: RiskLevel.high),
        reason: 'Road hump detected in driving path under 15 meters.',
      );
    }

    if (detection.isInDrivingPath && detection.estimatedDistanceMeters < 30) {
      return const _ScoredObject(
        score: RiskScore(value: 48, level: RiskLevel.medium),
        reason: 'Road hump detected in driving path under 30 meters.',
      );
    }

    return const _ScoredObject(
      score: RiskScore(value: 12, level: RiskLevel.low),
      reason: 'Road hump detected outside the higher-risk distance range.',
    );
  }

  _ScoredObject _scoreUnknownObstacle(DetectedObject detection) {
    if (detection.isInDrivingPath && detection.estimatedDistanceMeters < 20) {
      final bool highConfidence = detection.isHighConfidence(threshold: 0.8);

      return _ScoredObject(
        score: RiskScore(
          value: highConfidence ? 68 : 45,
          level: highConfidence ? RiskLevel.high : RiskLevel.medium,
        ),
        reason: highConfidence
            ? 'High-confidence unknown obstacle detected in driving path under 20 meters.'
            : 'Unknown obstacle detected in driving path under 20 meters with moderate confidence.',
      );
    }

    return const _ScoredObject(
      score: RiskScore(value: 18, level: RiskLevel.low),
      reason: 'Unknown obstacle detected outside the primary alert range.',
    );
  }

  String _buildPrimaryMessage(DetectedObject detection) {
    switch (detection.objectType) {
      case ObjectType.person:
        return 'Person crossing ahead';
      case ObjectType.car:
      case ObjectType.bus:
      case ObjectType.truck:
      case ObjectType.motorcycle:
      case ObjectType.bicycle:
      case ObjectType.autoRickshaw:
        return 'Vehicle ahead';
      case ObjectType.pothole:
        return 'Large pothole ahead';
      case ObjectType.roadHump:
        return 'Road hump ahead';
      case ObjectType.animal:
      case ObjectType.unknownObstacle:
      case ObjectType.unknown:
        return 'Obstacle ahead';
    }
  }
}

class _ScoredObject {
  const _ScoredObject({
    required this.score,
    required this.reason,
  });

  final RiskScore score;
  final String reason;
}
