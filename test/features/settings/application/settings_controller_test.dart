import 'package:flutter_test/flutter_test.dart';
import 'package:roadguard/features/settings/application/settings_controller.dart';
import 'package:roadguard/features/settings/domain/roadguard_settings.dart';

void main() {
  group('SettingsController', () {
    test('loads saved settings from injected store', () async {
      final _InMemorySettingsStore store = _InMemorySettingsStore(
        initialData: <String, dynamic>{
          'enableVoiceAlerts': false,
          'enableVibrationAlerts': true,
          'alertSensitivity': 'high',
          'detectionProcessingFps': 10,
          'enableDebugBoundingBoxes': true,
          'enableCloudSync': false,
          'enableDataSharing': true,
        },
      );

      final SettingsController controller = SettingsController(
        settingsStore: store,
        hazardCacheManager: _FakeHazardCacheManager(),
      );

      await controller.initialize();

      expect(controller.settings.enableVoiceAlerts, isFalse);
      expect(controller.settings.alertSensitivity, AlertSensitivity.high);
      expect(controller.settings.detectionProcessingFps, 10);
    });

    test('persists updated settings', () async {
      final _InMemorySettingsStore store = _InMemorySettingsStore();
      final SettingsController controller = SettingsController(
        settingsStore: store,
        hazardCacheManager: _FakeHazardCacheManager(),
      );

      await controller.initialize();
      await controller.setCloudSyncEnabled(false);

      expect(store.savedData?['enableCloudSync'], isFalse);
    });
  });
}

class _InMemorySettingsStore implements SettingsStore {
  _InMemorySettingsStore({
    Map<String, dynamic>? initialData,
  }) : _initialData = initialData;

  final Map<String, dynamic>? _initialData;
  Map<String, dynamic>? savedData;

  @override
  Future<Map<dynamic, dynamic>?> load() async {
    return _initialData;
  }

  @override
  Future<void> save(Map<String, dynamic> values) async {
    savedData = Map<String, dynamic>.from(values);
  }
}

class _FakeHazardCacheManager implements HazardCacheManager {
  @override
  Future<void> clear() async {}
}
