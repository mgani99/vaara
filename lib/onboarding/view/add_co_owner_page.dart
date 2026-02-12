import 'package:flutter/material.dart';
import 'package:my_app/onboarding/controller/onboarding_add_coowner_controller.dart';
import 'package:provider/provider.dart';
import 'package:my_app/session/app_data.dart';

class AddCoOwnersPage extends StatefulWidget {
  const AddCoOwnersPage({super.key});

  @override
  State<AddCoOwnersPage> createState() => _AddCoOwnersPageState();
}

class _AddCoOwnersPageState extends State<AddCoOwnersPage> {
  final _formKey = GlobalKey<FormState>();
  final emailCtrl = TextEditingController();
  final percentCtrl = TextEditingController(text: "50");

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OnboardingAddCoOwnersController>();
    final session = context.watch<AppSession>();

    return Scaffold(
      appBar: AppBar(title: const Text("Add Co‑Owners")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Add partners or co‑owners to this portfolio.\nThis step is optional.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(
                      labelText: "Co‑Owner Email",
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                    v == null || v.trim().isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: percentCtrl,
                    decoration: const InputDecoration(
                      labelText: "Ownership Percent",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return "Required";
                      final val = double.tryParse(v);
                      if (val == null || val <= 0 || val > 100) {
                        return "Enter a value between 1 and 100";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: controller.sending
                        ? null
                        : () async {
                      if (!_formKey.currentState!.validate()) return;

                      await controller.addCoOwner(
                        session: session,
                        email: emailCtrl.text.trim(),
                        percent: double.parse(percentCtrl.text.trim()),
                      );

                      emailCtrl.clear();
                      percentCtrl.text = "50";
                    },
                    child: controller.sending
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Send Invite"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Pending Invitations",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: ListView(
                children: controller.pendingInvites.map((invite) {
                  return ListTile(
                    title: Text(invite.invitedEmail),
                    subtitle: Text(
                      "${invite.ownershipPercent.toStringAsFixed(0)}% ownership",
                    ),
                  );
                }).toList(),
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, "/onboardingAddProperty");
              },
              child: const Text("Continue"),
            ),
          ],
        ),
      ),
    );
  }
}
