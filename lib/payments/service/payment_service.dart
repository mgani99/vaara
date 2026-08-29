import '../../property/domain/balance_model.dart';
import '../../property/domain/property_model.dart';
import '../../property/model/balance_repository.dart';
import '../repository/payment_repository.dart';

class PaymentService {
  final PaymentRepository paymentRepo;
  final BalanceRepository balanceRepo;

  PaymentService({
    required this.paymentRepo,
    required this.balanceRepo,
  });

  // ------------------------------------------------------------
  // Create payment
  // ------------------------------------------------------------
  Future<String> addPayment(PaymentModel model) async {
    final id = await paymentRepo.createPayment(model);
    await _updateBalance(model, oldAmount: 0);   // new payment
    return id;
  }

  // ------------------------------------------------------------
  // Update payment
  // ------------------------------------------------------------
  Future<void> updatePayment(PaymentModel model, {required double oldAmount}) async {
    await paymentRepo.updatePayment(model);
    await _updateBalance(model, oldAmount: oldAmount);  // adjust balance
  }

  // ------------------------------------------------------------
  // Soft delete payment
  // ------------------------------------------------------------
  Future<void> deletePayment(String orgId, String paymentId) async {
    await paymentRepo.deletePayment(orgId, paymentId);
  }

  // ------------------------------------------------------------
  // Fetch all payments
  // ------------------------------------------------------------
  Future<List<PaymentModel>> getAllPayments(String orgId) async {
    return await paymentRepo.fetchPayments(orgId);
  }

  // ------------------------------------------------------------
  // Fetch payments for a specific month
  // ------------------------------------------------------------
  Future<List<PaymentModel>> getPaymentsForMonth(
      String orgId, int year, int month) async {
    return await paymentRepo.fetchPaymentsForMonth(orgId, year, month);
  }

  // ------------------------------------------------------------
  // Compute monthly ledger summary
  // ------------------------------------------------------------
  Future<Map<String, double>> computeMonthlyLedger(
      String orgId, int year, int month) async {
    final list = await paymentRepo.fetchPaymentsForMonth(orgId, year, month);

    double debit = 0;
    double credit = 0;

    for (final p in list) {
      if (p.transactionType == "debit") {
        debit += p.amount;
      } else {
        credit += p.amount;
      }
    }

    return {
      "totalDebit": debit,
      "totalCredit": credit,
      "net": debit - credit,
    };
  }

  // ------------------------------------------------------------
  // End-of-month job
  // ------------------------------------------------------------
  Future<void> runEndOfMonthJob(String orgId, int year, int month) async {
    final ledger = await computeMonthlyLedger(orgId, year, month);

    await paymentRepo.saveMonthlyLedgerSummary(
      orgId: orgId,
      year: year,
      month: month,
      totalDebit: ledger["totalDebit"]!,
      totalCredit: ledger["totalCredit"]!,
      net: ledger["net"]!,
    );
  }

  // ------------------------------------------------------------
  // Fetch stored ledger summary
  // ------------------------------------------------------------
  Future<Map<String, dynamic>?> getLedgerSummary(
      String orgId, int year, int month) async {
    return await paymentRepo.getMonthlyLedgerSummary(orgId, year, month);
  }

  // ------------------------------------------------------------
  // INTERNAL: Update balance safely
  // ------------------------------------------------------------
  Future<void> _updateBalance(PaymentModel payment, {required double oldAmount}) async {
    // SAFETY CHECKS
    if (payment.unitId == null || payment.propertyId == null) {
      return; // skip balance update
    }

    final orgId = payment.orgId;
    final unitId = payment.unitId!;
    final propertyId = payment.propertyId!;

    // Compute period YYYY-MM
    final d = DateTime.fromMillisecondsSinceEpoch(payment.paymentDateEpoch);
    final period = "${d.year}-${d.month.toString().padLeft(2, '0')}";

    // Load existing balance
    final existing = await balanceRepo.getBalance(orgId, period, unitId);

    // Adjust paid amount
    final newPaid = (existing?.totalPaid ?? 0) - oldAmount + payment.amount;

    final balance = BalanceModel(
      unitId: unitId,
      propertyId: propertyId,
      orgId: orgId,
      totalPaid: newPaid,
      totalDue: existing?.totalDue ?? 0,
      period: period,
    );

    await balanceRepo.updateBalance(balance);
  }
}
