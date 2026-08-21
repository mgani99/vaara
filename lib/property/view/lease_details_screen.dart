import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_app/session/app_data.dart';
import 'package:my_app/property/domain/property_model.dart';
import 'package:my_app/property/view/inline_editable_component.dart';
import 'package:my_app/property/service/lease_details_service.dart';

class LeaseDetailsScreen extends StatefulWidget {
  final String leaseId;

  const LeaseDetailsScreen({super.key, required this.leaseId});

  @override
  State<LeaseDetailsScreen> createState() => _LeaseDetailsScreenState();
}

class _LeaseDetailsScreenState extends State<LeaseDetailsScreen> {
  late LeaseDetailsModel lease;

  late TenantModel selectedTenant;
  late List<TenantModel> otherTenants;

  bool lateFeeOpen = false;
  bool prorateFirstMonth = false;
  bool autoCalculateLateFee = false;

  // ------------------------------------------------------------
  // SAFE DATE PARSER
  // ------------------------------------------------------------
  DateTime _safeParseDate(int raw) {
    if (raw == null || raw == 0) return DateTime.now();

    return DateTime.fromMicrosecondsSinceEpoch(raw);

  }

  // ------------------------------------------------------------
  // SAVE FIELD → Firebase + Session Cache + UI
  // ------------------------------------------------------------
  Future<void> _saveLeaseField(String field, dynamic value) async {
    final session = context.read<AppSession>();
    final leaseService = context.read<LeaseDetailsService>();

    print(field + " " + value.toString() );
    print(lease.tenantIds);
    print(lease.leaseId);
    // 1️⃣ Update Firebase
    await leaseService.repo.updateLeaseField(
      orgId: session.activeOrgId!,
      leaseId: lease.leaseId,
      field: field,
      value: value,
    );

    print("888**** ${lease.tenantIds}");
    //2️⃣ Update local model — ⭐ MUST include tenantIds
    final updated = lease.copyWith(
      tenantIds: lease.tenantIds,   // ⭐ REQUIRED FIX
      updatedAt: DateTime.now().millisecondsSinceEpoch,

      startDateEpoch: field == "startDateEpoch" ? value : lease.startDateEpoch,
      endDateEpoch: field == "endDate" ? value : lease.endDateEpoch,
      rentAmount: field == "rentAmount" ? value : lease.rentAmount,
      securityDeposit: field == "securityDeposit" ? value : lease.securityDeposit,
      lateFeeType: field == "lateFeeType" ? value : lease.lateFeeType,
      lateFeeAmount: field == "lateFeeAmount" ? value : lease.lateFeeAmount,
      gracePeriodDays: field == "gracePeriodDays" ? value : lease.gracePeriodDays,
    );

    // 3️⃣ Update session cache
    session.currentLeaseCache[lease.leaseId] = updated;

    // 4️⃣ Update UI
    setState(() => lease = updated);
  }


