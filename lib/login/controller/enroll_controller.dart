import 'package:flutter/foundation.dart';
import 'package:my_app/login/domain/re_user.dart';
import 'package:my_app/login/model/user_repository.dart';
import 'package:my_app/login/model/org_user_repository.dart';
import 'package:my_app/login/service/role_resolver.dart';
import 'package:my_app/session/app_data.dart';


class EnrollmentController extends ChangeNotifier {
  final UserRepository userRepo;
  final OrgUserRepository orgUserRepo;
  final RoleResolver roleResolver;
  final UserPreferencesRepository prefsRepo;
  final AppSession session;

  EnrollmentController({
    required this.userRepo,
    required this.orgUserRepo,
    required this.roleResolver,
    required this.prefsRepo,
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
      /*final String orgId = await orgUserRepo.createDefaultOrg(
        ownerUserId: reUser.userId,
        orgName: "${reUser.firstName}-${reUser.lastName}",
      );

      // createDefaultOrg() already:
      // - creates org
      // - assigns user as landlord
      // - writes orgUsers/<orgId>/<userId>
      // - writes userOrgs/<userId>/<orgId>

      // ------------------------------------------------------------
      // 3. Save defaultOrgId in UserPreferences
      // ------------------------------------------------------------
      await prefsRepo.setDefaultOrg(
        reUser.userId.toString(),
        orgId,
      );
*/
      // ------------------------------------------------------------
      // 4. Update session with user + org
      // ------------------------------------------------------------
      session.setUser(reUser);
  //    session.setActiveOrg(orgId);

      // ------------------------------------------------------------
      // 5. Resolve role using RoleResolver
      // ------------------------------------------------------------
     /* final String resolvedRole = await roleResolver.resolveRole(
        userId: reUser.userId.toString(),
        orgId: orgId,
      );

      session.setActiveRole(resolvedRole);*/

    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
