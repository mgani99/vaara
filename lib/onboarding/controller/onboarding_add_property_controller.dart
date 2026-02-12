import 'package:flutter/material.dart';
import 'package:my_app/property/service/property_service.dart';

import 'package:my_app/session/app_data.dart';

import '../../property/domain/property_model.dart';

class OnboardingAddPropertyController extends ChangeNotifier {
  final PropertyService _service = PropertyService();

  bool saving = false;

  Future<String> addProperty({
    required AppSession session,
    required String name,
    required String address,
    required String type,
  }) async {
    saving = true;
    notifyListeners();

    final property = PropertyModel(
      propertyId: "",
      orgId: session.activeOrgId!,
      name: name,
      address: address,
      type: type,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    final propertyId = await _service.createProperty(property);

    saving = false;
    notifyListeners();

    return propertyId;
  }
}
