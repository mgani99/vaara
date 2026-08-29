import '../payments/repository/payment_repository.dart';

class LedgerJobService {
  final PaymentRepository _repo = PaymentRepository();

  /// Run ledger job for a given month
  Future<void> runMonthlyLedgerJob({
    required String orgId,
    required int year,
    required int month,
  }) async {
    // 1. Fetch payments for the month
    final payments = await _repo.fetchPaymentsForMonth(orgId, year, month);

    double totalDebit = 0;
    double totalCredit = 0;

    // 2. Aggregate
    for (final p in payments) {
      if (p.transactionType == "debit") {
        totalDebit += p.amount;
      } else {
        totalCredit += p.amount;
      }
    }

    final net = totalDebit - totalCredit;

    // 3. Save summary
    await _repo.saveMonthlyLedgerSummary(
      orgId: orgId,
      year: year,
      month: month,
      totalDebit: totalDebit,
      totalCredit: totalCredit,
      net: net,
    );
  }

  /// Fetch ledger summary (if exists)
  Future<Map<String, dynamic>?> getLedgerSummary(
      String orgId, int year, int month) async {
    return await _repo.getMonthlyLedgerSummary(orgId, year, month);
  }
}
/*
exports.runMonthlyLedgerJob = functions.pubsub
  .schedule('0 0 1 * *') // first day of month at midnight
  .timeZone('America/New_York')
  .onRun(async (context) => {

    const admin = require('firebase-admin');
    const db = admin.database();

    const now = new Date();
    const year = now.getFullYear();
    const month = now.getMonth(); // previous month

    const orgsSnap = await db.ref("orgs").get();

    orgsSnap.forEach(async (orgNode) => {
      const orgId = orgNode.key;

      const paymentsSnap = await db.ref(`orgs/${orgId}/Payments`).get();
      let debit = 0;
      let credit = 0;

      paymentsSnap.forEach((child) => {
        const p = child.val();
        const date = new Date(p.paymentDateEpoch);

        if (date.getFullYear() === year && date.getMonth() === month) {
          if (p.transactionType === "debit") debit += p.amount;
          else credit += p.amount;
        }
      });

      const net = debit - credit;

      await db.ref(`orgs/${orgId}/PaymentLedger/${year}-${month + 1}`).set({
        year,
        month: month + 1,
        totalDebit: debit,
        totalCredit: credit,
        net,
        createdAt: Date.now()
      });
    });

    return null;
  });

 */