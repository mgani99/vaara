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

  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

  bool selectionMode = false;
  final Set<String> selectedUnitIds = {};

  bool isSearching = false;
  final TextEditingController searchController = TextEditingController();
  late final PaymentService _service;
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
    _service = context.read<PaymentService>();   // FIX
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
  // UNIT ROW
  // ------------------------------------------------------------
  Widget _unitRow(
      UnitModel unit,
      LeaseDetailsModel? lease,
      TenantModel? tenant,
      double received,
      double credit,
      ) {
    final isVacant = lease == null;
    final rent = lease?.rentAmount ?? 0;
    final balance = rent - received;

    return InkWell(
      onTap: () {
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

      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
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
        child: Row(
          children: [
            const Icon(Icons.apartment, color: Colors.black54),
            const SizedBox(width: 8),

            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(unit.name,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    isVacant
                        ? "Vacant"
                        : tenant?.name ?? "Tenant",
                    style: TextStyle(
                      fontSize: 12,
                      color: isVacant ? Colors.red : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(
              width: 60,
              child: Text(
                isVacant ? "-" : "\$${rent.toStringAsFixed(0)}",
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 12,
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

          final totals = _computeSummary(payments, units, leases);

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _buildMonthNav(totals["received"]!),
              const SizedBox(height: 10),
              _buildSummaryBar(totals),
              const SizedBox(height: 20),

              ...units.values.map((unit) {
                final lease = leases[unit.currentLeaseId];
                final tenant = (lease == null || lease.tenantIds.isEmpty)
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

                return _unitRow(unit, lease, tenant, received, credit);
              }),
            ],
          );
        },
      ),
    );
  }
}
