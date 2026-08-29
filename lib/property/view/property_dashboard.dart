import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_app/session/app_data.dart';
import 'package:my_app/session/user_role.dart';

import 'package:my_app/property/domain/property_model.dart';
import 'package:my_app/property/domain/property_type.dart';

import 'package:my_app/route/route_constants.dart';
import 'multi_family_units_page.dart';

/// ===============================================================
/// PROPERTY DASHBOARD — GLOBAL TOGGLE + CARD WRAPPER
/// ===============================================================
class PropertyDashboard extends StatefulWidget {
  const PropertyDashboard({super.key});

  @override
  State<PropertyDashboard> createState() => _PropertyDashboardState();
}

class _PropertyDashboardState extends State<PropertyDashboard> {
  bool showFinance = false; // GLOBAL TOGGLE

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

    // Group units by property
    final Map<String, List<UnitModel>> unitsByProperty = {};
    for (final u in units) {
      unitsByProperty.putIfAbsent(u.propertyId, () => []);
      unitsByProperty[u.propertyId]!.add(u);
    }

    // Group leases by property + unit
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
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // HEADER
                  Text(
                    "Properties",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ⭐ GLOBAL TOGGLE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text("Operations"),
                        selected: !showFinance,
                        onSelected: (_) {
                          setState(() => showFinance = false);
                        },
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text("Finance"),
                        selected: showFinance,
                        onSelected: (_) {
                          setState(() => showFinance = true);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  /// SUMMARY GRID
                  _summaryGrid(
                    context,
                    properties,
                    units,
                    leasesByPropertyUnit,
                    valuations,
                    theme,
                  ),

                  const SizedBox(height: 10),

                  /// PROPERTY CARDS
                  ...properties.map((p) {
                    final propertyUnits = unitsByProperty[p.propertyId] ?? [];
                    final leaseMap = leasesByPropertyUnit[p.propertyId]!;

                    return _propertyCard(
                      context,
                      p,
                      propertyUnits,
                      leaseMap,
                      showFinance,
                    );
                  }),
                ],
              ),
            ),

            /// ADD PROPERTY BUTTON
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border(top: BorderSide(color: Colors.blue.shade200)),
              ),
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, propertyCreationRoute);
                  },
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
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

  /// ===============================================================
  /// PROPERTY CARD WRAPPER
  /// ===============================================================
  Widget _propertyCard(
      BuildContext context,
      PropertyModel property,
      List<UnitModel> units,
      Map<String, LeaseDetailsModel?> leaseMap,
      bool showFinance,
      ) {
    final isSfm = property.type == mapPropertyType(PropertyType.sfm);
    final totalUnits = units.length;
    final occupiedUnits =
        units.where((u) => leaseMap[u.unitId] != null).length;

    // Accent color
    final Color accentColor = {
      "single_family": Colors.green.shade400,
      "multi_family": Colors.purple.shade400,
      "commercial": Colors.orange.shade400,
    }[property.type] ?? Colors.blue.shade400;

    return PropertyDashboardCard(
      showFinance: showFinance,
      propertyId: property.propertyId,
      name: property.name,
      type: property.type,
      address: property.address,
      city: property.city,
      state: property.state,
      totalUnits: totalUnits,
      occupiedUnits: occupiedUnits,
      accentColor: accentColor,
      onViewProperty: () {
        Navigator.pushNamed(
          context,
          propertyDetailsRoute,
          arguments: {
            "propertyId": property.propertyId,
            "readOnly": true,
          },
        );
      },
      onOpenUnits: () {
        if (isSfm) {
          final unit = units.first;
          Navigator.pushNamed(
            context,
            unitDetailsRoute,
            arguments: unit.unitId,
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  MultiFamilyUnitsPage(propertyId: property.propertyId),
            ),
          );
        }
      },
    );
  }

  /// ===============================================================
  /// SUMMARY GRID (unchanged)
  /// ===============================================================
  Widget _summaryGrid(
      context,
      List<PropertyModel> properties,
      List<UnitModel> units,
      Map<String, Map<String, LeaseDetailsModel?>> leasesByPropertyUnit,
      Map<String, PropertyValuationModel?> valuations,
      ThemeData theme,
      ) {
    final totalProperties = properties.length;

    double totalValue = 0;
    for (final p in properties) {
      final val = valuations[p.propertyId];
      if (val?.currentValue != null) {
        totalValue += val!.currentValue!;
      }
    }

    String totalValueFormatted;
    if (totalValue >= 1000000) {
      totalValueFormatted = "${(totalValue / 1000000).toStringAsFixed(2)}M";
    } else {
      totalValueFormatted = "${(totalValue / 1000).toStringAsFixed(1)}K";
    }

    final cities = <String>{};
    for (final p in properties) {
      if (p.city != null && p.city!.trim().isNotEmpty) {
        cities.add(p.city!.trim());
      }
    }

    final totalUnits = units.length;

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

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                icon: Icons.home,
                title: "Property Count",
                value: "$totalProperties",
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _summaryCard(
                icon: Icons.attach_money,
                title: "Total Value",
                value: "\$$totalValueFormatted",
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _summaryCard(
                icon: Icons.location_pin,
                title: "Cities",
                value: "${cities.length}",
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                icon: Icons.apartment,
                title: "Unit Count",
                value: "$totalUnits",
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _summaryCard(
                icon: Icons.check_circle,
                title: "Occupied",
                value: "$occupied",
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _summaryCard(
                icon: Icons.cancel,
                title: "Vacant",
                value: "$vacant",
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Icon(icon, size: 16, color: Colors.grey.shade600),
        ],
      ),
    );
  }
}
/// ===============================================================
/// FLIPPABLE PROPERTY CARD — STATEFUL WITH LOCAL FLIP
/// ===============================================================
class PropertyDashboardCard extends StatefulWidget {
  final bool showFinance;
  final String propertyId;
  final String name;
  final String type;
  final String? address;
  final String? city;
  final String? state;
  final int totalUnits;
  final int occupiedUnits;
  final Color accentColor;
  final VoidCallback onViewProperty;
  final VoidCallback onOpenUnits;

