class SyncStatus {
  const SyncStatus({
    required this.totalPending,
    required this.successCount,
    required this.failureCount,
    required this.lastSyncedAt,
    required this.message,
  });

  final int totalPending;
  final int successCount;
  final int failureCount;
  final DateTime? lastSyncedAt;
  final String message;
}
