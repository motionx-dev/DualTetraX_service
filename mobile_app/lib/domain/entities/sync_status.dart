enum SyncStatus {
  notSynced(0),
  syncedToApp(1),
  syncedToServer(2),
  fullySynced(3);

  final int value;
  const SyncStatus(this.value);

  static SyncStatus fromValue(int value) {
    return SyncStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SyncStatus.notSynced,
    );
  }

  String get displayName {
    switch (this) {
      case SyncStatus.notSynced:
        return 'Not Synced';
      case SyncStatus.syncedToApp:
        return 'Synced to App';
      case SyncStatus.syncedToServer:
        return 'Synced to Server';
      case SyncStatus.fullySynced:
        return 'Fully Synced';
    }
  }

  bool get isSyncedToApp => value >= SyncStatus.syncedToApp.value;
  bool get isSyncedToServer => value >= SyncStatus.syncedToServer.value;
}
