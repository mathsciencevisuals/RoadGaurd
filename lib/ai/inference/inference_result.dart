import '../detection/detection_frame_result.dart';
import 'model_metadata.dart';

class InferenceImageInput {
  const InferenceImageInput({
    required this.bytes,
    required this.width,
    required this.height,
    this.rotationDegrees = 0,
    this.bytesPerRow,
  });

  final List<int> bytes;
  final int width;
  final int height;
  final int rotationDegrees;
  final int? bytesPerRow;
}

class InferenceResult {
  const InferenceResult({
    required this.frameResult,
    required this.modelMetadata,
    this.errorMessage,
  });

  final DetectionFrameResult frameResult;
  final ModelMetadata modelMetadata;
  final String? errorMessage;

  bool get hasError => errorMessage != null;
}
