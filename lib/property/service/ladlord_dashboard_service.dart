import 'package:firebase_database/firebase_database.dart';
import 'package:my_app/property/model/lease_details_repository.dart';
import 'package:my_app/property/model/payment_repository.dart';
import 'package:my_app/property/model/unit_repository.dart';
import 'package:my_app/login/model/org_user_repository.dart';
import 'package:my_app/session/app_data.dart';

class LandlordDashboardService {
  final AppSession session;
  final UnitRepository unitRepo;
  final OrgUserRepository orgUserRepo;
  final LeaseDetailsRepository leaseRepo;
  final PaymentRepository paymentRepo;
  final DatabaseReference db;

  LandlordDashboardService({
    required this.session,
    required this.unitRepo,
    required this.orgUserRepo,
    required this.leaseRepo,
    required this.paymentRepo,
    required this.db,
  });

  Future<Map<String, dynamic>> loadDashboard() async {
    final orgId = session.activeOrgId!;
    final navDate = session.navigationDate;

    // ------------------------------------------------------------
    // UNITS
    // ------------------------------------------------------------
    final unitsSnap = await db.child("orgs/$orgId/units").get();
    final totalUnits = unitsSnap.children.length;

    // ------------------------------------------------------------
    // ACTIVE LEASES FOR CURRENT MONTH
    // ------------------------------------------------------------
    final activeLeases = await leaseRepo.getActiveLeasesForMonth(
      orgId: orgId,
      month: navDate,
    );

    final occupiedUnitIds = <String>{};
    final tenantIds = <int>{};
    double expectedRent = 0;

    for (final lease in activeLeases) {
      final unitId = lease["unitId"] as String?;
      if (unitId != null) {
        occupiedUnitIds.add(unitId);
      }

      final rent = (lease["rent"] as num?)?.toDouble() ?? 0;
      expectedRent += rent;

      final leaseTenantIds = (lease["tenantIds"] as List?) ?? [];
      for (final t in leaseTenantIds) {
        if (t is int) tenantIds.add(t);
        if (t is num) tenantIds.add(t.toInt());
      }
    }

    final occupiedUnits = occupiedUnitIds.length;
    final occupancyRate =
    totalUnits == 0 ? 0.0 : occupiedUnits / totalUnits.toDouble();

    // ------------------------------------------------------------
    // PAYMENTS
    // ------------------------------------------------------------
    final receivedRent = await paymentRepo.sumPaymentsForMonth(
      orgId: orgId,
      month: navDate,
    ) ?? 0.0;

    final outstanding = expectedRent - receivedRent;

    // ------------------------------------------------------------
    // RECENT PAYMENTS
    // ------------------------------------------------------------
    final recentPayments = await paymentRepo.getRecentPayments(orgId: orgId);

    return {
      "totalUnits": totalUnits,
      "occupiedUnits": occupiedUnits,
      "occupancyRate": occupancyRate,
      "tenantCount": tenantIds.length,
      "expectedRent": expectedRent,
      "receivedRent": receivedRent,
      "outstanding": outstanding,
      "recentPayments": recentPayments,
    };
  }
}
