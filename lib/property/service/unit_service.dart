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


  Future<void> updateUnit(String orgId, String unitId, {required int bedrooms, required double bathrooms, required String name, required String type}) async {}
}
