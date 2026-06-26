import 'detection_frame_result.dart';

abstract class DetectionPipeline {
  Future<DetectionFrameResult?> processFrame(Object inputFrame);
}
