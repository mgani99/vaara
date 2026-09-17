import 'package:firebase_database/firebase_database.dart';

import '../../property/domain/property_model.dart';




class PaymentRepository {
  final _db = FirebaseDatabase.instance.ref();

  // ------------------------------------------------------------
  // Fetch all payments for org (filters archived/deleted)
  // ------------------------------------------------------------
  Future<List<PaymentModel>> fetchPayments(String orgId) async {
    final snapshot = await _db.child("orgs/$orgId/Payments").get();
    if (!snapshot.exists) return [];

    return snapshot.children
        .map((child) {
      final map = Map<String, dynamic>.from(child.value as Map);
      return PaymentModel.fromMap(child.key!, map);
    })
        .where((p) =>
    p.isDeleted != true &&
        p.status != "archived" &&
        p.status != "deleted")
        .toList();
  }

  // ------------------------------------------------------------
  // Create payment
  // ------------------------------------------------------------
  Future<String> createPayment(PaymentModel payment) async {
    final ref = _db.child("orgs/${payment.orgId}/Payments").push();
    await ref.set(payment.toMap());
    return ref.key!;
  }

  // ------------------------------------------------------------
  // Get payment by ID (filters archived)
  // ------------------------------------------------------------
  Future<PaymentModel?> getPaymentById(String orgId, String paymentId) async {
    final snapshot =
    await _db.child("orgs/$orgId/Payments/$paymentId").get();

    if (!snapshot.exists) return null;

    final map = Map<String, dynamic>.from(snapshot.value as Map);
    final model = PaymentModel.fromMap(paymentId, map);

    if (model.isDeleted == true) return null;
    if (model.status == "archived") return null;
    if (model.status == "deleted") return null;

    return model;
  }

  // ------------------------------------------------------------
  // Update payment
  // ------------------------------------------------------------
  Future<void> updatePayment(PaymentModel updated) async {
    final ref =
    _db.child("orgs/${updated.orgId}/Payments/${updated.paymentId}");
    await ref.update(updated.toMap());
  }

  // ------------------------------------------------------------
  // Soft delete / archive payment
  // ------------------------------------------------------------
  Future<void> deletePayment(String orgId, String paymentId) async {
    final ref = _db.child("orgs/$orgId/Payments/$paymentId");

    await ref.update({
      "status": "archived",
      "isDeleted": true,
      "deletedAt": DateTime.now().toIso8601String(),
    });
  }

  // ------------------------------------------------------------
  // Fetch payments for a specific month (YYYY-MM)
  // ------------------------------------------------------------
  Future<List<PaymentModel>> fetchPaymentsForMonth(
      String orgId, int year, int month) async {


    final snapshot = await _db.child("orgs/$orgId/Payments").get();
    if (!snapshot.exists) return [];

    return snapshot.children
        .map((child) {
      final map = Map<String, dynamic>.from(child.value as Map);
      return PaymentModel.fromMap(child.key!, map);
    })
        .where((p) {
      final eff = DateTime.fromMillisecondsSinceEpoch(p.effectiveDateEpoch, isUtc: true);

      // ✅ Correct month/year matching
      final sameMonth = eff.year == year && eff.month == month;

      return sameMonth && p.isDeleted != true;
    })
        .toList();
  }


  // ------------------------------------------------------------
  // End-of-month ledger aggregation (credit/debit summary)
  // ------------------------------------------------------------
  Future<void> saveMonthlyLedgerSummary({
    required String orgId,
    required int year,
    required int month,
    required double totalDebit,
    required double totalCredit,
    required double net,
  }) async {
    final ledgerId = "$year-$month";

    await _db.child("orgs/$orgId/PaymentLedger/$ledgerId").set({
      "year": year,
      "month": month,
      "totalDebit": totalDebit,
      "totalCredit": totalCredit,
      "net": net,
      "createdAt": DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<Map<String, dynamic>?> getMonthlyLedger({
    required String orgId,
    required String period,      // "2026-09"
    required String ledgerKey,   // "unitId_tenantId"
  }) async {
    final ref = _db.child("orgs/$orgId/MonthlyLedger/$period/$ledgerKey");

    final snapshot = await ref.get();
    print(ledgerKey + " " + period);
    if (!snapshot.exists) return null;

    return Map<String, dynamic>.from(snapshot.value as Map);
  }


  // ------------------------------------------------------------
  // Fetch monthly ledger summary
  // ------------------------------------------------------------
  Future<Map<String, dynamic>?> getMonthlyLedgerSummary(
      String orgId, int year, int month) async {
    final ledgerId = "$year-$month";
    final snapshot =
    await _db.child("orgs/$orgId/PaymentLedger/$ledgerId").get();

    if (!snapshot.exists) return null;
    return Map<String, dynamic>.from(snapshot.value as Map);
  }

  Future sumPaymentsForMonth({required String orgId, required DateTime month}) async {}

  Future getRecentPayments({required String orgId}) async {}
}
