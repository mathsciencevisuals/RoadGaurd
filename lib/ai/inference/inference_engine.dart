import '../models/detection_result.dart';

abstract class InferenceEngine {
  Future<List<DetectionResult>> runInference(Object inputFrame);
}
