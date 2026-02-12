import 'package:firebase_database/firebase_database.dart';
import 'package:my_app/property/domain/unit_model.dart';

class UnitRepository {
  final _db = FirebaseDatabase.instance.ref();

  Future<List<UnitModel>> fetchUnits(String orgId) async {
    final snapshot = await _db.child("Orgs/$orgId/Units").get();
    if (!snapshot.exists) return [];

    return snapshot.children.map((child) {
      final map = Map<String, dynamic>.from(child.value as Map);
      return UnitModel.fromMap(child.key!, map);
    }).toList();
  }

  Future<String> createUnit(UnitModel unit) async {
    final ref = _db.child("Orgs/${unit.orgId}/Units").push();
    await ref.set(unit.toMap());
    return ref.key!;
  }

  // ------------------------------------------------------------
  // NEW: Assign tenant to unit
  // ------------------------------------------------------------
  Future<void> assignTenantToUnit({
    required String orgId,
    required String unitId,
    required String tenantId,
  }) async {
    await _db
        .child("Orgs/$orgId/Units/$unitId/tenantId")
        .set(tenantId);
  }

  // ------------------------------------------------------------
  // NEW: Get Unit Name
  // ------------------------------------------------------------
  Future<String?> getUnitName(String orgId, String unitId) async {
    final snapshot =
    await _db.child("Orgs/$orgId/Units/$unitId/name").get();

    if (!snapshot.exists) return null;
    return snapshot.value as String?;
  }
}
