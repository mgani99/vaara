import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'package:my_app/route/route_constants.dart';
import 'package:my_app/session/app_data.dart';

class EnrollmentScreen extends StatefulWidget {
  const EnrollmentScreen({super.key});

  @override
  State<EnrollmentScreen> createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends State<EnrollmentScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue.shade50,
      appBar: AppBar(
        title: const Text("Enroll"),
        backgroundColor: Colors.lightBlue,

        // ⭐ NEW: Back button to Login screen
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            final session = context.read<AppSession>();
            session.clear(); // optional but recommended

            Navigator.pushNamedAndRemoveUntil(
              context,
              logInScreenRoute,
                  (route) => false,
            );
          },
        ),
      ),

      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Create Your Account",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // First Name
                          TextFormField(
                            controller: _firstName,
                            decoration: const InputDecoration(
                              labelText: "First name",
                            ),
                            validator: (v) =>
                            v == null || v.isEmpty ? "Required" : null,
                          ),
                          const SizedBox(height: 12),

                          // Last Name
                          TextFormField(
                            controller: _lastName,
                            decoration: const InputDecoration(
                              labelText: "Last name",
                            ),
                            validator: (v) =>
                            v == null || v.isEmpty ? "Required" : null,
                          ),
                          const SizedBox(height: 12),

                          // Email
                          TextFormField(
                            controller: _email,
                            decoration: const InputDecoration(
                              labelText: "Email",
                            ),
                            validator: (v) =>
                            v == null || v.isEmpty ? "Required" : null,
                          ),
                          const SizedBox(height: 12),

                          // Phone
                          TextFormField(
                            controller: _phone,
                            decoration: const InputDecoration(
                              labelText: "Phone",
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Password
                          TextFormField(
                            controller: _password,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: "Password",
                            ),
                            validator: (v) =>
                            v == null || v.length < 6
                                ? "Minimum 6 characters"
                                : null,
                          ),
                          const SizedBox(height: 24),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: FilledButton(
                              onPressed:
                              _loading ? null : () => _handleEnrollment(),
                              child: _loading
                                  ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                                  : const Text("Create Account"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Loading overlay
          if (_loading)
            const ColoredBox(
              color: Colors.black26,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // Handle Enrollment
  // ------------------------------------------------------------
  Future<void> _handleEnrollment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final auth = FirebaseAuth.instance;

      final pending = {
        "firstName": _firstName.text.trim(),
        "lastName": _lastName.text.trim(),
        "phone": _phone.text.trim(),
        "email": _email.text.trim(),
      };

      // Create Firebase user
      final cred = await auth.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );

      final firebaseUser = cred.user;
      if (firebaseUser == null) {
        throw Exception("User creation failed");
      }

      // Send verification email
      await firebaseUser.sendEmailVerification();

      // Navigate to VerifyEmailScreen
      Navigator.pushReplacementNamed(
        context,
        verifyEmailRoute,
        arguments: pending,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _loading = false);
    }
  }
}
