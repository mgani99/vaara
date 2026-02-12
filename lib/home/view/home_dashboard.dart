import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_app/session/app_data.dart';
import 'package:my_app/session/user_role.dart';

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    final theme = Theme.of(context);

    // Safety: If session is not ready, show loader
    if (session.userId == null || session.activeRole == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final role = session.activeRole!;
    final name = session.userName ?? "User";

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ------------------------------------------------------------
          // HEADER
          // ------------------------------------------------------------
          Text(
            "Welcome $name 👋",
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          if (role == UserRole.tenant && session.activeUnitName != null)
            Text(
              "Unit: ${session.activeUnitName}",
              style: theme.textTheme.bodyMedium,
            ),

          if (role == UserRole.landlord && session.activeOrgName != null)
            Text(
              "Organization: ${session.activeOrgName}",
              style: theme.textTheme.bodyMedium,
            ),

          const SizedBox(height: 24),

          // ------------------------------------------------------------
          // QUICK ACTIONS
          // ------------------------------------------------------------
          Text("Quick Actions", style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),

          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: _quickActionsForRole(role, context),
          ),

          const SizedBox(height: 32),

          // ------------------------------------------------------------
          // ROLE-SPECIFIC SECTIONS
          // ------------------------------------------------------------
          if (role == UserRole.landlord) _landlordSection(theme),
          if (role == UserRole.tenant) _tenantSection(theme),
          if (role == UserRole.contractor) _contractorSection(theme),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // QUICK ACTIONS BY ROLE
  // ------------------------------------------------------------
  List<Widget> _quickActionsForRole(UserRole role, BuildContext context) {
    switch (role) {
      case UserRole.landlord:
        return [
          _action(context, Icons.home_work, "Add Property", () {}),
          _action(context, Icons.add_business, "Add Unit", () {}),
          _action(context, Icons.attach_money, "Add Charge", () {}),
          _action(context, Icons.payments, "Record Payment", () {}),
        ];

      case UserRole.tenant:
        return [
          _action(context, Icons.report_problem, "Report Issue", () {}),
          _action(context, Icons.receipt_long, "View Payments", () {}),
        ];

      case UserRole.contractor:
        return [
          _action(context, Icons.build, "My Repairs", () {}),
          _action(context, Icons.schedule, "Upcoming Jobs", () {}),
        ];

      default:
        return [];
    }
  }

  Widget _action(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }

  // ------------------------------------------------------------
  // LANDLORD SECTION
  // ------------------------------------------------------------
  Widget _landlordSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Owner Dashboard", style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              "Your properties, payments, and tenant activity will appear here.",
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // TENANT SECTION
  // ------------------------------------------------------------
  Widget _tenantSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Tenant Dashboard", style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              "Your rent balance, payments, and maintenance requests will appear here.",
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // CONTRACTOR SECTION
  // ------------------------------------------------------------
  Widget _contractorSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Contractor Dashboard", style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              "Your assigned repair jobs and updates will appear here.",
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }
}
