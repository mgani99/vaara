import 'package:flutter/material.dart';
import 'package:my_app/property/domain/unit_model.dart';
import 'package:my_app/property/service/property_service.dart';
import 'package:my_app/property/service/unit_service.dart';
import 'package:my_app/session/user_role.dart';
import 'package:provider/provider.dart';

import 'package:my_app/session/app_data.dart';

import '../domain/property_model.dart';


class PropertyDashboard extends StatefulWidget {
  const PropertyDashboard({super.key});

  @override
  State<PropertyDashboard> createState() => _PropertyDashboardState();
}

class _PropertyDashboardState extends State<PropertyDashboard> {
  final PropertyService _propertyService = PropertyService();
  final UnitService _unitService = UnitService();

  bool loading = true;
  List<PropertyModel> properties = [];
  Map<String, List<UnitModel>> unitsByProperty = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final session = context.read<AppSession>();
    final orgId = session.activeOrgId;

    if (orgId == null) return;

    // Load properties
    final props = await _propertyService.getProperties(orgId);

    // Load units for each property
    final Map<String, List<UnitModel>> unitMap = {};
    for (final p in props) {
      final units = await _unitService.getUnitsForProperty(orgId, p.propertyId);
      unitMap[p.propertyId] = units;
    }

    setState(() {
      properties = props;
      unitsByProperty = unitMap;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    final theme = Theme.of(context);

    if (session.activeRole ==  UserRole.landlord) {
      return const Center(child: Text("Only landlords can view properties."));
    }

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            "Your Properties",
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 16),

          ElevatedButton.icon(
            icon: const Icon(Icons.add_home),
            label: const Text("Add Property"),
            onPressed: () {
              Navigator.pushNamed(context, "/onboardingAddProperty")
                  .then((_) => _load());
            },
          ),

          const SizedBox(height: 20),

          ...properties.map((p) => _propertyCard(context, p, theme)),
        ],
      ),
    );
  }

  Widget _propertyCard(
      BuildContext context, PropertyModel property, ThemeData theme) {
    final units = unitsByProperty[property.propertyId] ?? [];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  property.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_business),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      "/onboardingAddUnits",
                      arguments: property.propertyId,
                    ).then((_) => _load());
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Units
            if (units.isEmpty)
              Text(
                "No units added yet.",
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
              )
            else
              Column(
                children: units.map((u) => _unitTile(u, theme)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _unitTile(UnitModel unit, ThemeData theme) {
    final occupied = false; // You will replace this with tenant assignment later

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        occupied ? Icons.person : Icons.meeting_room,
        color: occupied ? Colors.green : Colors.grey,
      ),
      title: Text(unit.name),
      subtitle: Text(
        "${unit.bedrooms} bd • ${unit.bathrooms} ba • \$${unit.rentAmount.toStringAsFixed(0)}",
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
