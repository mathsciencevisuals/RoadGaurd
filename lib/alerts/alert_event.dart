import '../risk/risk_level.dart';

class AlertEvent {
  const AlertEvent({
    required this.message,
    required this.riskLevel,
  });

  final String message;
  final RiskLevel riskLevel;
}
