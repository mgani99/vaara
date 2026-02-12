import 'package:flutter/material.dart';
import 'package:my_app/onboarding/service/contractor_onboarding_service.dart';
import 'package:provider/provider.dart';

import 'package:my_app/route/route_constants.dart';

class ContractorOnboardingScreen extends StatefulWidget {
  const ContractorOnboardingScreen({super.key});

  @override
  State<ContractorOnboardingScreen> createState() =>
      _ContractorOnboardingScreenState();
}

class _ContractorOnboardingScreenState
    extends State<ContractorOnboardingScreen> {
  final _businessName = TextEditingController();
  final _serviceType = TextEditingController();
  final _phone = TextEditingController();
  final _notes = TextEditingController();

  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final service = context.read<ContractorOnboardingService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Contractor Onboarding"),
        backgroundColor: Colors.lightBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _businessName,
                      decoration:
                      const InputDecoration(labelText: "Business Name"),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _serviceType,
                      decoration:
                      const InputDecoration(labelText: "Service Type"),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phone,
                      decoration:
                      const InputDecoration(labelText: "Phone Number"),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notes,
                      decoration:
                      const InputDecoration(labelText: "Notes (optional)"),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: _loading
                            ? null
                            : () async {
                          setState(() => _loading = true);

                          await service.completeOnboarding(
                            businessName: _businessName.text.trim(),
                            serviceType: _serviceType.text.trim(),
                            phone: _phone.text.trim(),
                            notes: _notes.text.trim(),
                          );

                          setState(() => _loading = false);

                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            homeRoute,
                                (route) => false,
                          );
                        },
                        child: _loading
                            ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                            : const Text("Finish"),
                      ),
                    ),
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
