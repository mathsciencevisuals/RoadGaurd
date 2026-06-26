import '../detection/detected_object.dart';

abstract class ObjectTracker {
  List<DetectedObject> track(List<DetectedObject> detections);
}
