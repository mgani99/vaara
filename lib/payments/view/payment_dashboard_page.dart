import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/property/model/tenant_repository.dart';
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
  late AppSession session;
  late final PaymentService _service;
  late final TenantRepository _tenantService;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _service = context.read<PaymentService>();
    _tenantService = context.read<TenantRepository>();
    _searchController.addListener(() {
      setState(() {}); // live filtering
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<PaymentModel>> _loadPayments(BuildContext context) async {
    final session = context.read<AppSession>();
    return await _service.getPaymentsForMonth(
      session.activeOrgId!,
      selectedMonth.year,
      selectedMonth.month,
    );
  }

  Future<Map<String, double>> _computeSummary(
      List<PaymentModel> payments,
      Map<String, UnitModel> units,
      Map<String, LeaseDetailsModel?> leases,
      Map<String, TenantModel> tenants,
      ) async {
    double expected = 0;
    double received = 0;

    final session = context.read<AppSession>();

    final monthLedger = await session.getMonthlyLedger(session.activeOrgId!, DateTime(selectedMonth.year, selectedMonth.month-1, 1));

    // ⭐ Add beginningBalance for each unit+tenant
    for (final unit in units.values) {
      final lease = leases[unit.currentLeaseId];
      if (lease == null || lease.tenantIds.isEmpty) continue;

      final tenantId = lease.tenantIds.first;
      final tenant = tenants[tenantId];
      if (tenant == null) continue;
      final ledger = monthLedger["${unit.unitId}_${tenant.tenantId}"];


      final beginningBalance = ledger?.endingBalance ?? 0;
      expected += beginningBalance;
    }

    // ⭐ Add rent expected/received
    for (final p in payments) {
      final eff = DateTime.fromMillisecondsSinceEpoch(
        p.effectiveDateEpoch,
        isUtc: true,
      );

      final isThisMonth =
          eff.year == selectedMonth.year && eff.month == selectedMonth.month;

      if (p.paymentType == "Rent" && isThisMonth) {
        if (p.transactionType == "debit") {
          expected += p.amount;
        } else if (p.transactionType == "credit") {
          received += p.amount;
        }
      }
    }

    return {
      "expected": expected,
      "received": received,
      "balance": received - expected,
    };
  }

  Widget _tinyKpiCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
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
                fontSize: 13,
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
                fontSize: 11,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Icon(icon, size: 14, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBar(Map<String, double> totals, int rentedCount) {

    final expected = totals["expected"] ?? 0;
    final received = totals["received"] ?? 0;
    final balance = totals["balance"] ?? 0;

    final formatter = NumberFormat("#,##0", "en_US");
    final balanceColor =
    balance < 0 ? Colors.red.shade700 : Colors.green.shade700;

    return Row(
      children: [
        _tinyKpiCard(
          title: "Rented",
          value: rentedCount.toString(),
          icon: Icons.home_work,
        ),
        const SizedBox(width: 2),

        _tinyKpiCard(

          title: "Total Expected",
          value: "\$${formatter.format(expected)}",
          icon: Icons.attach_money,
        ),
        const SizedBox(width: 2),
        _tinyKpiCard(
          title: "Total Received",
          value: "\$${formatter.format(received)}",
          icon: Icons.payments,
        ),
        const SizedBox(width: 2),
        Expanded(
          child: Container(
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
                  "\$${formatter.format(balance)}",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: balanceColor,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  "Balance",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Icon(Icons.account_balance_wallet,
                    size: 14, color: Colors.grey.shade600),
              ],
            ),
          ),
        ),
      ],
    );
  }

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

  bool _matchesSearch(UnitModel unit, TenantModel? tenant, String propertyName) {
    if (!_isSearching || _searchController.text.trim().isEmpty) {
      return true;
    }
    final q = _searchController.text.toLowerCase();
    final unitName = unit.name.toLowerCase();
    final propName = propertyName.toLowerCase();
    final tenantName = (tenant?.name ?? "").toLowerCase();
    return unitName.contains(q) ||
        tenantName.contains(q) ||
        propName.contains(q);
  }

  bool _matchesProperty(PropertyModel property) {
    if (!_isSearching || _searchController.text.trim().isEmpty) {
      return true;
    }

    final q = _searchController.text.toLowerCase();
    return property.name.toLowerCase().contains(q);
  }
  bool get isCurrentMonth {
    final now = DateTime.now();
    return now.year == selectedMonth.year && now.month == selectedMonth.month;
  }


  @override
  Widget build(BuildContext context) {
    session = context.watch<AppSession>();

    return Scaffold(
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

    return FutureBuilder<Map<String, double>>(
    future: _computeSummary(payments, units, leases, tenants),
    builder: (context, totalsSnap) {
    if (!totalsSnap.hasData) {
    return const Center(child: CircularProgressIndicator());
    }

    final totals = totalsSnap.data!;
    final propertyList = properties.values.toList();
    final now = DateTime.now();
    final isCurrentMonth =
        now.year == selectedMonth.year && now.month == selectedMonth.month;

    int rentedCount;

    if (isCurrentMonth) {
      rentedCount = _computeRentedCountCurrentMonth(
        units.values.toList(),
      );
    } else {
      rentedCount = _computeRentedCountHistorical(payments);
    }


    return ListView(
    padding: const EdgeInsets.all(20),
    children: [
    Row(
    children: [
    Expanded(
    child: _isSearching
    ? TextField(
    controller: _searchController,
    autofocus: true,
    decoration: const InputDecoration(
    hintText: "Search payments...",
    border: InputBorder.none,
    ),
    style: const TextStyle(
    fontSize: 16,
    color: Colors.black87,
    ),
    )
        : Text(
    "Payment Tracker",
    style: Theme.of(context)
        .textTheme
        .headlineSmall
        ?.copyWith(
    fontWeight: FontWeight.w700,
    color: Colors.black87,
    ),
    ),
    ),
    const SizedBox(width: 10),
    IconButton(
    icon: Icon(
    _isSearching ? Icons.clear : Icons.search,
    size: 22,
    color: Colors.blue.shade700,
    ),
    onPressed: () {
    setState(() {
    if (_isSearching) _searchController.clear();
    _isSearching = !_isSearching;
    });
    },
    ),
    ],
    ),

    const SizedBox(height: 16),

    _buildMonthNav(totals["received"]!),
    const SizedBox(height: 10),
    _buildSummaryBar(totals, rentedCount),
    const SizedBox(height: 20),
      ...propertyList.where((property) {
        if (_matchesProperty(property)) return true;

        final propertyUnits = units.values
            .where((u) => u.propertyId == property.propertyId)
            .toList();

        if (isCurrentMonth) {
          // CURRENT MONTH → use active lease tenants
          for (final unit in propertyUnits) {
            final lease = leases[unit.currentLeaseId];
            final tenant = (lease == null || lease.tenantIds.isEmpty)
                ? null
                : tenants[lease.tenantIds.first];

            if (_matchesSearch(unit, tenant, property.name)) {
              return true;
            }
          }
        } else {
          // HISTORICAL MONTH → use historical buckets
          for (final p in payments) {
            if (p.unitId == null) continue;

            final unit = units[p.unitId];
            if (unit == null || unit.propertyId != property.propertyId) continue;

            final tenant = tenants[p.tenantId]; // historical tenant loaded earlier
            if (!matchesSearch(unit, tenant)) continue;
            if (_matchesSearch(unit, tenant, property.name)) {
              return true;
            }
          }
        }

        return false;
      })
.map((property) {
        final propertyUnits = units.values
            .where((u) => u.propertyId == property.propertyId)
            .toList();

        return FutureBuilder<List<Widget>>(
          future: _buildUnitCards(
            propertyUnits,
            payments,
            leases,
            tenants,
            session.activeOrgId!,
          ),
          builder: (context, unitSnap) {
            if (!unitSnap.hasData) {
              return const SizedBox.shrink();
            }

            final unitCards = unitSnap.data!;
            if (unitCards.isEmpty) return const SizedBox.shrink();

            return Column(
              children: [
                ...unitCards,
                const SizedBox(height: 10),
              ],
            );
          },
        );
      }),
    ],
    );
    },
    );
    },
        ),
    );
  }
  bool matchesSearch(UnitModel unit, TenantModel? tenant) {
    if (!_isSearching || _searchController.text.trim().isEmpty) return true;

    final q = _searchController.text.toLowerCase();
    final unitName = unit.name.toLowerCase();
    final tenantName = (tenant?.name ?? "").toLowerCase();

    return unitName.contains(q) || tenantName.contains(q);
  }

  int _computeRentedCountCurrentMonth(List<UnitModel> propertyUnits) {
    int count = 0;
    for (final unit in propertyUnits) {
      final lease = session.currentLeaseCache[unit.currentLeaseId];
      if (lease != null && lease.tenantIds.isNotEmpty) {
        count++;
      }
    }
    return count;
  }
  int _computeRentedCountHistorical(List<PaymentModel> payments) {
    final rentedUnits = <String>{};

    for (final p in payments) {
      final eff = DateTime.fromMillisecondsSinceEpoch(
        p.effectiveDateEpoch,
        isUtc: true,
      );

      final isThisMonth =
          eff.year == selectedMonth.year && eff.month == selectedMonth.month;

      if (!isThisMonth) continue;

      if (p.paymentType == "Rent") {
        rentedUnits.add(p.unitId!);
      }
    }

    return rentedUnits.length;
  }

  Future<List<Widget>> _buildUnitCards(
      List<UnitModel> propertyUnits,
      List<PaymentModel> payments,
      Map<String, LeaseDetailsModel?> leases,
      Map<String, TenantModel> tenants,
      String orgId,
      ) async {
    final List<Widget> cards = [];

    final monthLedger = await session.getMonthlyLedger(
      orgId,
      DateTime(selectedMonth.year, selectedMonth.month - 1, 1),
    );

    final now = DateTime.now();
    final isCurrentMonth =
        now.year == selectedMonth.year && now.month == selectedMonth.month;

    // -----------------------------------------------------------
    // Unified search matcher (unit + tenant + property)
    // -----------------------------------------------------------
    bool searchMatch(UnitModel unit, TenantModel? tenant) {
      if (!_isSearching || _searchController.text.trim().isEmpty) return true;

      final q = _searchController.text.toLowerCase();
      final unitName = unit.name.toLowerCase();
      final tenantName = (tenant?.name ?? "").toLowerCase();
      final propertyName =
          session.propertyCache[unit.propertyId]?.name.toLowerCase() ?? "";

      return unitName.contains(q) ||
          tenantName.contains(q) ||
          propertyName.contains(q);
    }

    // -----------------------------------------------------------
    // 🔵 MODE 1: CURRENT MONTH → active units + currentLeaseId
    // -----------------------------------------------------------
    if (isCurrentMonth) {
      for (final unit in propertyUnits) {
        final lease = leases[unit.currentLeaseId];
        if (lease == null || lease.tenantIds.isEmpty) continue;

        final tenantId = lease.tenantIds.first;
        final tenant = tenants[tenantId];
        if (tenant == null) continue;

        if (!searchMatch(unit, tenant)) continue;

        final ledger = monthLedger["${unit.unitId}_${tenant.tenantId}"];
        final beginningBalance = ledger?.endingBalance ?? 0;

        final unitPayments =
        payments.where((p) => p.unitId == unit.unitId).toList();

        double expectedRent = beginningBalance;
        double receivedRent = 0;

        for (final p in unitPayments) {
          final eff = DateTime.fromMillisecondsSinceEpoch(
            p.effectiveDateEpoch,
            isUtc: true,
          );

          final isThisMonth =
              eff.year == selectedMonth.year && eff.month == selectedMonth.month;

          if (p.paymentType == "Rent" && isThisMonth) {
            if (p.transactionType == "debit") {
              expectedRent += p.amount;
            } else if (p.transactionType == "credit") {
              receivedRent += p.amount;
            }
          }
        }

        final balance = receivedRent - expectedRent;

        cards.add(
          ExpandableUnitCard(
            unit: unit,
            tenant: tenant,
            rent: expectedRent - beginningBalance,
            otherDues: 0,
            pastBalance: beginningBalance,
            paid: receivedRent,
            balance: balance,
            onOpenDetails: () {
              Navigator.pushNamed(
                context,
                paymentDetailsRoute,
                arguments: {
                  "unitId": unit.unitId,
                  "tenantId": tenant.tenantId,
                  "navigationDate": selectedMonth,
                },
              );
            },
          ),
        );
      }

      return cards;
    }

    // -----------------------------------------------------------
    // 🔴 MODE 2: HISTORICAL MONTH → PaymentModel.unitId + tenantId
    // -----------------------------------------------------------

    final Map<String, _HistoricalBucket> buckets = {};

    for (final p in payments) {
      final eff = DateTime.fromMillisecondsSinceEpoch(
        p.effectiveDateEpoch,
        isUtc: true,
      );

      final isThisMonth =
          eff.year == selectedMonth.year && eff.month == selectedMonth.month;

      if (!isThisMonth) continue;

      final unit = session.unitCache[p.unitId];
      if (unit == null) continue;

      // Load historical tenant
      TenantModel? tenant;

      if (p.tenantId != null) {
        tenant = tenants[p.tenantId];

        if (tenant == null) {
          tenant = await _tenantService.getTenant(
            session.activeOrgId!,
            p.tenantId!,
          );

          if (tenant != null) {
            tenants[p.tenantId!] = tenant;
          }
        }
      }

      if (tenant == null) {
        print("HISTORICAL PAYMENT MISSING TENANT → UNIT: ${unit.name}");
      }

      final key = "${unit.unitId}_${tenant?.tenantId ?? 'NO_TENANT'}";

      buckets.putIfAbsent(key, () => _HistoricalBucket(unit, tenant, p.tenantId!));


      if (p.paymentType == "Rent") {
        if (p.transactionType == "debit") {
          buckets[key]!.expected += p.amount;
        } else if (p.transactionType == "credit") {
          buckets[key]!.received += p.amount;
        }
      }
    }

    // -----------------------------------------------------------
    // Sort historical buckets using current unit order
    // -----------------------------------------------------------
    final orderedUnits = session.unitCache.values.toList();
    final unitOrderIndex = {
      for (int i = 0; i < orderedUnits.length; i++)
        orderedUnits[i].unitId: i
    };

    final sortedKeys = buckets.keys.toList()
      ..sort((a, b) {
        final unitA = buckets[a]!.unit;
        final unitB = buckets[b]!.unit;

        final idxA = unitOrderIndex[unitA.unitId] ?? 99999;
        final idxB = unitOrderIndex[unitB.unitId] ?? 99999;

        return idxA.compareTo(idxB);
      });

    // -----------------------------------------------------------
    // Build historical cards
    // -----------------------------------------------------------
    for (final key in sortedKeys) {
      final bucket = buckets[key];

      if (!searchMatch(bucket!.unit, bucket.tenant)) continue;

      final ledgerKey = "${bucket.unit.unitId}_${bucket.tenant?.tenantId}";
      final ledger = monthLedger[ledgerKey];
      final beginningBalance = ledger?.endingBalance ?? 0;

      final totalExpected = beginningBalance + bucket.expected;
      final balance = bucket.received - totalExpected;

      cards.add(
        ExpandableUnitCard(
          unit: bucket.unit,
          tenant: bucket.tenant,
          rent: bucket.expected,
          otherDues: 0,
          pastBalance: beginningBalance,
          paid: bucket.received,
          balance: balance,
          onOpenDetails: () {
            Navigator.pushNamed(
              context,
              paymentDetailsRoute,
              arguments: {
                "unitId": bucket.unit.unitId!,
                "tenantId": bucket.tenantId,
                "navigationDate": selectedMonth,
              },
            );
          },
        ),
      );
    }

    return cards;
  }



}

