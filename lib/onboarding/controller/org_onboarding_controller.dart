import 'package:flutter/material.dart';
import 'package:my_app/login/domain/orgUser.dart';

import 'package:my_app/login/domain/org_model.dart';
import 'package:my_app/login/service/org_service.dart';
import 'package:my_app/session/app_data.dart';
import 'package:my_app/session/user_role.dart';

class OnboardingCreateOrgController extends ChangeNotifier {
  final OrgService _service = OrgService();

  bool saving = false;

  Future<String> createOrg({
    required AppSession session,
    required String name,
    required String type,
  }) async {
    saving = true;
    notifyListeners();

    final org = OrgModel(
      orgId: "",
      name: name,
      type: type,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    final owner = OrgUserModel(
      userId: session.userId!,
      role: "landlord",
      ownershipPercent: 100,
    );

    final orgId = await _service.createOrg(org: org, owner: owner);

    // Update session
    session.setActiveOrg(orgId);
    session.setActiveRole(UserRole.landlord);

    saving = false;
    notifyListeners();

    return orgId;
  }
}
