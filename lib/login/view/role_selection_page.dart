import 'package:flutter/material.dart';
import 'package:my_app/login/model/user_repository.dart';
import 'package:provider/provider.dart';

import 'package:my_app/login/model/org_user_repository.dart';
import 'package:my_app/session/app_data.dart';
import 'package:my_app/route/route_constants.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    final orgUserRepo = context.read<OrgUserRepository>();
    final prefsRepo = context.read<UserPreferencesRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Your Role"),
        backgroundColor: Colors.lightBlue,
      ),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ------------------------------------------------------------
                // LANDLORD
                // ------------------------------------------------------------
                _roleButton(
                  context,
                  label: "I'm a Landlord",
                  icon: Icons.home_work,
                  onTap: () async {
                    final name = await _askForPortfolioName(context, "Portfolio Name");
                    if (name == null || name.isEmpty) return;

                    final userId = session.user!.userId;

                    // Create new org with unique name
                    final orgId = await orgUserRepo.createDefaultOrg(
                      ownerUserId: userId,
                      orgName: session.user!.firstName.toLowerCase(),
                    );

                    // Save default org
                    await prefsRepo.setDefaultOrg(userId.toString(), orgId);

                    // Update session
                    session.setActiveOrg(orgId);
                    session.setActiveRole("landlord");

                    Navigator.pushNamed(context, landlordOnboardingRoute);
                  },
                ),

                const SizedBox(height: 16),

                // ------------------------------------------------------------
                // CONTRACTOR
                // ------------------------------------------------------------
                _roleButton(
                  context,
                  label: "I'm a Contractor",
                  icon: Icons.build,
                  onTap: () async {
                    final name = await _askForPortfolioName(context, "Business Name");
                    if (name == null || name.isEmpty) return;

                    final userId = session.user!.userId;

                    final orgId = await orgUserRepo.createDefaultOrg(
                      ownerUserId: userId,
                      orgName: session.user!.firstName.toLowerCase(),
                    );

                    await prefsRepo.setDefaultOrg(userId.toString(), orgId);

                    session.setActiveOrg(orgId);
                    session.setActiveRole("contractor");

                    Navigator.pushNamed(context, contractorOnboardingRoute);
                  },
                ),

                const SizedBox(height: 16),

                // ------------------------------------------------------------
                // TENANT
                // ------------------------------------------------------------
                _roleButton(
                  context,
                  label: "I'm a Tenant",
                  icon: Icons.person,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Tenants must join through an invitation from a landlord.",
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleButton(
      BuildContext context, {
        required String label,
        required IconData icon,
        required VoidCallback onTap,
      }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 24),
        label: Text(label, style: const TextStyle(fontSize: 16)),
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.lightBlue,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Future<String?> _askForPortfolioName(
      BuildContext context,
      String label,
      ) async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(label),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: TextField(
                controller: controller,
                decoration: InputDecoration(hintText: "Enter $label"),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text("Continue"),
            ),
          ],
        );
      },
    );
  }
}
