import 'package:flutter/material.dart';
import 'package:my_app/home/view/home_dashboard.dart';
import 'package:my_app/payments/view/payment_dashboard_page.dart';
import 'package:my_app/profile/view/profile_settings_page.dart';
import 'package:my_app/property/view/property_dashboard.dart';
import 'package:my_app/session/app_data.dart';

class NavBarController extends ChangeNotifier {
  int selectedIndex = 0;

  void onTap(int index) {
    selectedIndex = index;
    notifyListeners();
  }

  List<Widget> getPages(AppSession session) {
    final role = session.activeRole;

    if (role == null) {
      return [const SizedBox()];
    }

    late final List<Widget> pages;

    switch (role) {
      case "landlord":
        pages = [
          const HomeDashboard(),
          const PropertyDashboard(),
          const PaymentDashboardPage(),
          const ProfileSettingsPage(),
        ];
        break;

      case "tenant":
        pages = [
          const HomeDashboard(),
          const PaymentDashboardPage(),
          const ProfileSettingsPage(),
        ];
        break;

      case "contractor":
        pages = [
          const HomeDashboard(),
          // const RepairDashboard(),  // add when ready
          const ProfileSettingsPage(),
        ];
        break;

      default:
        pages = [
          const HomeDashboard(),
          const ProfileSettingsPage(),
        ];
        break;
    }

    // ------------------------------------------------------------
    // SAFETY: Prevent RangeError
    // ------------------------------------------------------------
    if (selectedIndex >= pages.length) {
      selectedIndex = 0;
    }

    return pages;
  }
}
