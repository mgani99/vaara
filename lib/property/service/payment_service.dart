
import 'package:my_app/property/domain/balance_model.dart';
import 'package:my_app/property/domain/payment_model.dart';
import 'package:my_app/property/model/balance_repository.dart';
import 'package:my_app/property/model/payment_repository.dart';

class PaymentService {
  final PaymentRepository paymentRepo;
  final BalanceRepository balanceRepo;

  PaymentService({
    required this.paymentRepo,
    required this.balanceRepo,
  });

  Future<String> createPayment(PaymentModel payment) async {
    // 1. Save payment
    final paymentId = await paymentRepo.createPayment(payment);

    // 2. Update balance
    await _updateBalance(payment);

    return paymentId;
  }

  Future<void> _updateBalance(PaymentModel payment) async {
    final orgId = payment.orgId;
    final period = payment.period;
    final unitId = payment.unitId;

    final existing =
    await balanceRepo.getBalance(orgId, period, unitId);

    final newPaid = (existing?.totalPaid ?? 0) + payment.amount;

    final balance = BalanceModel(
      unitId: unitId,
      propertyId: payment.propertyId,
      orgId: orgId,
      totalPaid: newPaid,
      totalDue: existing?.totalDue ?? 0,
      period: period,
    );

    await balanceRepo.updateBalance(balance);
  }

  Future<List<PaymentModel>> getPaymentsForPeriod(
      String orgId, String period) {
    return paymentRepo.getPaymentsForPeriod(orgId, period);
  }

  Future<List<PaymentModel>> getPaymentsForUnit(
      String orgId, String unitId) {
    return paymentRepo.getPaymentsForUnit(orgId, unitId);
  }
}
