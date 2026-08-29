import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_app/session/app_data.dart';
import 'package:my_app/property/service/unit_service.dart';
import 'package:my_app/property/domain/property_model.dart';
import 'package:my_app/route/route_constants.dart';

class MultiFamilyUnitsPage extends StatefulWidget {
  final String propertyId;

  const MultiFamilyUnitsPage({super.key, required this.propertyId});

  @override
  State<MultiFamilyUnitsPage> createState() => _MultiFamilyUnitsPageState();
}

class _MultiFamilyUnitsPageState extends State<MultiFamilyUnitsPage> {
  final Set<String> bedFilters = {};
  final Set<String> occFilters = {};

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    final property = session.propertyCache[widget.propertyId]!;

    final units = session.unitCache.values
        .where((u) => u.propertyId == widget.propertyId && u.isDeleted != true)
        .toList();

    final expectedUnits = property.numUnits ?? units.length;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(property.name),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildHeader(property),
          const SizedBox(height: 10),
          _buildAddRemoveButtons(units.length, expectedUnits),
          _buildFilterChips(units),
          _buildHeaderRow(),
          Expanded(child: _buildUnitGrid(units)),
          _buildFooterSummary(units),
        ],
      ),
    );
  }

  // ⭐ SIMPLE HEADER — Property Name + Address
  Widget _buildHeader(PropertyModel property) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(property.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (property.address != null) ...[
            const SizedBox(height: 4),
            Text(property.address!,
                style: const TextStyle(fontSize: 14, color: Colors.black54)),
          ],
        ],
      ),
    );
  }

  // ⭐ Add / Remove Buttons (unchanged)
  Widget _buildAddRemoveButtons(int actual, int expected) {
    final remainingToAdd = expected - actual;
    final extraToRemove = actual - expected;

    final session = context.watch<AppSession>();
    final property = session.propertyCache[widget.propertyId]!;
    final unitService = context.read<UnitService>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          if (remainingToAdd > 0)
            Flexible(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: Text("Add Unit ($remainingToAdd)"),
                onPressed: () async {
                  for (int i = 1; i <= remainingToAdd; i++) {
                    final nextIndex = actual + i;

                    final unit = UnitModel(
                      unitId: "",
                      orgId: session.activeOrgId!,
                      propertyId: property.propertyId,
                      type: "Apartment",
                      name: "${property.name} - Unit $nextIndex",
                      sqft: 0,
                      createdAt: DateTime.now().millisecondsSinceEpoch,
                    );

                    final newUnit =
                    await unitService.createUnit(session.activeOrgId!, unit);

                    session.unitCache[newUnit.unitId] = newUnit;
                    session.notifyListeners();
                  }
                },
              ),
            ),

          if (remainingToAdd > 0) const SizedBox(width: 12),

          if (extraToRemove > 0)
            Flexible(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.remove),
                label: Text("Remove Unit ($extraToRemove)"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => _showRemoveUnitSheet(),
              ),
            ),
        ],
      ),
    );
  }

  // ⭐ Dynamic, Compact Filter Chips — Blue background + count
  Widget _buildFilterChips(List<UnitModel> units) {
    final bedCounts = <String, int>{};
    int otherCount = 0;

    for (final u in units) {
      final b = u.bedrooms ?? 0;
      if (b == 1) bedCounts["Bed 1"] = (bedCounts["Bed 1"] ?? 0) + 1;
      if (b == 2) bedCounts["Bed 2"] = (bedCounts["Bed 2"] ?? 0) + 1;
      if (b >= 3) bedCounts["Bed 3+"] = (bedCounts["Bed 3+"] ?? 0) + 1;

      if (u.type.toLowerCase() == "garage" ||
          u.type.toLowerCase() == "parking" ||
          u.type.toLowerCase() == "parking lot" ||
          u.type.toLowerCase() == "storage") {
        otherCount++;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ...bedCounts.entries.map((e) => _chip("${e.key} (${e.value})", bedFilters)),
          if (otherCount > 0) _chip("Other ($otherCount)", bedFilters),
          _chip("Vacant", occFilters),
          _chip("Occupied", occFilters),
          _chip("All", occFilters),
        ],
      ),
    );
  }

  Widget _chip(String label, Set<String> filterSet) {
    final selected = filterSet.contains(label);

    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : Colors.black87,
        ),
      ),
      selected: selected,
      onSelected: (value) {
        setState(() {
          if (value) {
            filterSet.add(label);
          } else {
            filterSet.remove(label);
          }
        });
      },
      selectedColor: Colors.blue.shade600,
      backgroundColor: Colors.blue.shade50,
      checkmarkColor: Colors.white,
    );
  }

  // ⭐ Header Row — modernized
  Widget _buildHeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      color: Colors.grey.shade200,
      child: Row(
        children: const [
          Expanded(flex: 5, child: Text("Unit")),
          Expanded(flex: 4, child: Text("Tenant")),
          Expanded(flex: 1, child: Text("Rent")),
          SizedBox(width: 20),
        ],
      ),
    );
  }

  // ⭐ Modern Unit Grid
  Widget _buildUnitGrid(List<UnitModel> units) {
    final session = context.watch<AppSession>();
    final leases = session.currentLeaseCache;

    return ListView.builder(
      itemCount: units.length,
      itemBuilder: (context, index) {
        final unit = units[index];
        final lease = unit.currentLeaseId != null
            ? leases[unit.currentLeaseId]
            : null;

        final tenantName = lease?.tenantIds.isNotEmpty == true
            ? session.tenantCache[lease!.tenantIds.first]?.name ?? "No Tenant"
            : "Vacant";

        final rent = lease?.rentAmount ?? 0.0;

        final bg = index.isEven ? Colors.white : Colors.grey.shade50;

        return InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              unitDetailsRoute,
              arguments: unit.unitId.toString(),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _unitTypeIcon(unit.type),
                const SizedBox(width: 8),

                // ⭐ UNIT NAME + BED/BATH STACK
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        unit.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        "${unit.bedrooms ?? 0} bed • ${unit.bathrooms ?? 0} bath",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                // ⭐ TENANT NAME
                Expanded(
                  flex: 3,
                  child: Text(
                    tenantName,
                    style: TextStyle(
                      fontSize: 12,
                      color: lease == null ? Colors.red : Colors.black87,
                      fontWeight: lease == null ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),

                // ⭐ RENT — FIXED WIDTH FOR $9999
                SizedBox(
                  width: 60, // enough for "$9999"
                  child: Text(
                    lease == null ? "-" : "\$${rent.toStringAsFixed(0)}",
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),

                const SizedBox(width: 6),
                const Icon(Icons.chevron_right, color: Colors.blue),
              ],
            ),
          ),

        );
      },
    );
  }

  // ⭐ Footer Summary — different colors
  Widget _buildFooterSummary(List<UnitModel> units) {
    final session = context.read<AppSession>();
    final leases = session.currentLeaseCache;

    double totalRent = 0;
    for (final u in units) {
      final lease = u.currentLeaseId != null ? leases[u.currentLeaseId] : null;
      if (lease?.rentAmount != null) {
        totalRent += lease!.rentAmount!;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Text(
            "Total Units: ${units.length}",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          Text(
            "Total Rent: \$${totalRent.toStringAsFixed(0)}",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Icon _unitTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case "garage":
        return const Icon(Icons.garage, color: Colors.black54);
      case "parking":
      case "parking lot":
        return const Icon(Icons.local_parking, color: Colors.black54);
      default:
        return const Icon(Icons.apartment, color: Colors.black54);
    }
  }

  // ⭐ Remove Unit Sheet (unchanged)
  void _showRemoveUnitSheet() {
    final session = context.read<AppSession>();
    final units = session.unitCache.values
        .where((u) => u.propertyId == widget.propertyId && u.isDeleted != true)
        .toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text("Remove Unit",
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: units.map((unit) {
                    final lease = unit.currentLeaseId != null
                        ? session.currentLeaseCache[unit.currentLeaseId]
                        : null;

                    final disabled = lease != null;

                    return ListTile(
                      title: Text(unit.name),
                      subtitle: disabled
                          ? const Text("Active Lease",
                          style: TextStyle(color: Colors.red))
                          : const Text("Vacant"),
                      trailing: disabled
                          ? const Icon(Icons.block, color: Colors.red)
                          : const Icon(Icons.delete, color: Colors.red),
                      onTap: disabled
                          ? null
                          : () async {
                        final unitService =
                        Provider.of<UnitService>(context,
                            listen: false);

                        await unitService.deleteUnit(unit);

                        session.unitCache.remove(unit.unitId);
                        session.notifyListeners();

                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
