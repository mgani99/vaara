import 'package:flutter/foundation.dart';
import 'package:my_app/login/domain/re_user.dart';
import 'package:my_app/login/model/user_repository.dart';
import 'package:my_app/login/model/org_user_repository.dart';
import 'package:my_app/login/service/role_resolver.dart';
import 'package:my_app/session/app_data.dart';
import 'package:my_app/session/user_role.dart';

class EnrollmentController extends ChangeNotifier {
  final UserRepository userRepo;
  final OrgUserRepository orgUserRepo;
  final RoleResolver roleResolver;
  final AppSession session;

  EnrollmentController({
    required this.userRepo,
    required this.orgUserRepo,
    required this.roleResolver,
    required this.session,
  });

  bool _loading = false;
  bool get loading => _loading;

  Future<void> enroll({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String firebaseUid,
  }) async {
    _setLoading(true);

    try {
      // ------------------------------------------------------------
      // 1. Create ReUser in DB
      // ------------------------------------------------------------
      final ReUser reUser = await userRepo.createUser(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        firebaseUid: firebaseUid,
      );

      // ------------------------------------------------------------
      // 2. Create default org for new landlord
      // ------------------------------------------------------------
      final String orgId = await orgUserRepo.createDefaultOrg(
        ownerUserId: reUser.userId,
        orgName: "${reUser.firstName} ${reUser.lastName}'s Organization",
      );

      // NOTE:
      // createDefaultOrg() already:
      // - creates the org
      // - assigns the user as landlord
      // - writes orgUsers/<orgId>/<userId>
      // - writes userOrgs/<userId>/<orgId>

      // ------------------------------------------------------------
      // 3. Update session with user + org
      // ------------------------------------------------------------
      session.setUser(id: reUser.userId.toString(), name: reUser.firstName, email: reUser.email);
      session.setActiveOrg(orgId);
      session.setOrgMemberships([orgId]);

      // ------------------------------------------------------------
      // 4. Resolve role using RoleResolver
      // ------------------------------------------------------------
      final UserRole resolvedRole = await roleResolver.resolveRole(
        userId: reUser.userId.toString(),
        orgId: orgId,
      );

      session.setActiveRole(resolvedRole);

    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
