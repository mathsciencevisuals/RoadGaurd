class ModelMetadata {
  const ModelMetadata({
    required this.modelName,
    required this.modelVersion,
    required this.inputWidth,
    required this.inputHeight,
    required this.labels,
  });

  final String modelName;
  final String modelVersion;
  final int inputWidth;
  final int inputHeight;
  final List<String> labels;

  ModelMetadata copyWith({
    String? modelName,
    String? modelVersion,
    int? inputWidth,
    int? inputHeight,
    List<String>? labels,
  }) {
    return ModelMetadata(
      modelName: modelName ?? this.modelName,
      modelVersion: modelVersion ?? this.modelVersion,
      inputWidth: inputWidth ?? this.inputWidth,
      inputHeight: inputHeight ?? this.inputHeight,
      labels: labels ?? this.labels,
    );
  }
}
