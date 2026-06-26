class LocationSample {
  const LocationSample({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.headingDegrees,
    required this.speedKmph,
    required this.timestamp,
  });

  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final double headingDegrees;
  final double speedKmph;
  final DateTime timestamp;

  LocationSample copyWith({
    double? latitude,
    double? longitude,
    double? accuracyMeters,
    double? headingDegrees,
    double? speedKmph,
    DateTime? timestamp,
  }) {
    return LocationSample(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      headingDegrees: headingDegrees ?? this.headingDegrees,
      speedKmph: speedKmph ?? this.speedKmph,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
