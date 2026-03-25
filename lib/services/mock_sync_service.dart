import 'dart:async';
import 'mock_database_service.dart';

class MockSyncService {
  final MockDatabaseService database;
  bool _isOnline = false;

  MockSyncService(this.database);

  bool get isOnline => _isOnline;

  void toggleNetwork(bool online) {
    _isOnline = online;
    if (_isOnline) {
      _triggerSync();
    }
  }

  Future<void> _triggerSync() async {
    if (!_isOnline) return;

    final unsynced = await database.getUnsyncedDistributions();
    if (unsynced.isEmpty) return;

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    if (!_isOnline) return; // if network dropped during sync

    // Mark as synced
    await database.markDistributionsAsSynced(unsynced.map((e) => e.id).toList());
  }

  Future<int> getPendingSyncCount() async {
    final unsynced = await database.getUnsyncedDistributions();
    return unsynced.length;
  }
}
