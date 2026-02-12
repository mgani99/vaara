import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:my_app/session/app_data.dart';
import 'package:my_app/session/user_role.dart';
import 'package:my_app/home/controller/navbar_controller.dart';
import 'package:my_app/route/route_constants.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();

    // Load user profile if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = context.read<AppSession>();
      session.ensureUserLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    final nav = context.watch<NavBarController>();

    // Still loading session?
    if (session.activeRole == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: nav.getPages(session)[nav.selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: nav.selectedIndex,
        onTap: nav.onTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        items: _navItemsForRole(session.activeRole!),
      ),
    );
  }

  List<BottomNavigationBarItem> _navItemsForRole(UserRole role) {
    switch (role) {
      case UserRole.landlord:
        return [
          _item(Icons.home, "Home"),
          _item(Icons.home_work, "Properties"),
          _item(Icons.attach_money, "Payments"),
          _item(Icons.person, "Profile"),
        ];

      case UserRole.tenant:
        return [
          _item(Icons.home, "Home"),
          _item(Icons.receipt_long, "Payments"),
          _item(Icons.person, "Profile"),
        ];

      case UserRole.contractor:
        return [
          _item(Icons.home, "Home"),
          _item(Icons.build, "Repairs"),
          _item(Icons.person, "Profile"),
        ];

      default:
        return [
          _item(Icons.home, "Home"),
          _item(Icons.person, "Profile"),
        ];
    }
  }

  BottomNavigationBarItem _item(IconData icon, String label) {
    return BottomNavigationBarItem(
      icon: Icon(icon),
      label: label,
    );
  }
}
