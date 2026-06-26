import '../ai/detection/detected_object.dart';
import 'risk_level.dart';

class RiskDecision {
  const RiskDecision({
    required this.riskLevel,
    required this.primaryMessage,
    required this.detectedObject,
    required this.reason,
    required this.shouldAlert,
    required this.timestamp,
  });

  final RiskLevel riskLevel;
  final String primaryMessage;
  final DetectedObject? detectedObject;
  final String reason;
  final bool shouldAlert;
  final DateTime timestamp;

  RiskDecision copyWith({
    RiskLevel? riskLevel,
    String? primaryMessage,
    DetectedObject? detectedObject,
    bool clearDetectedObject = false,
    String? reason,
    bool? shouldAlert,
    DateTime? timestamp,
  }) {
    return RiskDecision(
      riskLevel: riskLevel ?? this.riskLevel,
      primaryMessage: primaryMessage ?? this.primaryMessage,
      detectedObject: clearDetectedObject
          ? null
          : detectedObject ?? this.detectedObject,
      reason: reason ?? this.reason,
      shouldAlert: shouldAlert ?? this.shouldAlert,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
