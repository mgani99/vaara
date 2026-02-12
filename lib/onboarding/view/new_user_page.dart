import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:my_app/onboarding/model/user_profile.dart';
import 'package:provider/provider.dart';

import 'package:my_app/session/app_data.dart';


class NewUserPage extends StatefulWidget {
  const NewUserPage({super.key});

  @override
  State<NewUserPage> createState() => _NewUserPageState();
}

class _NewUserPageState extends State<NewUserPage> {
  final _formKey = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final businessCtrl = TextEditingController();

  bool saving = false;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Set Up Your Profile"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                "Welcome! Let's set up your profile.",
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 20),

              // ------------------------------------------------------------
              // FULL NAME
              // ------------------------------------------------------------
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: "Full Name",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                v == null || v.trim().isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),

              // ------------------------------------------------------------
              // PHONE NUMBER
              // ------------------------------------------------------------
              TextFormField(
                controller: phoneCtrl,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                v == null || v.trim().isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),

              // ------------------------------------------------------------
              // BUSINESS NAME (OPTIONAL)
              // ------------------------------------------------------------
              TextFormField(
                controller: businessCtrl,
                decoration: const InputDecoration(
                  labelText: "Business Name (optional)",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 32),

              // ------------------------------------------------------------
              // SAVE BUTTON
              // ------------------------------------------------------------
              ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                  if (!_formKey.currentState!.validate()) return;

                  setState(() => saving = true);

                  final profile = UserProfile(
                    userId: session.userId!,
                    name: nameCtrl.text.trim(),
                    email: session.userEmail ?? "",
                    phone: phoneCtrl.text.trim(),
                    businessName: businessCtrl.text.trim().isEmpty
                        ? null
                        : businessCtrl.text.trim(),
                    createdAt:
                    DateTime.now().millisecondsSinceEpoch,
                  );

                  await FirebaseDatabase.instance
                      .ref("Users/${profile.userId}")
                      .set(profile.toMap());

                  session.setUser(
                    id: profile.userId,
                    email: profile.email,
                    name: profile.name,
                  );

                  setState(() => saving = false);

                  // Move to Step 1 of onboarding
                  Navigator.pushNamed(
                    context,
                    "/onboardingRoleQuestion",
                  );
                },
                child: saving
                    ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text("Continue"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
