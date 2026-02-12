import 'package:flutter/material.dart';


class OnboardingRoleController extends ChangeNotifier {
  OnboardingRoleChoice? choice;

  void select(OnboardingRoleChoice value) {
    choice = value;
    notifyListeners();
  }

  String nextRoute() {
    switch (choice) {
      case OnboardingRoleChoice.landlord:
        return "/onboardingCreateOrg";
      case OnboardingRoleChoice.tenant:
        return "/tenantInviteCheck";
      case OnboardingRoleChoice.contractor:
        return "/contractorOnboarding";
      default:
        return "/home";
    }
  }
}

enum OnboardingRoleChoice {
  landlord,
  tenant,
  contractor,
  none,
}

extension OnboardingRoleChoiceX on OnboardingRoleChoice {
  // ------------------------------------------------------------
  // Convert enum → string (for Firebase or logs)
  // ------------------------------------------------------------
  String get asString {
    switch (this) {
      case OnboardingRoleChoice.landlord:
        return "landlord";
      case OnboardingRoleChoice.tenant:
        return "tenant";
      case OnboardingRoleChoice.contractor:
        return "contractor";
      case OnboardingRoleChoice.none:
        return "none";
    }
  }

  // ------------------------------------------------------------
  // Human‑readable label for UI
  // ------------------------------------------------------------
  String get label {
    switch (this) {
      case OnboardingRoleChoice.landlord:
        return "Landlord";
      case OnboardingRoleChoice.tenant:
        return "Tenant";
      case OnboardingRoleChoice.contractor:
        return "Contractor";
      case OnboardingRoleChoice.none:
        return "None";
    }
  }

  // ------------------------------------------------------------
  // Next route in onboarding flow
  // ------------------------------------------------------------
  String get nextRoute {
    switch (this) {
      case OnboardingRoleChoice.landlord:
        return "/onboardingCreateOrg";
      case OnboardingRoleChoice.tenant:
        return "/tenantInviteCheck";
      case OnboardingRoleChoice.contractor:
        return "/contractorOnboarding";
      case OnboardingRoleChoice.none:
        return "/home";
    }
  }

  // ------------------------------------------------------------
  // Parse string → enum (safe)
  // ------------------------------------------------------------
  static OnboardingRoleChoice fromString(String? value) {
    switch (value?.toLowerCase()) {
      case "landlord":
        return OnboardingRoleChoice.landlord;
      case "tenant":
        return OnboardingRoleChoice.tenant;
      case "contractor":
        return OnboardingRoleChoice.contractor;
      default:
        return OnboardingRoleChoice.none;
    }
  }
}

