import 'package:firebase_database/firebase_database.dart';
import 'package:my_app/property/domain/unit_model.dart';
import 'package:my_app/property/model/unit_repository.dart';




class UnitService {
  final UnitRepository repo = UnitRepository();

  Future<List<UnitModel>> getUnits(String orgId) {
    return repo.fetchUnits(orgId);
  }

  Future<List<UnitModel>> getUnitsForProperty(String orgId, String propertyId) async {
    final all = await repo.fetchUnits(orgId);
    return all.where((u) => u.propertyId == propertyId).toList();
  }

  Future<String> createUnit(UnitModel unit) {
    return repo.createUnit(unit);
  }
}
