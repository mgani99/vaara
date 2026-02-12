
import 'package:my_app/property/domain/lease_details_model.dart';
import 'package:my_app/property/domain/payment_model.dart';
import 'package:my_app/property/domain/tenant_model.dart';
import 'package:my_app/property/domain/unit_model.dart';
import 'package:my_app/property/service/lease_details_service.dart';
import 'package:my_app/property/service/payment_service.dart';
import 'package:my_app/property/service/tenant_service.dart';
import 'package:my_app/property/service/unit_service.dart';

class PaymentListService {
  final PaymentService paymentService;
  final UnitService unitService;
  final TenantService tenantService;
  final LeaseDetailsService leaseService;

  PaymentListService({
    required this.paymentService,
    required this.unitService,
    required this.tenantService,
    required this.leaseService,
  });

  Future<List<UnitModel>> getAllUnits(String orgId) {
    return unitService.getUnits(orgId);
  }

  Future<List<PaymentModel>> getPaymentsForPeriod(
      String orgId, String period) {
    return paymentService.getPaymentsForPeriod(orgId, period);
  }

  Future<TenantModel?> getTenant(String orgId, String tenantId) {
    return tenantService.getTenant(orgId, tenantId);
  }

  Future<List<LeaseDetailsModel>> getLeaseHistory(
      String orgId, String unitId) {
    return leaseService.getLeasesForUnit(orgId, unitId);
  }

  Future<LeaseDetailsModel?> getLeaseById(
      String orgId, String leaseId) {
    return leaseService.getLease(orgId, leaseId);
  }
}
