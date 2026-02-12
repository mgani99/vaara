import 'package:flutter/material.dart';
import 'package:my_app/home/view/home_dashboard.dart';
import 'package:my_app/payments/view/payment_list_page.dart';
import 'package:my_app/property/view/property_dashboard.dart';
import 'package:my_app/session/app_data.dart';
import 'package:my_app/session/user_role.dart';


class NavBarController extends ChangeNotifier {
  int selectedIndex = 0;

  void onTap(int index) {
    selectedIndex = index;
    notifyListeners();
  }

  List<Widget> getPages(AppSession session) {
    switch (session.activeRole) {
      case UserRole.landlord:
        return [
          const HomeDashboard(),
          const PropertyDashboard(),
          const PaymentListPage(),
          const ProfileScreen(),
        ];

      case UserRole.tenant:
        return [
          const HomeDashboard(),
          const PaymentDashboard(),
          const ProfileScreen(),
        ];

      case UserRole.contractor:
        return [
          const HomeDashboard(),
          const RepairDashboard(),
          const ProfileScreen(),
        ];

      default:
        return [
          const HomeDashboard(),
          const ProfileScreen(),
        ];
    }
  }
}
