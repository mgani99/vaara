import 'package:flutter/material.dart';
import 'package:my_app/property/service/unit_service.dart';
import 'package:my_app/property/view/lease_creation_screen.dart';
import 'package:my_app/route/route_constants.dart';
import 'package:provider/provider.dart';

import 'package:my_app/property/domain/property_model.dart';
import 'package:my_app/property/view/inline_editable_component.dart';
import 'package:my_app/session/app_data.dart';
import 'package:url_launcher/url_launcher.dart';

import 'tenant_creation_page.dart';


class UnitDetailsScreen extends StatefulWidget {
  final String unitId;

  const UnitDetailsScreen({super.key, required this.unitId});

  @override
  State<UnitDetailsScreen> createState() => _UnitDetailsScreenState();
}

class _UnitDetailsScreenState extends State<UnitDetailsScreen> {
  late UnitModel? unit;
  late PropertyModel? property;
  late LeaseDetailsModel? lease;
  late bool isApartment;
  List<TenantModel> tenants = [];
  DateTime start = DateTime.now();
  DateTime end = DateTime.now();
  late AppSession session;
  bool showFullDescription = false;
  bool isHovering = false;
  bool showMoreLeaseDetails = false;


  @override
  void initState() {
    super.initState();

    session = context.read<AppSession>();

    unit = session.unitCache[widget.unitId];
    isApartment = unit!.type.toLowerCase() == "apartment";

    property = session.propertyCache[unit!.propertyId];

    final leaseId = unit!.currentLeaseId;
    lease = leaseId != null ? session.currentLeaseCache[leaseId] : null;

    if (lease != null) {
      start = DateTime.fromMillisecondsSinceEpoch(lease!.startDateEpoch);
      end = DateTime.fromMillisecondsSinceEpoch(lease!.endDateEpoch);

      tenants = lease!.tenantIds
          .map((id) => session.tenantCache[id])
          .where((t) => t != null)
          .cast<TenantModel>()
          .toList();
    } else {
      tenants = [];
    }
  }



  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    property = session.propertyCache[unit!.propertyId];
    unit = session.unitCache[widget.unitId];
    final leaseId = unit!.currentLeaseId;
    lease = leaseId != null ? session.currentLeaseCache[leaseId] : null;

    tenants = lease?.tenantIds
        .map((id) => session.tenantCache[id])
        .where((t) => t != null)
        .cast<TenantModel>()
        .toList() ?? [];


    return Scaffold(
      appBar: AppBar(title: const Text("Unit and Lease")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _topImage(),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  await Navigator.pushNamed(
                    context,
                    unitCreationRoute,
                    arguments: unit!.unitId,

                  );
                  setState(() {
                    unit = session.unitCache[unit!.unitId];

                    final leaseId = unit!.currentLeaseId;
                    lease = leaseId != null ? session.currentLeaseCache[leaseId] : null;

                    if (lease != null) {
                      start = DateTime.fromMillisecondsSinceEpoch(lease!.startDateEpoch);
                      end = DateTime.fromMillisecondsSinceEpoch(lease!.endDateEpoch);
                    }
                  });


                },
                child: _unitInfoSection(),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () async {
                  await Navigator.pushNamed(
                    context,
                    unitMetricsRoute,
                    arguments: unit!.unitId,
                  );

                  // 🔥 Refresh AFTER returning
                  await session.loadOrgScopedData();
                  final updatedUnit = session.unitCache[unit!.unitId];

                  setState(() {
                    unit = updatedUnit;

                    final leaseId = updatedUnit!.currentLeaseId;
                    lease = leaseId != null ? session.currentLeaseCache[leaseId] : null;

                    if (lease != null) {
                      start = DateTime.fromMillisecondsSinceEpoch(lease!.startDateEpoch);
                      end = DateTime.fromMillisecondsSinceEpoch(lease!.endDateEpoch);
                    }
                  });
                },
                child: _buildMetricsSection(),
              ),


