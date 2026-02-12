import 'package:flutter/material.dart';
import 'package:my_app/onboarding/controller/onboarding_addunit_controller.dart';
import 'package:provider/provider.dart';
import 'package:my_app/session/app_data.dart';

class AddUnitsPage extends StatefulWidget {
  const AddUnitsPage({super.key});

  @override
  State<AddUnitsPage> createState() => _AddUnitsPageState();
}

class _AddUnitsPageState extends State<AddUnitsPage> {
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final bedsCtrl = TextEditingController(text: "1");
  final bathsCtrl = TextEditingController(text: "1");
  final rentCtrl = TextEditingController(text: "0");

  late final String propertyId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    propertyId = ModalRoute.of(context)!.settings.arguments as String;
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OnboardingAddUnitsController>();
    final session = context.watch<AppSession>();

    return Scaffold(
      appBar: AppBar(title: const Text("Add Units")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Add one or more units for this property.\nYou can always add more later.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: "Unit Name / Number",
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                    v == null || v.trim().isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: bedsCtrl,
                    decoration: const InputDecoration(
                      labelText: "Bedrooms",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                    int.tryParse(v ?? "") == null ? "Enter a number" : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: bathsCtrl,
                    decoration: const InputDecoration(
                      labelText: "Bathrooms",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                    int.tryParse(v ?? "") == null ? "Enter a number" : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: rentCtrl,
                    decoration: const InputDecoration(
                      labelText: "Monthly Rent",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) =>
                    double.tryParse(v ?? "") == null ? "Enter a number" : null,
                  ),
                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: controller.saving
                        ? null
                        : () async {
                      if (!_formKey.currentState!.validate()) return;

                      await controller.addUnit(
                        session: session,
                        propertyId: propertyId,
                        name: nameCtrl.text.trim(),
                        bedrooms: int.parse(bedsCtrl.text.trim()),
                        bathrooms: int.parse(bathsCtrl.text.trim()),
                        rentAmount:
                        double.parse(rentCtrl.text.trim()),
                      );

                      nameCtrl.clear();
                      bedsCtrl.text = "1";
                      bathsCtrl.text = "1";
                      rentCtrl.text = "0";
                    },
                    child: controller.saving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Add Unit"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Units Added",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: ListView(
                children: controller.createdUnits.map((u) {
                  return ListTile(
                    title: Text(u.name),
                    subtitle: Text(
                      "${u.bedrooms} bd • ${u.bathrooms} ba • \$${u.rentAmount.toStringAsFixed(0)}",
                    ),
                  );
                }).toList(),
              ),
            ),

            ElevatedButton(
              onPressed: () {
                // You can route to "Assign Tenants" or straight to dashboard
                Navigator.pushNamed(context, "/home");
              },
              child: const Text("Finish"),
            ),
          ],
        ),
      ),
    );
  }
}
