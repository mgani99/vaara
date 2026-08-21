import 'package:firebase_database/firebase_database.dart';

import '../domain/property_model.dart';


class TenantRepository {
  final _db = FirebaseDatabase.instance.ref();

  // ------------------------------------------------------------
  // Create tenant
  // ------------------------------------------------------------
  Future<String> createTenant(TenantModel tenant) async {
    final ref = _db.child("orgs/${tenant.orgId}/Tenants").push();
    final tenantId = ref.key!;

    await ref.set({
      ...tenant.toMap(),
      "tenantId": tenantId,   // ensure tenantId is written
    });

    return tenantId;
  }


  // ------------------------------------------------------------
  // Get tenant by ID (filters archived)
  // ------------------------------------------------------------
  Future<TenantModel?> getTenant(String orgId, String tenantId) async {
    final snapshot =
    await _db.child("orgs/$orgId/Tenants/$tenantId").get();

    if (!snapshot.exists) return null;

    final map = Map<String, dynamic>.from(snapshot.value as Map);
    final model = TenantModel.fromMap(tenantId, map);

    if (model.isDeleted == true) return null;     // ⭐ new archive flag
    if (model.status == "archived") return null;  // ⭐ new status
    if (model.status == "deleted") return null;   // ⭐ backward compatibility

    return model;
  }

  // ------------------------------------------------------------
  // Get all tenants (filters archived)
  // ------------------------------------------------------------
  Future<List<TenantModel>> getAllTenants(String orgId) async {
    final snapshot = await _db.child("orgs/$orgId/Tenants").get();
    if (!snapshot.exists) return [];

    return snapshot.children
        .map((child) {
      final map = Map<String, dynamic>.from(child.value as Map);
      return TenantModel.fromMap(child.key!, map);
    })
        .where((t) =>
    t.isDeleted != true &&            // ⭐ new archive flag
        t.status != "archived" &&         // ⭐ new status
        t.status != "deleted")            // ⭐ backward compatibility
        .toList();
  }

  // ------------------------------------------------------------
  // Get tenants by a list of IDs (filters archived)
  // ------------------------------------------------------------
  Future<List<TenantModel>> getTenantsByIds(
      String orgId, List<String> tenantIds) async {
    if (tenantIds.isEmpty) return [];

    final List<TenantModel> results = [];

    for (final tenantId in tenantIds) {
      final snapshot =
      await _db.child("orgs/$orgId/Tenants/$tenantId").get();

      if (!snapshot.exists) continue;

      final map = Map<String, dynamic>.from(snapshot.value as Map);
      final model = TenantModel.fromMap(tenantId, map);

      if (model.isDeleted == true) continue;     // ⭐ new archive flag
      if (model.status == "archived") continue;  // ⭐ new status
      if (model.status == "deleted") continue;   // ⭐ backward compatibility

      results.add(model);
    }

    return results;
  }

  Future<void> updateTenant(TenantModel tenant) async {
    final ref = _db.child("orgs/${tenant.orgId}/Tenants/${tenant.tenantId}");

    await ref.update({
      ...tenant.toMap(),
      "tenantId": tenant.tenantId,
    });
  }

}
