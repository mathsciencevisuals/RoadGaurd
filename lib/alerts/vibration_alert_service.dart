import 'package:vibration/vibration.dart';

abstract class VibrationGateway {
  Future<bool> hasVibrator();
  Future<void> vibrate({
    int? duration,
    List<int>? pattern,
    List<int>? intensities,
  });
}

class VibrationPluginGateway implements VibrationGateway {
  const VibrationPluginGateway();

  @override
  Future<bool> hasVibrator() async {
    return await Vibration.hasVibrator() ?? false;
  }

  @override
  Future<void> vibrate({
    int? duration,
    List<int>? pattern,
    List<int>? intensities,
  }) {
    return Vibration.vibrate(
      duration: duration,
      pattern: pattern,
      intensities: intensities,
    );
  }
}

class VibrationAlertService {
  VibrationAlertService({
    VibrationGateway? gateway,
  }) : _gateway = gateway ?? const VibrationPluginGateway();

  final VibrationGateway _gateway;

  Future<bool> vibrate({
    int? duration,
    List<int>? pattern,
    List<int>? intensities,
  }) async {
    try {
      if (!await _gateway.hasVibrator()) {
        return false;
      }

      await _gateway.vibrate(
        duration: duration,
        pattern: pattern,
        intensities: intensities,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
