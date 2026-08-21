import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/login/domain/re_user.dart';
import 'package:my_app/login/model/user_repository.dart';
import 'package:my_app/login/model/org_user_repository.dart';
import 'package:my_app/property/model/contractor_repository.dart';
import 'package:my_app/login/service/role_resolver.dart';
import 'package:my_app/session/app_data.dart';


class AuthService {
  final FirebaseAuth _auth;
  final UserRepository userRepo;
  final OrgUserRepository orgUserRepo;
  final ContractorRepository contractorRepo;
  final RoleResolver roleResolver;
  final UserPreferencesRepository prefsRepo;
  final AppSession session;

  AuthService({
    required FirebaseAuth auth,
    required this.userRepo,
    required this.orgUserRepo,
    required this.contractorRepo,
    required this.roleResolver,
    required this.prefsRepo,
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
    await orgUserRepo.addRole(
      orgId,
      reUser.userId.toString(),
      role,
    );

    // 4. Save defaultOrgId in preferences
    await prefsRepo.setDefaultOrg(
      reUser.userId.toString(),
      orgId,
    );

    // 5. Update session
    session.setUser(reUser);

    session.setActiveOrg(orgId);

    // 6. Resolve role
    final resolvedRole = await roleResolver.resolveRole(
      orgId: orgId,
      userId: reUser.userId.toString(),
    );

    session.setActiveRole(resolvedRole);
  }

  // ------------------------------------------------------------
  // LOGIN (new flow)
  // ------------------------------------------------------------
  Future<void> login(String email, String password) async {
    // 1. Firebase login
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final firebaseUser = cred.user;
    if (firebaseUser == null) throw Exception("Authentication failed");

    if (!firebaseUser.emailVerified) {
      throw Exception("Email not verified");
    }

    // 2. Load ReUser
    final reUserMap = await userRepo.getByFirebaseUid(firebaseUser.uid);
    if (reUserMap == null) throw Exception("User not enrolled");

    final reUser = reUserMap;   // Already a ReUser


    // 3. Update last login
    await userRepo.updateLastLogin(reUser.userId);

    // 4. Store user in session
    session.setUser(reUser);

    // 5. Load preferences
    final prefs = await prefsRepo.getPreferences(reUser.userId.toString());

    // ------------------------------------------------------------
    // FAST PATH: Use defaultOrgId if valid
    // ------------------------------------------------------------
    if (prefs?.defaultOrgId != null) {
      final orgUser = await orgUserRepo.getOrgUser(
        prefs!.defaultOrgId!,
        reUser.userId.toString(),
      );

      if (orgUser != null) {
        final role = await roleResolver.resolveRole(
          orgId: prefs.defaultOrgId!,
          userId: reUser.userId.toString(),
        );

        session.setActiveOrg(prefs.defaultOrgId);
        session.setActiveRole(role);
        return;
      }
    }

    // ------------------------------------------------------------
    // FALLBACK: Choose best org + role
    // ------------------------------------------------------------
    final best = await roleResolver.chooseBestOrgAndRole(
      reUser.userId.toString(),
    );

    if (best != null) {
      session.setActiveOrg(best['orgId']);
      session.setActiveRole(best['role']);

      // Save preference for next login
      await prefsRepo.setDefaultOrg(
        reUser.userId.toString(),
        best['orgId']!,
      );
    } else {
      // No memberships → onboarding flow
      session.setActiveOrg(null);
      session.setActiveRole(null);
    }
  }

  // ------------------------------------------------------------
  // SIGN OUT
  // ------------------------------------------------------------
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      session.clear();
    } catch (e) {
      print("Error during signOut: $e");
      rethrow;
    }
  }
}
