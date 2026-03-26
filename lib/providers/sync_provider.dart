import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'distribution_provider.dart';
import 'api_service_provider.dart';
import 'auth_provider.dart';
import 'beneficiary_provider.dart';
import 'inventory_provider.dart';

class SyncSummary {
  final int pushedRecords; // Total of logs + beneficiaries
  final int pulledBeneficiaries;
  final String status;

  SyncSummary({
    this.pushedRecords = 0,
    this.pulledBeneficiaries = 0,
    required this.status,
  });
}

class NetworkNotifier extends StateNotifier<bool> {
  final Ref _ref;
  NetworkNotifier(this._ref) : super(false); // Default offline

  void toggleNetwork() async {
    state = !state;
    if (state) {
      await manualSync();
    }
  }

  Future<SyncSummary> manualSync() async {
    final distNotifier = _ref.read(distributionProvider.notifier);
    final benNotifier = _ref.read(beneficiaryProvider.notifier);
    
    final unsyncedLogs = distNotifier.getUnsynced();
    final unsyncedBens = benNotifier.getUnsynced();
    
    final api = _ref.read(apiServiceProvider);
    final auth = _ref.read(authProvider);
    final agentId = auth.user?.id ?? 'agent-anonymous';

    int pushedCount = 0;
    int pulledCount = 0;

    try {
      // 1. PUSH local unsynced data (Logs AND New Beneficiaries)
      if (unsyncedLogs.isNotEmpty || unsyncedBens.isNotEmpty) {
        final response = await api.pushSyncPayload(
          agentId: agentId, 
          logs: unsyncedLogs, 
          newBeneficiaries: unsyncedBens
        );
        
        if (response.statusCode == 200) {
          distNotifier.markAsSynced(unsyncedLogs.map((e) => e.id).toList());
          benNotifier.markAsSynced(unsyncedBens.map((e) => e.id).toList());
          pushedCount = unsyncedLogs.length + unsyncedBens.length;
        }
      }
      
      // 2. PULL remote updates
      final beneficiaries = await api.pullBeneficiaries(agentId: agentId);
      _ref.read(beneficiaryProvider.notifier).setBeneficiaries(beneficiaries);
      pulledCount = beneficiaries.length;

      // 3. FETCH current mission status
      await fetchAssignment();

      return SyncSummary(
        pushedRecords: pushedCount,
        pulledBeneficiaries: pulledCount,
        status: 'SUCCESS',
      );
    } catch (e) {
      print('Sync error: $e');
      return SyncSummary(status: 'ERROR');
    }
  }

  Future<void> fetchAssignment() async {
    final api = _ref.read(apiServiceProvider);
    final auth = _ref.read(authProvider);
    final userId = auth.user?.id;
    
    if (userId == null) return;

    try {
      final assignment = await api.getLatestAssignment(userId: userId);
      if (assignment != null) {
        final id = assignment['id'] as String?;
        final items = assignment['items'] as List<dynamic>? ?? [];
        final statusStr = assignment['status'] as String? ?? 'pending';
        
        if (id != null) {
          _ref.read(inventoryProvider.notifier).updateFromAssignment(id, items, statusStr);
        }
      }
    } catch (e) {
      print('Assignment fetch error: $e');
    }
  }

  Future<void> initialSync() async {
    state = true; // Set online for initial sync
    await manualSync();
  }

  Future<void> reconcileMission() async {
    final api = _ref.read(apiServiceProvider);
    final inventory = _ref.read(inventoryProvider);
    
    if (inventory.assignmentId == null) return;

    try {
      final List<Map<String, dynamic>> returns = inventory.items.map((item) => {
        'inventory_id': item.inventoryId,
        'quantity': item.returned
      }).toList();

      await api.reconcileAssignment(
        assignmentId: inventory.assignmentId!,
        returns: returns,
      );
      
      await fetchAssignment();
    } catch (e) {
      print('Reconcile error: $e');
      rethrow;
    }
  }
}

final networkProvider = StateNotifierProvider<NetworkNotifier, bool>((ref) {
  return NetworkNotifier(ref);
});

final pendingSyncCountProvider = Provider<int>((ref) {
  final distributions = ref.watch(distributionProvider);
  final beneficiaries = ref.watch(beneficiaryProvider);
  
  final unsyncedLogs = distributions.where((log) => !log.isSynced).length;
  final unsyncedBens = beneficiaries.where((ben) => !ben.isSynced).length;
  
  return unsyncedLogs + unsyncedBens;
});
