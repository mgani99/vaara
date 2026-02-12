import 'package:firebase_database/firebase_database.dart';
import 'package:my_app/property/domain/lease_details_model.dart';


class LeaseDetailsRepository {
  final _db = FirebaseDatabase.instance.ref();

  Future<String> createLease(LeaseDetailsModel lease) async {
    final ref = _db.child("Orgs/${lease.orgId}/LeaseDetails").push();
    await ref.set(lease.toMap());
    return ref.key!;
  }

  Future<LeaseDetailsModel?> getLease(String orgId, String leaseId) async {
    final snapshot =
    await _db.child("Orgs/$orgId/LeaseDetails/$leaseId").get();

    if (!snapshot.exists) return null;

    final map = Map<String, dynamic>.from(snapshot.value as Map);
    return LeaseDetailsModel.fromMap(leaseId, map);
  }

  Future<List<LeaseDetailsModel>> getLeasesForUnit(
      String orgId, String unitId) async {
    final snapshot = await _db.child("Orgs/$orgId/LeaseDetails").get();
    if (!snapshot.exists) return [];

    return snapshot.children
        .map((child) {
      final map = Map<String, dynamic>.from(child.value as Map);
      return LeaseDetailsModel.fromMap(child.key!, map);
    })
        .where((lease) => lease.unitId == unitId)
        .toList();
  }
  Future<List<Map<String, dynamic>>> getActiveLeasesForMonth({
    required String orgId,
    required DateTime month,
  }) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);

    final startTs = startOfMonth.millisecondsSinceEpoch;
    final endTs = endOfMonth.millisecondsSinceEpoch;

    final snap = await _db.child("Orgs/$orgId/LeaseDetails").get();
    final leases = <Map<String, dynamic>>[];

    for (final child in snap.children) {
      final data = Map<String, dynamic>.from(child.value as Map);

      final startDate = data["startDate"] as int?;
      final endDate = data["endDate"] as int?;

      if (startDate == null || endDate == null) continue;

      final overlaps =
          startDate <= endTs && endDate >= startTs; // active in this month

      if (overlaps) {
        leases.add(data..["leaseId"] = child.key);
      }
    }

    return leases;
  }
}














