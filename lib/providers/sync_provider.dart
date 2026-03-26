import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'distribution_provider.dart';
import 'api_service_provider.dart';
import 'auth_provider.dart';
import 'beneficiary_provider.dart';
import 'inventory_provider.dart';

class NetworkNotifier extends StateNotifier<bool> {
  final Ref ref;
  NetworkNotifier(this.ref) : super(false); // Default offline

  void toggleNetwork() async {
    state = !state;
    if (state) {
      await _triggerSync();
    }
  }

  Future<void> _triggerSync() async {
    final distNotifier = ref.read(distributionProvider.notifier);
    final unsynced = distNotifier.getUnsynced();
    
    final api = ref.read(apiServiceProvider);
    final auth = ref.read(authProvider);
    final agentId = auth.user?.id ?? 'agent-anonymous';

    try {
      if (unsynced.isNotEmpty) {
        final response = await api.pushSyncPayload(agentId: agentId, logs: unsynced, newBeneficiaries: []);
        if (response.statusCode == 200) {
          distNotifier.markAsSynced(unsynced.map((e) => e.id).toList());
        }
      }
      
      // Always pull fresh data during a sync if online
      await pullBeneficiaries();
      await fetchAssignment();
    } catch (e) {
      print('Sync error: $e');
    }
  }

  Future<void> fetchAssignment() async {
    final api = ref.read(apiServiceProvider);
    final auth = ref.read(authProvider);
    final userId = auth.user?.id;
    
    if (userId == null) return;

    try {
      final assignment = await api.getLatestAssignment(userId: userId);
      if (assignment != null) {
        final id = assignment['id'] as String?;
        final total = assignment['total_assigned_items'] as int? ?? 0;
        final statusStr = assignment['status'] as String? ?? 'pending';
        
        InventoryStatus status = InventoryStatus.pending;
        if (statusStr == 'accepted') status = InventoryStatus.accepted;
        if (statusStr == 'reconciling') status = InventoryStatus.reconciling;
        if (statusStr == 'completed') status = InventoryStatus.completed;

        if (id != null) {
          ref.read(inventoryProvider.notifier).updateFromAssignment(id, total, status);
        }
      }
    } catch (e) {
      print('Assignment fetch error: $e');
    }
  }

  Future<void> pullBeneficiaries() async {
    final api = ref.read(apiServiceProvider);
    final auth = ref.read(authProvider);
    final agentId = auth.user?.id ?? 'agent-anonymous';
    
    try {
      final beneficiaries = await api.pullBeneficiaries(agentId: agentId);
      ref.read(beneficiaryProvider.notifier).setBeneficiaries(beneficiaries);
    } catch (e) {
      print('Pull error: $e');
    }
  }

  Future<void> initialSync() async {
    state = true; // Set online for initial sync
    await _triggerSync();
  }

  Future<void> reconcileMission() async {
    final api = ref.read(apiServiceProvider);
    final inventory = ref.read(inventoryProvider);
    
    if (inventory.assignmentId == null) return;

    try {
      // Map returns for the API
      final List<Map<String, dynamic>> returns = [
        {
          'inventory_id': 'default_id', // In a multi-item system, we'd map correctly
          'quantity': inventory.returned_quantity // I need to add this to DailyInventory model or use returnedAid
        }
      ];

      await api.reconcileAssignment(
        assignmentId: inventory.assignmentId!,
        returns: [
          {'inventory_id': 'kits_001', 'quantity': inventory.returnedAid} // Using hardcoded ID for now as per MVP
        ],
      );
      
      // Refresh assignment status
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
  return distributions.where((log) => !log.isSynced).length;
});
