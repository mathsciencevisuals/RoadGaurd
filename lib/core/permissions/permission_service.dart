import 'dart:io';

import 'package:permission_handler/permission_handler.dart' as permission_handler;

enum AppPermission {
  camera,
  location,
  notifications,
  motionSensors,
}

enum AppPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  limited,
  unsupported,
}

class PermissionResult {
  const PermissionResult({
    required this.permission,
    required this.status,
    required this.message,
    this.required = true,
  });

  final AppPermission permission;
  final AppPermissionStatus status;
  final String message;
  final bool required;

  bool get isGranted =>
      status == AppPermissionStatus.granted ||
      status == AppPermissionStatus.limited;

  bool get satisfiesRequirement => isGranted || !required;
}

class PermissionBatchResult {
  const PermissionBatchResult(this.results);

  final List<PermissionResult> results;

  bool get allRequiredGranted =>
      results.every((PermissionResult result) => result.satisfiesRequirement);

  List<String> get blockingMessages => results
      .where(
        (PermissionResult result) => !result.satisfiesRequirement,
      )
      .map((PermissionResult result) => result.message)
      .toList();
}

abstract class PermissionService {
  Future<PermissionResult> requestCameraPermission();
  Future<PermissionResult> requestLocationPermission();
  Future<PermissionResult> requestNotificationPermission();
  Future<PermissionResult> requestMotionSensorPermission();
  Future<PermissionBatchResult> requestRequiredPermissions();
  Future<PermissionBatchResult> checkRequiredPermissions();
}

abstract class PermissionGateway {
  Future<permission_handler.PermissionStatus> getStatus(
    permission_handler.Permission permission,
  );

  Future<permission_handler.PermissionStatus> request(
    permission_handler.Permission permission,
  );
}

class PermissionHandlerGateway implements PermissionGateway {
  const PermissionHandlerGateway();

  @override
  Future<permission_handler.PermissionStatus> getStatus(
    permission_handler.Permission permission,
  ) {
    return permission.status;
  }

  @override
  Future<permission_handler.PermissionStatus> request(
    permission_handler.Permission permission,
  ) {
    return permission.request();
  }
}

class PermissionHandlerService implements PermissionService {
  PermissionHandlerService({
    PermissionGateway permissionGateway = const PermissionHandlerGateway(),
  }) : _permissionGateway = permissionGateway;

  final PermissionGateway _permissionGateway;

  @override
  Future<PermissionResult> requestCameraPermission() {
    return _requestPermission(
      appPermission: AppPermission.camera,
      permission: permission_handler.Permission.camera,
      grantedMessage: 'Camera access is enabled for live road detection.',
      deniedMessage:
          'Camera access is needed so RoadGuard can detect hazards in front of the vehicle.',
      permanentlyDeniedMessage:
          'Camera access is permanently denied. Enable it in system settings to use live road detection.',
    );
  }

  @override
  Future<PermissionResult> requestLocationPermission() {
    return _requestPermission(
      appPermission: AppPermission.location,
      permission: permission_handler.Permission.locationWhenInUse,
      grantedMessage: 'Location access is enabled for GPS hazard tagging.',
      deniedMessage:
          'Location access is needed so RoadGuard can tag hazards with GPS coordinates.',
      permanentlyDeniedMessage:
          'Location access is permanently denied. Enable it in system settings to continue.',
    );
  }

  @override
  Future<PermissionResult> requestNotificationPermission() {
    return _requestPermission(
      appPermission: AppPermission.notifications,
      permission: permission_handler.Permission.notification,
      grantedMessage: 'Notification access is enabled for future alerts.',
      deniedMessage:
          'Notification access helps RoadGuard deliver future safety alerts when the app is not in the foreground.',
      permanentlyDeniedMessage:
          'Notification access is permanently denied. Enable it in system settings for future alerts.',
    );
  }

  @override
  Future<PermissionResult> requestMotionSensorPermission() async {
    if (!_supportsMotionSensorPermission()) {
      return const PermissionResult(
        permission: AppPermission.motionSensors,
        status: AppPermissionStatus.unsupported,
        message: 'Motion sensor permission is not required on this platform.',
        required: false,
      );
    }

    return _requestPermission(
      appPermission: AppPermission.motionSensors,
      permission: permission_handler.Permission.sensors,
      grantedMessage:
          'Motion sensor access is enabled for acceleration and movement signals.',
      deniedMessage:
          'Motion sensor access improves detection quality where the platform supports it.',
      permanentlyDeniedMessage:
          'Motion sensor access is permanently denied. Enable it in system settings to improve sensing quality.',
      required: false,
    );
  }

