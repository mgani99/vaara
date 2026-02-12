import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
class PasswordResetController extends ChangeNotifier {
  final FirebaseAuth _auth;

  PasswordResetState state = const PasswordResetIdle();

  PasswordResetController(this._auth);

  Future<void> sendResetEmail(String email) async {
    state = const PasswordResetLoading();
    notifyListeners();

    try {
      await _auth.sendPasswordResetEmail(email: email.trim());

      state = const PasswordResetSuccess();
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      state = PasswordResetError(e.message ?? "Unable to send reset email");
      notifyListeners();
    } catch (e) {
      state = PasswordResetError(e.toString());
      notifyListeners();
    }
  }

  void resetState() {
    state = const PasswordResetIdle();
    notifyListeners();
  }
}
sealed class PasswordResetState {
  const PasswordResetState();
}

class PasswordResetIdle extends PasswordResetState {
  const PasswordResetIdle();
}

class PasswordResetLoading extends PasswordResetState {
  const PasswordResetLoading();
}

class PasswordResetSuccess extends PasswordResetState {
  const PasswordResetSuccess();
}

class PasswordResetError extends PasswordResetState {
  final String message;
  const PasswordResetError(this.message);
}

