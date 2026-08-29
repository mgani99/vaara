import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../property/domain/property_model.dart';
import '../../route/route_constants.dart';
import '../../session/app_data.dart';
import '../service/payment_service.dart';

class PaymentDashboardPage extends StatefulWidget {
  const PaymentDashboardPage({super.key});

  @override
  State<PaymentDashboardPage> createState() => _PaymentDashboardPageState();
}

class _PaymentDashboardPageState extends State<PaymentDashboardPage> {
  DateTime selectedMonth =
  DateTime(DateTime.now().year, DateTime.now().month, 1);

  late final PaymentService _service;

  @override
  void initState() {
    super.initState();
    _service = context.read<PaymentService>();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ------------------------------------------------------------
  // FETCH PAYMENTS FOR MONTH
  // ------------------------------------------------------------
  Future<List<PaymentModel>> _loadPayments(BuildContext context) async {
    final session = context.read<AppSession>();
    return await _service.getPaymentsForMonth(
      session.activeOrgId!,
      selectedMonth.year,
      selectedMonth.month,
    );
  }

  // ------------------------------------------------------------
  // SUMMARY CALCULATION
  // ------------------------------------------------------------
  Map<String, double> _computeSummary(
      List<PaymentModel> payments,
      Map<String, UnitModel> units,
      Map<String, LeaseDetailsModel?> leases,
      ) {
    double expected = 0;
    double received = 0;
    double credit = 0;

    for (final unit in units.values) {
      final lease = leases[unit.unitId];
      if (lease != null) {
        expected += lease.rentAmount;
      }
    }

    for (final p in payments) {
      if (p.transactionType == "debit") {
        received += p.amount;
      } else {
        credit += p.amount;
      }
    }

    final pending = expected - received;
    final net = received - credit;

    return {
      "expected": expected,
      "received": received,
      "pending": pending,
      "credit": credit,
      "net": net,
    };
  }

  // ------------------------------------------------------------
  // MONTH NAVIGATION
  // ------------------------------------------------------------
  Widget _buildMonthNav(double received) {
    final monthName = DateFormat('MMMM yyyy').format(selectedMonth);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () {
              setState(() {
                selectedMonth = DateTime(
                  selectedMonth.year,
                  selectedMonth.month - 1,
                  1,
                );
              });
            },
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  monthName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Received: \$${received.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 18),
            onPressed: () {
              setState(() {
                selectedMonth = DateTime(
                  selectedMonth.year,
                  selectedMonth.month + 1,
                  1,
                );
              });
            },
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // SUMMARY BAR
  // ------------------------------------------------------------
  Widget _summaryBox(String title, String value, {Color? color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color ?? Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBar(Map<String, double> totals) {
    final fmt = NumberFormat('#,##0');

    return Column(
      children: [
        Row(
          children: [
            _summaryBox("Expected", "\$${fmt.format(totals["expected"])}"),
            _summaryBox("Received", "\$${fmt.format(totals["received"])}",
                color: Colors.green.shade700),
            _summaryBox("Pending", "\$${fmt.format(totals["pending"])}",
                color: Colors.red.shade700),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _summaryBox("Credit", "\$${fmt.format(totals["credit"])}"),
            _summaryBox("Net", "\$${fmt.format(totals["net"])}",
                color: Colors.blue.shade700),
          ],
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // PROPERTY COLORS
  // ------------------------------------------------------------
  final List<Color> propertyColors = [
    Colors.blue.shade400,
    Colors.green.shade400,
    Colors.orange.shade400,
    Colors.purple.shade400,
    Colors.teal.shade400,
    Colors.indigo.shade400,
  ];

  Widget verticalPropertyLabel(String name, Color color, double height) {
    return Container(
      width: 60,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: RotatedBox(
          quarterTurns: 3,
          child: Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget propertyGroup({
    required PropertyModel property,
    required List<Widget> unitCards,
    required Color color,
  }) {
    final double totalHeight = (unitCards.length * 170).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          verticalPropertyLabel(property.name, color, totalHeight),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: unitCards,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // UNIT PAYMENT CARD
  // ------------------------------------------------------------
  Widget unitPaymentCard({
    required UnitModel unit,
    required TenantModel? tenant,
    required double rentDue,
    required double utilityDue,
    required double pastDue,
    required double payments,
    required double credits,
    required double balance,
    required VoidCallback onOpenDetails,
    required VoidCallback onViewActivity,
  }) {
    final balanceColor =
    balance < 0 ? Colors.red.shade700 : Colors.green.shade700;

    return InkWell(
      onTap: onOpenDetails,
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(unit.name,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(
                      tenant?.name ?? "Vacant",
                      style: TextStyle(
                        fontSize: 12,
                        color: tenant == null ? Colors.red : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.chevron_right, color: Colors.blue),
              ],
            ),
            const SizedBox(height: 12),
            // GRID
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _moneyRow("Rent Due", rentDue),
                      const SizedBox(height: 6),
                      _moneyRow("Utility Due", utilityDue),
                      const SizedBox(height: 6),
                      _moneyRow("Past Due", pastDue,
                          color: Colors.red.shade700),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _moneyRow("Payments", payments,
                          color: Colors.green.shade700),
                      const SizedBox(height: 6),
                      _moneyRow("Credits", credits,
                          color: Colors.red.shade700),
                      const SizedBox(height: 6),
                      _moneyRow("Balance", balance, color: balanceColor),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onViewActivity,
                child: const Text(
                  "View Activity",
                  style: TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _moneyRow(String label, double value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
        Text(
          "\$${value.toStringAsFixed(0)}",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // MAIN UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Payments"),
      ),
      body: FutureBuilder<List<PaymentModel>>(
        future: _loadPayments(context),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final payments = snap.data!;
          final units = session.unitCache;
          final leases = session.currentLeaseCache;
          final tenants = session.tenantCache;
          final properties = session.propertyCache;

          final totals = _computeSummary(payments, units, leases);

          final propertyList = properties.values.toList();

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _buildMonthNav(totals["received"]!),
              const SizedBox(height: 10),
              _buildSummaryBar(totals),
              const SizedBox(height: 20),

              ...List.generate(propertyList.length, (index) {
                final property = propertyList[index];
                final color = propertyColors[index % propertyColors.length];

                final propertyUnits = units.values
                    .where((u) => u.propertyId == property.propertyId)
                    .toList();

                final unitCards = propertyUnits.map((unit) {
                  final lease = leases[unit.currentLeaseId];
                  final tenant =
                  (lease == null || lease.tenantIds.isEmpty)
                      ? null
                      : tenants[lease.tenantIds.first];

                  final unitPayments = payments
                      .where((p) => p.unitId == unit.unitId)
                      .toList();

                  double received = 0;
                  double credit = 0;

                  for (final p in unitPayments) {
                    if (p.transactionType == "debit") {
                      received += p.amount;
                    } else {
                      credit += p.amount;
                    }
                  }

                  final rentDue = lease?.rentAmount ?? 0;
                  final utilityDue = 0; // hook to utilities later
                  final pastDue = 0;    // hook to journal later
                  final balance = rentDue - received - credit;

                  return unitPaymentCard(
                    unit: unit,
                    tenant: tenant,
                    rentDue: rentDue,
                    utilityDue: 0,
                    pastDue: 0,
                    payments: received,
                    credits: credit,
                    balance: balance,
                    onOpenDetails: () {
                      Navigator.pushNamed(
                        context,
                        paymentDetailsRoute,
                        arguments: {
                          "unitId": unit.unitId,
                          "tenantId": tenant?.tenantId,
                          "navigationDate": selectedMonth,
                        },
                      );
                    },
                    onViewActivity: () {
                      Navigator.pushNamed(
                        context,
                        paymentDetailsRoute,
                        arguments: {
                          "unitId": unit.unitId,
                          "month": selectedMonth,
                        },
                      );
                    },
                  );
                }).toList();

                if (unitCards.isEmpty) {
                  return const SizedBox.shrink();
                }

                return propertyGroup(
                  property: property,
                  unitCards: unitCards,
                  color: color,
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
