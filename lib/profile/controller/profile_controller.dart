import 'package:flutter/material.dart';
import 'package:my_app/login/domain/orgUser.dart';
import 'package:my_app/login/domain/re_user.dart';
import 'package:my_app/login/model/org_user_repository.dart';
import 'package:my_app/login/service/auth_service.dart';
import 'package:my_app/profile/service/profile_service.dart';


class ProfileController extends ChangeNotifier {
  final ProfileService profileService;
  final OrgUserRepository orgUserRepo;
  final AuthService authService;

  ReUser? currentUser;

  ProfileController({
    required this.profileService,
    required this.orgUserRepo,
    required this.authService,
  });

  // LOAD USER (safe)
  Future<void> loadUser(int userId) async {
    currentUser = await profileService.getUser(userId);
    notifyListeners();
  }

  Future<void> updateUser(ReUser user) async {
    await profileService.updateUser(user);
    currentUser = user;
    notifyListeners();
  }

  // LOAD ORG USER (safe)
  Future<OrgUser?> loadActiveOrgUser() async {
    if (currentUser == null) return null;

    final session = authService.session;
    final orgId = session.activeOrgId;
    if (orgId == null) return null;

    return await orgUserRepo.getOrgUser(
      orgId,
      currentUser!.userId.toString(),
    );
  }

  // CLEAN LOGOUT — NO notifyListeners, NO context
  Future<bool> signOut() async {
    await authService.signOut();

    return true;
  }
}
