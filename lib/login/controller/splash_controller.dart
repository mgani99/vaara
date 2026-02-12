import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/login/model/invitation_repository.dart';
import 'package:my_app/login/model/org_user_repository.dart';
import 'package:my_app/login/model/user_repository.dart';
import 'package:my_app/login/service/role_resolver.dart';
import 'package:my_app/session/app_data.dart';
import 'package:my_app/session/user_role.dart';

class SplashController {
  final UserRepository userRepo;
  final OrgUserRepository orgUserRepo;
  final InvitationRepository invitationRepo;
  final RoleResolver roleResolver;
  final AppSession session;

  SplashController({
    required this.userRepo,
    required this.orgUserRepo,
    required this.invitationRepo,
    required this.roleResolver,
    required this.session,
  });

  // ------------------------------------------------------------
  // MAIN ENTRY POINT
  // ------------------------------------------------------------
  Future<SplashResult> handleStartup() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    // ------------------------------------------------------------
    // 0. No Firebase user → go to login
    // ------------------------------------------------------------
    if (firebaseUser == null) {
      session.clear();
      return SplashResult.goToLogin();
    }

    // ------------------------------------------------------------
    // 1. Load ReUser
    // ------------------------------------------------------------
    final reUser = await userRepo.getUserByFirebaseUid(firebaseUser.uid);
    if (reUser == null) {
      session.clear();
      return SplashResult.goToLogin();
    }

    // Store userId in session
    session.setUser(id: reUser.userId.toString(), name: reUser.firstName, email: reUser.email);

    // ------------------------------------------------------------
    // 2. Check for invitations
    // ------------------------------------------------------------
    final invites = await invitationRepo.getInvitationsForEmail(reUser.email);

    if (invites.isNotEmpty) {
      await _applyInvitations(reUser.userId, invites);

      // After applying invitations, user now belongs to org(s)
      final orgs = await orgUserRepo.getUserOrgs(reUser.userId);
      session.setOrgMemberships(orgs);

      // Pick first org as active
      final activeOrg = orgs.first;
      session.setActiveOrg(activeOrg);

      // Resolve role
      final role = await roleResolver.resolveRole(
        userId: reUser.userId.toString(),
        orgId: activeOrg,
      );
      session.setActiveRole(role);

      return SplashResult.goToHome();
    }

    // ------------------------------------------------------------
    // 3. Check if user belongs to any org
    // ------------------------------------------------------------
    final userOrgs = await orgUserRepo.getUserOrgs(reUser.userId);

    if (userOrgs.isNotEmpty) {
      session.setOrgMemberships(userOrgs);

      final activeOrg = userOrgs.first;
      session.setActiveOrg(activeOrg);

      final role = await roleResolver.resolveRole(
        userId: reUser.userId.toString(),
        orgId: activeOrg,
      );
      session.setActiveRole(role);

      return SplashResult.goToHome();
    }

    // ------------------------------------------------------------
    // 4. No orgs + no invitations → first-time user
    // ------------------------------------------------------------
    if (!reUser.onboardingCompleted) {
      return SplashResult.goToRoleSelection();
    }

    // ------------------------------------------------------------
    // 5. Safety fallback
    // ------------------------------------------------------------
    return SplashResult.goToHome();
  }

  // ------------------------------------------------------------
  // Apply invitations (landlord, tenant, contractor)
  // ------------------------------------------------------------
  Future<void> _applyInvitations(
      int userId,
      List<Map<String, dynamic>> invites,
      ) async {
    for (final invite in invites) {
      final orgId = invite["orgId"];
      final role = invite["role"];

      await orgUserRepo.applyInvitation(
        orgId: orgId,
        userId: userId,
        role: role,
      );

      await invitationRepo.markAccepted(invite["inviteId"]);
    }
  }
}

// ------------------------------------------------------------
// Splash Result Routing Enum
// ------------------------------------------------------------
class SplashResult {
  final String route;

  SplashResult._(this.route);

  static SplashResult goToLogin() => SplashResult._("login");
  static SplashResult goToHome() => SplashResult._("home");
  static SplashResult goToRoleSelection() => SplashResult._("roleSelection");
}
