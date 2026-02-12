import 'package:my_app/login/model/org_user_repository.dart';
import 'package:my_app/login/service/role_resolver.dart';
import 'package:my_app/session/app_data.dart';

class OrgSwitcherService {
  final AppSession session;
  final OrgUserRepository orgUserRepo;
  final RoleResolver roleResolver;

  OrgSwitcherService({
    required this.session,
    required this.orgUserRepo,
    required this.roleResolver,
  });

  // ------------------------------------------------------------
  // Load all orgs the user belongs to
  // ------------------------------------------------------------
  Future<List<String>> loadUserOrgs() async {
    final userId = UserId.fromSession(session.userId).asInt;
    return orgUserRepo.getUserOrgs(userId);
  }

  // ------------------------------------------------------------
  // Switch active organization
  // ------------------------------------------------------------
  Future<void> switchOrg(String orgId) async {
    // 1. Update active org
    session.setActiveOrg(orgId);

    // 2. Resolve correct role for this org
    final resolvedRole = await roleResolver.resolveRole(
      userId: session.userId!,
      orgId: orgId,
    );

    // 3. Update session role
    session.setActiveRole(resolvedRole);
  }
}
