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
      appBar: AppBar(title: Text(property.name)),
      body: Column(
        children: [
          _buildPropertyHeader(property, units),
          const SizedBox(height: 12),
          _buildAddRemoveButtons(units.length, expectedUnits),
          _buildFilterChips(),
          _buildHeaderRow(),
          Expanded(child: _buildUnitGrid()),
        ],
      ),
    );
  }

  // ⭐ HEADER — SUMMARY BOX ONLY
  Widget _buildPropertyHeader(PropertyModel property, List<UnitModel> units) {
    final session = context.read<AppSession>();
    final leases = session.currentLeaseCache;

    final occupied = units.where((u) => u.currentLeaseId != null).length;
    final vacant = units.length - occupied;

    final bed1 = units.where((u) => (u.bedrooms ?? 0) == 1).length;
    final bed2 = units.where((u) => (u.bedrooms ?? 0) == 2).length;
    final bed3plus = units.where((u) => (u.bedrooms ?? 0) >= 3).length;

    final other = units.where((u) =>
    u.type.toLowerCase() == "garage" ||
        u.type.toLowerCase() == "parking" ||
        u.type.toLowerCase() == "parking lot" ||
        u.type.toLowerCase() == "storage").length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(property.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(property.address ?? "",
              style: const TextStyle(fontSize: 14, color: Colors.black54)),
          const SizedBox(height: 16),

          // ⭐ SUMMARY GRID
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _summaryBox("Units", units.length.toString()),
              _summaryBox("Vacant", vacant.toString()),
              _summaryBox("Occupied", occupied.toString()),
              _summaryBox("1 Bed", bed1.toString()),
              _summaryBox("2 Bed", bed2.toString()),
              _summaryBox("3+ Bed", bed3plus.toString()),
              _summaryBox("Other", other.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryBox(String label, String value) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ⭐ Add / Remove Buttons
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

  // ⭐ Remove Unit Sheet
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

  // ⭐ Header Row — remove Sq Ft column
  Widget _buildHeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      color: Colors.grey.shade200,
      child: Row(
        children: const [
          Expanded(flex: 3, child: Text("Unit")),
          Expanded(flex: 3, child: Text("Tenant")),
          Expanded(flex: 2, child: Text("Rent")),
          SizedBox(width: 20),
        ],
      ),
    );
  }

  // ⭐ Unit Grid — remove Sq Ft, show Vacant in red
  Widget _buildUnitGrid() {
    final session = context.watch<AppSession>();

    final units = session.unitCache.values
        .where((u) => u.propertyId == widget.propertyId && u.isDeleted != true)
        .toList();

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

                Expanded(
                  flex: 3,
                  child: Text(unit.name,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ),

                Expanded(
                  flex: 3,
                  child: Text(
                    tenantName,
                    style: TextStyle(
                      fontSize: 13,
                      color: lease == null ? Colors.red : Colors.black87,
                      fontWeight:
                      lease == null ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),

                Expanded(
                  flex: 2,
                  child: Text(
                    lease == null
                        ? "-"
                        : "\$${rent.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),

                const Icon(Icons.chevron_right, color: Colors.blue),
              ],
            ),
          ),
        );
      },
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

  // ⭐ Filter Chips
  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _chip("Bed 1", bedFilters),
          _chip("Bed 2", bedFilters),
          _chip("Bed 3+", bedFilters),
          _chip("Other", bedFilters),

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
      label: Text(label),
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
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
