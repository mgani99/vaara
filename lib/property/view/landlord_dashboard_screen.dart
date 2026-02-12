// landlord_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_app/property/controller/landlord_dashboard_controller.dart';
import 'package:my_app/session/app_data.dart';

class LandlordDashboardScreen extends StatefulWidget {
  const LandlordDashboardScreen({super.key});

  @override
  State<LandlordDashboardScreen> createState() =>
      _LandlordDashboardScreenState();
}

class _LandlordDashboardScreenState extends State<LandlordDashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<LandlordDashboardController>().load();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    final controller = context.watch<LandlordDashboardController>();
    final state = controller.state;

    final navDate = session.navigationDate;
    final monthLabel =
        "${navDate.year}-${navDate.month.toString().padLeft(2, '0')}";

    return Scaffold(
      appBar: AppBar(
        title: Text(session.activeOrgName ?? "Portfolio"),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              session.previousMonth();
              controller.load();
            },
          ),
          Center(child: Text(monthLabel)),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              session.nextMonth();
              controller.load();
            },
          ),
        ],
      ),
      body: switch (state) {
        LandlordDashboardLoading _ =>
        const Center(child: CircularProgressIndicator()),
        LandlordDashboardError s =>
            Center(child: Text("Error: ${s.message}")),
        LandlordDashboardLoaded s =>
            _buildContent(context, s.data),
      },
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> data) {
    final totalUnits = data["totalUnits"] as int? ?? 0;
    final occupiedUnits = data["occupiedUnits"] as int? ?? 0;
    final occupancyRate = (data["occupancyRate"] as num?)?.toDouble() ?? 0;
    final tenantCount = data["tenantCount"] as int? ?? 0;
    final expectedRent = (data["expectedRent"] as num?)?.toDouble() ?? 0;
    final receivedRent = (data["receivedRent"] as num?)?.toDouble() ?? 0;
    final outstanding = (data["outstanding"] as num?)?.toDouble() ?? 0;
    final recentPayments =
        (data["recentPayments"] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _summaryCard("Units", "$occupiedUnits / $totalUnits"),
              _summaryCard(
                  "Occupancy", "${(occupancyRate * 100).toStringAsFixed(1)}%"),
              _summaryCard("Tenants", "$tenantCount"),
              _summaryCard("Expected Rent", expectedRent.toStringAsFixed(2)),
              _summaryCard("Received Rent", receivedRent.toStringAsFixed(2)),
              _summaryCard("Outstanding", outstanding.toStringAsFixed(2)),
            ],
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Recent Payments",
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 8),
          ...recentPayments.map((p) {
            final amount = (p["amount"] as num?)?.toDouble() ?? 0;
            final ts = p["timestamp"] as int?;
            final dt =
            ts != null ? DateTime.fromMillisecondsSinceEpoch(ts) : null;
            final dateLabel = dt != null
                ? "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}"
                : "";

            return ListTile(
              title: Text("\$${amount.toStringAsFixed(2)}"),
              subtitle: Text(dateLabel),
            );
          }),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, String value) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
