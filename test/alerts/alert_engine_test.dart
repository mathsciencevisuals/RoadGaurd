import 'package:flutter_test/flutter_test.dart';
import 'package:roadguard/alerts/alert_engine.dart';
import 'package:roadguard/alerts/alert_throttle_service.dart';
import 'package:roadguard/alerts/vibration_alert_service.dart';
import 'package:roadguard/alerts/voice_alert_service.dart';
import 'package:roadguard/ai/detection/bounding_box.dart';
import 'package:roadguard/ai/detection/detected_object.dart';
import 'package:roadguard/ai/detection/object_type.dart';
import 'package:roadguard/ai/detection/relative_position.dart';
import 'package:roadguard/risk/risk_decision.dart';
import 'package:roadguard/risk/risk_level.dart';

void main() {
  test('low risk alert does not trigger voice by default', () async {
    final _FakeVoiceGateway voiceGateway = _FakeVoiceGateway();
    final _FakeVibrationGateway vibrationGateway = _FakeVibrationGateway();
    final AlertEngine engine = AlertEngine(
      voiceAlertService: VoiceAlertService(gateway: voiceGateway),
      vibrationAlertService: VibrationAlertService(gateway: vibrationGateway),
      alertThrottleService: AlertThrottleService(),
    );

    final alert = await engine.handleRiskDecision(
      RiskDecision(
        riskLevel: RiskLevel.low,
        primaryMessage: 'Vehicle ahead',
        detectedObject: _object(ObjectType.car),
        reason: 'Low-risk roadside vehicle.',
        shouldAlert: true,
        timestamp: DateTime.utc(2026, 1, 1, 12),
      ),
    );

    expect(alert.shouldSpeak, isFalse);
    expect(voiceGateway.spokenMessages, isEmpty);
  });
}

DetectedObject _object(ObjectType objectType) {
  final DateTime now = DateTime.utc(2026, 1, 1, 12);

  return DetectedObject(
    id: 'obj-1',
    label: objectType.name,
    objectType: objectType,
    confidence: 0.9,
    boundingBox: const BoundingBox(
      x: 0,
      y: 0,
      width: 100,
      height: 100,
      imageWidth: 1000,
      imageHeight: 1000,
    ),
    estimatedDistanceMeters: 50,
    relativePosition: RelativePosition.roadside,
    firstSeenAt: now,
    lastSeenAt: now,
  );
}

class _FakeVoiceGateway implements VoiceAlertGateway {
  final List<String> spokenMessages = <String>[];

  @override
  Future<void> speak(String message) async {
    spokenMessages.add(message);
  }

  @override
  Future<void> stop() async {}
}

class _FakeVibrationGateway implements VibrationGateway {
  @override
  Future<bool> hasVibrator() async => true;

  @override
  Future<void> vibrate({
    int? duration,
    List<int>? pattern,
    List<int>? intensities,
  }) async {}
}
