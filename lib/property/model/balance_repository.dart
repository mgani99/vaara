import 'package:firebase_database/firebase_database.dart';
import 'package:my_app/property/domain/balance_model.dart';

class BalanceRepository {
  final _db = FirebaseDatabase.instance.ref();

  Future<void> updateBalance(BalanceModel balance) async {
    await _db
        .child("Orgs/${balance.orgId}/Balances/${balance.period}/${balance.unitId}")
        .set(balance.toMap());
  }

  Future<BalanceModel?> getBalance(
      String orgId, String period, String unitId) async {
    final snapshot = await _db
        .child("Orgs/$orgId/Balances/$period/$unitId")
        .get();

    if (!snapshot.exists) return null;

    final map = Map<String, dynamic>.from(snapshot.value as Map);
    return BalanceModel.fromMap(map);
  }

  Future<List<BalanceModel>> getBalancesForPeriod(
      String orgId, String period) async {
    final snapshot =
    await _db.child("Orgs/$orgId/Balances/$period").get();

    if (!snapshot.exists) return [];

    return snapshot.children.map((child) {
      final map = Map<String, dynamic>.from(child.value as Map);
      return BalanceModel.fromMap(map);
    }).toList();
  }
}