class _HistoricalBucket {
  final UnitModel unit;
  final TenantModel? tenant;
  final String tenantId;

  double expected = 0;
  double received = 0;

  _HistoricalBucket(this.unit, this.tenant, this.tenantId);
}

class ExpandableUnitCard extends StatefulWidget {
  final UnitModel unit;
  final TenantModel? tenant;

  final double rent;
  final double otherDues;
  final double pastBalance;
  final double paid;
  final double balance;

  final VoidCallback onOpenDetails;

  const ExpandableUnitCard({
    super.key,
    required this.unit,
    required this.tenant,
    required this.rent,
    required this.otherDues,
    required this.pastBalance,
    required this.paid,
    required this.balance,
    required this.onOpenDetails,
  });

  @override
  State<ExpandableUnitCard> createState() => _ExpandableUnitCardState();
}

class _ExpandableUnitCardState extends State<ExpandableUnitCard> {
  bool expandDues = false;
  bool expandPayments = false;

  void _showTenantMenu() {
    final tenant = widget.tenant;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.attach_money, size: 20),
                title: const Text("Pay Rent", style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement Pay Rent
                },
              ),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet, size: 20),
                title: const Text("Pay Current Balance", style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement Pay Current Balance
                },
              ),
              ListTile(
                leading: const Icon(Icons.phone, size: 20),
                title: const Text("Call Tenant", style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement Call Tenant
                },
              ),
              ListTile(
                leading: const Icon(Icons.sms, size: 20),
                title: const Text("Text Tenant", style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement Text Tenant
                },
              ),
            ],
          ),
        );
      },
    );
  }
  IconData get _tenantIcon => Icons.person;

  @override
  Widget build(BuildContext context) {
    final duesColor = Colors.red.shade700;
    final paymentColor = Colors.green.shade700;
    final balanceColor =
    widget.balance >= 0 ? Colors.green.shade700 : Colors.red.shade700;

    final tenantFullName = widget.tenant?.name ?? "Vacant";
    final tenantFirstName = tenantFullName.split(" ").first;

    final totalDues =
        widget.rent + widget.otherDues + widget.pastBalance;

    return GestureDetector(
      onTap: widget.onOpenDetails,
      onLongPress: _showTenantMenu,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade500),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ---------------------------------------------------------
            // UNIT NAME + FIRST NAME
            // ---------------------------------------------------------
            // ---------------------------------------------------------
// UNIT NAME WITH ICON
// ---------------------------------------------------------
            Row(
              children: [
                Icon(
                  _unitTypeIcon(widget.unit.type),
                  size: 16,
                  color: Colors.blueGrey.shade700,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.unit.name,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

// ---------------------------------------------------------
// TENANT FULL NAME WITH ICON
// ---------------------------------------------------------
            Row(
              children: [
                Icon(
                  _tenantIcon,
                  size: 16,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 6),
                Text(
                  tenantFullName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),


            const SizedBox(height: 1),

            // ---------------------------------------------------------
            // EXPECTED + BALANCE ROW
            // ---------------------------------------------------------
            Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => expandDues = !expandDues),
                  child: Icon(
                    expandDues
                        ? Icons.remove_circle_outline
                        : Icons.add_circle_outline,
                    size: 18,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 6),

                Expanded(
                  child: Text(
                    "Expected  \$${totalDues.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "\$${widget.balance.toStringAsFixed(0)}",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: balanceColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      "Balance",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 6),
                const Icon(Icons.chevron_right,
                    size: 18, color: Colors.blue),
              ],
            ),

            // ---------------------------------------------------------
            // EXPANDED DUES
            // ---------------------------------------------------------
            if (expandDues) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detailRow("Past Due", widget.pastBalance,
                        color: duesColor),
                    const SizedBox(height: 6),
                    _detailRow("Rent", widget.rent, color: duesColor),
                    const SizedBox(height: 6),
                    _detailRow("Late fees", widget.otherDues,
                        color: duesColor),
                    const SizedBox(height: 6),
                    _detailRow("Utilities", widget.pastBalance,
                        color: duesColor),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 3),

            // ---------------------------------------------------------
            // RECEIVED ROW
            // ---------------------------------------------------------
            Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => expandPayments = !expandPayments),
                  child: Icon(
                    expandPayments
                        ? Icons.remove_circle_outline
                        : Icons.add_circle_outline,
                    size: 18,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    "Received  \$${widget.paid.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),

            // ---------------------------------------------------------
            // EXPANDED PAYMENTS
            // ---------------------------------------------------------
            if (expandPayments) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Column(
                  children: [
                    _detailRow("Paid", widget.paid, color: paymentColor),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }IconData _unitTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case "parking":
        return Icons.local_parking;        // 🅿️ Parking
      case "garage":
        return Icons.garage;               // 🚗 Garage
      case "other":
        return Icons.store_mall_directory; // 🏬 Other / Commercial
      case "residential":
      default:
        return Icons.home_work;            // 🏠 Default Residential
    }
  }



  Widget _detailRow(String label, double value, {Color? color}) {
    return Wrap(
      spacing: 8,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.black87)),
        Text(
          "\$${value.toStringAsFixed(0)}",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
