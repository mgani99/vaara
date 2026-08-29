import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_app/login/model/invitation_repository.dart';
import 'package:my_app/login/model/user_repository.dart';
import 'package:my_app/login/model/org_user_repository.dart';
import 'package:my_app/session/app_data.dart';
import 'package:my_app/route/route_constants.dart';

class UnifiedInviteScreen extends StatefulWidget {
  final List<Map<String, dynamic>> invites;

  const UnifiedInviteScreen({super.key, required this.invites});

  @override
  State<UnifiedInviteScreen> createState() => _UnifiedInviteScreenState();
}

class _UnifiedInviteScreenState extends State<UnifiedInviteScreen> {
  bool loading = true;
  Map<String, dynamic> inviteDetails = {}; // inviteId → details

  @override
  void initState() {
    super.initState();
    _loadAllInvites();
  }

  Future<void> _loadAllInvites() async {
    final orgRepo = context.read<OrgUserRepository>();
    final userRepo = context.read<UserRepository>();

    final Map<String, dynamic> details = {};

    for (var invite in widget.invites) {
      final orgId = invite["orgId"];
      final inviterEmail = invite["email"]; // inviter email
      final inviterUser = await userRepo.getByEmail(inviterEmail);

      final orgName = await orgRepo.getOrgName(orgId);

      details[invite["inviteId"]] = {
        "orgName": orgName,
        "invitedByName": "Unknown",
        "invitedByEmail": inviterEmail,
      };
    }

    setState(() {
      inviteDetails = details;
      loading = false;
    });
  }

  Future<void> _acceptInvite(Map<String, dynamic> invite) async {
    final inviteRepo = context.read<InvitationRepository>();
    final orgRepo = context.read<OrgUserRepository>();
    final session = context.read<AppSession>();

    final orgId = invite["orgId"];
    final role = invite["role"];
    final userId = session.user!.userId.toString();

    // 1. Mark accepted
    await inviteRepo.markAccepted(invite["inviteId"]);

    // 2. Add user to org
    await orgRepo.addOrgUser(
      orgId: orgId,
      userId: userId,
      role: role,
    );
    orgRepo.createUserOrgs(int.parse(userId), orgId);

    // 3. Reload orgs
    final orgs = await orgRepo.getOrgsForUser(userId);
    session.setOrganizations(orgs);

    // 4. Set active org + role
    session.setActiveOrg(orgId);
    session.setActiveRole(role);

    // 5. Navigate home
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        homeRoute,
            (route) => false,
      );
    });
  }

  Future<void> _rejectInvite(Map<String, dynamic> invite) async {
    final inviteRepo = context.read<InvitationRepository>();

    await inviteRepo.db.child("invitations/${invite["inviteId"]}").update({
      "status": "Invitee Rejected",
    });

    setState(() {}); // refresh UI
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Invitations")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            Text(
              "You have ${widget.invites.length} invitation(s)",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),

            ...widget.invites.map((invite) => _inviteCard(invite)),
          ],
        ),
      ),
    );
  }

  Widget _inviteCard(Map<String, dynamic> invite) {
    final id = invite["inviteId"];
    final details = inviteDetails[id];

    final orgName = details["orgName"];
    final invitedByName = details["invitedByName"];
    final invitedByEmail = details["invitedByEmail"];

    final createdAtMs = invite["createdAt"];

    DateTime? createdAt;
    if (createdAtMs is int && createdAtMs > 0) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(createdAtMs);
    }

    final createdAtStr = createdAt != null
        ? "${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}"
        : "Unknown";


    final role = invite["role"];
    final status = invite["accepted"] == true
        ? "Accepted"
        : (invite["status"] == "Invitee Rejected" ? "Rejected" : "Pending");

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Invited by: $invitedByName ($invitedByEmail)"),
          Text("Organization: $orgName"),
          Text("Role: $role"),
          Text("Date: $createdAtStr"),
          Text("Status: $status"),

          const SizedBox(height: 16),

          if (status == "Pending")
            Wrap(
              spacing: 12,
              children: [
                ElevatedButton(
                  onPressed: () => _acceptInvite(invite),
                  child: const Text("Accept"),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => _rejectInvite(invite),
                  child: const Text("Reject"),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
