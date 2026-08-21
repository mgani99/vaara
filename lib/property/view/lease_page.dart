import 'package:flutter/material.dart';
import 'package:my_app/property/model/tenant_repository.dart';
import '../domain/property_model.dart';
import 'inline_editable_component.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LeasePage(),
    );
  }
}

class LeasePage extends StatefulWidget {
  const LeasePage({super.key});

  @override
  State<LeasePage> createState() => _LeasePageState();
}

class _LeasePageState extends State<LeasePage> {
  bool showLeaseCard = false;
  bool isEditing = false;

  late LeaseDetailsModel lease;

  /// Tenant cache: tenantId -> TenantModel
  final Map<String, TenantModel> tenantCache = {};

  /// Replace with your real repo
  String unit = "apartment";
  double bedrooms = 2.0;
  double bathrooms = 2.0;
  double sqrft = 300;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    final start = now.add(const Duration(days: 1));
    final end = DateTime(start.year + 1, start.month, start.day);

    lease = LeaseDetailsModel(
      leaseId: "temp_${now.millisecondsSinceEpoch}",
      orgId: "",
      propertyId: "",
      unitId: "",
      tenantIds: [],
      tenantRoles: {},
      startDateEpoch: start.millisecondsSinceEpoch,
      endDateEpoch: end.millisecondsSinceEpoch,
      rentAmount: 0,
      securityDeposit: 0,
      createdAt: now.millisecondsSinceEpoch,
      updatedAt: now.millisecondsSinceEpoch,
      leaseType: "Yearly",
    );


  }

  @override
  Widget build(BuildContext context) {
    final start = DateTime.fromMillisecondsSinceEpoch(lease.startDateEpoch);
    final end = DateTime.fromMillisecondsSinceEpoch(lease.endDateEpoch);

    return Scaffold(
      appBar: AppBar(title: const Text("Lease Setup")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _topImage(),
              const SizedBox(height: 10),
              _unitInfoSection(),
              const SizedBox(height: 10),
              _buildMetricsSection(),
              const SizedBox(height: 10),
              if (showLeaseCard) _buildLeaseCard(start, end),
              if (!showLeaseCard)
                GestureDetector(
                  onTap: () => setState(() => showLeaseCard = true),
                  child: const Text(
                    "+ Add Lease",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
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
      height: 240,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/unit.png"),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _unitInfoSection() {
    final String description =
        "This is a sample unit description that will be truncated when displayed. this is a test test stesaetlj";

    bool isHovering = false;

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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 4),

              // -----------------------------------------------------------
              // UNIT NAME + UNIT TYPE (15px)
              // -----------------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    lease.unitId.isNotEmpty ? "Main" : "Unit",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  Text(
                    unit.toLowerCase() == "apartment"
                        ? "Apartment"
                        : "Residential",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // -----------------------------------------------------------
              // ADDRESS (12px)
              // -----------------------------------------------------------
              Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "14315 Milverton Rd, Cleveland OH 44120",
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // -----------------------------------------------------------
              // DESCRIPTION (one line + ...more)
              // -----------------------------------------------------------
              GestureDetector(
                onTap: () {
                  // TODO: expand description
                },
                child: Text(
                  "${description.split('\n').first} ...more",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



// ---------------------------------------------------------------------------
// LEASE CARD
// ---------------------------------------------------------------------------

  Widget _buildLeaseCard(DateTime start, DateTime end) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
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
              // LEASE TYPE ROW + 3-DOT MENU
              // -----------------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Lease",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),

                  Row(
                    children: [
                      Text(
                        lease.leaseType ?? "Yearly",
                        style: const TextStyle(fontSize: 12),
                      ),

                      const SizedBox(width: 8),

                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == "Edit") {
                            // Navigate to separate edit page
                            // Navigator.push(context, MaterialPageRoute(
                            //   builder: (_) => LeaseEditPage(lease: lease),
                            // ));
                          }
                          if (value == "New Lease"){}
                          if (value == "End Lease") {
                            // TODO: implement end lease flow
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: "Edit", child: Text("Edit")),
                          const PopupMenuItem(value: "New Lease", child: Text("New Lease")),
                          const PopupMenuItem(value: "Extend Lease", child: Text("Extend Lease")),
                          const PopupMenuItem(value: "End Lease", child: Text("End Lease")),
                        ],
                        child: const Icon(Icons.more_vert, size: 18),
                      ),
                    ],
                  ),
                ],
              ),

              _divider(),

              // -----------------------------------------------------------
              // YEARLY READ MODE — period + remaining underneath
              // -----------------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Period",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${_monthName(start.month)} '${start.year.toString().substring(2)}"
                            " → ${_monthName(end.month)} '${end.year.toString().substring(2)}",
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "(Expires in: ${_remainingMonths()} months)",
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 6),
              _divider(),

              // -----------------------------------------------------------
              // RENT
              // -----------------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Rent",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                   Text(
                    "\$${lease.rentAmount.toStringAsFixed(0)}",
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),

                ],
              ),
              const SizedBox(height: 5),
              _divider(),

              // -----------------------------------------------------------
              // DEPOSIT
              // -----------------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Deposit",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                   Text(
                    "\$${lease.securityDeposit.toStringAsFixed(0)}",
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),

                ],
              ),

              const SizedBox(height: 20),

              // -----------------------------------------------------------
              // TENANTS
              // -----------------------------------------------------------
              const Text(
                "Tenants",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),

              Column(
                children: [
                  ...lease.tenantIds.map((tid) {
                    final role = lease.tenantRoles[tid] ?? "Lease Holder";
                    final tenant = tenantCache[tid];
                    final fullName = tenant?.name ?? _displayNameFromId(tid);

                    return Column(
                      children: [
                        _tenantRowCompact(role, fullName, tid),
                        const Divider(height: 1, thickness: 1),
                      ],
                    );
                  }).toList(),
                ],
              ),

              const SizedBox(height: 20),

              // -----------------------------------------------------------
              // VIEW MORE
              // -----------------------------------------------------------
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue.shade300),
                  ),
                  child: Text(
                    "More Lease Details >",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildMetricsSection() {
    final bool isApartment = unit.toLowerCase() == "apartment";

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
              label: "${sqrft.toStringAsFixed(0)} sqft",
            ),

            if (isApartment)
              _metricDisplay(icon: Icons.bed, label: "$bedrooms bd"),

            if (isApartment)
              _metricDisplay(
                icon: Icons.bathtub,
                label: "${bathrooms.toStringAsFixed(1)} ba",
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
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
// REMAINING MONTHS (today → lease end)
// ---------------------------------------------------------------------------
  int _remainingMonths() {
    final now = DateTime.now();
    final end = DateTime.fromMillisecondsSinceEpoch(lease.endDateEpoch);

    // If lease already ended
    if (end.isBefore(now)) return 0;

    final days = end.difference(now).inDays;

    // Convert days → months (approx 30 days per month)
    return (days / 30).floor();
  }

  // ---------------------------------------------------------------------------
// M2M EDIT MODE — Only Start Date is editable
// ---------------------------------------------------------------------------
  Widget _startDateOnlyEdit(DateTime start) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Start Date",
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),

        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: start,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              setState(() {
                lease = lease.copyWith(startDateEpoch: picked.millisecondsSinceEpoch);
              });
            }
          },
          child: _dateBox(start),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
