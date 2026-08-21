import 'package:firebase_database/firebase_database.dart';

import '../domain/property_model.dart';

class LeaseDetailsRepository {
  final _db = FirebaseDatabase.instance.ref();

  // ------------------------------------------------------------
  // Create lease
  // ------------------------------------------------------------
  Future<String> createLease(LeaseDetailsModel lease) async {
    final ref = _db.child("orgs/${lease.orgId}/LeaseDetails").push();
    await ref.set(lease.toMap());
    return ref.key!;
  }

  // ------------------------------------------------------------
  // Get lease by ID (filters archived)
  // ------------------------------------------------------------
  Future<LeaseDetailsModel?> getLease(String orgId, String leaseId) async {
    final snapshot =
    await _db.child("orgs/$orgId/LeaseDetails/$leaseId").get();

    if (!snapshot.exists) return null;

    final map = Map<String, dynamic>.from(snapshot.value as Map);
    final model = LeaseDetailsModel.fromMap(leaseId, map);

    if (model.isDeleted == true) return null;     // ⭐ new archive flag
    if (model.status == "archived") return null;  // ⭐ new status
    if (model.status == "deleted") return null;   // ⭐ backward compatibility

    return model;
  }

  // ------------------------------------------------------------
  // Update leaseId field
  // ------------------------------------------------------------
  Future<void> updateLeaseId(String leaseId, String orgId) async {
    await _db.child("orgs/$orgId/LeaseDetails/$leaseId").update({
      "leaseId": leaseId,
    });
  }

  // ------------------------------------------------------------
  // Get all leases for a unit (filters archived)
  // ------------------------------------------------------------
  Future<List<LeaseDetailsModel>> getLeasesForUnit(
      String orgId, String unitId) async {
    final snapshot = await _db.child("orgs/$orgId/LeaseDetails").get();
    if (!snapshot.exists) return [];

    return snapshot.children
        .map((child) {
      final map = Map<String, dynamic>.from(child.value as Map);
      return LeaseDetailsModel.fromMap(child.key!, map);
    })
        .where((lease) =>
    lease.unitId == unitId &&
        lease.isDeleted != true &&            // ⭐ new archive flag
        lease.status != "archived" &&         // ⭐ new status
        lease.status != "deleted")            // ⭐ backward compatibility
        .toList();
  }

  // ------------------------------------------------------------
  // Get leases active in a given month (filters archived)
  // ------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getActiveLeasesForMonth({
    required String orgId,
    required DateTime month,
  }) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);

    final startTs = startOfMonth.millisecondsSinceEpoch;
    final endTs = endOfMonth.millisecondsSinceEpoch;

    final snap = await _db.child("orgs/$orgId/LeaseDetails").get();
    final leases = <Map<String, dynamic>>[];

    for (final child in snap.children) {
      final data = Map<String, dynamic>.from(child.value as Map);

      // ⭐ Skip archived leases
      if (data["isDeleted"] == true) continue;
      if (data["status"] == "archived") continue;
      if (data["status"] == "deleted") continue;

      final startDate = data["startDate"] as int?;
      final endDate = data["endDate"] as int?;

      if (startDate == null || endDate == null) continue;

      final overlaps = startDate <= endTs && endDate >= startTs;

      if (overlaps) {
        leases.add(data..["leaseId"] = child.key);
      }
    }

    return leases;
  }

  // ------------------------------------------------------------
  // Get all current leases for org (filters archived)
  // ------------------------------------------------------------
  Future<List<LeaseDetailsModel>> getCurrentLeasesForOrg(String orgId) async {
    try {
      // ============================================================
      // 1. Load all units for org
      // ============================================================
      final unitSnapshot = await _db.child("orgs/$orgId/Units").get();
      if (!unitSnapshot.exists) return [];

      final List<String> leaseIds = [];

      for (final child in unitSnapshot.children) {
        final map = Map<String, dynamic>.from(child.value as Map);

        // ⭐ Skip archived units
        if (map["isDeleted"] == true) continue;
        if (map["status"] == "archived") continue;
        if (map["status"] == "deleted") continue;

        final currentLeaseId = map["currentLeaseId"];
        if (currentLeaseId != null && currentLeaseId.toString().isNotEmpty) {
          leaseIds.add(currentLeaseId.toString());
        }
      }

      if (leaseIds.isEmpty) return [];

      // ============================================================
      // 2. Fetch each lease by ID (filters archived)
      // ============================================================
      final List<LeaseDetailsModel> leases = [];

      for (final leaseId in leaseIds) {
        final leaseSnap =
        await _db.child("orgs/$orgId/LeaseDetails/$leaseId").get();

        if (!leaseSnap.exists) continue;

        final map = Map<String, dynamic>.from(leaseSnap.value as Map);
        final model = LeaseDetailsModel.fromMap(leaseId, map);

        if (model.isDeleted == true) continue;     // ⭐ new archive flag
        if (model.status == "archived") continue;  // ⭐ new status
        if (model.status == "deleted") continue;   // ⭐ backward compatibility

        leases.add(model);
      }

      return leases;
    } catch (e) {
      print("🔥 Error loading current leases for org $orgId: $e");
      return [];
    }
  }

  Future<void> updateLeaseField({
    required String orgId,
    required String leaseId,
    required String field,
    required dynamic value,
  }) async {
    await _db
        .child("orgs/$orgId/LeaseDetails/$leaseId/$field")
        .set(value);
  }

  Future<void> updateLease(LeaseDetailsModel lease) async {
    await _db
        .child("orgs/${lease.orgId}/LeaseDetails/${lease.leaseId}")
        .update(lease.toMap());
  }


}
