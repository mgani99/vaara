
import 'package:flutter/material.dart';
import 'package:my_app/portfolio/model/linked_bank_repository.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:my_app/session/app_data.dart';
import 'package:my_app/session/user_role.dart';

import '../../login/model/invitation_repository.dart';
import '../../login/model/org_user_repository.dart';
import '../../property/domain/property_model.dart';
import '../../route/route_constants.dart';
import '../model/portfolio_repository.dart';
import 'package:plaid_flutter/plaid_flutter.dart';
import '../../utils/plaid_service.dart';



class PortfolioDetailsScreen extends StatefulWidget {
  final String portfolioId;

  const PortfolioDetailsScreen({super.key, required this.portfolioId});

  @override
  State<PortfolioDetailsScreen> createState() => _PortfolioDetailsScreenState();
}

class _PortfolioDetailsScreenState extends State<PortfolioDetailsScreen> {
  LinkTokenConfiguration? _plaidConfig;
  bool _plaidLoading = false;

  StreamSubscription<LinkEvent>? _plaidEvent;
  StreamSubscription<LinkExit>? _plaidExit;
  StreamSubscription<LinkSuccess>? _plaidSuccess;
  StreamSubscription<LinkOnLoad>? _plaidLoad;

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

    _plaidEvent = PlaidLink.onEvent.listen(_onPlaidEvent);
    _plaidExit = PlaidLink.onExit.listen(_onPlaidExit);
    _plaidSuccess = PlaidLink.onSuccess.listen(_onPlaidSuccess);
    _plaidLoad = PlaidLink.onLoad.listen(_onPlaidLoad);
  }

  @override
  void dispose() {
    _plaidEvent?.cancel();
    _plaidExit?.cancel();
    _plaidSuccess?.cancel();
    _plaidLoad?.cancel();
    super.dispose();
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

    Future<Map<String, List<BankAccount>>> _loadOrgBanks() async {
      final session = context.read<AppSession>();
      final repo = context.read<LinkedBankRepository>();

      return await repo.getAllOrgBanks(session.activeOrgId!);
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
  Future<void> _startPlaidFlow() async {
    final session = context.read<AppSession>();
    final orgId = session.activeOrgId!;
    final userId = session.user!.userId.toString();
    final bankName = "primary_bank"; // or derive from portfolio

    setState(() => _plaidLoading = true);

    final linkToken = await PlaidService.createLinkToken(
      orgId: orgId,
      userId: userId,
      bankName: bankName,
    );

    if (linkToken == null) {
      setState(() => _plaidLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to create link token")),
      );
      return;
    }

    final config = LinkTokenConfiguration(token: linkToken);
    await PlaidLink.create(configuration: config);

    setState(() {
      _plaidConfig = config;
      _plaidLoading = false;
    });

    await PlaidLink.open();
  }

  void _onPlaidSuccess(LinkSuccess event) async {
    final session = context.read<AppSession>();
    final orgId = session.activeOrgId!;
    final userId = session.user!.userId.toString();
    final bankName = "primary_bank";

    final publicToken = event.publicToken;

    final ok = await PlaidService.exchangePublicToken(
      publicToken: publicToken,
      orgId: orgId,
      userId: userId,
      bankName: bankName,
    );

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bank linked successfully")),
      );

      // TODO: reload portfolio.bankAccounts from Firebase if you store them there
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save bank link")),
      );
    }
  }

  void _onPlaidEvent(LinkEvent event) {
    debugPrint("Plaid event: ${event.name}, metadata: ${event.metadata.description()}");
  }

  void _onPlaidExit(LinkExit event) {
    debugPrint("Plaid exit: ${event.error?.description()}");
  }

  void _onPlaidLoad(LinkOnLoad event) {
    debugPrint("Plaid loaded");
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
  Future<double?> _loadDailyBalance({
    required String institutionName,
    required String mask,
    required String acct_id,
  }) async {
    final session = context.read<AppSession>();
    final repo = context.read<LinkedBankRepository>();

    final today = DateTime.now();
    final yyyymmdd =
        "${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}";
    final userId = await repo.findUserIdForAccount(orgId: session.activeOrgId!,
        institutionName: institutionName, acctId: acct_id);
    return await repo.getDailyBalance(
      orgId: session.activeOrgId!,
      userId: userId!,
      institutionName: institutionName,
      mask: mask,
      acct_id: acct_id,
      dateKey: yyyymmdd,
    );
  }

  Future<Map<String, List<BankAccount>>> _loadOrgBanks() async {
    final session = context.read<AppSession>();
    final repo = context.read<LinkedBankRepository>();

    return await repo.getAllOrgBanks(session.activeOrgId!);
  }

  Future<double> _refreshBalance({
    required String institutionName,
    required String mask,
    required String acctId
  }) async {
    final session = context.read<AppSession>();
    final orgId = session.activeOrgId!;
    final userId = session.user!.userId.toString();


    // 1. Call backend to get balance from Plaid
    final result = await PlaidService.getBalance(
      orgId: orgId,
      userId: userId,
      institutionName: institutionName,
      acctId: acctId,
      mask: mask,
    );
    print(result);

    // ⭐ Handle backend error
    if (result["error"] != null) {
      final errorMsg = result["error"].toString();

      // Show error to user for 5 seconds
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Balance refresh failed: $errorMsg"),
          duration: const Duration(seconds: 5),
        ),
      );

      throw errorMsg; // ⭐ propagate error upward
    }

    // ⭐ Extract balance
    final balance = result["balance"] as double;

    // 2. Save to Firebase
    final repo = context.read<LinkedBankRepository>();
    final ownerUserId = await repo.findUserIdForAccount(
      orgId: orgId,
      institutionName: institutionName,
      acctId: acctId,
    );

    await repo.saveDailyBalance(
      orgId: orgId,
      userId: ownerUserId!,
      institutionName: institutionName,
      acctId: acctId,
      balance: balance,
    );

    return balance;
  }


  // ============================================================
  // BANK LINK (Plaid)
  // ============================================================
  Widget _bankSection() {
    return FutureBuilder(
      future: _loadOrgBanks(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Text("Loading bank accounts...");
        }

        final data = snapshot.data as Map<String, List<BankAccount>>;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ⭐ ALWAYS SHOW THIS BUTTON
            ElevatedButton.icon(
              icon: const Icon(Icons.account_balance),
              label: _plaidLoading
                  ? const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text("Connect Bank via Plaid"),
              onPressed: _startPlaidFlow,
            ),

            const SizedBox(height: 12),

            const Text(
              "Linked Bank Accounts:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // ⭐ If no banks → show message but KEEP the Plaid button above
            if (data.isEmpty)
              const Text("No bank accounts linked."),

            // ⭐ Otherwise show accounts
            ...data.entries.map((entry) {
              final institutionName = entry.key;
              final accounts = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        institutionName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      // 🌀 Sync Button (NEW)
                      IconButton(
                        icon: const Icon(Icons.sync, size: 20),
                        tooltip: "Sync Transactions",
                        onPressed: () async {
                          final session = context.read<AppSession>();
                          final orgId = session.activeOrgId!;

                          // Call backend syncer for this institution
                          await PlaidService.syncer(
                            orgId: orgId,

                          );


                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Transactions synced"),
                                duration: Duration(seconds: 3),
                              ),
                            );

                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  ...accounts.map((acct) {
                    return FutureBuilder(
                      future: _loadDailyBalance(
                        institutionName: institutionName,
                        mask: acct.mask,
                        acct_id: acct.accountId
                      ),
                      builder: (context, snap) {
                        final balance = snap.data;

                        return Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  "${acct.name} ••••${acct.mask}",
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // REFRESH BUTTON
                                  IconButton(
                                    icon: const Icon(Icons.refresh, color: Colors.blue),
                                    tooltip: "Refresh Balance",
                                    onPressed: () async {
                                      final newBalance = await _refreshBalance(
                                        institutionName: institutionName,
                                        mask: acct.mask,
                                        acctId: acct.accountId,
                                      );
                                      setState(() {});
                                    },
                                  ),

                                  // ⭐ VIEW TRANSACTIONS BUTTON (NEW)
                                  IconButton(
                                    icon: const Icon(Icons.visibility, color: Colors.green),
                                    tooltip: "View Today's Transactions",
                                    onPressed: () async {
                                      final session = context.read<AppSession>();
                                      final repo = context.read<LinkedBankRepository>();

                                      final orgId = session.activeOrgId!;
                                      final userId = await repo.findUserIdForAccount(
                                        orgId: orgId,
                                        institutionName: institutionName,
                                        acctId: acct.accountId,
                                      );

                                      final today = DateTime.now();
                                      final dayKey =
                                          "${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}";

                                      final txList = await repo.getDailyTransactions(
                                        orgId: orgId,
                                        userId: userId!,
                                        institutionName: institutionName,
                                        accountId: acct.accountId,
                                        dayKey: dayKey,
                                      );

                                      if (txList.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("No transactions for today")),
                                        );
                                        return;
                                      }

                                      // Navigate to list of transactions
                                      Navigator.pushNamed(
                                        context,
                                        bankTransactionRoute,
                                        arguments: {
                                          "institutionName": institutionName,
                                          "accountId": acct.accountId,
                                        },
                                      );

                                    },
                                  ),

                                  // DELETE BUTTON
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    tooltip: "Delete Account",
                                    onPressed: () async {
                                      // your delete logic
                                    },
                                  ),
                                ],
                              )

                            ],
                          ),
                        );
                      },
                    );
                  }),
                ],
              );
            }),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount(String institutionName, String acctId) async {
    final session = context.read<AppSession>();
    final repo = context.read<LinkedBankRepository>();
    final orgId = session.activeOrgId!;

    // 1. Find which user linked this account
    final ownerUserId = await repo.findUserIdForAccount(
      orgId: orgId,
      institutionName: institutionName,
      acctId: acctId,
    );


    if (ownerUserId == null) {
      print("ERROR: No user found for account $acctId");
      return;
    }

    // 2. Delete the account under the correct user
    await repo.deleteAccount(
      orgId: orgId,
      userId: ownerUserId,
      institutionName: institutionName,
      acctId: acctId,
    );

    // 3. Reload all banks
    final allBanks = await _loadOrgBanks();
    final accounts = allBanks[institutionName] ?? [];

    // 4. If this user has no accounts left → disconnect bank for THIS user
    if (accounts.isEmpty) {
      await repo.disconnectBank(
        orgId: orgId,
        userId: ownerUserId,
        institutionName: institutionName,
      );
    }

    // 5. Refresh UI
    setState(() {});
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
