enum SyncStatus { synced, syncing, offline, error }

extension SyncStatusText on SyncStatus {
  String get label {
    switch (this) {
      case SyncStatus.synced:
        return 'Tüm değişiklikler güncel';
      case SyncStatus.syncing:
        return 'Değişiklikler eşitleniyor';
      case SyncStatus.offline:
        return 'Çevrimdışı · değişiklikler bekliyor';
      case SyncStatus.error:
        return 'Eşitleme sorunu · tekrar dokun';
    }
  }
}
