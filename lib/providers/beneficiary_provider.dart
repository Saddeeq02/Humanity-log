import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/beneficiary.dart';

class BeneficiaryNotifier extends StateNotifier<List<Beneficiary>> {
  BeneficiaryNotifier() : super([]);

  Future<void> addBeneficiary(Beneficiary beneficiary) async {
    // Simulate DB save delay
    await Future.delayed(const Duration(milliseconds: 300));
    state = [...state, beneficiary];
  }
}

final beneficiaryProvider = StateNotifierProvider<BeneficiaryNotifier, List<Beneficiary>>((ref) {
  return BeneficiaryNotifier();
});
