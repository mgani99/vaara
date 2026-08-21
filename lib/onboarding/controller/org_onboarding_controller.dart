import 'package:flutter/material.dart';
import 'package:my_app/login/model/org_user_repository.dart';
import 'package:my_app/login/model/user_repository.dart';
import 'package:my_app/session/app_data.dart';


class OnboardingCreateOrgController extends ChangeNotifier {
  final OrgUserRepository orgUserRepo;
  final UserPreferencesRepository prefsRepo;

  OnboardingCreateOrgController({
    required this.orgUserRepo,
    required this.prefsRepo,
  });

  bool saving = false;

  Future<String> createOrg({
    required AppSession session,
    required String name,
    required String type, // still accepted if UI uses it
  }) async {
    saving = true;
    notifyListeners();

    final userId = session.user!.userId;

    // ------------------------------------------------------------
    // 1. Create new org using the new unique-name generator
    // ------------------------------------------------------------
    final orgId = await orgUserRepo.createDefaultOrg(
      ownerUserId: userId,
      orgName: session.user!.firstName.toLowerCase(),
    );

    // ------------------------------------------------------------
    // 2. Save default org in preferences
    // ------------------------------------------------------------
    await prefsRepo.setDefaultOrg(
      userId.toString(),
      orgId,
    );

    // ------------------------------------------------------------
    // 3. Update session
    // ------------------------------------------------------------
    session.setActiveOrg(orgId);
    session.setActiveRole("landlord"); // string role

    saving = false;
    notifyListeners();

    return orgId;
  }
}
