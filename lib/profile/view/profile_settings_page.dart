import 'package:flutter/material.dart';
import 'package:my_app/login/domain/orgUser.dart';
import 'package:provider/provider.dart';

import '../controller/profile_controller.dart';
import '../../login/domain/re_user.dart';

import '../view/settings_section.dart';

class ProfileSettingsPage extends StatelessWidget {
  const ProfileSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Provider.of<ProfileController>(context);

    final user = ctrl.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Profile & Settings",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto',
          ),
        ),
        actions: [
          _roleSwitcher(context, ctrl),
          _signOutButton(context, ctrl),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _header(user),
          const SizedBox(height: 24),

          _securitySection(),
          _personalDetailsSection(context, user),
          _orgSection(context),
          _notificationsSection(),
          _documentsSection(),
          _preferencesSection(),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // HEADER
  // ------------------------------------------------------------
  Widget _header(ReUser user) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            backgroundImage: user.profilePictureUrl.isNotEmpty
                ? NetworkImage(user.profilePictureUrl)
                : null,
            child: user.profilePictureUrl.isEmpty
                ? const Icon(Icons.person, size: 40, color: Colors.grey)
                : null,
          ),

          const SizedBox(height: 8),

          Text(
            "${user.firstName} ${user.lastName}",
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            "Last login: ${DateTime.fromMillisecondsSinceEpoch(user.lastLoginAt)}",
            style: TextStyle(
              fontFamily: 'Roboto',
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // ROLE SWITCHER (OrgUser-based)
  // ------------------------------------------------------------
  Widget _roleSwitcher(BuildContext context, ProfileController ctrl) {
    return FutureBuilder<List<OrgUser>>(
      future: ctrl.loadLinkedUsers(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox();

        final roles = snap.data!;
        if (roles.isEmpty) return const SizedBox();

        final defaultRole = roles.firstWhere(
              (r) => r.isDefaultRole,
          orElse: () => roles.first,
        );

        return Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black.withOpacity(0.4)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<OrgUser>(
              value: defaultRole,
              items: roles.map((r) {
                return DropdownMenuItem(
                  value: r,
                  child: Text(
                    r.role,
                    style: const TextStyle(fontFamily: 'Roboto'),
                  ),
                );
              }).toList(),
              onChanged: (selected) {
                if (selected != null) {
                  ctrl.switchRole(selected);
                }
              },
            ),
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // SIGN OUT BUTTON
  // ------------------------------------------------------------
  Widget _signOutButton(BuildContext context, ProfileController ctrl) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () => ctrl.signOut(context),
        child: Row(
          children: const [
            Icon(Icons.logout, color: Colors.red, size: 20),
            SizedBox(width: 6),
            Text(
              "Sign Out",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // SECTIONS
  // ------------------------------------------------------------
  Widget _securitySection() {
    return const SettingsSection(
      title: "Security & Privacy",
      icon: Icons.lock,
      items: [
        SettingsItem(label: "Change password"),
        SettingsItem(label: "Two-factor authentication"),
        SettingsItem(label: "App permissions"),
      ],
    );
  }

  Widget _personalDetailsSection(BuildContext context, ReUser user) {
    return SettingsSection(
      title: "Personal Details",
      icon: Icons.person,
      items: [
        SettingsItem(label: "Phone"),
        SettingsItem(label: "Email"),
        SettingsItem(label: "Address"),
        const SettingsItem(label: "Connect Plaid®"),
        const SettingsItem(label: "Social Security ID"),
      ],
    );
  }

  Widget _orgSection(BuildContext context) {
    return const SettingsSection(
      title: "Organizations",
      icon: Icons.apartment,
      items: [
        SettingsItem(label: "Switch organization"),
        SettingsItem(label: "Manage organizations"),
      ],
    );
  }

  Widget _notificationsSection() {
    return const SettingsSection(
      title: "Notifications",
      icon: Icons.notifications,
      items: [
        SettingsItem(label: "Email notifications"),
        SettingsItem(label: "SMS notifications"),
        SettingsItem(label: "Push notifications"),
      ],
    );
  }

  Widget _documentsSection() {
    return const SettingsSection(
      title: "Documents",
      icon: Icons.description,
      items: [
        SettingsItem(label: "Lease agreement"),
        SettingsItem(label: "Upload documents"),
        SettingsItem(label: "View shared files"),
      ],
    );
  }

  Widget _preferencesSection() {
    return const SettingsSection(
      title: "Preferences",
      icon: Icons.settings,
      items: [
        SettingsItem(label: "Language"),
        SettingsItem(label: "Timezone"),
        SettingsItem(label: "Biometric login"),
      ],
    );
  }
}
