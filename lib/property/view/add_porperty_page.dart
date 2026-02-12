import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_app/onboarding/controller/onboarding_add_property_controller.dart';
import 'package:my_app/session/app_data.dart';

class AddPropertyPage extends StatefulWidget {
  const AddPropertyPage({super.key});

  @override
  State<AddPropertyPage> createState() => _AddPropertyPageState();
}

class _AddPropertyPageState extends State<AddPropertyPage> {
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  String type = "single_family";

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OnboardingAddPropertyController>();
    final session = context.watch<AppSession>();

    return Scaffold(
      appBar: AppBar(title: const Text("Add Your First Property")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                "Let's add your first property.",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: "Property Name",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                v == null || v.trim().isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: addressCtrl,
                decoration: const InputDecoration(
                  labelText: "Address",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                v == null || v.trim().isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(
                  labelText: "Property Type",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                      value: "single_family", child: Text("Single Family")),
                  DropdownMenuItem(
                      value: "multi_family", child: Text("Multi‑Family")),
                  DropdownMenuItem(
                      value: "commercial", child: Text("Commercial")),
                ],
                onChanged: (v) => setState(() => type = v!),
              ),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: controller.saving
                    ? null
                    : () async {
                  if (!_formKey.currentState!.validate()) return;

                  final propertyId = await controller.addProperty(
                    session: session,
                    name: nameCtrl.text.trim(),
                    address: addressCtrl.text.trim(),
                    type: type,
                  );

                  Navigator.pushNamed(
                    context,
                    "/onboardingAddUnits",
                    arguments: propertyId,
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
