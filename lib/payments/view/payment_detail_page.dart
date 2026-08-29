import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/payments/view/payment_form_page.dart';
import 'package:my_app/session/app_data.dart';
import 'package:my_app/utils/export_file.dart';
import 'package:provider/provider.dart';

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

  @override
  void initState() {
    super.initState();
    _future = _loadHeader();
  }

  Future<_HeaderBundle> _loadHeader() async {
    final session = context.read<AppSession>();

    final unit = session.unitCache[widget.unitId]!;
    final lease = session.currentLeaseCache[unit.currentLeaseId];
    final tenant = session.tenantCache[widget.tenantId]!;

    final payments = session.paymentCache.values
        .where((p) =>
    p.unitId == widget.unitId &&
        p.tenantId == widget.tenantId &&
        DateTime.fromMillisecondsSinceEpoch(p.paymentDateEpoch)
            .isBefore(DateTime(widget.navigationDate.year,
            widget.navigationDate.month + 1, 1)))
        .toList();

    payments.sort((a, b) =>
        a.paymentDateEpoch.compareTo(b.paymentDateEpoch));

    double runningBalance = 0;
    final rows = <_RowData>[];

    for (final p in payments) {
      final isDebit = p.transactionType == "debit";
      runningBalance += isDebit ? p.amount : -p.amount;

      rows.add(_RowData(
        payment: p,
        balance: runningBalance,
      ));
    }

    return _HeaderBundle(
      unitName: unit.name,
      tenantName: tenant.name,
      tenantPhone: tenant.phone,
      rent: lease?.rentAmount ?? 0,
      leaseEnd: lease == null
          ? "-"
          : DateFormat("MMM dd, yyyy").format(
          DateTime.fromMillisecondsSinceEpoch(lease.endDateEpoch)),
      rows: rows.reversed.toList(),
    );
  }

  void _openAddPayment(_HeaderBundle header) async {
    final payment = PaymentModel(
      paymentId: DateTime.now().millisecondsSinceEpoch.toString(),
      orgId: context.read<AppSession>().activeOrgId!,
      propertyId: null,
      unitId: widget.unitId,
      tenantId: widget.tenantId,
      transactionType: "debit",
      paymentType: "Rent",
      amount: 0,
      paymentDateEpoch: DateTime.now().millisecondsSinceEpoch,
      note: "",
      status: "active",
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentFormPage(
          payment: payment,
        ),
      ),
    );
    final future = _loadHeader();
    setState(() {
      _future = future;
    });


  }

  void _openEditPayment(PaymentModel payment) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentFormPage(
          payment: payment,
        ),
      ),
    );
    final future = _loadHeader();
    setState(() {
      _future = future;
    });

  }

  String _exportLedger(_HeaderBundle header) {
    final fmt = DateFormat("yyyy-MM-dd");
    final buffer = StringBuffer();

    buffer.writeln("Tenant Ledger");
    buffer.writeln("Tenant: ${header.tenantName}");
    buffer.writeln("Unit: ${header.unitName}");
    buffer.writeln("");
    buffer.writeln("Date,Amount,Type,Balance");

    for (final row in header.rows) {
      final p = row.payment;
      final date = fmt.format(
          DateTime.fromMillisecondsSinceEpoch(p.paymentDateEpoch));

      final type = p.transactionType == "debit"
          ? "${p.paymentType} paid"
          : "${p.paymentType} charged";

      final amt = p.transactionType == "debit"
          ? p.amount
          : -p.amount;

      buffer.writeln(
          "$date,$amt,$type,${row.balance.toStringAsFixed(2)}");
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
              // HEADER CARD
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
                          child: const Icon(Icons.edit_note,
                              color: Colors.blue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _headerRow("Unit", header.unitName),
                    _headerRow("Tenant", header.tenantName),
                    _headerRow("Rent", "\$${fmt.format(header.rent)}"),
                    _headerRow("Lease End", header.leaseEnd),
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

              ...header.rows.map((row) {
                final p = row.payment;
                final date = DateFormat("MMM dd, yyyy").format(
                    DateTime.fromMillisecondsSinceEpoch(
                        p.paymentDateEpoch));

                final isDebit = p.transactionType == "debit";
                final color = isDebit ? Colors.green : Colors.red;

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
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
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
                                  padding:
                                  const EdgeInsets.only(top: 4),
                                  child: Text(
                                    p.note,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black87),
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
                                  color: Colors.black54),
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
                  avatar: const Icon(Icons.attach_money,
                      color: Colors.green),
                  label: const Text("+Pay"),
                  onPressed: () => _openAddPayment(header),
                ),
                ActionChip(
                  avatar: const Icon(Icons.receipt_long,
                      color: Colors.blue),
                  label: const Text("Ledger"),
                  onPressed: () {
                    final csv = _exportLedger(header);
                    exportCsv(csv,
                        "ledger_${header.unitName}_${header.tenantName}.csv");
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
              style: const TextStyle(
                  fontSize: 14, color: Colors.black87)),
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
  final List<_RowData> rows;

  _HeaderBundle({
    required this.unitName,
    required this.tenantName,
    required this.tenantPhone,
    required this.rent,
    required this.leaseEnd,
    required this.rows,
  });
}
