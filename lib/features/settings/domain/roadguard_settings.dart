enum AlertSensitivity {
  low,
  normal,
  high,
}

class RoadGuardSettings {
  const RoadGuardSettings({
    required this.enableVoiceAlerts,
    required this.enableVibrationAlerts,
    required this.alertSensitivity,
    required this.detectionProcessingFps,
    required this.enableDebugBoundingBoxes,
    required this.enableCloudSync,
    required this.enableDataSharing,
  });

  factory RoadGuardSettings.defaults() {
    return const RoadGuardSettings(
      enableVoiceAlerts: true,
      enableVibrationAlerts: true,
      alertSensitivity: AlertSensitivity.normal,
      detectionProcessingFps: 5,
      enableDebugBoundingBoxes: false,
      enableCloudSync: true,
      enableDataSharing: false,
    );
  }

  factory RoadGuardSettings.fromMap(Map<dynamic, dynamic> map) {
    final RoadGuardSettings defaults = RoadGuardSettings.defaults();

    return RoadGuardSettings(
      enableVoiceAlerts:
          map['enableVoiceAlerts'] as bool? ?? defaults.enableVoiceAlerts,
      enableVibrationAlerts: map['enableVibrationAlerts'] as bool? ??
          defaults.enableVibrationAlerts,
      alertSensitivity: AlertSensitivity.values.firstWhere(
        (AlertSensitivity value) =>
            value.name == (map['alertSensitivity'] as String?),
        orElse: () => defaults.alertSensitivity,
      ),
      detectionProcessingFps: _parseAllowedFps(
        value: map['detectionProcessingFps'],
        fallback: defaults.detectionProcessingFps,
      ),
      enableDebugBoundingBoxes: map['enableDebugBoundingBoxes'] as bool? ??
          defaults.enableDebugBoundingBoxes,
      enableCloudSync:
          map['enableCloudSync'] as bool? ?? defaults.enableCloudSync,
      enableDataSharing:
          map['enableDataSharing'] as bool? ?? defaults.enableDataSharing,
    );
  }

  final bool enableVoiceAlerts;
  final bool enableVibrationAlerts;
  final AlertSensitivity alertSensitivity;
  final int detectionProcessingFps;
  final bool enableDebugBoundingBoxes;
  final bool enableCloudSync;
  final bool enableDataSharing;

  static const List<int> supportedFpsValues = <int>[3, 5, 10];

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'enableVoiceAlerts': enableVoiceAlerts,
      'enableVibrationAlerts': enableVibrationAlerts,
      'alertSensitivity': alertSensitivity.name,
      'detectionProcessingFps': detectionProcessingFps,
      'enableDebugBoundingBoxes': enableDebugBoundingBoxes,
      'enableCloudSync': enableCloudSync,
      'enableDataSharing': enableDataSharing,
    };
  }

  RoadGuardSettings copyWith({
    bool? enableVoiceAlerts,
    bool? enableVibrationAlerts,
    AlertSensitivity? alertSensitivity,
    int? detectionProcessingFps,
    bool? enableDebugBoundingBoxes,
    bool? enableCloudSync,
    bool? enableDataSharing,
  }) {
    return RoadGuardSettings(
      enableVoiceAlerts: enableVoiceAlerts ?? this.enableVoiceAlerts,
      enableVibrationAlerts:
          enableVibrationAlerts ?? this.enableVibrationAlerts,
      alertSensitivity: alertSensitivity ?? this.alertSensitivity,
      detectionProcessingFps:
          detectionProcessingFps ?? this.detectionProcessingFps,
      enableDebugBoundingBoxes:
          enableDebugBoundingBoxes ?? this.enableDebugBoundingBoxes,
      enableCloudSync: enableCloudSync ?? this.enableCloudSync,
      enableDataSharing: enableDataSharing ?? this.enableDataSharing,
    );
  }

  static int _parseAllowedFps({
    required Object? value,
    required int fallback,
  }) {
    final int? parsedValue = value is int ? value : int.tryParse('$value');

    if (parsedValue != null && supportedFpsValues.contains(parsedValue)) {
      return parsedValue;
    }

    return fallback;
  }
}
