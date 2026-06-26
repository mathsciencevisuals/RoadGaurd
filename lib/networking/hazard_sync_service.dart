import '../storage/hazard_event_entity.dart';
import '../storage/hazard_event_store.dart';
import 'hazard_api.dart';
import 'sync_status.dart';

class HazardSyncService {
  HazardSyncService({
    HazardApi? hazardApi,
    HazardEventStore? hazardEventStore,
  })  : _hazardApi = hazardApi ?? HazardApi(),
        _hazardEventStore = hazardEventStore ?? const HazardEventStore();

  final HazardApi _hazardApi;
  final HazardEventStore _hazardEventStore;

  Future<SyncStatus> syncPendingHazards({
    required String deviceId,
    String? userId,
  }) async {
    final List<HazardEventEntity> pendingHazards =
        await _hazardEventStore.getUnsyncedHazards();

    if (pendingHazards.isEmpty) {
      return const SyncStatus(
        totalPending: 0,
        successCount: 0,
        failureCount: 0,
        lastSyncedAt: null,
        message: 'No pending hazards to sync.',
      );
    }

    int successCount = 0;
    int failureCount = 0;

    for (final HazardEventEntity hazard in pendingHazards) {
      final result = await _hazardApi.uploadHazardEvent(
        event: hazard,
        deviceId: deviceId,
        userId: userId,
      );

      if (result.isSuccess) {
        await _hazardEventStore.markHazardSynced(hazard.id);
        successCount++;
      } else {
        failureCount++;
      }
    }

    return SyncStatus(
      totalPending: pendingHazards.length,
      successCount: successCount,
      failureCount: failureCount,
      lastSyncedAt: successCount > 0 ? DateTime.now() : null,
      message: failureCount == 0
          ? 'Hazard sync completed successfully.'
          : 'Hazard sync completed with some failures.',
    );
  }
}
