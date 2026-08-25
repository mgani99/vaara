import 'package:flutter/material.dart';
import 'package:my_app/session/app_data.dart';
import 'package:provider/provider.dart';

import 'package:my_app/session/user_role.dart';

import 'package:my_app/property/domain/property_type.dart';
import 'package:my_app/property/domain/property_model.dart';


import 'package:my_app/route/route_constants.dart';
import 'inline_editable_component.dart';
import 'mf_unit_grid.dart';
import 'multi_family_units_page.dart';

class PropertyDashboard extends StatelessWidget {
  const PropertyDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    final theme = Theme.of(context);

    if (session.activeRole != UserRole.landlord.name) {
      return const Center(child: Text("Only landlords can view properties."));
    }

    final properties = session.propertyCache.values.toList();
    final units = session.unitCache.values.toList();
    final leases = session.currentLeaseCache;
    final valuations = session.valuationCache;


    final Map<String, List<UnitModel>> unitsByProperty = {};
    for (final u in units) {
      unitsByProperty.putIfAbsent(u.propertyId, () => []);
      unitsByProperty[u.propertyId]!.add(u);
    }

    final Map<String, Map<String, LeaseDetailsModel?>> leasesByPropertyUnit = {};
    for (final p in properties) {
      final propertyUnits = unitsByProperty[p.propertyId] ?? [];
      final Map<String, LeaseDetailsModel?> unitLeaseMap = {};

      for (final u in propertyUnits) {
        unitLeaseMap[u.unitId] =
        (u.currentLeaseId != null) ? leases[u.currentLeaseId] : null;

      }

      leasesByPropertyUnit[p.propertyId] = unitLeaseMap;
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      body: SafeArea(
        child: Column(
          children: [
            // ------------------------------------------------------------
            // SCROLLABLE CONTENT
            // ------------------------------------------------------------
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    "Properties",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _summaryGrid(
                    properties,
                    units,
                    leasesByPropertyUnit,
                    session.valuationCache,   // ⭐ NEW
                    theme,
                  ),

                  const SizedBox(height: 10),

                  ...properties.map((p) {
                    final units = unitsByProperty[p.propertyId] ?? [];
                    return p.type == mapPropertyType(PropertyType.sfm)
                        ? _sfmCard(
                      context,
                      p,
                      units,
                      leasesByPropertyUnit[p.propertyId]!,
                      theme,
                    )
                        : _mfCard(
                      context,
                      p,
                      units,
                      leasesByPropertyUnit[p.propertyId]!,
                      theme,
                    );
                  }),
                ],
              ),
            ),

            // ------------------------------------------------------------
            // FIXED BOTTOM BUTTON
            // ------------------------------------------------------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50, // ⭐ Same color as "More Lease Details"
                border: Border(
                  top: BorderSide(color: Colors.blue.shade200),
                ),
              ),
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, propertyCreationRoute);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blue.shade300),
                    ),
                    child: Text(
                      "Add Property",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

  }

  // ============================================================
  // TYPE ICON (SFM / MF / COMM)
  // ============================================================
  Widget _typeIcon(String type) {
    String label = "SFM";
    if (type == "multi_family") label = "MF";
    if (type == "commercial") label = "COMM";

    return CircleAvatar(
      radius: 14,
      backgroundColor: Colors.blue.shade50,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _sfmCard(
      BuildContext context,
      PropertyModel property,
      List<UnitModel> units,
      Map<String, LeaseDetailsModel?> leaseMap,
      ThemeData theme,
      ) {
    final unit = units.isNotEmpty ? units.first : null;
    final lease = unit != null ? leaseMap[unit.unitId] : null;

    final bedrooms = unit?.bedrooms ?? 0;
    final bathrooms = unit?.bathrooms ?? 0.0;

    final isOccupied = lease != null;
    final occupancyText = isOccupied ? "Occupied" : "Vacant";

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _typeIcon(property.type),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  property.name,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    propertyDetailsRoute,
                    arguments: {
                      "propertyId": property.propertyId,
                      "readOnly": true,
                    },
                  );
                },
                child: const Icon(Icons.visibility, size: 20, color: Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 0),
                child: Icon(
                  Icons.location_on,
                  size: 28,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.address!,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${property.city}, ${property.state}",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                unitDetailsRoute,
                arguments: unit!.unitId,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue.shade300),
                color: Colors.blue.shade50,
              ),
              child: Text(
                "1 unit",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }


  Widget _summaryGrid(
      List<PropertyModel> properties,
      List<UnitModel> units,
      Map<String, Map<String, LeaseDetailsModel?>> leasesByPropertyUnit,
      Map<String, PropertyValuationModel?> valuations,
      ThemeData theme,
      ) {
    // ------------------------------------------------------------
    // 1. TOTAL PROPERTIES
    // ------------------------------------------------------------
    final totalProperties = properties.length;

    // ------------------------------------------------------------
    // 2. TOTAL VALUE (from valuation.currentValue)
    // ------------------------------------------------------------
    double totalValue = 0;
    for (final p in properties) {
      final val = valuations[p.propertyId];
      if (val?.currentValue != null) {
        totalValue += val!.currentValue!;
      }
    }

    // ------------------------------------------------------------
    // 3. DISTINCT CITIES & STATES
    // ------------------------------------------------------------
    final cities = <String>{};
    final states = <String>{};

    for (final p in properties) {
      if (p.city != null && p.city!.trim().isNotEmpty) cities.add(p.city!.trim());
      if (p.state != null && p.state!.trim().isNotEmpty) states.add(p.state!.trim());
    }

    // ------------------------------------------------------------
    // 4. TOTAL UNITS
    // ------------------------------------------------------------
    final totalUnits = units.length;

    // ------------------------------------------------------------
    // 5 & 6. OCCUPIED / VACANT
    // ------------------------------------------------------------
    int occupied = 0;
    int vacant = 0;

    for (final p in properties) {
      final unitMap = leasesByPropertyUnit[p.propertyId] ?? {};
      for (final lease in unitMap.values) {
        if (lease != null) {
          occupied++;
        } else {
          vacant++;
        }
      }
    }

    // ------------------------------------------------------------
    // UI: TWO ROWS, THREE CARDS EACH
    // ------------------------------------------------------------
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _summaryCard("Total Properties", "$totalProperties")),
            const SizedBox(width: 10),
            Expanded(child: _summaryCard("Total Value", "\$${totalValue.toStringAsFixed(0)}")),
            const SizedBox(width: 10),
            Expanded(child: _summaryCard("Cities / States", "${cities.length} cities • ${states.length} states")),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _summaryCard("Total Units", "$totalUnits")),
            const SizedBox(width: 10),
            Expanded(child: _summaryCard("Occupied", "$occupied")),
            const SizedBox(width: 10),
            Expanded(child: _summaryCard("Vacant", "$vacant")),
          ],
        ),
      ],
    );
  }