              const SizedBox(height: 10),
              if (lease == null)
                GestureDetector(
                  onTap: () async {
                    await Navigator.pushNamed(
                      context,
                      leaseCreationRoute,
                      arguments: {
                        "unitId": unit!.unitId,
                        "propertyId": unit!.propertyId,
                        //"leaseId" : lease!.leaseId,
                        "mode": LeasePageMode.newMode,
                      },
                    );

                    // 🔥 Refresh AFTER returning
                    final updatedUnit = session.unitCache[unit!.unitId];

                    setState(() {
                      unit = updatedUnit;
                      final leaseId = updatedUnit!.currentLeaseId;
                      lease = leaseId != null ? session.currentLeaseCache[leaseId] : null;
                    });
                  },

                  child: const Text(
                    "+ Add Lease",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    leaseCreationRoute,
                    arguments: {
                      "unitId": unit!.unitId,
                      "propertyId": unit!.propertyId,
                      "mode": LeasePageMode.readMode,   // 🔥 NEW FLAG
                      "leaseId": lease!.leaseId,
                    },
                  );
                  final updatedUnit = session.unitCache[unit!.unitId];
                  setState(() {
                    unit = updatedUnit;
                    final leaseId = updatedUnit!.currentLeaseId;
                    lease = leaseId != null ? session.currentLeaseCache[leaseId] : null;
                  });
                },
                child: _buildLeaseCard(),
              ),
              const SizedBox(height: 10),
              if (lease != null )_buildTenantCard(),
              const SizedBox(height: 10),

              if (lease != null)
                GestureDetector(
                  onTap: () {
                    setState(() => showMoreLeaseDetails = !showMoreLeaseDetails);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "More Lease Details",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        showMoreLeaseDetails
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 16,
                        color: Colors.blue.shade700,
                      ),
                    ],
                  ),
                ),
              if (showMoreLeaseDetails) ...[
                const SizedBox(height: 10),
                _paymentCard(),
                const SizedBox(height: 10),
                _utilitiesCard(),
                const SizedBox(height: 10),
                _appliancesCard(),
              ]

            ],
          ),
        ),
      ),

    );
  }
  Widget _paymentCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0F000000),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Payment",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          _detailRow("Paying Party",
              "Self Paying"), // You can adjust field name

          const SizedBox(height: 10),

          _detailRow("Late Fee",
              lease!.lateFeeType == "fixed" ? "Flat Fee" : "Formula"),
        ],
      ),
    );
  }
  Widget _utilitiesCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0F000000),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Utilities",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          _detailRow("Electricity", lease!.electricity),
          _detailRow("Gas", lease!.gas),
          _detailRow("Heating", lease!.heat),
          _detailRow("Water", lease!.water),
          _detailRow("Sewer", lease!.sewer),
          _detailRow("Waste", lease!.trash),
        ],
      ),
    );
  }
  Widget _appliancesCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0F000000),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Appliances",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          _detailRow("Refrigerator", "Yes"),
          _detailRow("Dishwasher",  "Yes"),
          _detailRow("Other",  "None"),
        ],
      ),
    );
  }
  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.black87)),
        Text(value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _unitInfoSection() {
    final String description = unit!.description ?? "";

    return MouseRegion(
      onEnter: (_) => setState(() => isHovering = true),
      onExit: (_) => setState(() => isHovering = false),

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isHovering ? Colors.blue.shade300 : Colors.grey.shade300,
            width: isHovering ? 1.4 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0x0F000000),
              blurRadius: isHovering ? 10 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),

        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 4),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    unit!.name,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87
                    ),
                  ),

                  Text(
                    unit!.type,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      unit!.address != null ? unit!.address! : property!.address,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              GestureDetector(
                onTap: () {
                  setState(() {
                    showFullDescription = !showFullDescription;
                  });
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      showFullDescription
                          ? description
                          : "${description.split('\n').first} .....More",
                      maxLines: showFullDescription ? null : 1,
                      overflow: showFullDescription
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),

                    if (showFullDescription)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          "Less",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _topImage() {
    return Container(
      height: 180,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/unit.png"),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildLeaseCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4), // 🔥 reduced spacing
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0F000000),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // -----------------------------------------------------------
          // HEADER + MENU
          // -----------------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Lease",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18),
                onSelected: (value) async {
                  if (value == "End Lease") {
                    final tenantNames = tenants.isNotEmpty
                        ? tenants.map((t) => t.name).join(", ")
                        : "this unit";

                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("End Lease"),
                        content: Text(
                          "Are you sure you want to end the lease for $tenantNames on ${unit!.name}?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("End Lease"),
                          ),
                        ],
                      ),
                    );

                    if (confirm != true) return;

                    final unitService = Provider.of<UnitService>(context, listen: false);

                    await unitService.vacateUnit(unit!, lease!);

                    setState(() {
                      final updatedUnit = session.unitCache[unit!.unitId];
                      unit = updatedUnit;
                      lease = null;
                      tenants = [];
                    });
                  }

                  if (value == "Edit") {
                    Navigator.pushNamed(
                      context,
                      leaseCreationRoute,
                      arguments: {
                        "unitId": unit!.unitId,
                        "propertyId": unit!.propertyId,
                        "mode": LeasePageMode.readMode,
                        "leaseId": lease!.leaseId,
                      },
                    );
                  }

                  if (value == "New Lease") {
                    Navigator.pushNamed(
                      context,
                      leaseCreationRoute,
                      arguments: {
                        "unitId": unit!.unitId,
                        "propertyId": unit!.propertyId,
                        "mode": LeasePageMode.newMode,
                      },
                    );
                  }

                  if (value == "Extend Lease") {
                    // your extend logic here
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: "Edit", child: Text("Edit")),
                  const PopupMenuItem(value: "New Lease", child: Text("New Lease")),
                  const PopupMenuItem(value: "Extend Lease", child: Text("Extend Lease")),
                  const PopupMenuItem(value: "End Lease", child: Text("End Lease")),
                ],
              )

            ],
          ),


          _divider(),

          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Lease Type",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              Text(
                lease!.leaseType ?? "Yearly",
                style: const TextStyle(
                  fontSize: 14,
                  //fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),


          const SizedBox(height: 8),
          _divider(),

          // -----------------------------------------------------------
          // EXPIRES IN
          // -----------------------------------------------------------
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Expires in",
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              Text(
                _remainingDisplay(),
                style: TextStyle(
                  fontSize: 14,
                  //fontWeight: FontWeight.w600,
                  color: _expiryColor(), // 🔥 changed from dynamic color
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          _divider(),

          // -----------------------------------------------------------
          // RENT
          // -----------------------------------------------------------
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Rent",
                  style: TextStyle(fontSize: 14
                      , fontWeight: FontWeight.w500, color: Colors.black87)),
              Text(
                "\$${lease!.rentAmount.toStringAsFixed(0)}",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          _divider(),

          // -----------------------------------------------------------
          // DEPOSIT
          // -----------------------------------------------------------
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Deposit",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
              Text(
                "\$${lease!.securityDeposit.toStringAsFixed(0)}",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _remainingDisplay() {
    final now = DateTime.now();
    final endDate = DateTime.fromMillisecondsSinceEpoch(lease!.endDateEpoch);

    final diff = endDate.difference(now).inDays;

    // 🔥 Already expired
    if (diff < 0) {
      if (diff > -30) {
        return "${diff.abs()} days ago";
      }
      final monthsAgo = (diff.abs() / 30).floor();
      return "$monthsAgo month ago";
    }

    // 🔥 Less than 60 days → show days
    if (diff <= 60) {
      return "$diff days";
    }

    // 🔥 Otherwise → show months
    final months = (diff / 30).floor();
    return "$months months";
  }



  Widget _buildTenantCard() {
    // If no lease, show empty tenant card with header only
    if (lease == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: const Color(0x0F000000),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Text(
          "Tenants",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      );
    }

    // 🔥 Sort tenants: Lease Holder first, then Occupant
    final sortedTenants = lease!.tenantIds.toList()
      ..sort((a, b) {
        final roleA = lease!.tenantRoles[a] ?? "Occupant";
        final roleB = lease!.tenantRoles[b] ?? "Occupant";
        if (roleA == "Lease Holder" && roleB != "Lease Holder") return -1;
        if (roleB == "Lease Holder" && roleA != "Lease Holder") return 1;
        return 0;
      });

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0F000000),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -----------------------------------------------------------
          // HEADER + ADD TENANT BUTTON (only if lease exists)
          // -----------------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Tenants",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              IconButton(
                icon: const Icon(Icons.person_add, size: 20, color: Colors.blue),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () async {
                  final result = await Navigator.pushNamed(
                    context,
                    tenantCreationRoute,
                    arguments: {
                      "tenantId": "",
                      "leaseId": lease!.leaseId,
                      "mode": TenantPageMode.create,
                    },
                  );

                  if (result != null) {
                    setState(() {
                      lease = session.currentLeaseCache[lease!.leaseId];
                      tenants = lease!.tenantIds
                          .map((id) => session.tenantCache[id])
                          .where((t) => t != null)
                          .cast<TenantModel>()
                          .toList();
                    });
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // -----------------------------------------------------------
          // TENANT AVATARS
          // -----------------------------------------------------------
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              separatorBuilder: (_, __) => const SizedBox(width: 20),
              itemCount: sortedTenants.length,
              itemBuilder: (_, index) {
                final tid = sortedTenants[index];
                final tenant = session.tenantCache[tid];
                final fullName = tenant?.name ?? _displayNameFromId(tid);
                final role = lease!.tenantRoles[tid] ?? "Occupant";

                return _tenantAvatarItem(
                  tenantId: tid,
                  fullName: fullName,
                  role: role,
                  phone: tenant?.phone ?? "",
                  email: tenant?.email ?? "",
                );
              },
            ),
          ),
        ],
      ),
    );
  }






  Widget _tenantAvatarItem({
    required String tenantId,
    required String fullName,
    required String role,
    required String phone,
    required String email,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () async {
              final result = await Navigator.pushNamed(
                context,
                tenantCreationRoute,
                arguments: {
                  "tenantId": tenantId,
                  "leaseId": lease!.leaseId,
                  "mode": TenantPageMode.view,
                },
              );

              if (result != null) {
                setState(() {
                  lease = session.currentLeaseCache[lease!.leaseId];
                  tenants = lease!.tenantIds
                      .map((id) => session.tenantCache[id])
                      .where((t) => t != null)
                      .cast<TenantModel>()
                      .toList();
                });
              }

            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue.shade50,
                  child: Text(
                    _initials(fullName),
                    style: TextStyle(color: Colors.blue.shade700, fontSize: 14),
                  ),
                ),

                Positioned(
                  right: -12,
                  bottom: -10,
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.arrow_drop_down_circle, size: 18, color: Colors.blue),
                    onSelected: (value) {
                      if (value == "call") _callPhone(phone);
                      if (value == "sms") _sendSMS(phone);
                      if (value == "email") _sendEmail(email);
                      if (value == "view") _viewTenant(tenantId);
                    },
                      itemBuilder: (context) => [
                        if (phone.isNotEmpty)
                          PopupMenuItem(
                            value: "call",
                            child: Row(
                              children: const [
                                Icon(Icons.phone, size: 16),
                                SizedBox(width: 8),
                                Text("Call", style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),

                        if (phone.isNotEmpty)
                          PopupMenuItem(
                            value: "sms",
                            child: Row(
                              children: const [
                                Icon(Icons.sms, size: 16),
                                SizedBox(width: 8),
                                Text("SMS", style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),

                        if (email.isNotEmpty)
                          PopupMenuItem(
                            value: "email",
                            child: Row(
                              children: const [
                                Icon(Icons.email, size: 16),
                                SizedBox(width: 8),
                                Text("Email", style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),

                        PopupMenuItem(
                          value: "view",
                          child: Row(
                            children: const [
                              Icon(Icons.person, size: 16),
                              SizedBox(width: 8),
                              Text("View", style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ]

                  ),
                ),
              ],
            ),
          ),


          const SizedBox(height: 6),

          Text(
            fullName,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black87,     // 🔥 NEW
            ),
          ),


          Text(
            role,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _callPhone(String phone) {
    if (phone.isEmpty) return;
    launchUrl(Uri.parse("tel:$phone"));
  }

  void _sendSMS(String phone) {
    if (phone.isEmpty) return;
    launchUrl(Uri.parse("sms:$phone"));
  }

  void _sendEmail(String email) {
    if (email.isEmpty) return;
    launchUrl(Uri.parse("mailto:$email"));
  }

  Future<void> _viewTenant(String tenantId) async {
    final result = await Navigator.pushNamed(
      context,
      tenantCreationRoute,
      arguments: {
        "tenantId": tenantId,
        "leaseId": lease!.leaseId,
        "mode": TenantPageMode.view,
      },
    );

    if (result != null) {
      setState(() {
        lease = session.currentLeaseCache[lease!.leaseId];
        tenants = lease!.tenantIds
            .map((id) => session.tenantCache[id])
            .where((t) => t != null)
            .cast<TenantModel>()
            .toList();
      });
    }

  }

  String _displayNameFromId(String id) {
    if (id.startsWith("temp_")) return "New Tenant";
    return "Unknown Tenant";
  }

  Color _expiryColor() {
    final months = _remainingMonths();
    if (months <= 0) return Colors.red;        // 🔥 expired
    if (months < 2) return Colors.orange;      // 🔥 expiring soon
    return Colors.black87;                        // normal
  }

  Widget _tenantRowCompact(String role, String fullName, String tenantId) {
    return InkWell(
      onTap: () {
        // TODO: open tenant detail page or modal
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            // Avatar initials
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.blue.shade50,
              child: Text(
                _initials(fullName),
                style: TextStyle(color: Colors.blue.shade700, ),
              ),
            ),
            const SizedBox(width: 12),

            // Role (fixed width)
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 120, maxWidth: 140),
              child: Text(
                role,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500,color: Colors.black87),
              ),
            ),

            // Tenant name (right aligned)
            Expanded(
              child: Text(
                fullName,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500,color: Colors.black87),
              ),
            ),

            const SizedBox(width: 8),

              const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }
  Widget _divider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      height: 1,
      color: Colors.grey.shade300,
    );
  }
  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return "";
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
  String _monthName(int m) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
    ];
    return months[m - 1];
  }

  Widget _buildMetricsSection() {
    final bool isApartment = (unit!.type.toString().toLowerCase() != "parking" || unit!.type.toString().toLowerCase() != "garage")? true : false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0F000000),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _metricDisplay(
              icon: Icons.square_foot,
              label: "${unit!.sqft != null ? unit!.sqft!.toStringAsFixed(0) : 0} sqft",
            ),

            if (isApartment)
              _metricDisplay(icon: Icons.bed, label: "${unit!.bedrooms} bd"),

            if (isApartment)
              _metricDisplay(
                icon: Icons.bathtub,
                label: "${unit!.bathrooms != null ?unit!.bathrooms!.toStringAsFixed(1) : 0.0} ba",
              ),
          ],
        ),
      ),
    );
  }



  Widget _metricDisplay({required IconData icon, required String label}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade700),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
// REMAINING MONTHS (today → lease end)
// ---------------------------------------------------------------------------
  int _remainingMonths() {
    final now = DateTime.now();
    final end = DateTime.fromMillisecondsSinceEpoch(lease!.endDateEpoch);

    // If lease already ended
    if (end.isBefore(now)) return 0;

    final days = end.difference(now).inDays;

    // Convert days → months (approx 30 days per month)
    return (days / 30).floor();
  }

}
