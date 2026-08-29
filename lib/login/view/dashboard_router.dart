import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';

import 'package:my_app/property/controller/landlord_dashboard_controller.dart';
import 'package:my_app/property/model/lease_details_repository.dart';
import 'package:my_app/property/model/unit_repository.dart';
import 'package:my_app/property/service/ladlord_dashboard_service.dart';
import 'package:my_app/property/view/landlord_dashboard_screen.dart';
import 'package:my_app/session/app_data.dart';

import '../../payments/repository/payment_repository.dart';

class DashboardRouter extends StatelessWidget {
  const DashboardRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();

    // ------------------------------------------------------------
    // 1. User must be loaded
    // ------------------------------------------------------------
    if (session.user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // ------------------------------------------------------------
    // 2. Org must be selected
    // ------------------------------------------------------------
    if (session.activeOrgId == null) {
      return const Center(child: Text("No organization selected."));
    }

    // ------------------------------------------------------------
    // 3. Role must be selected
    // ------------------------------------------------------------
    final role = session.activeRole;
    if (role == null) {
      return const Center(child: Text("No role selected."));
    }

    // ------------------------------------------------------------
    // 4. Route based on string role
    // ------------------------------------------------------------
    switch (role) {
      case "tenant":
        return const Center(child: Text("Tenant Dashboard Placeholder"));

      case "landlord":
        return ChangeNotifierProvider(
          create: (context) => LandlordDashboardController(
            service: LandlordDashboardService(
              session: context.read<AppSession>(),
              unitRepo: context.read<UnitRepository>(),
              leaseRepo: context.read<LeaseDetailsRepository>(),
              paymentRepo: context.read<PaymentRepository>(),
              db: FirebaseDatabase.instance.ref(),
            ),
          ),
          child: const LandlordDashboardScreen(),
        );

      case "manager":
        return const Center(child: Text("Manager Dashboard Placeholder"));

      case "contractor":
        return const Center(child: Text("Contractor Dashboard Placeholder"));

      default:
        return Center(child: Text("Unknown role: $role"));
    }
  }
}
