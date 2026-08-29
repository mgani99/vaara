import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_app/session/app_data.dart';
import 'package:my_app/property/service/lease_details_service.dart';
import 'package:my_app/property/service/unit_service.dart';
import '../domain/property_model.dart';

enum LeasePageMode { newMode, editMode, readMode }

class LeaseCreationScreen extends StatefulWidget {
  final String propertyId;
  final String unitId;
  final String? leaseId;
  final LeasePageMode mode;

  const LeaseCreationScreen({
    super.key,
    required this.propertyId,
    required this.unitId,
    this.leaseId,
    this.mode = LeasePageMode.newMode,
  });

  @override
  State<LeaseCreationScreen> createState() => _LeaseCreationScreenState();
}

class _LeaseCreationScreenState extends State<LeaseCreationScreen> {
  bool isReadOnly = false;

  // Lease fields
  String leaseType = "Yearly";
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now().add(const Duration(days: 365));
  double rentAmount = 0.0;
  double depositAmount = 0.0;

  // Persistent controllers
  late TextEditingController rentController;
  late TextEditingController depositController;

  @override
  void initState() {
    super.initState();

    isReadOnly = widget.mode == LeasePageMode.readMode;

    rentController = TextEditingController();
    depositController = TextEditingController();

    if (widget.mode != LeasePageMode.newMode) {
      _loadExistingLease();
    }
  }

