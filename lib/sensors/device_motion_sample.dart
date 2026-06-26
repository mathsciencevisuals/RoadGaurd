class DeviceMotionSample {
  const DeviceMotionSample({
    required this.accelerationX,
    required this.accelerationY,
    required this.accelerationZ,
    required this.gyroscopeX,
    required this.gyroscopeY,
    required this.gyroscopeZ,
    required this.verticalImpactMagnitude,
    required this.isImpactDetected,
    required this.timestamp,
  });

  final double accelerationX;
  final double accelerationY;
  final double accelerationZ;
  final double gyroscopeX;
  final double gyroscopeY;
  final double gyroscopeZ;
  final double verticalImpactMagnitude;
  final bool isImpactDetected;
  final DateTime timestamp;

  DeviceMotionSample copyWith({
    double? accelerationX,
    double? accelerationY,
    double? accelerationZ,
    double? gyroscopeX,
    double? gyroscopeY,
    double? gyroscopeZ,
    double? verticalImpactMagnitude,
    bool? isImpactDetected,
    DateTime? timestamp,
  }) {
    return DeviceMotionSample(
      accelerationX: accelerationX ?? this.accelerationX,
      accelerationY: accelerationY ?? this.accelerationY,
      accelerationZ: accelerationZ ?? this.accelerationZ,
      gyroscopeX: gyroscopeX ?? this.gyroscopeX,
      gyroscopeY: gyroscopeY ?? this.gyroscopeY,
      gyroscopeZ: gyroscopeZ ?? this.gyroscopeZ,
      verticalImpactMagnitude:
          verticalImpactMagnitude ?? this.verticalImpactMagnitude,
      isImpactDetected: isImpactDetected ?? this.isImpactDetected,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
