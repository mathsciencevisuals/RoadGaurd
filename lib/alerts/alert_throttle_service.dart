import '../risk/risk_level.dart';

typedef DateTimeProvider = DateTime Function();

class AlertThrottleService {
  AlertThrottleService({
    DateTimeProvider? now,
  }) : _now = now ?? DateTime.now;

  final DateTimeProvider _now;
  final Map<String, DateTime> _lastAlertTimes = <String, DateTime>{};

  bool shouldAllow({
    required RiskLevel riskLevel,
    required String alertKey,
  }) {
    final Duration? interval = _repeatIntervalFor(riskLevel);
    if (interval == null) {
      return true;
    }

    final DateTime currentTime = _now();
    final DateTime? lastAlertTime = _lastAlertTimes[alertKey];
    if (lastAlertTime == null ||
        currentTime.difference(lastAlertTime) >= interval) {
      _lastAlertTimes[alertKey] = currentTime;
      return true;
    }

    return false;
  }

  void reset() {
    _lastAlertTimes.clear();
  }

  Duration? _repeatIntervalFor(RiskLevel riskLevel) {
    switch (riskLevel) {
      case RiskLevel.critical:
        return const Duration(seconds: 2);
      case RiskLevel.high:
        return const Duration(seconds: 5);
      case RiskLevel.medium:
        return const Duration(seconds: 10);
      case RiskLevel.none:
      case RiskLevel.low:
        return null;
    }
  }
}
