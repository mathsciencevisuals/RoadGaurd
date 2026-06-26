class DetectionResult {
  const DetectionResult({
    required this.label,
    required this.confidence,
    required this.distanceMeters,
  });

  final String label;
  final double confidence;
  final double distanceMeters;
}
