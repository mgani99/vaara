

import 'dart:io';

import 'package:my_app/login/model/invitation_repository.dart';
import 'package:my_app/property/model/tenant_repository.dart';
import 'package:my_app/services/storage_upload_service.dart';

import '../domain/property_model.dart';

class TenantService {
  final TenantRepository repo;
  final InvitationRepository inviteRepo;
  final StorageUploadService storage;

  TenantService({
    required this.repo,
    required this.inviteRepo,
    required this.storage,
  });

// ------------------------------------------------------------
// CREATE TENANT
// ------------------------------------------------------------
  Future<String> createTenant(TenantModel tenant) {
    return repo.createTenant(tenant);
  }

// ------------------------------------------------------------
// GET TENANT
// ------------------------------------------------------------
  Future<TenantModel?> getTenant(String orgId, String tenantId) {
    return repo.getTenant(orgId, tenantId);
  }

  Future<List<TenantModel>> getAllTenants(String orgId) {
    return repo.getAllTenants(orgId);
  }

// ------------------------------------------------------------
// UPDATE TENANT (contact + financial + DL image)
// ------------------------------------------------------------
  Future<void> updateTenant(TenantModel tenant) {
    return repo.updateTenant(tenant);
  }

// ------------------------------------------------------------
// UPDATE FINANCIAL INFO
// ------------------------------------------------------------
  Future<void> updateFinancialInfo({
    required TenantModel tenant,
    required String bankName,
    required String accountNumber,
    required String zelleId,
  }) {
    final updated = tenant.copyWith(
      bankName: bankName,
      accountNumber: accountNumber,
      zelleId: zelleId,
    );

    return repo.updateTenant(updated);
  }

  Future<String> uploadDLImage({
    required String orgId,
    required String tenantId,
    required File file,
  }) {
    return storage.uploadFile(
      file: file,
      path: "orgs/$orgId/tenants/$tenantId/dl_image.jpg",
    );
  }

  Future<void> updateDLImage(TenantModel tenant, String dlImageUrl) {
    final updated = tenant.copyWith(dlImageUrl: dlImageUrl);
    return repo.updateTenant(updated);
  }


// ------------------------------------------------------------
// SOFT DELETE TENANT
// ------------------------------------------------------------
  Future<void> softDeleteTenant(TenantModel tenant) {
    final updated = tenant.copyWith(
      isDeleted: true,
      status: "deleted",
      deletedAt: DateTime.now().toIso8601String(),
    );

    return repo.updateTenant(updated);
  }

// ------------------------------------------------------------
// RESTORE TENANT
// ------------------------------------------------------------
  Future<void> restoreTenant(TenantModel tenant) {
    final updated = tenant.copyWith(
      isDeleted: false,
      status: "active",
      deletedAt: null,
    );

    return repo.updateTenant(updated);
  }
}
