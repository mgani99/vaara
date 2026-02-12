import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/login/controller/enroll_controller.dart';
import 'package:provider/provider.dart';


sealed class VerifyEmailState {
  const VerifyEmailState();
}

class VerifyEmailIdle extends VerifyEmailState {
  const VerifyEmailIdle();
}

class VerifyEmailChecking extends VerifyEmailState {
  const VerifyEmailChecking();
}

class VerifyEmailVerified extends VerifyEmailState {
  const VerifyEmailVerified();
}

class VerifyEmailNotVerified extends VerifyEmailState {
  const VerifyEmailNotVerified();
}

class VerifyEmailError extends VerifyEmailState {
  final String message;
  const VerifyEmailError(this.message);
}

class VerifyEmailController extends ChangeNotifier {
  final FirebaseAuth _auth;

  VerifyEmailState state = const VerifyEmailIdle();

  VerifyEmailController({
    required FirebaseAuth auth,
  }) : _auth = auth;

  // ------------------------------------------------------------
  // Resend verification email
  // ------------------------------------------------------------
  Future<void> resendEmail() async {
    final user = _auth.currentUser;
    await user?.sendEmailVerification();
  }

  // ------------------------------------------------------------
  // Complete enrollment after email verification
  // ------------------------------------------------------------
  Future<void> completeEnrollment(
      BuildContext context,
      Map<String, dynamic> pending,
      ) async {
    state = const VerifyEmailChecking();
    notifyListeners();

    try {
      // 1. Refresh Firebase user
      final user = _auth.currentUser;
      await user?.reload();
      final refreshed = _auth.currentUser;

      if (refreshed == null) {
        state = const VerifyEmailError("User session expired");
        notifyListeners();
        return;
      }

      // 2. Check verification
      if (!refreshed.emailVerified) {
        state = const VerifyEmailNotVerified();
        notifyListeners();
        return;
      }

      // 3. Create ReUser in DB
      final enrollment = context.read<EnrollmentController>();

      await enrollment.enroll(
        firstName: pending["firstName"],
        lastName: pending["lastName"],
        email: pending["email"],
        phone: pending["phone"],
        firebaseUid: refreshed.uid,
      );

      // 4. Mark success
      state = const VerifyEmailVerified();
      notifyListeners();

    } catch (e) {
      state = VerifyEmailError(e.toString());
      notifyListeners();
    }
  }
}
