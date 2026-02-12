import 'package:flutter/material.dart';
import 'package:my_app/property/domain/unit_model.dart';
import 'package:my_app/property/service/unit_service.dart';
import 'package:my_app/session/app_data.dart';

class OnboardingAddUnitsController extends ChangeNotifier {
  final UnitService _service = UnitService();

  bool saving = false;
  final List<UnitModel> createdUnits = [];

  Future<void> addUnit({
    required AppSession session,
    required String propertyId,
    required String name,
    required int bedrooms,
    required int bathrooms,
    required double rentAmount,
  }) async {
    saving = true;
    notifyListeners();

    final unit = UnitModel(
      unitId: "",
      orgId: session.activeOrgId!,
      propertyId: propertyId,
      name: name,
      bedrooms: bedrooms,
      bathrooms: bathrooms,
      rentAmount: rentAmount,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    final unitId = await _service.createUnit(unit);

    createdUnits.add(
      unit.copyWith(unitId: unitId),
    );

    saving = false;
    notifyListeners();
  }
}

extension on UnitModel {
  UnitModel copyWith({
    String? unitId,
    String? name,
    int? bedrooms,
    int? bathrooms,
    double? rentAmount,
  }) {
    return UnitModel(
      unitId: unitId ?? this.unitId,
      orgId: orgId,
      propertyId: propertyId,
      name: name ?? this.name,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      rentAmount: rentAmount ?? this.rentAmount,
      createdAt: createdAt,
    );
  }
}
