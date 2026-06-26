import '../ai/detection/object_type.dart';
import '../risk/risk_decision.dart';
import '../risk/risk_level.dart';
import 'alert_throttle_service.dart';
import 'roadguard_alert.dart';
import 'vibration_alert_service.dart';
import 'voice_alert_service.dart';

class AlertEngine {
  AlertEngine({
    VoiceAlertService? voiceAlertService,
    VibrationAlertService? vibrationAlertService,
    AlertThrottleService? alertThrottleService,
  })  : _voiceAlertService = voiceAlertService ?? VoiceAlertService(),
        _vibrationAlertService =
            vibrationAlertService ?? VibrationAlertService(),
        _alertThrottleService =
            alertThrottleService ?? AlertThrottleService();

  final VoiceAlertService _voiceAlertService;
  final VibrationAlertService _vibrationAlertService;
  final AlertThrottleService _alertThrottleService;

  Future<RoadguardAlert> handleRiskDecision(
    RiskDecision decision, {
    bool enableVoiceAlerts = true,
    bool enableVibrationAlerts = true,
  }) async {
    if (!decision.shouldAlert || decision.riskLevel == RiskLevel.none) {
      return RoadguardAlert(
        riskLevel: decision.riskLevel,
        message: decision.primaryMessage,
        shouldSpeak: false,
        shouldVibrate: false,
        wasThrottled: false,
      );
    }

    final String alertMessage = _voiceMessageFor(decision);
    final String alertKey =
        '${decision.riskLevel.name}:${decision.detectedObject?.objectType.name ?? 'none'}:$alertMessage';
    final bool allowed = _alertThrottleService.shouldAllow(
      riskLevel: decision.riskLevel,
      alertKey: alertKey,
    );

    final bool shouldSpeak = allowed &&
        enableVoiceAlerts &&
        _shouldSpeakFor(decision.riskLevel);
    final bool shouldVibrate = allowed &&
        enableVibrationAlerts &&
        _shouldVibrateFor(decision.riskLevel);
    final List<int>? vibrationPattern =
        shouldVibrate ? _vibrationPatternFor(decision.riskLevel) : null;

    bool spoke = false;
    bool vibrated = false;

    if (shouldSpeak) {
      spoke = await _voiceAlertService.speak(alertMessage);
    }

    if (shouldVibrate) {
      vibrated = await _vibrationAlertService.vibrate(
        pattern: vibrationPattern,
      );
    }

    return RoadguardAlert(
      riskLevel: decision.riskLevel,
      message: alertMessage,
      shouldSpeak: spoke,
      shouldVibrate: vibrated,
      wasThrottled: !allowed,
      vibrationPattern: vibrationPattern,
    );
  }

  bool _shouldSpeakFor(RiskLevel riskLevel) {
    switch (riskLevel) {
      case RiskLevel.none:
      case RiskLevel.low:
        return false;
      case RiskLevel.medium:
      case RiskLevel.high:
      case RiskLevel.critical:
        return true;
    }
  }

  bool _shouldVibrateFor(RiskLevel riskLevel) {
    switch (riskLevel) {
      case RiskLevel.none:
      case RiskLevel.low:
        return false;
      case RiskLevel.medium:
      case RiskLevel.high:
      case RiskLevel.critical:
        return true;
    }
  }

  String _voiceMessageFor(RiskDecision decision) {
    switch (decision.detectedObject?.objectType) {
      case ObjectType.person:
        return 'Person crossing ahead';
      case ObjectType.car:
      case ObjectType.bus:
      case ObjectType.truck:
      case ObjectType.motorcycle:
      case ObjectType.bicycle:
      case ObjectType.autoRickshaw:
        return 'Vehicle ahead';
      case ObjectType.pothole:
        return 'Large pothole ahead';
      case ObjectType.roadHump:
        return 'Road hump ahead';
      case ObjectType.animal:
      case ObjectType.unknownObstacle:
      case ObjectType.unknown:
      case null:
        return 'Obstacle ahead';
    }
  }

  List<int> _vibrationPatternFor(RiskLevel riskLevel) {
    switch (riskLevel) {
      case RiskLevel.critical:
        return const <int>[0, 500, 150, 500];
      case RiskLevel.high:
        return const <int>[0, 300, 120, 300];
      case RiskLevel.medium:
        return const <int>[0, 180];
      case RiskLevel.none:
      case RiskLevel.low:
        return const <int>[];
    }
  }
}
