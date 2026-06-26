import 'package:flutter_test/flutter_test.dart';
import 'package:roadguard/alerts/alert_throttle_service.dart';
import 'package:roadguard/risk/risk_level.dart';

void main() {
  group('AlertThrottleService', () {
    test('repeated high alert is throttled', () {
      final _FakeClock clock = _FakeClock(DateTime.utc(2026, 1, 1, 12));
      final AlertThrottleService service = AlertThrottleService(
        now: clock.now,
      );

      expect(
        service.shouldAllow(
          riskLevel: RiskLevel.high,
          alertKey: 'high:vehicle',
        ),
        isTrue,
      );

      clock.advance(const Duration(seconds: 3));

      expect(
        service.shouldAllow(
          riskLevel: RiskLevel.high,
          alertKey: 'high:vehicle',
        ),
        isFalse,
      );
    });

    test('high alert is allowed again after throttle window', () {
      final _FakeClock clock = _FakeClock(DateTime.utc(2026, 1, 1, 12));
      final AlertThrottleService service = AlertThrottleService(
        now: clock.now,
      );

      service.shouldAllow(
        riskLevel: RiskLevel.high,
        alertKey: 'high:vehicle',
      );
      clock.advance(const Duration(seconds: 5));

      expect(
        service.shouldAllow(
          riskLevel: RiskLevel.high,
          alertKey: 'high:vehicle',
        ),
        isTrue,
      );
    });
  });
}

class _FakeClock {
  _FakeClock(this._current);

  DateTime _current;

  DateTime now() => _current;

  void advance(Duration duration) {
    _current = _current.add(duration);
  }
}
