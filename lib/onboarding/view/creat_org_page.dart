import 'package:flutter/material.dart';
import 'package:my_app/onboarding/controller/org_onboarding_controller.dart';
import 'package:provider/provider.dart';
import 'package:my_app/session/app_data.dart';

class CreateOrgPage extends StatefulWidget {
  const CreateOrgPage({super.key});

  @override
  State<CreateOrgPage> createState() => _CreateOrgPageState();
}

class _CreateOrgPageState extends State<CreateOrgPage> {
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  String type = "personal";

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OnboardingCreateOrgController>();
    final session = context.watch<AppSession>();

    return Scaffold(
      appBar: AppBar(title: const Text("Create Portfolio")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                "What is the ownership entity?",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: "Portfolio / Organization Name",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                v == null || v.trim().isEmpty ? "Required" : null,
              ),

              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(
                  labelText: "Ownership Type",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: "personal", child: Text("Personal")),
                  DropdownMenuItem(value: "llc", child: Text("LLC")),
                  DropdownMenuItem(value: "trust", child: Text("Trust")),
                  DropdownMenuItem(value: "partnership", child: Text("Partnership")),
                  DropdownMenuItem(value: "other", child: Text("Other")),
                ],
                onChanged: (v) => setState(() => type = v!),
              ),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: controller.saving
                    ? null
                    : () async {
                  if (!_formKey.currentState!.validate()) return;

                  final orgId = await controller.createOrg(
                    session: session,
                    name: nameCtrl.text.trim(),
                    type: type,
                  );

                  Navigator.pushNamed(
                    context,
                    "/onboardingAddCoOwners",
                    arguments: orgId,
                  );
                },
                child: controller.saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Continue"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
