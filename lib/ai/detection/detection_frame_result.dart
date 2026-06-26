import 'detected_object.dart';

class DetectionFrameResult {
  const DetectionFrameResult({
    required this.frameId,
    required this.timestamp,
    required this.detections,
    required this.processingTimeMs,
    required this.modelName,
    required this.modelVersion,
  });

  final String frameId;
  final DateTime timestamp;
  final List<DetectedObject> detections;
  final int processingTimeMs;
  final String modelName;
  final String modelVersion;

  DetectionFrameResult copyWith({
    String? frameId,
    DateTime? timestamp,
    List<DetectedObject>? detections,
    int? processingTimeMs,
    String? modelName,
    String? modelVersion,
  }) {
    return DetectionFrameResult(
      frameId: frameId ?? this.frameId,
      timestamp: timestamp ?? this.timestamp,
      detections: detections ?? this.detections,
      processingTimeMs: processingTimeMs ?? this.processingTimeMs,
      modelName: modelName ?? this.modelName,
      modelVersion: modelVersion ?? this.modelVersion,
    );
  }
}
