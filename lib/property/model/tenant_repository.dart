import 'package:firebase_database/firebase_database.dart';
import 'package:my_app/property/domain/tenant_model.dart';


class TenantRepository {
  final _db = FirebaseDatabase.instance.ref();

  Future<void> createTenant(TenantModel tenant) async {
    await _db
        .child("Orgs/${tenant.orgId}/Tenants/${tenant.tenantId}")
        .set(tenant.toMap());
  }

  Future<TenantModel?> getTenant(String orgId, String tenantId) async {
    final snapshot =
    await _db.child("Orgs/$orgId/Tenants/$tenantId").get();

    if (!snapshot.exists) return null;

    final map = Map<String, dynamic>.from(snapshot.value as Map);
    return TenantModel.fromMap(tenantId, map);
  }

  Future<List<TenantModel>> getAllTenants(String orgId) async {
    final snapshot = await _db.child("Orgs/$orgId/Tenants").get();
    if (!snapshot.exists) return [];

    return snapshot.children.map((child) {
      final map = Map<String, dynamic>.from(child.value as Map);
      return TenantModel.fromMap(child.key!, map);
    }).toList();
  }
}
