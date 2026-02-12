import 'package:flutter/material.dart';
import 'package:my_app/login/domain/orgUser.dart';
import 'package:my_app/login/domain/re_user.dart';
import 'package:my_app/login/model/org_user_repository.dart';
import 'package:my_app/login/service/auth_service.dart';
import 'package:my_app/profile/service/profile_service.dart';

import '../../route/route_constants.dart';

class ProfileController extends ChangeNotifier {
  final ProfileService profileService;
  final OrgUserRepository orgUserRepo;
  final AuthService authService;

  ReUser? currentUser;
  String? currentOrgId;
  List<OrgUser> linkedUsers = [];

  ProfileController({
    required this.profileService,
    required this.orgUserRepo,
    required this.authService,
  });

  // ------------------------------------------------------------
  // LOAD CURRENT USER + ORG + ROLES
  // ------------------------------------------------------------
  Future<void> loadUser(int userId, String firebaseUid, String orgId) async {
    currentUser = await profileService.getUser(userId);
    linkedUsers = await orgUserRepo.getOrgUsersForUser(
      orgId: orgId,
      userId: userId,
    );
    notifyListeners();
  }

  Future<void> updateUser(ReUser user) async {
    await profileService.updateUser(user);
    currentUser = user;
    notifyListeners();
  }

  // ------------------------------------------------------------
  // LOAD ONLY ORG ROLES FOR THIS USER
  // ------------------------------------------------------------
  Future<List<OrgUser>> loadLinkedUsers() async {
    if (currentUser == null || currentOrgId == null) return [];

    linkedUsers = await orgUserRepo.getOrgUsersForUser(
      orgId: currentOrgId!,
      userId: currentUser!.userId,
    );

    return linkedUsers;
  }

  // ------------------------------------------------------------
  // SWITCH ROLE (OrgUser.isDefaultRole)
  // ------------------------------------------------------------
  Future<void> switchRole(OrgUser selected) async {
    if (currentUser == null || currentOrgId == null) return;

    // Update the single OrgUser record for this user in this org
    final updated = selected.copyWith(
      isDefaultRole: true,
    );

    await orgUserRepo.updateOrgUser(updated);

    // Refresh local state
    linkedUsers = await loadLinkedUsers();
    notifyListeners();
  }


  // ------------------------------------------------------------
  // SIGN OUT
  // ------------------------------------------------------------
  Future<void> signOut(BuildContext context) async {
    await authService.signOut();

    currentUser = null;
    linkedUsers = [];
    currentOrgId = null;

    notifyListeners();

    Navigator.pushNamedAndRemoveUntil(
      context,
      logInScreenRoute,
          (route) => false,
    );
  }
}


