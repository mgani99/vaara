import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/login/model/org_user_repository.dart';
import 'package:my_app/login/model/user_repository.dart';
import 'package:my_app/property/model/contractor_repository.dart';
import 'package:my_app/login/service/role_resolver.dart';
import 'package:my_app/session/app_data.dart';
import 'package:my_app/session/user_role.dart';

class AuthService {
  final FirebaseAuth _auth;
  final UserRepository userRepo;
  final OrgUserRepository orgUserRepo;
  final ContractorRepository contractorRepo;
  final RoleResolver roleResolver;
  final AppSession session;

  AuthService({
    required FirebaseAuth auth,
    required this.userRepo,
    required this.orgUserRepo,
    required this.contractorRepo,
    required this.roleResolver,
    required this.session,
  }) : _auth = auth;

  // ------------------------------------------------------------
  // LOGOUT
  // ------------------------------------------------------------
  Future<void> logout() async {
    await _auth.signOut();
    session.clear();
  }

  // ------------------------------------------------------------
  // PASSWORD RESET
  // ------------------------------------------------------------
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ------------------------------------------------------------
  // ENROLL + LOGIN (legacy flow)
  // ------------------------------------------------------------
  Future<void> enrollAndLogin({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required String orgId,
    required String role,
  }) async {
    // 1. Create Firebase user
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final firebaseUser = cred.user;
    if (firebaseUser == null) {
      throw Exception("User not created");
    }

    // 2. Create ReUser in DB
    final reUser = await userRepo.createUser(
      email: email,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      firebaseUid: firebaseUser.uid,
    );

    // 3. Add user to org with role
    await orgUserRepo.addUserToOrg(
      orgId: orgId,
      userId: reUser.userId,
      role: role,
    );

    // 4. Update session with new user
    session.setUser(id: reUser.userId.toString(), name: reUser.firstName, email: reUser.email);
    session.setActiveOrg(orgId);

    // 5. Resolve the user's role
    final resolvedRole = await roleResolver.resolveRole(
      userId: reUser.userId.toString(),
      orgId: orgId,
    );

    session.setActiveRole(resolvedRole);
  }
}
