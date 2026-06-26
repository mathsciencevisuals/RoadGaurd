import 'dart:async';

import 'package:sensors_plus/sensors_plus.dart';

import 'device_motion_sample.dart';

class MotionServiceConfig {
  const MotionServiceConfig({
    this.verticalImpactThreshold = 4.0,
    this.gravityCompensation = 9.81,
  });

  final double verticalImpactThreshold;
  final double gravityCompensation;
}

class MotionService {
  MotionService({
    MotionServiceConfig config = const MotionServiceConfig(),
  }) : _config = config;

  final MotionServiceConfig _config;

  Stream<DeviceMotionSample> observeMotion() {
    late final StreamController<DeviceMotionSample> controller;
    StreamSubscription<AccelerometerEvent>? accelerometerSubscription;
    StreamSubscription<GyroscopeEvent>? gyroscopeSubscription;
    double latestGyroscopeX = 0;
    double latestGyroscopeY = 0;
    double latestGyroscopeZ = 0;

    controller = StreamController<DeviceMotionSample>.broadcast(
      onListen: () {
        gyroscopeSubscription = gyroscopeEvents.listen(
          (GyroscopeEvent event) {
            latestGyroscopeX = event.x;
            latestGyroscopeY = event.y;
            latestGyroscopeZ = event.z;
          },
          onError: controller.addError,
        );

        accelerometerSubscription = accelerometerEvents.listen(
          (AccelerometerEvent event) {
            final double verticalImpactMagnitude =
                (event.z.abs() - _config.gravityCompensation).abs();

            controller.add(
              DeviceMotionSample(
                accelerationX: event.x,
                accelerationY: event.y,
                accelerationZ: event.z,
                gyroscopeX: latestGyroscopeX,
                gyroscopeY: latestGyroscopeY,
                gyroscopeZ: latestGyroscopeZ,
                verticalImpactMagnitude: verticalImpactMagnitude,
                isImpactDetected:
                    verticalImpactMagnitude >= _config.verticalImpactThreshold,
                timestamp: DateTime.now(),
              ),
            );
          },
          onError: controller.addError,
        );
      },
      onCancel: () async {
        await accelerometerSubscription?.cancel();
        await gyroscopeSubscription?.cancel();
      },
    );

    return controller.stream;
  }
}
