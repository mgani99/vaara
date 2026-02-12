import 'package:my_app/login/model/invitation_repository.dart';
import 'package:my_app/login/model/org_user_repository.dart';
import 'package:my_app/login/service/role_resolver.dart';
import 'package:my_app/property/model/unit_repository.dart';
import 'package:my_app/property/model/property_repository.dart';
import 'package:my_app/session/app_data.dart';
import 'package:my_app/session/user_role.dart';

class TenantInviteService {
  final AppSession session;
  final InvitationRepository inviteRepo;
  final OrgUserRepository orgUserRepo;
  final UnitRepository unitRepo;
  final PropertyRepository propertyRepo;
  final RoleResolver roleResolver;

  TenantInviteService({
    required this.session,
    required this.inviteRepo,
    required this.orgUserRepo,
    required this.unitRepo,
    required this.propertyRepo,
    required this.roleResolver
  });

  Future<String?> getOrgName(String orgId) async {
    return await orgUserRepo.getOrgName(orgId);
  }

  Future<String?> getPropertyName(String orgId, String propertyId) async {
    return await propertyRepo.getPropertyName(orgId, propertyId);
  }

  Future<String?> getUnitName(String orgId, String unitId) async {
    return await unitRepo.getUnitName(orgId, unitId);
  }

  Future<void> acceptInvitation({
    required String inviteId,
    required String orgId,
    required String propertyId,
    required String unitId,
    required String roleFromInvite,
  }) async {
    final userId = UserId.fromSession(session.userId).value;

    // 1. Add the role defined in the invitation
    await orgUserRepo.addUserToOrg(
      orgId: orgId,
      userId: userId,
      role: roleFromInvite,
    );

    // 2. Only tenants get assigned to units
    if (roleFromInvite == "tenant") {
      await unitRepo.assignTenantToUnit(
        orgId: orgId,
        unitId: unitId,
        tenantId: userId.toString(),
      );
    }

    // 3. Mark invite accepted
    await inviteRepo.markAccepted(inviteId);

    // 4. Resolve active role (user may now have multiple)
    final resolvedRole = await roleResolver.resolveRole(
      userId: userId.toString(),
      orgId: orgId,
    );

    // 5. Update session
    session.setActiveOrg(orgId);
    session.setActiveRole(resolvedRole);
  }


}
