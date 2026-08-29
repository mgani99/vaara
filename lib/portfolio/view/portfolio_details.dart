import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_app/session/app_data.dart';
import 'package:my_app/session/user_role.dart';

import '../../login/model/invitation_repository.dart';
import '../../login/model/org_user_repository.dart';
import '../../property/domain/property_model.dart';
import '../model/portfolio_repository.dart';


class PortfolioDetailsScreen extends StatefulWidget {
  final String portfolioId;

  const PortfolioDetailsScreen({super.key, required this.portfolioId});

  @override
  State<PortfolioDetailsScreen> createState() => _PortfolioDetailsScreenState();
}

class _PortfolioDetailsScreenState extends State<PortfolioDetailsScreen> {
  PortfolioModel? portfolio;
  bool isLoading = true;
  bool isReadOnly = true;

  // Section toggles
  bool infoOpen = true;
  bool accessOpen = false;
  bool bankOpen = false;
  bool ownershipOpen = false;


  // Controllers
  late TextEditingController nameCtrl;
  late TextEditingController descCtrl;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final session = context.read<AppSession>();
    final repo = context.read<PortfolioRepository>();

    final result = await repo.getPortfolio(widget.portfolioId);

    if (result == null) {
      // Portfolio deleted / archived / missing
      setState(() {
        isLoading = false;
        portfolio = null; // allow null
      });
      return;
    }

    portfolio = result;

    nameCtrl = TextEditingController(text: portfolio!.name);
    descCtrl = TextEditingController(text: portfolio!.description ?? "");

