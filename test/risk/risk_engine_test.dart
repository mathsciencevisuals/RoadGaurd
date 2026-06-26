import 'package:flutter_test/flutter_test.dart';
import 'package:roadguard/ai/detection/bounding_box.dart';
import 'package:roadguard/ai/detection/detected_object.dart';
import 'package:roadguard/ai/detection/detection_frame_result.dart';
import 'package:roadguard/ai/detection/object_type.dart';
import 'package:roadguard/ai/detection/relative_position.dart';
import 'package:roadguard/risk/risk_engine.dart';
import 'package:roadguard/risk/risk_level.dart';

void main() {
  group('RiskEngine', () {
    const RiskEngine riskEngine = RiskEngine();
    final DateTime timestamp = DateTime.utc(2026, 1, 1, 12);

    test('person under 10 meters in driving path returns critical', () {
      final DetectionFrameResult frame = DetectionFrameResult(
        frameId: 'frame-1',
        timestamp: timestamp,
        detections: <DetectedObject>[
          _detectedObject(
            id: 'person-1',
            objectType: ObjectType.person,
            label: 'person',
            distance: 8,
            relativePosition: RelativePosition.roadLane,
            confidence: 0.92,
          ),
        ],
        processingTimeMs: 12,
        modelName: 'rg',
        modelVersion: '1',
      );

      final decision = riskEngine.evaluateFrame(frame);

      expect(decision.riskLevel, RiskLevel.critical);
      expect(decision.shouldAlert, isTrue);
    });

    test('pothole under 15 meters in driving path returns high', () {
      final DetectionFrameResult frame = DetectionFrameResult(
        frameId: 'frame-2',
        timestamp: timestamp,
        detections: <DetectedObject>[
          _detectedObject(
            id: 'pothole-1',
            objectType: ObjectType.pothole,
            label: 'pothole',
            distance: 12,
            relativePosition: RelativePosition.roadLane,
            confidence: 0.88,
          ),
        ],
        processingTimeMs: 14,
        modelName: 'rg',
        modelVersion: '1',
      );

      final decision = riskEngine.evaluateFrame(frame);

      expect(decision.riskLevel, RiskLevel.high);
    });

    test('vehicle at 40 meters in driving path returns medium', () {
      final DetectionFrameResult frame = DetectionFrameResult(
        frameId: 'frame-3',
        timestamp: timestamp,
        detections: <DetectedObject>[
          _detectedObject(
            id: 'car-1',
            objectType: ObjectType.car,
            label: 'car',
            distance: 40,
            relativePosition: RelativePosition.roadLane,
            confidence: 0.8,
          ),
        ],
        processingTimeMs: 10,
        modelName: 'rg',
        modelVersion: '1',
      );

      final decision = riskEngine.evaluateFrame(frame);

      expect(decision.riskLevel, RiskLevel.medium);
    });
  });
}

DetectedObject _detectedObject({
  required String id,
  required ObjectType objectType,
  required String label,
  required double distance,
  required RelativePosition relativePosition,
  required double confidence,
}) {
  final DateTime now = DateTime.utc(2026, 1, 1, 12);

  return DetectedObject(
    id: id,
    label: label,
    objectType: objectType,
    confidence: confidence,
    boundingBox: const BoundingBox(
      x: 100,
      y: 100,
      width: 200,
      height: 200,
      imageWidth: 1000,
      imageHeight: 1000,
    ),
    estimatedDistanceMeters: distance,
    relativePosition: relativePosition,
    firstSeenAt: now,
    lastSeenAt: now,
  );
}
