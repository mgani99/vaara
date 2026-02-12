import 'package:flutter/material.dart';
import 'package:my_app/login/controller/passord_reset_controller.dart';
import 'package:provider/provider.dart';



class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PasswordResetController>();
    final state = controller.state;

    if (state is PasswordResetSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password reset email sent.")),
        );
        Navigator.pop(context);
      });
    }

    if (state is PasswordResetError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.message)),
        );
      });
    }

    return Scaffold(
      backgroundColor: Colors.lightBlue.shade50,
      appBar: AppBar(
        title: const Text("Reset Password"),
        backgroundColor: Colors.lightBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text(
                    "Forgot Password?",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(
                      labelText: "Enter your email",
                    ),
                    validator: (v) =>
                    v == null || v.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: state is PasswordResetLoading
                          ? null
                          : () {
                        if (!_formKey.currentState!.validate()) return;
                        controller.sendResetEmail(_email.text.trim());
                      },
                      child: state is PasswordResetLoading
                          ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                          : const Text("Send Reset Email"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