    setState(() => isLoading = false);
  }

  Future<List<Map<String, dynamic>>> _loadInvitations(AppSession session) async {
    final repo = context.read<InvitationRepository>();
    return repo.loadInvitationsForOrg(session.activeOrgId!);
  }

  Future<void> _save() async {
    final session = context.read<AppSession>();
    final repo = context.read<PortfolioRepository>();

    final updated = portfolio!.copyWith(
      name: nameCtrl.text.trim(),
      description: descCtrl.text.trim(),
    );


    await repo.updatePortfolio(session.activeOrgId!, updated);

    // ⭐ Update session so HomeDashboard refreshes the portfolio card
    session.updateOrganizationName(session.activeOrgId!, updated.name);
    session.setActiveOrgName(updated.name);

    setState(() => portfolio = updated);
  }




  Future<void> _deletePortfolio() async {
    final session = context.read<AppSession>();
    final repo = PortfolioRepository();

    await repo.updatePortfolio(
      session.activeOrgId!,
      portfolio!.copyWith(status: "deleted"),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();

    // 1. Loading state
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 2. Portfolio missing / deleted / archived
    if (portfolio == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Portfolio")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orange),
              SizedBox(height: 16),
              Text(
                "This portfolio is no longer available.",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                "It may have been deleted or archived.",
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Normal screen (portfolio is guaranteed non-null here)
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(portfolio!.name),
        actions: [
          IconButton(
            icon: Icon(isReadOnly ? Icons.edit : Icons.check),
            onPressed: () async {
              if (!isReadOnly) {
                await _save();
              }
              setState(() => isReadOnly = !isReadOnly);
            },
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _section("Portfolio Info", Icons.info_outline, infoOpen, () {
            setState(() => infoOpen = !infoOpen);
          }, _portfolioInfo()),

          _section(
            "Access",
            Icons.group_add,   // ⭐ Add icon
            accessOpen,
                () => setState(() => accessOpen = !accessOpen),
            _accessTable(session),
          ),


          _section("Bank Link", Icons.account_balance, bankOpen, () {
            setState(() => bankOpen = !bankOpen);
          }, _bankSection()),


          const SizedBox(height: 20),
// ------------------------------------------------------------
// OWNERSHIP SECTION (LANDLORD ONLY)
// ------------------------------------------------------------
          _section(
            "Ownership %",
            Icons.percent,
            ownershipOpen,
                () => setState(() => ownershipOpen = !ownershipOpen),
            _ownershipSection(session),
          ),



          if (!isReadOnly)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _deleteButton(),
            ),


        ],
      ),
    );
  }

  Widget _ownershipSection(AppSession session) {
    final orgRepo = context.read<OrgUserRepository>();

    // Filter only landlords
    final landlords = session.orgUsersCache.values.where((u) {
      return u.roles.containsKey("landlord");
    }).toList();

    if (landlords.isEmpty) {
      return const Text("No landlords assigned.");
    }

    return Column(
      children: landlords.map((u) {
        final profile = session.userCache[u.userId];
        final name = profile?.fullName ?? "Unknown User";

        final ctrl = TextEditingController(
          text: u.ownershipPercent.toString(),   // ⭐ FIXED
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(name),
              ),

              Expanded(
                flex: 1,
                child: TextField(
                  controller: ctrl,
                  readOnly: isReadOnly,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  ),
                  onSubmitted: isReadOnly
                      ? null
                      : (value) async {
                    final percent = double.tryParse(value) ?? 0.0;

                    final updated = u.copyWith(
                      ownershipPercent: percent,
                    );

                    await orgRepo.updateOrgUser(updated);

                    setState(() {
                      session.orgUsersCache[u.userId] = updated;
                    });
                  },
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }


  // ============================================================
  // SECTION WRAPPER
  // ============================================================
  Widget _section(String title, IconData icon, bool open, VoidCallback toggle, Widget child) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: toggle,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: Colors.grey.shade700),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                Icon(open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
              ],
            ),
          ),
          if (open) ...[
            const SizedBox(height: 10),
            child,
          ]
        ],
      ),
    );
  }


  // ============================================================
  // PORTFOLIO INFO
  // ============================================================
  Widget _portfolioInfo() {
    return Column(
      children: [
        _row("Name", nameCtrl),
        _divider(),

        _multilineRow("Description", descCtrl),
      ],
    );
  }

  Widget _multilineRow(String label, TextEditingController ctrl) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.black)),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: TextField(
            controller: ctrl,
            readOnly: isReadOnly,
            maxLines: 4,
            decoration: InputDecoration(
              isDense: true,
              border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(2.0),
                borderSide: BorderSide(
                  color: isReadOnly ? Colors.grey.shade300 : Colors.blue.shade300,
                ),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: Colors.blue, width: 1.4),
              ),
              contentPadding: const EdgeInsets.all(8),
            ),
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ACCESS TABLE
  // ============================================================
  Widget _accessTable(AppSession session) {
    final orgUsers = session.orgUsersCache.values.toList();

    final filtered = orgUsers.where((u) {
      final roles = u.roles.keys.toList();
      return !roles.contains(UserRole.tenant.name);
    }).toList();

    return FutureBuilder(
      future: _loadInvitations(session),
      builder: (context, snapshot) {
        final invites = snapshot.data ?? [];

        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ------------------------------------------------------------
              // HEADER + INVITE BUTTON
              // ------------------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "User Access",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_add, color: Colors.blue),
                    onPressed: () => _showInviteDialog(session),
                  ),
                ],
              ),

              const Divider(),

              // ------------------------------------------------------------
              // EXISTING USERS
              // ------------------------------------------------------------
              ...filtered.map((u) {
                final userProfile = session.userCache[u.userId];
                final fullName = userProfile?.fullName ?? "Unknown User";
                final accessLevel = u.roles.keys.join(", ");

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(child: Text(fullName)),
                      Expanded(child: Text(accessLevel)),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 16),
              const Text(
                "Invitations",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Divider(),

              // ------------------------------------------------------------
              // INVITATION STATUS LIST
              // ------------------------------------------------------------
              if (invites.isEmpty)
                const Text("No invitations sent.")
              else
                ...invites.map((inv) {
                  final invitedName = inv["metadata"]?["invitedName"] ?? "Unknown";
                  final role = inv["role"];
                  final createdMs = inv["createdAt"];
                  final created = (createdMs is int)
                      ? DateTime.fromMillisecondsSinceEpoch(createdMs)
                      : null;
                  final accepted = inv["accepted"] == true;

                  return Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ------------------------------------------------------------
                        // HEADER ROW WITH DELETE ICON
                        // ------------------------------------------------------------
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              invitedName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),

                            // HARD DELETE ICON
                            IconButton(
                              icon: const Icon(Icons.delete_forever, color: Colors.red),
                              onPressed: () async {
                                final repo = context.read<InvitationRepository>();
                                await repo.db
                                    .child("invitations/${inv["inviteId"]}")
                                    .remove();

                                setState(() {}); // refresh UI
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),
                        Text("Role: $role"),
                        Text("Invitation Sent: ${created ?? "Unknown"}"),
                        Text("Status: ${accepted ? "Accepted" : "Pending"}"),
                      ],
                    ),
                  );
                }),

            ],
          ),
        );
      },
    );
  }



  void _showInviteDialog(AppSession session) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String selectedRole = "landlord"; // default

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Invite User"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: "Full Name",
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: "Email",
                ),
              ),
              const SizedBox(height: 10),

              // ROLE DROPDOWN
              DropdownButtonFormField<String>(
                value: selectedRole,
                items: const [
                  DropdownMenuItem(
                    value: "landlord",
                    child: Text("Landlord"),
                  ),
                  DropdownMenuItem(
                    value: "property_manager",
                    child: Text("Property Manager"),
                  ),
                  DropdownMenuItem(
                    value: "contractor",
                    child: Text("Contractor"),
                  ),
                ],
                onChanged: (v) => selectedRole = v!,
                decoration: const InputDecoration(labelText: "Role"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                await _createInvitation(
                  session,
                  nameCtrl.text.trim(),
                  emailCtrl.text.trim(),
                  selectedRole,
                );
                Navigator.pop(context);
              },
              child: const Text("Send Invite"),
            ),
          ],
        );
      },
    );
  }
  Future<void> _createInvitation(
      AppSession session,
      String name,
      String email,
      String role,
      ) async {
    final repo = context.read<InvitationRepository>();

    await repo.createInvitation(
      orgId: session.activeOrgId!,
      email: email,
      role: role,
      inviter: session.user!.fullName,
      inviterEmail: session.user!.email,
      metadata: {
        "invitedName": name,
        "portfolioId": widget.portfolioId,
      },
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Invitation sent")),
    );
  }


  // ============================================================
  // BANK LINK (Plaid)
  // ============================================================
  Widget _bankSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.account_balance),
          label: const Text("Connect Bank via Plaid"),
          onPressed: isReadOnly ? null : () {
            // TODO: integrate Plaid link flow
          },
        ),

        const SizedBox(height: 12),

        if (portfolio!.bankAccounts != null && portfolio!.bankAccounts!.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Linked Accounts:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...portfolio!.bankAccounts!.map((acc) {
                return Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(acc),
                );
              }),
            ],
          )
        else
          const Text("No bank accounts linked."),
      ],
    );
  }

  // ============================================================
  // DELETE BUTTON
  // ============================================================
  Widget _deleteButton() {
    return Align(
      alignment: Alignment.center,
      child: IconButton(
        icon: const Icon(Icons.delete_forever, color: Colors.red, size: 32),
        onPressed: () => _confirmDelete(),
      ),
    );
  }


  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Delete Portfolio"),
          content: const Text(
            "Are you sure you want to delete this portfolio? "
                "This is a soft delete and can be restored later.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await _deletePortfolio();
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // UTIL ROWS
  // ============================================================
  Widget _row(String label, TextEditingController ctrl,
      [TextInputType type = TextInputType.text]) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.black)),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: TextField(
            controller: ctrl,
            readOnly: isReadOnly,
            keyboardType: type,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              isDense: true,
              border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(2.0),
                borderSide: BorderSide(
                  color: isReadOnly ? Colors.grey.shade300 : Colors.blue.shade300,
                ),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: Colors.blue, width: 1.4),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _divider() => const SizedBox(height: 12);
}
