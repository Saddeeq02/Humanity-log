import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/distribution_log.dart';

class DistributionNotifier extends StateNotifier<List<DistributionLog>> {
  DistributionNotifier() : super([]);

  Future<void> addDistribution(DistributionLog log) async {
    await Future.delayed(const Duration(milliseconds: 300));
    state = [...state, log];
  }

  void markAsSynced(List<String> ids) {
    state = [
      for (final log in state)
        if (ids.contains(log.id)) log.copyWith(isSynced: true) else log
    ];
  }

  List<DistributionLog> getUnsynced() {
    return state.where((log) => !log.isSynced).toList();
  }
}

final distributionProvider = StateNotifierProvider<DistributionNotifier, List<DistributionLog>>((ref) {
  return DistributionNotifier();
});