  void _loadExistingLease() {
    final session = context.read<AppSession>();
    final lease = session.currentLeaseCache[widget.leaseId];

    if (lease == null) return;

    leaseType = lease.leaseType ?? "Yearly";
    startDate = DateTime.fromMillisecondsSinceEpoch(lease.startDateEpoch);
    endDate = DateTime.fromMillisecondsSinceEpoch(lease.endDateEpoch);
    rentAmount = lease.rentAmount;
    depositAmount = lease.securityDeposit;

    rentController.text = rentAmount.toString();
    depositController.text = depositAmount.toString();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    final unit = session.unitCache[widget.unitId];

    if (widget.mode != LeasePageMode.newMode && isReadOnly) {
      final lease = session.currentLeaseCache[widget.leaseId];
      if (lease != null) {
        leaseType = lease.leaseType ?? "Yearly";
        startDate = DateTime.fromMillisecondsSinceEpoch(lease.startDateEpoch);
        endDate = DateTime.fromMillisecondsSinceEpoch(lease.endDateEpoch);
        rentAmount = lease.rentAmount;
        depositAmount = lease.securityDeposit;

        rentController.text = rentAmount.toString();
        depositController.text = depositAmount.toString();
      }
    }


    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          widget.mode == LeasePageMode.newMode
              ? "New Lease - ${unit!.name}"
              : widget.mode == LeasePageMode.editMode
              ? "Edit Lease - ${unit!.name}"
              : "Lease Details - ${unit!.name}",
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          if (widget.mode == LeasePageMode.readMode)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() => isReadOnly = false);
              },
            ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _leaseBasicInfoCard(),
          const SizedBox(height: 20),

          if (!isReadOnly)
            ElevatedButton(
              onPressed: _saveLease,
              child: const Text("Save Lease", style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // BASIC INFO ONLY
  // ------------------------------------------------------------
  Widget _leaseBasicInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Lease Info",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          Row(
            children: [
              _chip("Yearly", leaseType == "Yearly", () {
                if (!isReadOnly) setState(() => leaseType = "Yearly");
              }),
              const SizedBox(width: 10),
              _chip("Monthly", leaseType == "Monthly", () {
                if (!isReadOnly) setState(() => leaseType = "Monthly");
              }),
            ],
          ),

          const SizedBox(height: 20),

          _dateField(
            label: "Start Date",
            value: startDate,
            readOnly: isReadOnly,
            onTap: () async {
              if (isReadOnly) return;

              // ⭐ FIX: use startDate instead of value
              final safeValue = startDate.isBefore(DateTime(2000))
                  ? DateTime(2000)
                  : startDate;

              final picked = await showDatePicker(
                context: context,
                initialDate: safeValue,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );

              if (picked != null) {
                setState(() {
                  startDate = picked;
                  endDate = picked.add(const Duration(days: 365));
                });
              }
            },
          ),


          const SizedBox(height: 20),

          _dateField(
            label: "End Date",
            value: endDate,
            readOnly: isReadOnly,
            onTap: () async {
              if (isReadOnly) return;

              final safeValue = endDate.isBefore(startDate)
                  ? startDate
                  : endDate;

              final picked = await showDatePicker(
                context: context,
                initialDate: safeValue,
                firstDate: startDate,
                lastDate: DateTime(2100),
              );

              if (picked != null) {
                setState(() => endDate = picked);
              }
            },
          ),


          const SizedBox(height: 20),

          _textField(
            label: "Rent Amount",
            controller: rentController,
            readOnly: isReadOnly,
            keyboard: TextInputType.number,
            onChanged: (v) => rentAmount = double.tryParse(v) ?? 0,
          ),

          const SizedBox(height: 20),

          _textField(
            label: "Deposit (optional)",
            controller: depositController,
            readOnly: isReadOnly,
            keyboard: TextInputType.number,
            onChanged: (v) => depositAmount = double.tryParse(v) ?? 0,
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // SAVE LEASE (NEW or UPDATE)
  // ------------------------------------------------------------
  Future<void> _saveLease() async {
    final session = context.read<AppSession>();
    final leaseService = context.read<LeaseDetailsService>();
    final unitService = context.read<UnitService>();

    if (widget.mode == LeasePageMode.newMode) {
      final newLeaseId = UniqueKey().toString();

      final newLease = LeaseDetailsModel(
        leaseId: newLeaseId,
        orgId: session.activeOrgId!,
        propertyId: widget.propertyId,
        unitId: widget.unitId,
        tenantIds: [],
        tenantRoles: {},
        startDateEpoch: startDate.millisecondsSinceEpoch,
        endDateEpoch: endDate.millisecondsSinceEpoch,
        rentAmount: rentAmount,
        securityDeposit: depositAmount,
        lateFeeType: "fixed",
        lateFeeAmount: 0.0,
        gracePeriodDays: 0,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        status: "active",
        electricity: "tenant",
        gas: "tenant",
        heat: "owner",
        water: "owner",
        trash: "owner",
        sewer: "owner",
        leaseType: leaseType,
      );

      final savedLease = await leaseService.createLease(
        session.activeOrgId!,
        newLease,
      );

      // Update unit with new leaseId
      unitService.repo.updateUnitField(
        orgId: session.activeOrgId!,
        unitId: widget.unitId,
        field: "currentLeaseId",
        value: savedLease.leaseId,
      );

      session.updateLeaseInCache(savedLease);
      final unit = session.unitCache[widget.unitId];
      session.updateUnitInCache(
        unit!.copyWith(currentLeaseId: savedLease.leaseId),
      );

      Navigator.pop(context, "lease_created");
      return;
    }

    // UPDATE EXISTING LEASE
    final existing = session.currentLeaseCache[widget.leaseId];
    if (existing == null) return;

    final updatedLease = existing.copyWith(
      leaseType: leaseType,
      startDateEpoch: startDate.millisecondsSinceEpoch,
      endDateEpoch: endDate.millisecondsSinceEpoch,
      rentAmount: rentAmount,
      securityDeposit: depositAmount,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    await leaseService.repo.updateLease(updatedLease);
    session.updateLeaseInCache(updatedLease);
    Navigator.pop(context, "lease_updated");
  }

  // ------------------------------------------------------------
  // REUSABLE WIDGETS
  // ------------------------------------------------------------
  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }

  Widget _dateField({
    required String label,
    required DateTime value,
    required bool readOnly,
    required VoidCallback onTap,
  }) {
    final safeValue = value.isBefore(DateTime(2000))
        ? DateTime(2000)
        : value;

    return GestureDetector(
      onTap: readOnly ? null : onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(
            "${safeValue.year}-${safeValue.month}-${safeValue.day}",
            style: TextStyle(
              fontSize: 12,
              color: readOnly ? Colors.grey : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }


  Widget _textField({
    required String label,
    required TextEditingController controller,
    required bool readOnly,
    required TextInputType keyboard,
    required Function(String) onChanged,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboard,
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: readOnly ? Colors.grey.shade300 : Colors.grey),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue),
        ),
      ),
      onChanged: readOnly ? null : onChanged,
    );
  }
}