// ============================================================
// SUMMARY CARD WIDGET
// ============================================================
  Widget _summaryCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }


  Widget _mfCard(
      BuildContext context,
      PropertyModel property,
      List<UnitModel> units,
      Map<String, LeaseDetailsModel?> leaseMap,
      ThemeData theme,
      ) {
    final totalUnits = units.length;
    final occupiedUnits = units.where((u) => leaseMap[u.unitId] != null).length;
    final vacantUnits = totalUnits - occupiedUnits;


    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // =============================================================
          // HEADER ROW (Row 1)
          // =============================================================
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _typeIcon(property.type),
              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  property.name,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)
                ),
              ),

              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    propertyDetailsRoute,
                    arguments: {
                      "propertyId": property.propertyId,
                      "readOnly": true,
                    },
                  );
                },
                child: const Icon(Icons.visibility, size: 20, color: Colors.blue),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // =============================================================
          // ADDRESS ROW (Row 2)
          // =============================================================
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 0),
                child: Icon(
                  Icons.location_on,
                  size: 28,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(width: 6),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.address!,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${property.city}, ${property.state}",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // =============================================================
          // UNIT COUNT BOX
          // =============================================================
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      MultiFamilyUnitsPage(propertyId: property.propertyId),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue.shade300),
                color: Colors.blue.shade50,
              ),
              child: Text(
                "$totalUnits units",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ),


        ],
      ),
    );
  }


  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(8),
    );
  }
}
