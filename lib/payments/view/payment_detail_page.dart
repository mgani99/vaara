import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:my_app/payments/view/payment_form_page.dart';
import 'package:my_app/session/app_data.dart';
import 'package:my_app/utils/export_file.dart';

import '../../property/domain/property_model.dart';
import '../../route/route_constants.dart';
import '../service/payment_service.dart';

class PaymentDetailPage extends StatefulWidget {
  final String unitId;
  final String tenantId;
  final DateTime navigationDate;

  const PaymentDetailPage({
    super.key,
    required this.unitId,
    required this.tenantId,
    required this.navigationDate,
  });

  @override
  State<PaymentDetailPage> createState() => _PaymentDetailPageState();
}

class _PaymentDetailPageState extends State<PaymentDetailPage> {
  late Future<_HeaderBundle> _future;
  DateTime _currentMonth = DateTime.now();
  List<_RowData> _allRows = [];
  bool _loadingMore = false;
  bool _noMoreData = false;

  @override
  void initState() {
    super.initState();
    _currentMonth = widget.navigationDate;
    _future = _loadHeader();

  }

  Future<_HeaderBundle> _loadHeader() async {
    final session = context.read<AppSession>();

    // Ledger month = previous month
    final ledgerMonth = DateTime(
      widget.navigationDate.year,
      widget.navigationDate.month - 1,
      1,
    );

    final unit = session.unitCache[widget.unitId]!;
    final lease = session.currentLeaseCache[unit.currentLeaseId];
    final tenant = session.tenantCache[widget.tenantId]!;

    // Load ledger for previous month
    final monthLedger = await session.getMonthlyLedger(
      session.activeOrgId!,
      ledgerMonth,
    );

    final ledger = monthLedger["${unit.unitId}_${tenant.tenantId}"];
    final beginningBalance = ledger?.endingBalance ?? 0;


    final payments = await session.getPaymentsForMonth(
      session.activeOrgId!,
      widget.navigationDate.year,
      widget.navigationDate.month,
    );

    final filtered = payments.where((p) =>
    p.unitId == widget.unitId &&
        p.tenantId == widget.tenantId
    ).toList();

    filtered.sort((a, b) => b.effectiveDateEpoch.compareTo(a.effectiveDateEpoch));





    double runningBalance = beginningBalance;
    final rows = <_RowData>[];

    for (final p in filtered) {
      final isDebit = p.transactionType == "debit";
      runningBalance += isDebit ? -p.amount : p.amount;

      rows.add(_RowData(payment: p, balance: runningBalance));
    }

    _allRows = rows;   // initialize master list

    return _HeaderBundle(
      unitName: unit.name,
      tenantName: tenant.name,
      tenantPhone: tenant.phone,
      rent: lease?.rentAmount ?? 0,
      leaseEnd: lease == null
          ? "-"
          : DateFormat("MMM dd, yyyy").format(
        DateTime.fromMillisecondsSinceEpoch(
          lease.endDateEpoch,
          isUtc: true,
        ),
      ),
      beginningBalance: beginningBalance,
      rows: _allRows,
    );

  }

  Future<void> _loadPreviousMonth() async {
    if (_loadingMore || _noMoreData) return;

    setState(() => _loadingMore = true);

    final session = context.read<AppSession>();

    // Move to previous month
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);

    final payments = await session.getPaymentsForMonth(
      session.activeOrgId!,
      _currentMonth.year,
      _currentMonth.month,
    );

    // Filter for same unit + tenant
    final filtered = payments.where((p) =>
    p.unitId == widget.unitId &&
        p.tenantId == widget.tenantId
    ).toList();

    if (filtered.isEmpty) {
      setState(() {
        _noMoreData = true;
        _loadingMore = false;
      });
      return;
    }

    // ⭐ Sort DESCENDING inside the month
    filtered.sort((a, b) => b.effectiveDateEpoch.compareTo(a.effectiveDateEpoch));

    // Continue running balance from last known balance
    double runningBalance = _allRows.isNotEmpty
        ? _allRows.last.balance
        : 0;

    // ⭐ Append at the BOTTOM
    for (final p in filtered) {
      final isDebit = p.transactionType == "debit";
      runningBalance += isDebit ? p.amount : -p.amount;

      _allRows.add(_RowData(payment: p, balance: runningBalance));
    }

