import 'package:firebase_database/firebase_database.dart';

import '../domain/property_model.dart';
class UnitRepository {
  final _db = FirebaseDatabase.instance.ref();

  // ------------------------------------------------------------
  // Fetch all units (filters archived)
  // ------------------------------------------------------------
  Future<List<UnitModel>> fetchUnits(String orgId) async {
    final snapshot = await _db.child("orgs/$orgId/Units").get();
    if (!snapshot.exists) return [];

    return snapshot.children
        .map((child) {
      final map = Map<String, dynamic>.from(child.value as Map);
      return UnitModel.fromMap(child.key!, map);
    })
        .where((u) =>
    u.isDeleted != true &&            // ⭐ new archive flag
        u.status != "archived" &&         // ⭐ new status
        u.status != "deleted")            // ⭐ backward compatibility
        .toList();
  }

  // ------------------------------------------------------------
  // Create unit
  // ------------------------------------------------------------
  Future<String> createUnit(UnitModel unit) async {
    final ref = _db.child("orgs/${unit.orgId}/Units").push();
    await ref.set(unit.toMap());
    return ref.key!;
  }


  Future<void> updateUnit(UnitModel unit) async {
    final ref = _db.child("orgs/${unit.orgId}/Units/${unit.unitId}");

    // Update only the fields present in the model
    await ref.update(unit.toMap());
  }

  // ------------------------------------------------------------
  // Update unitId field inside the unit
  // ------------------------------------------------------------
  Future<void> updateUnitId(String unitId, String orgId) async {
    await _db.child("orgs/$orgId/Units/$unitId").update({
      "unitId": unitId,
    });
  }

  // ------------------------------------------------------------
  // Assign tenant to unit
  // ------------------------------------------------------------
  Future<void> assignTenantToUnit({
    required String orgId,
    required String unitId,
    required String tenantId,
  }) async {
    await _db.child("orgs/$orgId/Units/$unitId/tenantId").set(tenantId);
  }

  // ------------------------------------------------------------
  // Get Unit Name
  // ------------------------------------------------------------
  Future<String?> getUnitName(String orgId, String unitId) async {
    final snapshot =
    await _db.child("orgs/$orgId/Units/$unitId/name").get();

    if (!snapshot.exists) return null;
    return snapshot.value as String?;
  }

  // ------------------------------------------------------------
  // NEW: Get all units for org (filters archived)
  // ------------------------------------------------------------
  Future<List<UnitModel>> getUnitsForOrg(String orgId) async {
    try {
      final snapshot = await _db.child("orgs/$orgId/Units").get();
      if (!snapshot.exists) return [];

      return snapshot.children
          .map((child) {
        final map = Map<String, dynamic>.from(child.value as Map);
        return UnitModel.fromMap(child.key!, map);
      })
          .where((u) =>
      u.isDeleted != true &&            // ⭐ new archive flag
          u.status != "archived" &&         // ⭐ new status
          u.status != "deleted")            // ⭐ backward compatibility
          .toList();
    } catch (e) {
      print("🔥 Error loading units for org $orgId: $e");
      return [];
    }
  }

  Future<void> updateUnitName(String orgId, String unitId, String newName) async {
    await _db.child("orgs/$orgId/Units/$unitId/name").set(newName);
  }
  Future<void> updateUnitField({
    required String orgId,
    required String unitId,
    required String field,
    required dynamic value,
  }) async {
    await _db.child("orgs/$orgId/Units/$unitId/$field").set(value);
  }





  Future<void> clearUnitLease(UnitModel unit) async {

  }


}
