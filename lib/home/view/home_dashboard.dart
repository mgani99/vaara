import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_app/session/app_data.dart';
import 'package:my_app/portfolio/view/add_portfolio_page.dart';
import '../../portfolio/model/portfolio_repository.dart';
import '../../route/route_constants.dart';

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});



  DateTime parseEpocTime(int epoc) {
    if (epoc!= null && epoc == 0) return DateTime.now();
    return DateTime.fromMicrosecondsSinceEpoch(epoc);
  }
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

    final totalRent = units.fold<double>(0.0, (sum, u) => sum + 300);
    final collectedRent =
    leases.fold<double>(0.0, (sum, l) => sum + (l.rentAmount ?? 0.0));

    // ------------------------------------------------------------
    // ATTENTION NEEDED (limit 5)
    // ------------------------------------------------------------
    final attentionItems = [
      ...units.where((u) => session.currentLeaseCache[u.unitId] == null)
          .map((u) => "Vacant: ${u.name}"),
      ...leases.where((l) {
        if (l.endDateEpoch == 0) return false;
        final parsed = parseEpocTime(l.startDateEpoch);
        if (parsed == 0) return false;
        return parsed.isBefore(DateTime.now().add(const Duration(days: 30)));
      }).map((l) => "Lease expiring soon: ${l.unitId}"),
    ].take(5).toList();

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
            // PORTFOLIOS (Smaller boxes + settings icon)
            // ------------------------------------------------------------
            Text(
              "Portfolios",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 70,
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
                      width: 70,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: const Center(
                        child: Icon(Icons.add, size: 30, color: Colors.blue),
                      ),
                    ),
                  ),

                  // EXISTING PORTFOLIOS
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
                        width: 100,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue.shade50 : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.center,
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

                            // ⭐ Settings icon → go to Portfolio Details
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    portfolioDetailsRoute,
                                    arguments: orgId,
                                  ).then((_) async {
                                    await session.loadOrgScopedData();

                                    final repo = context.read<PortfolioRepository>();
                                    final updated = await repo.getPortfolio(orgId);

                                    if (updated != null) {
                                      session.updateOrganizationName(orgId, updated.name);   // ⭐ FIX
                                      session.setActiveOrgName(updated.name);                // optional
                                    }
                                  });



                                },
                                child: Icon(
                                  Icons.settings,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),

                ],
              ),
            ),

            const SizedBox(height: 20),

            // ------------------------------------------------------------
            // PORTFOLIO OVERVIEW — Summary Cards (no graphs)
            // ------------------------------------------------------------
            Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _tinyKpiCard(title: "Prop#", value: "$propertyCount", icon: Icons.home)),
                    const SizedBox(width: 10),
                    Expanded(child: _tinyKpiCard(title: "Units", value: "$totalUnits", icon: Icons.apartment)),
                    const SizedBox(width: 10),
                    Expanded(child: _tinyKpiCard(
                      title: "Occupancy",
                      value: totalUnits == 0
                          ? "0%"
                          : "${(100 - (((totalUnits - occupiedUnits) / totalUnits) * 100)).toStringAsFixed(1)}%",
                      icon: Icons.percent,
                    )),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(child: _tinyKpiCard(title: "Value", value: "\$3.2M", icon: Icons.attach_money)),
                    const SizedBox(width: 10),
                    Expanded(child: _tinyKpiCard(title: "Gross", value: "\$${totalRent.toStringAsFixed(0)}", icon: Icons.trending_up)),
                    const SizedBox(width: 10),
                    Expanded(child: _tinyKpiCard(title: "Net", value: "\$${collectedRent.toStringAsFixed(0)}", icon: Icons.account_balance_wallet)),
                  ],
                ),
              ],
            ),




            const SizedBox(height: 20),

            // ------------------------------------------------------------
            // ATTENTION NEEDED — scrollable, max 5
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

                  SizedBox(
                    height: 180, // scrollable height
                    child: attentionItems.isEmpty
                        ? Text("All good! No issues right now.",
                        style: theme.textTheme.bodyMedium)
                        : ListView.builder(
                      itemCount: attentionItems.length,
                      itemBuilder: (_, i) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(attentionItems[i]),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ------------------------------------------------------------
            // REMOVE: Top Properties
            // REMOVE: Quick Actions
            // ------------------------------------------------------------


          ],
        ),
      ),
    );
  }

  Widget _tinyKpiCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Icon(icon, size: 14, color: Colors.grey.shade600),
        ],
      ),
    );
  }


}
