class SensorSnapshot {
  const SensorSnapshot({
    required this.latitude,
    required this.longitude,
    required this.speedMps,
    required this.acceleration,
    required this.gyroscope,
  });

  final double latitude;
  final double longitude;
  final double speedMps;
  final List<double> acceleration;
  final List<double> gyroscope;
}
