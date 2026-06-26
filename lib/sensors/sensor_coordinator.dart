import 'sensor_snapshot.dart';

abstract class SensorCoordinator {
  Stream<SensorSnapshot> observe();
}
