import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../settings/domain/roadguard_settings.dart';

abstract class SettingsStore {
  Future<Map<dynamic, dynamic>?> load();
  Future<void> save(Map<String, dynamic> values);
}

abstract class HazardCacheManager {
  Future<void> clear();
}

class HiveSettingsStore implements SettingsStore {
  static const String _settingsBoxName = 'roadguard_settings';
  static const String _settingsKey = 'current';

  @override
  Future<Map<dynamic, dynamic>?> load() async {
    final Box<dynamic> box = await _openBox();
    final dynamic rawValue = box.get(_settingsKey);
    if (rawValue is Map) {
      return rawValue;
    }

    return null;
  }

  @override
  Future<void> save(Map<String, dynamic> values) async {
    final Box<dynamic> box = await _openBox();
    await box.put(_settingsKey, values);
  }

  Future<Box<dynamic>> _openBox() async {
    if (Hive.isBoxOpen(_settingsBoxName)) {
      return Hive.box<dynamic>(_settingsBoxName);
    }

    return Hive.openBox<dynamic>(_settingsBoxName);
  }
}

class LocalHazardCacheManager implements HazardCacheManager {
  const LocalHazardCacheManager();

  @override
  Future<void> clear() async {
    final Box<dynamic> hazardBox = Hive.isBoxOpen('hazard_events')
        ? Hive.box<dynamic>('hazard_events')
        : await Hive.openBox<dynamic>('hazard_events');
    await hazardBox.clear();
  }
}

class SettingsController extends ChangeNotifier {
  SettingsController({
    SettingsStore? settingsStore,
    HazardCacheManager? hazardCacheManager,
  })  : _settingsStore = settingsStore ?? HiveSettingsStore(),
        _hazardCacheManager = hazardCacheManager ?? const LocalHazardCacheManager();

  RoadGuardSettings _settings = RoadGuardSettings.defaults();
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isSaving = false;
  String? _statusMessage;
  final SettingsStore _settingsStore;
  final HazardCacheManager _hazardCacheManager;

  RoadGuardSettings get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isSaving => _isSaving;
  String? get statusMessage => _statusMessage;

  Future<void> initialize() async {
    if (_isInitialized || _isLoading) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final Map<dynamic, dynamic>? rawValue = await _settingsStore.load();

      if (rawValue != null) {
        _settings = RoadGuardSettings.fromMap(rawValue);
      } else {
        await _persistSettings(RoadGuardSettings.defaults());
      }

      _statusMessage = null;
      _isInitialized = true;
    } catch (error) {
      _statusMessage =
          'Settings could not be loaded. Default values are being used.';
      _settings = RoadGuardSettings.defaults();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setVoiceAlertsEnabled(bool enabled) {
    return _updateSettings(
      _settings.copyWith(enableVoiceAlerts: enabled),
    );
  }

  Future<void> setVibrationAlertsEnabled(bool enabled) {
    return _updateSettings(
      _settings.copyWith(enableVibrationAlerts: enabled),
    );
  }

  Future<void> setAlertSensitivity(AlertSensitivity sensitivity) {
    return _updateSettings(
      _settings.copyWith(alertSensitivity: sensitivity),
    );
  }

  Future<void> setDetectionProcessingFps(int fps) {
    if (!RoadGuardSettings.supportedFpsValues.contains(fps)) {
      return Future<void>.value();
    }

    return _updateSettings(
      _settings.copyWith(detectionProcessingFps: fps),
    );
  }

  Future<void> setDebugBoundingBoxesEnabled(bool enabled) {
    return _updateSettings(
      _settings.copyWith(enableDebugBoundingBoxes: enabled),
    );
  }

  Future<void> setCloudSyncEnabled(bool enabled) {
    return _updateSettings(
      _settings.copyWith(enableCloudSync: enabled),
    );
  }

  Future<void> setDataSharingEnabled(bool enabled) {
    return _updateSettings(
      _settings.copyWith(enableDataSharing: enabled),
    );
  }

  Future<void> clearLocalHazardCache() async {
    try {
      await _hazardCacheManager.clear();
      _statusMessage = 'Local hazard cache cleared.';
    } catch (error) {
      _statusMessage = 'Local hazard cache could not be cleared.';
    }

    notifyListeners();
  }

  void clearStatusMessage() {
    if (_statusMessage == null) {
      return;
    }

    _statusMessage = null;
    notifyListeners();
  }

  Future<void> _updateSettings(RoadGuardSettings updatedSettings) async {
    _settings = updatedSettings;
    _isSaving = true;
    _statusMessage = null;
    notifyListeners();

    try {
      await _persistSettings(updatedSettings);
    } catch (error) {
      _statusMessage = 'Settings could not be saved locally.';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> _persistSettings(RoadGuardSettings settings) async {
    await _settingsStore.save(settings.toMap());
  }
}
