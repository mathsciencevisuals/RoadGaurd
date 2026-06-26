import '../risk/risk_level.dart';

class RoadguardAlert {
  const RoadguardAlert({
    required this.riskLevel,
    required this.message,
    required this.shouldSpeak,
    required this.shouldVibrate,
    required this.wasThrottled,
    this.vibrationPattern,
  });

  final RiskLevel riskLevel;
  final String message;
  final bool shouldSpeak;
  final bool shouldVibrate;
  final bool wasThrottled;
  final List<int>? vibrationPattern;

  bool get shouldDispatch => shouldSpeak || shouldVibrate;
}
