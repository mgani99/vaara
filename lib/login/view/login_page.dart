import 'package:flutter/material.dart';
import 'package:my_app/login/controller/login_controller.dart';
import 'package:my_app/route/route_constants.dart';
import 'package:provider/provider.dart';



class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LoginController>().reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LoginController>();
    final state = controller.state;

    _loading = state is LoginLoading;

    if (state is LoginSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, homeRoute);
      });
    }

    if (state is LoginEmailNotVerified) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please verify your email.")),
        );
      });
    }

    if (state is LoginNotEnrolled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("User authenticated but not enrolled. Enrol now.")),
        );
        Navigator.pushReplacementNamed(context, enrollmentRoute);
      });
    }

    if (state is LoginError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.message)),
        );
      });
    }

    return Scaffold(
      backgroundColor: Colors.lightBlue.shade50,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Rental.AI",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.lightBlue,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _email,
                            decoration: const InputDecoration(
                              labelText: "Email",
                            ),
                            validator: (v) =>
                            v == null || v.isEmpty ? "Required" : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _password,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: "Password",
                            ),
                            validator: (v) =>
                            v == null || v.isEmpty ? "Required" : null,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: FilledButton(
                              onPressed: _loading
                                  ? null
                                  : () {
                                if (!_formKey.currentState!.validate()) {
                                  return;
                                }
                                controller.login(
                                  _email.text.trim(),
                                  _password.text.trim(),
                                );
                              },
                              child: const Text("Login"),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                  context, passwordResetRoute);
                            },
                            child: const Text("Forgot password?"),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(
                                  context, enrollmentRoute);
                            },
                            child: const Text("Enrol"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_loading)
              const ColoredBox(
                color: Colors.black26,
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
