import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/login/model/user_repository.dart';
import 'package:my_app/session/app_data.dart';

class LoginController extends ChangeNotifier {
  final FirebaseAuth _auth;
  final UserRepository userRepo;
  final AppSession session;

  LoginState state = LoginIdle();

  LoginController({
    required FirebaseAuth auth,
    required this.userRepo,
    required this.session,
  }) : _auth = auth;

  void reset() {
    state = LoginIdle();
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    state = LoginLoading();
    notifyListeners();

    try {
      // 1. Firebase login
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final firebaseUser = credential.user;

      if (firebaseUser == null) {
        state = LoginError("Authentication failed");
        notifyListeners();
        return;
      }

      // 2. Email must be verified
      if (!firebaseUser.emailVerified) {
        state = LoginEmailNotVerified();
        notifyListeners();
        return;
      }

      // 3. Load ReUser from DB
      final reUser = await userRepo.getByFirebaseUid(firebaseUser.uid);

      if (reUser == null) {
        state = LoginNotEnrolled();
        notifyListeners();
        return;
      }

      // 4. Update last login timestamp
      await userRepo.updateLastLogin(reUser.userId);

      // 5. Store full user in session
      session.setUser(id: reUser.userId.toString(), name: reUser.firstName, email: reUser.email);
     // session.setActiveOrg(reUser.defaultOrgId);   // if applicable
     // session.setActiveRole(UserRole.landlord);    // or resolved role


      // 6. Do NOT set activeOrg or activeRole here
      // SplashScreen will determine:
      // - invitations
      // - org memberships
      // - onboarding state

      state = LoginSuccess();
      notifyListeners();

    } on FirebaseAuthException catch (e) {
      state = LoginError(e.message ?? "Login failed");
      notifyListeners();
    }
  }
}

sealed class LoginState {
  const LoginState();
}

class LoginIdle extends LoginState {}

class LoginLoading extends LoginState {}

class LoginSuccess extends LoginState {}

class LoginEmailNotVerified extends LoginState {}

class LoginNotEnrolled extends LoginState {}

class LoginError extends LoginState {
  final String message;
  const LoginError(this.message);
}

