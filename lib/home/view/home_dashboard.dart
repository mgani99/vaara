import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_app/session/app_data.dart';
import 'package:my_app/portfolio/view/add_portfolio_page.dart';

import '../../route/route_constants.dart';

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    final theme = Theme.of(context);

    if (session.user == null || session.activeOrgId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final name = session.user!.fullName;

    // ------------------------------------------------------------
    // CALCULATIONS
    // ------------------------------------------------------------
    final units = session.unitCache.values.toList();
    final leases = session.currentLeaseCache.values.toList();
    final properties = session.propertyCache.values.toList();

    final totalUnits = units.length;
    final occupiedUnits = leases.length;
    final propertyCount = properties.length;

    final totalRent = units.fold<double>(0.0, (sum, u) => sum + (300));
    final collectedRent =
    leases.fold<double>(0.0, (sum, l) => sum + (l.rentAmount ?? 0.0));

    final occupancyPercent =
    totalUnits == 0 ? 0.0 : (occupiedUnits / totalUnits).clamp(0.0, 1.0);

    final rentPercent =
    totalRent == 0 ? 0.0 : (collectedRent / totalRent).clamp(0.0, 1.0);

    // ------------------------------------------------------------
    // ATTENTION NEEDED
    // ------------------------------------------------------------
    final attentionItems = [
      ...units.where((u) => session.currentLeaseCache[u.unitId] == null)
          .map((u) => "Vacant: ${u.name}"),
      ...leases.where((l) {
        if (l.endDateEpoch == 0) return false;
        final parsed = l.parseEpocTime(l.startDateEpoch);
        if (parsed == 0) return false;
        return parsed.isBefore(DateTime.now().add(const Duration(days: 30)));
      }).map((l) => "Lease expiring soon: ${l.unitId}"),
    ].take(5).toList();

    // ------------------------------------------------------------
    // TOP 5 PROPERTIES (FIRST 5)
    // ------------------------------------------------------------
    final topProperties = properties.take(5).toList();

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ------------------------------------------------------------
            // HEADER
            // ------------------------------------------------------------
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Welcome $name",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    session.activeOrgName!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ------------------------------------------------------------
            // PORTFOLIOS (Horizontal Scroll)
            // ------------------------------------------------------------
            Text(
              "Portfolios",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 80,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  const SizedBox(width: 4),

                  // ADD PORTFOLIO FIRST
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddPortfolioPage(),
                        ),
                      );
                    },
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: const Center(
                        child: Icon(Icons.add, size: 36, color: Colors.blue),
                      ),
                    ),
                  ),

                  // EXISTING PORTFOLIOS (NO PROPERTY COUNT)
                  ...session.organizations.map((org) {
                    final orgId = org["orgId"];
                    final name = org["name"];
                    final bool isSelected = session.activeOrgId == orgId;

                    return GestureDetector(
                      onTap: () async {
                        session.setActiveOrg(orgId);
                        session.setActiveOrgName(name);
                        session.clearOrgScopedData();
                        await session.loadOrgScopedData();
                      },
                      child: Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue.shade50 : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.grey.shade300,
                            width: isSelected ? 2.5 : 1.0,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.blue.shade800
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ------------------------------------------------------------
            // PORTFOLIO OVERVIEW (Shaded Box)
            // ------------------------------------------------------------
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white60,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Portfolio Overview",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // PROPERTY + UNIT COUNT
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Properties: $propertyCount",
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        "Units: $totalUnits",
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // CHARTS ROW
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text("Occupancy",
                                style: theme.textTheme.titleMedium),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 120,
                              width: 120,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: occupancyPercent,
                                    strokeWidth: 10,
                                    backgroundColor: Colors.grey.shade300,
                                    color: Colors.green.shade600,
                                  ),
                                  Text(
                                    "${(occupancyPercent * 100).toStringAsFixed(0)}%",
                                    style: theme.textTheme.titleLarge,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text("$occupiedUnits occupied / $totalUnits units"),
                          ],
                        ),
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: Column(
                          children: [
                            Text("Rent Collection",
                                style: theme.textTheme.titleMedium),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 120,
                              width: 120,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: rentPercent,
                                    strokeWidth: 10,
                                    backgroundColor: Colors.grey.shade300,
                                    color: Colors.blue.shade600,
                                  ),
                                  Text(
                                    "${(rentPercent * 100).toStringAsFixed(0)}%",
                                    style: theme.textTheme.titleLarge,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text("Collected: \$${collectedRent.toStringAsFixed(0)}"),
                            Text(
                              "Total: \$${totalRent.toStringAsFixed(0)}",
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ------------------------------------------------------------
            // ATTENTION NEEDED (Shaded Box)
            // ------------------------------------------------------------
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white60,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Attention Needed",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (attentionItems.isEmpty)
                    Text("All good! No issues right now.",
                        style: theme.textTheme.bodyMedium)
                  else
                    ...attentionItems.map((item) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(item),
                      );
                    }).toList(),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ------------------------------------------------------------
            // TOP 5 PROPERTIES (Shaded Box)
            // ------------------------------------------------------------
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white60,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Top Properties",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...topProperties.map((property) {
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            propertyDetailsRoute,
                            arguments: property.propertyId,
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                property.name,
                                style: theme.textTheme.titleMedium,
                              ),
                              Text(
                                "\$${property.totalRent.toStringAsFixed(0)}",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),

                  // ADD PROPERTY ICON
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, propertyCreationRoute);
                    },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: const Center(
                        child: Icon(Icons.add, size: 30, color: Colors.blue),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ------------------------------------------------------------
            // QUICK ACTIONS (Only Add Property + Record Payment)
            // ------------------------------------------------------------
            Text("Quick Actions", style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_home),
                  label: const Text("Add Property"),
                  onPressed: () {
                    Navigator.pushNamed(context, propertyCreationRoute);
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.payments),
                  label: const Text("Record Payment"),
                  onPressed: () {},
                ),
              ],
            ),

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, propertyDashboardRoute);
              },
              child: const Text("View All Properties"),
            ),
          ],
        ),
      ),
    );
  }
}
