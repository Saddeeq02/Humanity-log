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
}

final beneficiaryProvider = StateNotifierProvider<BeneficiaryNotifier, List<Beneficiary>>((ref) {
  return BeneficiaryNotifier();
});
