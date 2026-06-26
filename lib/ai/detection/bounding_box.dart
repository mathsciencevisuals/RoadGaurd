class BoundingBox {
  const BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.imageWidth,
    required this.imageHeight,
  });

  final double x;
  final double y;
  final double width;
  final double height;
  final double imageWidth;
  final double imageHeight;

  double get centerX => x + (width / 2);
  double get centerY => y + (height / 2);

  double get areaRatio {
    final double imageArea = imageWidth * imageHeight;
    if (imageArea <= 0) {
      return 0;
    }

    return (width * height) / imageArea;
  }

  BoundingBox copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    double? imageWidth,
    double? imageHeight,
  }) {
    return BoundingBox(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      imageWidth: imageWidth ?? this.imageWidth,
      imageHeight: imageHeight ?? this.imageHeight,
    );
  }
}
