import 'package:flutter/foundation.dart';
import 'package:my_app/onboarding/service/landlord_onboarding_service.dart';

class LandlordOnboardingController extends ChangeNotifier {
  final LandlordOnboardingService service;

  int step = 0;
  bool loading = false;

  String? propertyId;
  String? unitId;

  LandlordOnboardingController({required this.service});

  Future<void> nextStep({
    required String propertyName,
    required String propertyAddress,
    required String unitName,
    required double unitRent,
    required String tenantEmail,
    required String coOwnerEmail,
  }) async {
    loading = true;
    notifyListeners();

    try {
      if (step == 0) {
        propertyId = await service.createProperty(
          name: propertyName,
          address: propertyAddress,
          type: "single_family",
        );
      } else if (step == 1) {
        if (propertyId == null) {
          throw Exception("Property must be created before adding a unit.");
        }
        unitId = await service.createUnit(
          propertyId: propertyId!,
          name: unitName,
          bedrooms: 1,
          bathrooms: 2,
          type: "unit", // "unit", "studio", "parking", "garage"
        );

      } else if (step == 2 && tenantEmail.trim().isNotEmpty) {
        if (propertyId == null || unitId == null) {
          throw Exception("Property and unit must exist before inviting tenant.");
        }
        await service.inviteTenant(
          email: tenantEmail,
          propertyId: propertyId!,
          unitId: unitId!,
        );
      } else if (step == 3 && coOwnerEmail.trim().isNotEmpty) {
        await service.inviteCoOwner(email: coOwnerEmail);
      }

      step++;
      notifyListeners();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void previousStep() {
    if (step > 0) {
      step--;
      notifyListeners();
    }
  }

  bool get isLastStep => step >= 4;
}