// YEARLY EDIT MODE — Start + End date pickers inline
// ---------------------------------------------------------------------------
  Widget _leasePeriodEditMode(DateTime start, DateTime end) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Period",
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),

        Row(
          children: [
            // START DATE PICKER
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: start,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() {
                    lease = lease.copyWith(startDateEpoch: picked.millisecondsSinceEpoch);
                  });
                }
              },
              child: _dateBox(start),
            ),

            const SizedBox(width: 10),
            const Text("→", style: TextStyle(fontSize: 12)),
            const SizedBox(width: 10),

            // END DATE PICKER
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: end,
                  firstDate: start,
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() {
                    lease = lease.copyWith(endDateEpoch: picked.millisecondsSinceEpoch);
                  });
                }
              },
              child: _dateBox(end),
            ),
          ],
        ),
      ],
    );
  }

// ---------------------------------------------------------------------------
// TENANT ROW — compact row with avatar + role + name + chevron/delete
// ---------------------------------------------------------------------------
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
              radius: 18,
              backgroundColor: Colors.blue.shade50,
              child: Text(
                _initials(fullName),
                style: TextStyle(color: Colors.blue.shade700),
              ),
            ),
            const SizedBox(width: 12),

            // Role (fixed width)
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 120, maxWidth: 140),
              child: Text(
                role,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),

            // Tenant name (right aligned)
            Expanded(
              child: Text(
                fullName,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),

            const SizedBox(width: 8),

            // Delete icon in edit mode, chevron otherwise
            if (isEditing)
              GestureDetector(
                onTap: () {
                  setState(() {
                    lease = lease.copyWith(
                      tenantIds: lease.tenantIds.where((id) => id != tenantId)
                          .toList(),
                      tenantRoles: Map.from(lease.tenantRoles)
                        ..remove(tenantId),
                    );
                    tenantCache.remove(tenantId);
                  });
                },
                child: const Icon(Icons.delete, color: Colors.red),
              )
            else
              const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }

