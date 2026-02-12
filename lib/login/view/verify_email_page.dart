import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_app/login/controller/verify_email_controller.dart';
import 'package:my_app/route/route_constants.dart';

class VerifyEmailScreen extends StatelessWidget {
  final Map<String, dynamic> pending;

  const VerifyEmailScreen({
    super.key,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<VerifyEmailController>();
    final state = controller.state;

    // ------------------------------------------------------------
    // SUCCESS → Navigate to SplashScreen (not Home)
    // SplashScreen will:
    // - load ReUser
    // - detect invitations
    // - detect org membership
    // - route to RoleSelection or Home
    // ------------------------------------------------------------
    if (state is VerifyEmailVerified) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email verified! Completing setup...")),
        );

        Navigator.pushNamedAndRemoveUntil(
          context,
          splashRoute,
              (route) => false,
        );
      });
    }

    // ------------------------------------------------------------
    // ERROR MESSAGE
    // ------------------------------------------------------------
    if (state is VerifyEmailError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.message)),
        );
      });
    }

    final email = pending["email"] ?? "";

    return Scaffold(
      backgroundColor: Colors.lightBlue.shade50,
      appBar: AppBar(
        title: const Text("Verify Email"),
        backgroundColor: Colors.lightBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.mark_email_read,
                      size: 72,
                      color: Colors.lightBlue,
                    ),
                    const SizedBox(height: 16),

                    Text(
                      "A verification link has been sent to:",
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ------------------------------------------------------------
                    // CONTINUE BUTTON
                    // ------------------------------------------------------------
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: state is VerifyEmailChecking
                            ? null
                            : () => controller.completeEnrollment(context, pending),
                        child: state is VerifyEmailChecking
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Text("Continue"),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ------------------------------------------------------------
                    // RESEND EMAIL
                    // ------------------------------------------------------------
                    TextButton(
                      onPressed: () {
                        controller.resendEmail();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Verification email sent again"),
                          ),
                        );
                      },
                      child: const Text("Resend verification email"),
                    ),

                    // ------------------------------------------------------------
                    // NOT VERIFIED MESSAGE
                    // ------------------------------------------------------------
                    if (state is VerifyEmailNotVerified) ...[
                      const SizedBox(height: 12),
                      const Text(
                        "Email not verified yet. Please check your inbox.",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
