import 'dart:async';
import '../models/beneficiary.dart';
import '../models/distribution_log.dart';

class MockDatabaseService {
  final List<Beneficiary> _beneficiaries = [];
  final List<DistributionLog> _distributions = [];

  Future<void> saveBeneficiary(Beneficiary beneficiary) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _beneficiaries.add(beneficiary);
  }

  Future<void> saveDistribution(DistributionLog log) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _distributions.add(log);
  }

  Future<List<Beneficiary>> getAllBeneficiaries() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_beneficiaries);
  }

  Future<List<DistributionLog>> getAllDistributions() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_distributions);
  }

  Future<List<DistributionLog>> getUnsyncedDistributions() async {
    return _distributions.where((log) => !log.isSynced).toList();
  }

  Future<void> markDistributionsAsSynced(List<String> logIds) async {
    for (int i = 0; i < _distributions.length; i++) {
        if (logIds.contains(_distributions[i].id)) {
            _distributions[i] = _distributions[i].copyWith(isSynced: true);
        }
    }
  }

  Future<int> getBeneficiaryCount() async {
    return _beneficiaries.length;
  }
}
