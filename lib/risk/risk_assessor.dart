import '../ai/detection/detection_frame_result.dart';
import 'risk_decision.dart';

abstract class RiskAssessor {
  RiskDecision evaluate(DetectionFrameResult frameResult);
}