  @override
  void initState() {
    super.initState();
    final session = context.read<AppSession>();

    lease = session.currentLeaseCache[widget.leaseId]!;

    final allTenants = lease.tenantIds
        .map((tid) => session.tenantCache[tid]!)
        .toList();

    selectedTenant = allTenants.first;
    otherTenants = allTenants.skip(1).toList();

    final start = _safeParseDate(lease.startDateEpoch);
    prorateFirstMonth = start.day != 1;
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(title: const Text("Lease Details")),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(height: 12),

          _sectionTitle("Tenant"),
          _buildTenantSection(session),

          const SizedBox(height: 12),

          _sectionTitle("Lease Details"),
          _buildLeaseInfoSection(session),

          const SizedBox(height: 12),

          _buildLateFeeSection(session),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // TENANT SECTION
  // ------------------------------------------------------------
  Widget _buildTenantSection(AppSession session) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (otherTenants.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () async {
                  final tid = await showModalBottomSheet<String>(
                    context: context,
                    builder: (_) => _tenantPicker(session),
                  );

                  if (tid != null) {
                    setState(() {
                      selectedTenant = session.tenantCache[tid]!;
                    });
                  }
                },
                child: Text(
                  "${otherTenants.length} other tenant${otherTenants.length > 1 ? 's' : ''}…",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 8),

          Row(
            children: [
              ClipOval(
                child: Container(
                  width: 72,
                  height: 72,
                  color: Colors.blue.shade100,
                  child: Center(
                    child: Text(
                      selectedTenant.name[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InlineEditableText(
                      value: selectedTenant.name,
                      onSave: (v) {
                        final updated = selectedTenant.copyWith(name: v);
                        session.tenantCache[selectedTenant.tenantId] = updated;
                      },
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 6),

                    Row(
                      children: [
                        const Icon(Icons.email, size: 18, color: Colors.black54),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InlineEditableText(
                            value: selectedTenant.email,
                            onSave: (v) {
                              final updated = selectedTenant.copyWith(email: v);
                              session.tenantCache[selectedTenant.tenantId] = updated;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    Row(
                      children: [
                        const Icon(Icons.phone, size: 18, color: Colors.black54),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InlineEditableText(
                            value: selectedTenant.phone,
                            onSave: (v) {
                              final updated = selectedTenant.copyWith(phone: v);
                              session.tenantCache[selectedTenant.tenantId] = updated;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tenantPicker(AppSession session) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: otherTenants.map((t) {
          return ListTile(
            title: Text(t.name),
            subtitle: Text(t.email),
            onTap: () => Navigator.pop(context, t.tenantId),
          );
        }).toList(),
      ),
    );
  }

  // ------------------------------------------------------------
  // LEASE INFO SECTION
  // ------------------------------------------------------------
  Widget _buildLeaseInfoSection(AppSession session) {
    final start = _safeParseDate(lease.startDateEpoch);
    final end = _safeParseDate(lease.endDateEpoch);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _rowLabelValue(
            label: "Start",
            value: "${start.month}/${start.day}/${start.year}",
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: start,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                _saveLeaseField("startDate", picked.toIso8601String());
                prorateFirstMonth = picked.day != 1;
              }
            },
          ),

          if (prorateFirstMonth)
            Row(
              children: [
                Checkbox(
                  value: prorateFirstMonth,
                  onChanged: (v) => setState(() => prorateFirstMonth = v!),
                ),
                const Text("Pro‑rate first month"),
              ],
            ),

          const SizedBox(height: 12),

          _rowLabelValue(
            label: "End",
            value: "${end.month}/${end.day}/${end.year}",
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: end,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                _saveLeaseField("endDate", picked.toIso8601String());
              }
            },
          ),

          const SizedBox(height: 12),

          _rowLabelInlineEdit(
            label: "Rent",
            value: lease.rentAmount.toStringAsFixed(0),
            onSave: (v) {
              final rent = double.tryParse(v) ?? lease.rentAmount;
              _saveLeaseField("rentAmount", rent);
            },
          ),

          const SizedBox(height: 12),

          _rowLabelInlineEdit(
            label: "Security Deposit",
            value: lease.securityDeposit.toStringAsFixed(0),
            onSave: (v) {
              final dep = double.tryParse(v) ?? lease.securityDeposit;
              _saveLeaseField("securityDeposit", dep);
            },
          ),
        ],
      ),
    );
  }

  Widget _rowLabelValue({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black87, fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _rowLabelInlineEdit({
    required String label,
    required String value,
    required Function(String) onSave,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black87, fontSize: 16)),
        SizedBox(
          width: 120,
          child: InlineEditableText(
            value: value,
            onSave: onSave,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // LATE FEE SECTION
  // ------------------------------------------------------------
  Widget _buildLateFeeSection(AppSession session) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => lateFeeOpen = !lateFeeOpen),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Late Fee Settings",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Icon(
                  lateFeeOpen ? Icons.expand_less : Icons.expand_more,
                  size: 22,
                ),
              ],
            ),
          ),

          if (lateFeeOpen) ...[
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Late Fee Type", style: TextStyle(color: Colors.black87, fontSize: 16)),
                DropdownButton<String>(
                  value: lease.lateFeeType,
                  items: const [
                    DropdownMenuItem(value: "fixed", child: Text("Fixed")),
                    DropdownMenuItem(value: "calculated", child: Text("Calculated")),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      _saveLeaseField("lateFeeType", v);
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            _rowLabelInlineEdit(
              label: "Late Fee Amount",
              value: lease.lateFeeAmount.toString(),
              onSave: (v) {
                final amt = double.tryParse(v) ?? lease.lateFeeAmount;
                _saveLeaseField("lateFeeAmount", amt);
              },
            ),

            const SizedBox(height: 12),

            _rowLabelInlineEdit(
              label: "Grace Period (days)",
              value: lease.gracePeriodDays.toString(),
              onSave: (v) {
                final gp = int.tryParse(v) ?? lease.gracePeriodDays;
                _saveLeaseField("gracePeriodDays", gp);
              },
            ),

            Row(
              children: [
                Checkbox(
                  value: autoCalculateLateFee,
                  onChanged: (v) => setState(() => autoCalculateLateFee = v!),
                ),
                const Text("Auto calculate Late Fee (after grace period)"),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
