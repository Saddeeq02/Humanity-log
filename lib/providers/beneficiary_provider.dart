import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/beneficiary.dart';

class BeneficiaryNotifier extends StateNotifier<List<Beneficiary>> {
  BeneficiaryNotifier() : super([]);

  Future<void> addBeneficiary(Beneficiary beneficiary) async {
    state = [...state, beneficiary];
  }

  Future<void> setBeneficiaries(List<Beneficiary> beneficiaries) async {
    state = beneficiaries;
  }

  List<Beneficiary> getUnsynced() {
    return state.where((b) => !b.isSynced).toList();
  }

  void markAsSynced(List<String> ids) {
    state = [
      for (final b in state)
        if (ids.contains(b.id)) b.copyWith(isSynced: true) else b,
    ];
  }
}

final beneficiaryProvider = StateNotifierProvider<BeneficiaryNotifier, List<Beneficiary>>((ref) {
  return BeneficiaryNotifier();
});
