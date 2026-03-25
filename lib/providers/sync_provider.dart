import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'distribution_provider.dart';
import 'api_service_provider.dart';
import 'auth_provider.dart';

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
    if (unsynced.isEmpty) return;

    final api = ref.read(apiServiceProvider);
    final auth = ref.read(authProvider);
    final agentId = auth.user?.id ?? 'agent-anonymous';

    try {
      final response = await api.pushSyncPayload(agentId: agentId, logs: unsynced, newBeneficiaries: []);
      if (response.statusCode == 200) {
        distNotifier.markAsSynced(unsynced.map((e) => e.id).toList());
      } else {
        // handle error - keep unsynced
        // Could emit some state or log
        print('Sync failed with status: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Sync error: $e');
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