// ---------------------------------------------------------------------------
// TENANT MODAL — Add Tenant (name + email + role)
// ---------------------------------------------------------------------------
  void _openAddTenantModal() {
    String fullName = "";
    String email = "";
    String role = "Lease Holder";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Stack(
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery
                        .of(context)
                        .viewInsets
                        .bottom + 60,
                    left: 16,
                    right: 16,
                    top: 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Add Tenant",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 20),

                      TextField(
                        decoration: const InputDecoration(
                            labelText: "Full Name"),
                        onChanged: (v) => fullName = v,
                      ),
                      const SizedBox(height: 10),

                      TextField(
                        decoration: const InputDecoration(labelText: "Email"),
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (v) => email = v,
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text("Lease Holder"),
                            selected: role == "Lease Holder",
                            onSelected: (_) =>
                                setModalState(() => role = "Lease Holder"),
                          ),
                          const SizedBox(width: 10),
                          ChoiceChip(
                            label: const Text("Occupant"),
                            selected: role == "Occupant",
                            onSelected: (_) =>
                                setModalState(() => role = "Occupant"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _squareButton(
                        icon: Icons.check,
                        color: Colors.green.shade600,
                        onTap: () {
                          if (fullName.isEmpty) return;

                          final tempId = "temp_${DateTime
                              .now()
                              .millisecondsSinceEpoch}";

                          final tenantModel = TenantModel(
                            tenantId: tempId,
                            name: fullName,
                            email: email,

                            orgId: lease.orgId,
                            createdAt: DateTime
                                .now()
                                .millisecondsSinceEpoch,
                            phone: '',
                          );

                          setState(() {
                            tenantCache[tempId] = tenantModel;

                            lease = lease.copyWith(
                              tenantIds: [...lease.tenantIds, tempId],
                              tenantRoles: {
                                ...lease.tenantRoles,
                                tempId: role,
                              },
                            );
                          });

                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(width: 20),
                      _squareButton(
                        icon: Icons.close,
                        color: Colors.red.shade600,
                        onTap: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

// ---------------------------------------------------------------------------
// DATE BOX
// ---------------------------------------------------------------------------
  Widget _dateBox(DateTime d) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text("${d.month}/${d.day}/${d.year}"),
    );
  }

// ---------------------------------------------------------------------------
// DIVIDER
// ---------------------------------------------------------------------------
  Widget _divider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      height: 1,
      color: Colors.grey.shade300,
    );
  }


// ---------------------------------------------------------------------------
// INITIALS HELPER
// ---------------------------------------------------------------------------
  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return "";
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

// ---------------------------------------------------------------------------
// FALLBACK NAME
// ---------------------------------------------------------------------------
  String _displayNameFromId(String id) {
    if (id.startsWith("temp_")) return "New Tenant";
    return "Unknown Tenant";
  }

// ---------------------------------------------------------------------------
// MONTH NAME
// ---------------------------------------------------------------------------
  String _monthName(int m) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
    ];
    return months[m - 1];
  }

// ---------------------------------------------------------------------------
// SQUARE BUTTON (Save / Cancel)
// ---------------------------------------------------------------------------
  Widget _squareButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color, width: 1.6),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  void _resetLease() {}
}