import 'package:flutter_tts/flutter_tts.dart';

abstract class VoiceAlertGateway {
  Future<void> speak(String message);
  Future<void> stop();
}

class FlutterTtsGateway implements VoiceAlertGateway {
  FlutterTtsGateway({
    FlutterTts? flutterTts,
  }) : _flutterTts = flutterTts ?? FlutterTts();

  final FlutterTts _flutterTts;

  @override
  Future<void> speak(String message) async {
    await _flutterTts.speak(message);
  }

  @override
  Future<void> stop() async {
    await _flutterTts.stop();
  }
}

class VoiceAlertService {
  VoiceAlertService({
    VoiceAlertGateway? gateway,
  }) : _gateway = gateway ?? FlutterTtsGateway();

  final VoiceAlertGateway _gateway;

  Future<bool> speak(String message) async {
    try {
      await _gateway.speak(message);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> stop() async {
    try {
      await _gateway.stop();
    } catch (_) {
      // Ignore platform failures so alerts never crash the app.
    }
  }
}
