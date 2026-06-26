import 'bounding_box.dart';
import 'object_type.dart';
import 'relative_position.dart';

class DetectedObject {
  const DetectedObject({
    required this.id,
    required this.label,
    required this.objectType,
    required this.confidence,
    required this.boundingBox,
    required this.estimatedDistanceMeters,
    required this.relativePosition,
    required this.firstSeenAt,
    required this.lastSeenAt,
  });

  final String id;
  final String label;
  final ObjectType objectType;
  final double confidence;
  final BoundingBox boundingBox;
  final double estimatedDistanceMeters;
  final RelativePosition relativePosition;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;

  bool isHighConfidence({double threshold = 0.7}) {
    return confidence >= threshold;
  }

  bool get isInDrivingPath {
    switch (relativePosition) {
      case RelativePosition.center:
      case RelativePosition.roadLane:
        return true;
      case RelativePosition.left:
      case RelativePosition.right:
      case RelativePosition.oppositeLane:
      case RelativePosition.roadside:
      case RelativePosition.unknown:
        return false;
    }
  }

  DetectedObject copyWith({
    String? id,
    String? label,
    ObjectType? objectType,
    double? confidence,
    BoundingBox? boundingBox,
    double? estimatedDistanceMeters,
    RelativePosition? relativePosition,
    DateTime? firstSeenAt,
    DateTime? lastSeenAt,
  }) {
    return DetectedObject(
      id: id ?? this.id,
      label: label ?? this.label,
      objectType: objectType ?? this.objectType,
      confidence: confidence ?? this.confidence,
      boundingBox: boundingBox ?? this.boundingBox,
      estimatedDistanceMeters:
          estimatedDistanceMeters ?? this.estimatedDistanceMeters,
      relativePosition: relativePosition ?? this.relativePosition,
      firstSeenAt: firstSeenAt ?? this.firstSeenAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }
}
