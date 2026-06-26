import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart' as permission_handler;
import 'package:roadguard/core/permissions/permission_service.dart';

void main() {
  group('PermissionHandlerService', () {
    test('maps denied status to denied permission result', () async {
      final PermissionHandlerService service = PermissionHandlerService(
        permissionGateway: _FakePermissionGateway(
          requestStatuses: <permission_handler.Permission,
              permission_handler.PermissionStatus>{
            permission_handler.Permission.camera:
                permission_handler.PermissionStatus.denied,
          },
        ),
      );

      final PermissionResult result = await service.requestCameraPermission();

      expect(result.status, AppPermissionStatus.denied);
      expect(result.isGranted, isFalse);
    });

    test('maps permanently denied status correctly', () async {
      final PermissionHandlerService service = PermissionHandlerService(
        permissionGateway: _FakePermissionGateway(
          requestStatuses: <permission_handler.Permission,
              permission_handler.PermissionStatus>{
            permission_handler.Permission.locationWhenInUse:
                permission_handler.PermissionStatus.permanentlyDenied,
          },
        ),
      );

      final PermissionResult result = await service.requestLocationPermission();

      expect(result.status, AppPermissionStatus.permanentlyDenied);
      expect(result.message, contains('permanently denied'));
    });
  });
}

class _FakePermissionGateway implements PermissionGateway {
  _FakePermissionGateway({
    Map<permission_handler.Permission, permission_handler.PermissionStatus>?
        statuses,
    Map<permission_handler.Permission, permission_handler.PermissionStatus>?
        requestStatuses,
  })  : _statuses = statuses ?? <permission_handler.Permission,
            permission_handler.PermissionStatus>{},
        _requestStatuses = requestStatuses ?? <permission_handler.Permission,
            permission_handler.PermissionStatus>{};

  final Map<permission_handler.Permission, permission_handler.PermissionStatus>
      _statuses;
  final Map<permission_handler.Permission, permission_handler.PermissionStatus>
      _requestStatuses;

  @override
  Future<permission_handler.PermissionStatus> getStatus(
    permission_handler.Permission permission,
  ) async {
    return _statuses[permission] ?? permission_handler.PermissionStatus.denied;
  }

  @override
  Future<permission_handler.PermissionStatus> request(
    permission_handler.Permission permission,
  ) async {
    return _requestStatuses[permission] ??
        permission_handler.PermissionStatus.denied;
  }
}