  const PropertyDashboardCard({
    super.key,
    required this.showFinance,
    required this.propertyId,
    required this.name,
    required this.type,
    required this.address,
    required this.city,
    required this.state,
    required this.totalUnits,
    required this.occupiedUnits,
    required this.accentColor,
    required this.onViewProperty,
    required this.onOpenUnits,
  });

  @override
  State<PropertyDashboardCard> createState() => _PropertyDashboardCardState();
}

class _PropertyDashboardCardState extends State<PropertyDashboardCard> {
  bool localFlip = false; // ⭐ LOCAL FLIP STATE

  @override
  Widget build(BuildContext context) {
    // ⭐ Combined flip logic
    final showFinance = widget.showFinance || localFlip;

    return GestureDetector(
      onTap: widget.onViewProperty,   // ⭐ NEW — whole card is clickable
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) {
          final rotate = Tween(begin: pi, end: 0.0).animate(animation);

          return AnimatedBuilder(
            animation: rotate,
            builder: (context, _) {
              final tilt = (rotate.value > pi / 2) ? pi : 0.0;

              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(rotate.value + tilt),
                child: child,
              );
            },
          );
        },
        child: showFinance
            ? _financeCard(context, key: const ValueKey(true))
            : _operationsCard(context, key: const ValueKey(false)),
      ),
    );

  }

  // ===============================================================
  // FRONT SIDE — OPERATIONS VIEW
  // ===============================================================
  Widget _operationsCard(BuildContext context, {required Key key}) {
    final isSfm = widget.type == "single_family";
    final vacantUnits = widget.totalUnits - widget.occupiedUnits;

    return Container(
      key: key,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: widget.accentColor, width: 3)),
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER + LOCAL FLIP ICON
          Row(
            children: [
              _typeIcon(widget.type),
              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  widget.name,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // ⭐ LOCAL FLIP ICON
              GestureDetector(
                onTap: () => setState(() => localFlip = !localFlip),
                child: Icon(Icons.change_circle_outlined, color: Colors.blue.shade700),
              ),
            ],
          ),

          const SizedBox(height: 8),
          _addressBlock(),

          const Divider(height: 14),

          Row(
            children: [
              GestureDetector(
                onTap: widget.onOpenUnits,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.grey.shade200,
                  ),
                  child: Text(
                    isSfm ? "1 unit" : "${widget.totalUnits} units",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // ⭐ Occupied/vacant styling
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                  children: [
                    TextSpan(
                      text: "${widget.occupiedUnits} occupied",
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const TextSpan(
                      text: " • ",
                      style: TextStyle(color: Colors.grey),
                    ),
                    TextSpan(
                      text: "$vacantUnits vacant",
                      style: TextStyle(
                        color: vacantUnits > 0
                            ? Colors.red.shade700
                            : Colors.grey,
                      ),
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

  // ===============================================================
  // BACK SIDE — FINANCE VIEW
  // ===============================================================
  Widget _financeCard(BuildContext context, {required Key key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: widget.accentColor, width: 3)),
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER + LOCAL FLIP ICON
          Row(
            children: [
              Expanded(
                child: Text(
                  "${widget.name} — Financials",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              // ⭐ LOCAL FLIP ICON
              GestureDetector(
                onTap: () => setState(() => localFlip = !localFlip),
                child: Icon(
                  Icons.change_circle_outlined,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          _financeRow("Gross Rent (YTD)", "\$32,400"),
          _financeRow("Expenses (YTD)", "\$8,900"),
          _financeRow("Net (YTD)", "\$23,500"),

          const SizedBox(height: 12),

          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, paymentDashboardRoute);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.blue.shade200,
              ),
              child: const Text(
                "Open Rent Roll",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _financeRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 12)),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _addressBlock() {
    return Row(
      children: [
        Icon(Icons.location_on, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.address != null)
                Text(widget.address!, style: const TextStyle(fontSize: 13)),
              if (widget.city != null && widget.state != null)
                Text(
                  "${widget.city}, ${widget.state}",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _typeIcon(String type) {
    String label = "SFM";
    if (type == "multi_family") label = "MF";
    if (type == "commercial") label = "COMM";

    return CircleAvatar(
      radius: 13,
      backgroundColor: Colors.green.shade100,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