  @override
  Future<PermissionBatchResult> requestRequiredPermissions() async {
    final List<PermissionResult> results = <PermissionResult>[
      await requestCameraPermission(),
      await requestLocationPermission(),
      await requestNotificationPermission(),
      await requestMotionSensorPermission(),
    ];

    return PermissionBatchResult(results);
  }

  @override
  Future<PermissionBatchResult> checkRequiredPermissions() async {
    final List<PermissionResult> results = <PermissionResult>[
      await _checkPermission(
        appPermission: AppPermission.camera,
        permission: permission_handler.Permission.camera,
        grantedMessage: 'Camera access is enabled.',
        deniedMessage: 'Camera access has not been granted yet.',
        permanentlyDeniedMessage:
            'Camera access is permanently denied in system settings.',
      ),
      await _checkPermission(
        appPermission: AppPermission.location,
        permission: permission_handler.Permission.locationWhenInUse,
        grantedMessage: 'Location access is enabled.',
        deniedMessage: 'Location access has not been granted yet.',
        permanentlyDeniedMessage:
            'Location access is permanently denied in system settings.',
      ),
      await _checkPermission(
        appPermission: AppPermission.notifications,
        permission: permission_handler.Permission.notification,
        grantedMessage: 'Notification access is enabled.',
        deniedMessage: 'Notification access has not been granted yet.',
        permanentlyDeniedMessage:
            'Notification access is permanently denied in system settings.',
      ),
      await (_supportsMotionSensorPermission()
          ? _checkPermission(
              appPermission: AppPermission.motionSensors,
              permission: permission_handler.Permission.sensors,
              grantedMessage: 'Motion sensor access is enabled.',
              deniedMessage: 'Motion sensor access has not been granted yet.',
              permanentlyDeniedMessage:
                  'Motion sensor access is permanently denied in system settings.',
              required: false,
            )
          : Future<PermissionResult>.value(
              const PermissionResult(
                permission: AppPermission.motionSensors,
                status: AppPermissionStatus.unsupported,
                message:
                    'Motion sensor permission is not required on this platform.',
                required: false,
              ),
            )),
    ];

    return PermissionBatchResult(results);
  }

  Future<PermissionResult> _checkPermission({
    required AppPermission appPermission,
    required permission_handler.Permission permission,
    required String grantedMessage,
    required String deniedMessage,
    required String permanentlyDeniedMessage,
    bool required = true,
  }) async {
    final permission_handler.PermissionStatus status =
        await _permissionGateway.getStatus(permission);

    return _toPermissionResult(
      appPermission: appPermission,
      status: status,
      grantedMessage: grantedMessage,
      deniedMessage: deniedMessage,
      permanentlyDeniedMessage: permanentlyDeniedMessage,
      required: required,
    );
  }

  Future<PermissionResult> _requestPermission({
    required AppPermission appPermission,
    required permission_handler.Permission permission,
    required String grantedMessage,
    required String deniedMessage,
    required String permanentlyDeniedMessage,
    bool required = true,
  }) async {
    final permission_handler.PermissionStatus status =
        await _permissionGateway.request(permission);

    return _toPermissionResult(
      appPermission: appPermission,
      status: status,
      grantedMessage: grantedMessage,
      deniedMessage: deniedMessage,
      permanentlyDeniedMessage: permanentlyDeniedMessage,
      required: required,
    );
  }

  PermissionResult _toPermissionResult({
    required AppPermission appPermission,
    required permission_handler.PermissionStatus status,
    required String grantedMessage,
    required String deniedMessage,
    required String permanentlyDeniedMessage,
    required bool required,
  }) {
    if (status.isGranted) {
      return PermissionResult(
        permission: appPermission,
        status: AppPermissionStatus.granted,
        message: grantedMessage,
        required: required,
      );
    }

    if (status.isLimited) {
      return PermissionResult(
        permission: appPermission,
        status: AppPermissionStatus.limited,
        message: grantedMessage,
        required: required,
      );
    }

    if (status.isPermanentlyDenied) {
      return PermissionResult(
        permission: appPermission,
        status: AppPermissionStatus.permanentlyDenied,
        message: permanentlyDeniedMessage,
        required: required,
      );
    }

    if (status.isRestricted) {
      return PermissionResult(
        permission: appPermission,
        status: AppPermissionStatus.restricted,
        message:
            'This permission is restricted by the platform and cannot currently be granted.',
        required: required,
      );
    }

    return PermissionResult(
      permission: appPermission,
      status: AppPermissionStatus.denied,
      message: deniedMessage,
      required: required,
    );
  }

  bool _supportsMotionSensorPermission() {
    return Platform.isAndroid || Platform.isIOS;
  }
}
