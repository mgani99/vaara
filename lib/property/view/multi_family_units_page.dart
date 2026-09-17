import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_app/session/app_data.dart';
import 'package:my_app/property/service/unit_service.dart';
import 'package:my_app/property/domain/property_model.dart';
import 'package:my_app/route/route_constants.dart';
import 'package:url_launcher/url_launcher.dart';

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

      if (b == 0 && u.type.toLowerCase() == "residential") {
        bedCounts["Studio"] = (bedCounts["Studio"] ?? 0) + 1;
      } else if (b == 1) {
        bedCounts["Bed 1"] = (bedCounts["Bed 1"] ?? 0) + 1;
      } else if (b == 2) {
        bedCounts["Bed 2"] = (bedCounts["Bed 2"] ?? 0) + 1;
      } else if (b >= 3) {
        bedCounts["Bed 3+"] = (bedCounts["Bed 3+"] ?? 0) + 1;
      }

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
          ...bedCounts.entries.map(
                (e) => _chip("${e.key} (${e.value})", bedFilters),
          ),
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
          if (label == "All") {
            // Selecting ALL clears other occupancy filters
            if (value) {
              occFilters
                ..clear()
                ..add("All");
            } else {
              occFilters.remove("All");
            }
            return;
          }

          // If selecting Vacant or Occupied → remove ALL
          if (value) {
            occFilters.remove("All");
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
          Expanded(flex: 4, child: Text("Unit")),
          Expanded(flex: 6, child: Text("Tenant")),
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

    // -----------------------------
    // BEDROOM FILTER
    // -----------------------------
    List<UnitModel> filtered = units.where((u) {
      if (bedFilters.isEmpty) return true;

      final b = u.bedrooms ?? 0;
      final type = u.type.toLowerCase();

      bool match = false;

      for (final f in bedFilters) {
        if (f.startsWith("Studio")) {
          if (b == 0) match = true;
        } else if (f.startsWith("Bed 1")) {
          if (b == 1) match = true;
        } else if (f.startsWith("Bed 2")) {
          if (b == 2) match = true;
        } else if (f.startsWith("Bed 3+")) {
          if (b >= 3) match = true;
        } else if (f.startsWith("Other")) {
          if (type == "garage" ||
              type == "parking" ||
              type == "parking lot" ||
              type == "storage") {
            match = true;
          }
        }
      }

      return match;
    }).toList();

    // -----------------------------
    // OCCUPANCY FILTER
    // -----------------------------
    filtered = filtered.where((u) {
      if (occFilters.isEmpty || occFilters.contains("All")) return true;

      final lease = u.currentLeaseId != null
          ? leases[u.currentLeaseId]
          : null;

      final isOccupied = lease != null;

      if (occFilters.contains("Vacant") && !isOccupied) return true;
      if (occFilters.contains("Occupied") && isOccupied) return true;

      return false;
    }).toList();

    // -----------------------------
    // BUILD GRID
    // -----------------------------
    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final unit = filtered[index];
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
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        unit.name,
                        style: const TextStyle(
                          fontSize: 14,
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

                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TENANT NAME WITH ICON
                      Row(
                        children: [
                          const Icon(Icons.person, size: 16, color: Colors.black54),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              tenantName,
                              style: TextStyle(
                                fontSize: 14, // +2pt
                                color: lease == null ? Colors.red : Colors.black87,
                                fontWeight:
                                lease == null ? FontWeight.bold : FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      // TENANT PHONE NUMBER WITH PHONE + SMS ICONS
                      // TENANT PHONE NUMBER WITH PHONE ICON ABOVE AND SMS ICON BELOW
                      if (lease != null &&
                          session.tenantCache[lease.tenantIds.first]?.phone != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // LEFT COLUMN: PHONE ICON ABOVE, SMS ICON BELOW
                              Column(
                                children: [
                                  const Icon(Icons.phone, size: 14, color: Colors.blueGrey),
                                  const SizedBox(height: 4),
                                  GestureDetector(
                                    onTap: () {
                                      final phone =
                                      session.tenantCache[lease.tenantIds.first]!.phone!;
                                      final uri = Uri.parse("sms:$phone");
                                      launchUrl(uri, mode: LaunchMode.externalApplication);
                                    },
                                    child: const Icon(Icons.sms, size: 14, color: Colors.blueGrey),
                                  ),
                                ],
                              ),

                              const SizedBox(width: 8),

                              // PHONE NUMBER IN THE MIDDLE
                              Expanded(
                                child: Text(
                                  session.tenantCache[lease.tenantIds.first]!.phone!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                    ],
                  ),
                ),


                SizedBox(
                  width: 60,
                  child: Text(
                    lease == null ? "-" : "\$${rent.toStringAsFixed(0)}",
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 14,
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
