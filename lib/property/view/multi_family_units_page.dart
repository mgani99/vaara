import 'package:flutter/material.dart';
import 'package:my_app/session/app_data.dart';
import 'package:provider/provider.dart';

import '../../route/route_constants.dart';
import '../domain/property_model.dart';

class MultiFamilyUnitsPage extends StatefulWidget {
  final String propertyId;

  const MultiFamilyUnitsPage({super.key, required this.propertyId});

  @override
  State<MultiFamilyUnitsPage> createState() => _MultiFamilyUnitsPageState();
}

class _MultiFamilyUnitsPageState extends State<MultiFamilyUnitsPage> {
  late List<UnitModel> units;
  late Map<String, LeaseDetailsModel?> leases;

  final Set<String> bedFilters = {};
  final Set<String> occFilters = {};

  @override
  void initState() {
    super.initState();

  }

  @override
  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    final property = session.propertyCache[widget.propertyId]!;

    return Scaffold(
      appBar: AppBar(title: Text(property.name)),
      body: Column(
        children: [
          _buildPropertyHeader(property),
          const SizedBox(height: 12),
          _buildFilterChips(),
          _buildHeaderRow(),
          Expanded(child: _buildUnitGrid()),
        ],
      ),
    );
  }




  Widget _buildHeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      color: Colors.grey.shade200,
      child: Row(
        children: const [
          Expanded(flex: 3, child: Text("Unit")),
          Expanded(flex: 2, child: Text("Sq Ft")),
          Expanded(flex: 3, child: Text("Tenant")),
          Expanded(flex: 2, child: Text("Rent")),
          SizedBox(width: 20), // Chevron space (tight)
        ],
      ),
    );
  }



  Widget _buildUnitGrid() {
    final session = context.watch<AppSession>();

    final units = session.unitCache.values
        .where((u) => u.propertyId == widget.propertyId)
        .toList();

    final leases = session.currentLeaseCache;

    final filtered = units.where((u) {

      final lease = leases[u.unitId];
      final isOccupied = lease != null && lease.tenantIds.isNotEmpty;

      // OCCUPANCY FILTER
      if (occFilters.isNotEmpty && !occFilters.contains("All")) {
        if (occFilters.contains("Vacant") && isOccupied) return false;
        if (occFilters.contains("Occupied") && !isOccupied) return false;
      }

      // BED FILTER
      if (bedFilters.isNotEmpty) {
        final beds = u.bedrooms ?? 0;

        if (beds == 1 && !bedFilters.contains("Bed 1")) return false;
        if (beds == 2 && !bedFilters.contains("Bed 2")) return false;
        if (beds == 3 && !bedFilters.contains("Bed 3")) return false;
        if (beds >= 4 && !bedFilters.contains("Bed 4+")) return false;

        if ((u.type != "Apartment") && !bedFilters.contains("Other")) return false;
      }

      return true;
    }).toList();

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final unit = filtered[index];
        final lease = leases[unit.currentLeaseId];

        final tenantName = lease?.tenantIds.isNotEmpty == true
            ? session.tenantCache[lease!.tenantIds.first]?.name ?? "No Tenant"
            : "No Tenant";

        final rent = lease?.rentAmount ?? 0.0;

        final bg = index.isEven ? Colors.white : Colors.grey.shade50;

        return InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              unitDetailsRoute,
              arguments: unit.unitId,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
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
                // ⭐ Leading Icon
                _unitTypeIcon(unit.type),
                const SizedBox(width: 8),

                // ⭐ Unit name + bed/bath under it
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(unit.name,
                          style: const TextStyle(
                            fontSize: 12,
                            //fontWeight: FontWeight.w600,
                          )),
                      if (unit.type.toLowerCase() == "apartment")
                        Text(
                          "${unit.bedrooms} bd / ${unit.bathrooms} ba",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        )
                      else
                        const SizedBox.shrink(),

                    ],
                  ),
                ),

                Expanded(flex: 2, child: Text("${unit.sqft ?? 0}")),
                Expanded(flex: 3, child: Text(tenantName)),

                // ⭐ Tighter spacing between rent and chevron
                Expanded(
                  flex: 2,
                  child: Text(
                    "\$${rent.toStringAsFixed(0)}",
                    style: const TextStyle(
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

  Widget _buildPropertyHeader(PropertyModel property) {
    final session = context.read<AppSession>();
    final units = session.unitCache.values
        .where((u) => u.propertyId == property.propertyId)
        .toList();

    final leases = session.currentLeaseCache;
    final occupied = units.where((u) => leases[u.unitId] != null).length;
    final vacant = units.length - occupied;

    final totalRent = units.fold<double>(
      0.0,
          (sum, u) => sum + (leases[u.unitId]?.rentAmount ?? 0.0),
    );

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
          // Property Name
          Text(
            property.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          // Address
          Text(
            "${property.address}",
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),

          const SizedBox(height: 12),

          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${units.length} Units"),
              Text("$occupied Occupied"),
              Text("$vacant Vacant"),
              Text("Total Rent: \$${totalRent.toStringAsFixed(0)}"),
            ],
          ),

          const SizedBox(height: 12),

          // Property Image
          Container(
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: const DecorationImage(
                image: AssetImage("assets/placeholder.jpg"),
                fit: BoxFit.cover,
              ),
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

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _chip("Bed 1", bedFilters),
          _chip("Bed 2", bedFilters),
          _chip("Bed 3", bedFilters),
          _chip("Bed 4+", bedFilters),
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