    setState(() => _loadingMore = false);
  }


  void _openAddPayment(_HeaderBundle header) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentFormPage(
          payment: null,
          unitId: widget.unitId,
          tenantId: widget.tenantId,
        ),
      ),
    );

    setState(() => _future = _loadHeader());
  }

  void _openEditPayment(PaymentModel payment) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentFormPage(payment: payment),
      ),
    );

    setState(() => _future = _loadHeader());
  }

  String _exportLedger(_HeaderBundle header) {
    final fmt = DateFormat("yyyy-MM-dd");
    final buffer = StringBuffer();

    buffer.writeln("Tenant Ledger");
    buffer.writeln("Tenant: ${header.tenantName}");
    buffer.writeln("Unit: ${header.unitName}");
    buffer.writeln("");
    buffer.writeln("Beginning Balance: ${header.beginningBalance}");
    buffer.writeln("");
    buffer.writeln("Date,Amount,Type,Balance");

    for (final row in header.rows) {
      final p = row.payment;
      final date = fmt.format(
        DateTime.fromMillisecondsSinceEpoch(
          p.effectiveDateEpoch,
          isUtc: true,
        ),
      );

      final isDebit = p.transactionType == "debit";
      final amt = isDebit ? p.amount : -p.amount;
      final type = isDebit ? "${p.paymentType} (Charge)" : "${p.paymentType} (Payment)";

      buffer.writeln("$date,$amt,$type,${row.balance.toStringAsFixed(2)}");
    }

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payment Details")),
      body: FutureBuilder<_HeaderBundle>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final header = snap.data!;
          final fmt = NumberFormat("#,##0.00");

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ⭐ HEADER CARD
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          "Lease Details",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              unitDetailsRoute,
                              arguments: widget.unitId,
                            );
                          },
                          child: const Icon(Icons.edit_note, color: Colors.blue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _headerRow("Unit", header.unitName),
                    _headerRow("Tenant", header.tenantName),
                    _headerRow("Rent", "\$${fmt.format(header.rent)}"),
                    _headerRow("Lease End", header.leaseEnd),
                    _headerRow(
                      "Beginning Balance",
                      "\$${fmt.format(header.beginningBalance)}",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Payment History",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 10),

              ..._allRows.map((row) {
                final p = row.payment;
                final date = DateFormat("MMM dd, yyyy").format(
                  DateTime.fromMillisecondsSinceEpoch(
                    p.effectiveDateEpoch,
                    isUtc: true,
                  ),
                );

                final isDebit = p.transactionType == "debit";
                final color = isDebit ? Colors.red : Colors.green;

                return GestureDetector(
                  onTap: () => _openEditPayment(p),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(date,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(
                                "${p.paymentType} • \$${fmt.format(p.amount)}",
                                style: TextStyle(color: color),
                              ),
                              if (p.note.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    p.note,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "\$${fmt.format(row.balance)}",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: row.balance < 0
                                    ? Colors.red
                                    : Colors.black,
                              ),
                            ),
                            const Text(
                              "Balance",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right,
                            color: Colors.black45),
                      ],
                    ),
                  ),
                );
              }),
              if (_noMoreData)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      "No more data",
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: ElevatedButton(
                      onPressed: _loadingMore ? null : _loadPreviousMonth,
                      child: _loadingMore
                          ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Text("Load More"),
                    ),
                  ),
                ),
              const SizedBox(height: 40),
            ],
          );

        },
      ),

      bottomNavigationBar: FutureBuilder<_HeaderBundle>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) return const SizedBox.shrink();
          final header = snap.data!;

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.attach_money, color: Colors.green),
                  label: const Text("+Pay"),
                  onPressed: () => _openAddPayment(header),
                ),
                ActionChip(
                  avatar: const Icon(Icons.receipt_long, color: Colors.blue),
                  label: const Text("Ledger"),
                  onPressed: () {
                    final csv = _exportLedger(header);
                    exportCsv(
                      csv,
                      "ledger_${header.unitName}_${header.tenantName}.csv",
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _headerRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 14, color: Colors.black87)),
          Text(value,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _RowData {
  final PaymentModel payment;
  final double balance;

  _RowData({required this.payment, required this.balance});
}

class _HeaderBundle {
  final String unitName;
  final String tenantName;
  final String tenantPhone;
  final double rent;
  final String leaseEnd;
  final double beginningBalance;
  final List<_RowData> rows;

  _HeaderBundle({
    required this.unitName,
    required this.tenantName,
    required this.tenantPhone,
    required this.rent,
    required this.leaseEnd,
    required this.beginningBalance,
    required this.rows,
  });
}
