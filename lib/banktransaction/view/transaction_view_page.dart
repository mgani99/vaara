import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/property/domain/property_model.dart';
import 'package:provider/provider.dart';


import 'package:my_app/session/app_data.dart';
import 'package:my_app/portfolio/model/linked_bank_repository.dart';

class TransactionViewPage extends StatefulWidget {
  final String institutionName;
  final String accountId;

  const TransactionViewPage({
    super.key,
    required this.institutionName,
    required this.accountId,
  });

  @override
  State<TransactionViewPage> createState() => _TransactionViewPageState();
}

class _TransactionViewPageState extends State<TransactionViewPage> {
  List<PlaidTransaction> transactions = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final session = context.read<AppSession>();
    final repo = context.read<LinkedBankRepository>();

    final orgId = session.activeOrgId!;

    final userId = await repo.findUserIdForAccount(
      orgId: orgId,
      institutionName: widget.institutionName,
      acctId: widget.accountId,
    );

    final today = DateTime.now();
    final dayKey =
        "${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}";

    final txList = await repo.getDailyTransactions(
      orgId: orgId,
      userId: userId!,
      institutionName: widget.institutionName,
      accountId: widget.accountId,
      dayKey: dayKey,
    );
    txList.sort((a, b) => b.date.compareTo(a.date));
    setState(() {
      transactions = txList;
      loading = false;
    });
  }

  String formatFancyDate(DateTime date) {
    final day = date.day;
    final suffix = (day == 1 || day == 21 || day == 31)
        ? "st"
        : (day == 2 || day == 22)
        ? "nd"
        : (day == 3 || day == 23)
        ? "rd"
        : "th";

    final month = DateFormat('MMM').format(date);
    final year = date.year;

    return "$month $day$suffix, $year";
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Transactions • ${widget.institutionName}"),
      ),
      body: transactions.isEmpty
          ? const Center(child: Text("No transactions for today"))
          : ListView.builder(
        itemCount: transactions.length,
        itemBuilder: (_, i) {
          final tx = transactions[i];

          final isMoneyReceived = tx.amount < 0;
          final amountColor =
          isMoneyReceived ? Colors.green : Colors.grey[800];

          return ListTile(
            title: Text(
              tx.merchantName.isNotEmpty ? tx.merchantName : tx.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(formatFancyDate(tx.date)),
            trailing: Text(
              "${tx.amount < 0 ? '+' : '-'} \$${tx.amount.abs().toStringAsFixed(2)}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: amountColor,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _TransactionDetail(tx: tx),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _TransactionDetail extends StatelessWidget {
  final PlaidTransaction tx;

  const _TransactionDetail({required this.tx});

  String formatFancyDate(DateTime date) {
    final day = date.day;
    final suffix = (day == 1 || day == 21 || day == 31)
        ? "st"
        : (day == 2 || day == 22)
        ? "nd"
        : (day == 3 || day == 23)
        ? "rd"
        : "th";

    final month = DateFormat('MMM').format(date);
    final year = date.year;

    return "$month $day$suffix, $year";
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = formatFancyDate(tx.date);

    final isMoneyReceived = tx.amount < 0;
    final amountColor = isMoneyReceived ? Colors.green : Colors.grey[800];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Transaction Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formattedDate,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    tx.merchantName.isNotEmpty ? tx.merchantName : tx.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  "${tx.amount < 0 ? '+' : '-'} \$${tx.amount.abs().toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: amountColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Text(
              tx.name,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 20),

            Wrap(
              spacing: 8,


              children: tx.category
                  .map(
                    (c) => Chip(label: Text(c)),
              )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
