

import 'package:my_app/property/domain/tenant_model.dart';
import 'package:my_app/property/model/tenant_repository.dart';

class TenantService {
  final TenantRepository repo;

  TenantService({required this.repo});

  Future<void> createTenant(TenantModel tenant) {
    return repo.createTenant(tenant);
  }

  Future<TenantModel?> getTenant(String orgId, String tenantId) {
    return repo.getTenant(orgId, tenantId);
  }

  Future<List<TenantModel>> getAllTenants(String orgId) {
    return repo.getAllTenants(orgId);
  }
}
