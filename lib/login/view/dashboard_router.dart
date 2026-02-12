import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_app/login/model/org_user_repository.dart';
import 'package:my_app/property/controller/landlord_dashboard_controller.dart';
import 'package:my_app/property/model/lease_details_repository.dart';
import 'package:my_app/property/model/payment_repository.dart';
import 'package:my_app/property/model/unit_repository.dart';
import 'package:my_app/property/service/ladlord_dashboard_service.dart';
import 'package:my_app/property/view/landlord_dashboard_screen.dart';
import 'package:my_app/session/app_data.dart';
import 'package:my_app/session/user_role.dart';

class DashboardRouter extends StatelessWidget {
  const DashboardRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();

    // ------------------------------------------------------------
    // 1. No user loaded yet
    // ------------------------------------------------------------
    if (session.userId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // ------------------------------------------------------------
    // 2. No active org selected yet
    // ------------------------------------------------------------
    if (session.activeOrgId == null) {
      return const Center(child: Text("No organization selected."));
    }

    // ------------------------------------------------------------
    // 3. No active role selected yet
    // ------------------------------------------------------------
    final role = session.activeRole;
    if (role == null) {
      return const Center(child: Text("No role selected."));
    }

    // ------------------------------------------------------------
    // 4. Route based on role
    // ------------------------------------------------------------
    switch (role) {
      case UserRole.tenant:
        return const Center(child: Text("Tenant Dashboard Placeholder"));

      case UserRole.landlord:
        return ChangeNotifierProvider(
          create: (context) => LandlordDashboardController(
            service: LandlordDashboardService(
              session: context.read<AppSession>(),
              unitRepo: context.read<UnitRepository>(),
              orgUserRepo: context.read<OrgUserRepository>(),
              leaseRepo: context.read<LeaseDetailsRepository>(),
              paymentRepo: context.read<PaymentRepository>(),
              db: FirebaseDatabase.instance.ref(),
            ),
          ),
          child: const LandlordDashboardScreen(),
        );

      case UserRole.manager:
        return const Center(child: Text("Manager Dashboard Placeholder"));

      case UserRole.contractor:
        return const Center(child: Text("Contractor Dashboard Placeholder"));
    }
  }
}
