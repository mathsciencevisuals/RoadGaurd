import 'risk_level.dart';

class RiskScore {
  const RiskScore({
    required this.value,
    required this.level,
  });

  final int value;
  final RiskLevel level;

  RiskScore copyWith({
    int? value,
    RiskLevel? level,
  }) {
    return RiskScore(
      value: value ?? this.value,
      level: level ?? this.level,
    );
  }
}
