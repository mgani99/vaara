import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/login/domain/re_user.dart';
import 'package:my_app/login/model/invitation_repository.dart';
import 'package:my_app/login/model/org_user_repository.dart';
import 'package:my_app/login/model/user_repository.dart';
import 'package:my_app/login/service/role_resolver.dart';
import 'package:my_app/session/app_data.dart';


class SplashController {
  final UserRepository userRepo;
  final OrgUserRepository orgUserRepo;
  final InvitationRepository invitationRepo;
  final RoleResolver roleResolver;
  final UserPreferencesRepository prefsRepo;
  final AppSession session;

  SplashController({
    required this.userRepo,
    required this.orgUserRepo,
    required this.invitationRepo,
    required this.roleResolver,
    required this.prefsRepo,
    required this.session,
  });

  // ------------------------------------------------------------
  // MAIN ENTRY POINT
  // ------------------------------------------------------------
  Future<SplashResult> handleStartup() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    // 0. No Firebase user → go to login
    if (firebaseUser == null) {
      session.clear();
      return SplashResult.goToLogin();
    }

    // 1. Load ReUser
    final reUserMap = await userRepo.getUserByFirebaseUid(firebaseUser.uid);
    if (reUserMap == null) {
      session.clear();
      return SplashResult.goToLogin();
    }

    final reUser = reUserMap;

    session.setUser(reUser);

    // 2. Check for invitations
    final invites = await invitationRepo.getInvitationsForEmail(reUser.email);

    if (invites.isNotEmpty) {
      await _applyInvitations(reUser.userId, invites);

      // After applying invitations, resolve org + role
      await _resolveOrgAndRole(reUser);

      return SplashResult.goToHome();
    }

    // 3. Check if user belongs to any org
    final memberships =
    await orgUserRepo.getMembershipsForUser(reUser.userId.toString());

    if (memberships.isNotEmpty) {
      await _resolveOrgAndRole(reUser);
      return SplashResult.goToHome();
    }

    // 4. No orgs + no invitations → first-time user
    if (!reUser.onboardingCompleted) {
      return SplashResult.goToRoleSelection();
    }

    // 5. Safety fallback
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

      // Add role to OrgUser (multi-role model)
      await orgUserRepo.addRole(
        orgId,
        userId.toString(),
        role,
      );

      await invitationRepo.markAccepted(invite["inviteId"]);
    }
  }

  // ------------------------------------------------------------
  // Resolve active org + role using preferences + resolver
  // ------------------------------------------------------------
  Future<void> _resolveOrgAndRole(ReUser reUser) async {
    final userId = reUser.userId.toString();

    // 1. Try defaultOrgId from preferences
    final prefs = await prefsRepo.getPreferences(userId);

    if (prefs?.defaultOrgId != null) {
      final orgUser =
      await orgUserRepo.getOrgUser(prefs!.defaultOrgId!, userId);

      if (orgUser != null) {
        final role = await roleResolver.resolveRole(
          orgId: prefs.defaultOrgId!,
          userId: userId,
        );

        session.setActiveOrg(prefs.defaultOrgId);
        session.setActiveRole(role);
        return;
      }
    }

    // 2. Fallback: choose best org + role
    final best = await roleResolver.chooseBestOrgAndRole(userId);

    if (best != null) {
      session.setActiveOrg(best['orgId']);
      session.setActiveRole(best['role']);

      // Save preference for next login
      await prefsRepo.setDefaultOrg(userId, best['orgId']!);
    } else {
      // No orgs → leave null
      session.setActiveOrg(null);
      session.setActiveRole(null);
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
