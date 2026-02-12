import 'package:firebase_database/firebase_database.dart';
import 'package:my_app/property/domain/payment_model.dart';



class PaymentRepository {
  final _db = FirebaseDatabase.instance.ref();

  Future<String> createPayment(PaymentModel payment) async {
    final ref = _db
        .child("Orgs/${payment.orgId}/Payments/${payment.period}")
        .push();

    await ref.set(payment.toMap());
    return ref.key!;
  }

  Future<List<PaymentModel>> getPaymentsForPeriod(
      String orgId, String period) async {
    final snapshot =
    await _db.child("Orgs/$orgId/Payments/$period").get();

    if (!snapshot.exists) return [];

    return snapshot.children.map((child) {
      final map = Map<String, dynamic>.from(child.value as Map);
      return PaymentModel.fromMap(child.key!, map);
    }).toList();
  }

  Future<List<PaymentModel>> getPaymentsForUnit(
      String orgId, String unitId) async {
    final payments = <PaymentModel>[];

    final snapshot =
    await _db.child("Orgs/$orgId/Payments").get();

    if (!snapshot.exists) return [];

    for (final periodFolder in snapshot.children) {
      for (final child in periodFolder.children) {
        final map = Map<String, dynamic>.from(child.value as Map);
        final payment = PaymentModel.fromMap(child.key!, map);

        if (payment.unitId == unitId) {
          payments.add(payment);
        }
      }
    }

    return payments;
  }

  Future<List<Map<String, dynamic>>> getPaymentsForMonth({
    required String orgId,
    required DateTime month,
  }) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);

    final startTs = startOfMonth.millisecondsSinceEpoch;
    final endTs = endOfMonth.millisecondsSinceEpoch;

    final snap = await _db.child("Orgs/$orgId/Payments").get();
    final payments = <Map<String, dynamic>>[];

    for (final child in snap.children) {
      final data = Map<String, dynamic>.from(child.value as Map);
      final ts = data["timestamp"] as int?;
      if (ts == null) continue;

      if (ts >= startTs && ts <= endTs) {
        payments.add(data..["paymentId"] = child.key);
      }
    }

    return payments;
  }

  Future<double> sumPaymentsForMonth({
    required String orgId,
    required DateTime month,
  }) async {
    final payments = await getPaymentsForMonth(orgId: orgId, month: month);
    double total = 0;
    for (final p in payments) {
      final amount = (p["amount"] as num?)?.toDouble() ?? 0;
      total += amount;
    }
    return total;
  }

  Future<List<Map<String, dynamic>>> getRecentPayments({
    required String orgId,
    int limit = 10,
  }) async {
    final snap = await _db
        .child("Orgs/$orgId/Payments")
        .orderByChild("timestamp")
        .limitToLast(limit)
        .get();

    final payments = <Map<String, dynamic>>[];
    for (final child in snap.children) {
      final data = Map<String, dynamic>.from(child.value as Map);
      payments.add(data..["paymentId"] = child.key);
    }

    // newest first
    payments.sort((a, b) =>
        (b["timestamp"] as int).compareTo(a["timestamp"] as int));

    return payments;
  }

}







