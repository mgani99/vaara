

import 'package:my_app/property/domain/balance_model.dart';
import 'package:my_app/property/model/balance_repository.dart';

class BalanceService {
  final BalanceRepository repo;

  BalanceService({required this.repo});

  Future<BalanceModel?> getBalance(
      String orgId, String period, String unitId) {
    return repo.getBalance(orgId, period, unitId);
  }

  Future<List<BalanceModel>> getBalancesForPeriod(
      String orgId, String period) {
    return repo.getBalancesForPeriod(orgId, period);
  }

  Future<void> updateBalance(BalanceModel balance) {
    return repo.updateBalance(balance);
  }
}
