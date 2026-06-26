import 'package:flutter_test/flutter_test.dart';
import 'package:roadguard/ai/detection/bounding_box.dart';

void main() {
  test('BoundingBox helper methods compute center and area ratio', () {
    const BoundingBox box = BoundingBox(
      x: 10,
      y: 20,
      width: 30,
      height: 40,
      imageWidth: 200,
      imageHeight: 100,
    );

    expect(box.centerX, 25);
    expect(box.centerY, 40);
    expect(box.areaRatio, closeTo(0.06, 0.0001));
  });
}
