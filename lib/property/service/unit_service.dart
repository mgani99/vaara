import 'package:my_app/property/model/unit_repository.dart';
import 'package:my_app/session/app_data.dart';

import '../domain/property_model.dart';




class UnitService {
  final UnitRepository repo;
  final AppSession session;

  UnitService({
    required this.repo,
    required this.session,
  });


  Future<List<UnitModel>> getUnits(String orgId) {
    return repo.fetchUnits(orgId);
  }

  Future<List<UnitModel>> getUnitsForProperty(String orgId, String propertyId) async {
    final all = await repo.fetchUnits(orgId);
    return all.where((u) => u.propertyId == propertyId).toList();
  }

  Future<UnitModel> createUnit(String orgId, UnitModel unit) async {
    final id = await repo.createUnit(unit);

    final newUnit = unit.copyWith(unitId: id);

    await repo.updateUnitId(id, orgId);
    return newUnit;
  }


  Future<void> vacateUnit(UnitModel unit, LeaseDetailsModel lease) async {
    final orgId = session.activeOrgId!;

    // 1️⃣ End lease
    final endEpoch = DateTime.now().millisecondsSinceEpoch;
    await session.leaseRepo.updateLeaseField(
      orgId: orgId,
      leaseId: lease.leaseId,
      field: "endDateEpoch",
      value: endEpoch,
    );


    // 2️⃣ Clear tenants
    await session.leaseRepo.updateLeaseField(
      orgId: orgId,
      leaseId: lease.leaseId,
      field: "tenantIds",
      value: [],
    );


    // 3️⃣ Clear unit lease
    await repo.updateUnitField(
      orgId: orgId,
      unitId: unit.unitId,
      field: "currentLeaseId",
      value: null,
    );
    if (lease.tenantIds.isNotEmpty) {
      for (final tenantId in lease.tenantIds) {
        final ten = await session.tenantCache[tenantId];
        // Soft delete tenant
        await session.tenantRepo.updateTenant(
          ten!.copyWith(status: 'archived', isDeleted: true)
       );



        // Remove from cache
        session.tenantCache.remove(tenantId);
      }
    }
    // 4️⃣ Update cache (requires correct copyWith)
    final updatedLease = lease.copyWith(
      endDateEpoch: endEpoch,
      tenantIds: [],
    );
    session.updateLeaseInCache(updatedLease);

    final updatedUnit = unit.copyWith(currentLeaseId: null);
    session.updateUnitInCache(updatedUnit);
  }



  Future<void> updateUnit(String orgId, String unitId, {required int bedrooms, required double bathrooms, required String name, required String type}) async {}

  Future<void> deleteUnit(UnitModel unit) async {
    final orgId = session.activeOrgId!;
    await repo.updateUnitField(
      orgId: orgId,
      unitId: unit.unitId,
      field: "isDeleted",
      value: "true",
    );
    await repo.updateUnitField(
      orgId: orgId,
      unitId: unit.unitId,
      field: "status",
      value: "deleted",
    );

    session.unitCache.remove(unit.unitId);
    // Update cache
    //final updatedUnit = unit.copyWith(status: "deleted", isDeleted: true);
    //session.updateUnitInCache(updatedUnit);
    //session.updatePropertyInCache(session.propertyCache[unit.propertyId]!); // Update property cache if needed
    session.noifyListeners();
  }
}
