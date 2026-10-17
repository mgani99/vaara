import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/property/domain/property_model.dart';

class UncategorizedTransactionsPage extends StatelessWidget {
  final String title;
  final List<PlaidTransaction> transactions;

  const UncategorizedTransactionsPage({
    super.key,
    required this.title,
    required this.transactions,
  });

  String _formatDate(DateTime date) {
    final day = date.day;

    final suffix = (day == 1 || day == 21 || day == 31)
        ? 'st'
        : (day == 2 || day == 22)
        ? 'nd'
        : (day == 3 || day == 23)
        ? 'rd'
        : 'th';

    return '${DateFormat('MMM').format(date)} $day$suffix, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final sortedTransactions =
    [...transactions]
      ..sort(
            (a, b) => b.date.compareTo(a.date),
      );

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: sortedTransactions.isEmpty
          ? const Center(
        child: Text(
          'No uncategorized transactions found',
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: sortedTransactions.length,
        separatorBuilder: (_, __) =>
        const SizedBox(height: 8),
        itemBuilder: (_, index) {
          final tx = sortedTransactions[index];

          final isIncome = tx.amount < 0;

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(8),
              side: BorderSide(
                color: Colors.grey.shade300,
              ),
            ),
            child: ListTile(
              contentPadding:
              const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),

              leading: CircleAvatar(
                backgroundColor: isIncome
                    ? Colors.green.shade100
                    : Colors.red.shade100,
                child: Icon(
                  isIncome
                      ? Icons.arrow_downward
                      : Icons.arrow_upward,
                  color: isIncome
                      ? Colors.green
                      : Colors.red,
                ),
              ),

              title: Text(
                tx.merchantName.isNotEmpty
                    ? tx.merchantName
                    : tx.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),

              subtitle: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),

                  Text(
                    _formatDate(tx.date),
                  ),

                  if (tx.category.isNotEmpty) ...[
                    const SizedBox(height: 6),

                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: tx.category
                          .map(
                            (c) => Chip(
                          label: Text(c),
                          visualDensity:
                          VisualDensity
                              .compact,
                        ),
                      )
                          .toList(),
                    ),
                  ],
                ],
              ),

              trailing: Text(
                '${isIncome ? '+' : '-'} \$${tx.amount.abs().toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isIncome
                      ? Colors.green
                      : Colors.red,
                ),
              ),

              // onTap: () {
              //   showModalBottomSheet(
              //     context: context,
              //     isScrollControlled: true,
              //     builder: (_) {
              //       return Padding(
              //         padding:
              //         const EdgeInsets.all(16),
              //         child: Column(
              //           mainAxisSize:
              //           MainAxisSize.min,
              //           crossAxisAlignment:
              //           CrossAxisAlignment
              //               .start,
              //           children: [
              //             Text(
              //               tx.merchantName
              //                   .isNotEmpty
              //                   ? tx.merchantName
              //                   : tx.name,
              //               style:
              //               const TextStyle(
              //                 fontSize: 18,
              //                 fontWeight:
              //                 FontWeight
              //                     .bold,
              //               ),
              //             ),
              //
              //             const SizedBox(
              //               height: 16,
              //             ),
              //
              //             _detailRow(
              //               'Amount',
              //               '\$${tx.amount.abs().toStringAsFixed(2)}',
              //             ),
              //
              //             _detailRow(
              //               'Date',
              //               _formatDate(
              //                 tx.date,
              //               ),
              //             ),
              //
              //             _detailRow(
              //               'Description',
              //               tx.name,
              //             ),
              //
              //             const SizedBox(
              //               height: 16,
              //             ),
              //
              //             Wrap(
              //               spacing: 8,
              //               runSpacing: 8,
              //               children: tx.category
              //                   .map(
              //                     (c) => Chip(
              //                   label:
              //                   Text(c),
              //                 ),
              //               )
              //                   .toList(),
              //             ),
              //
              //             const SizedBox(
              //               height: 24,
              //             ),
              //
              //             SizedBox(
              //               width:
              //               double.infinity,
              //               child:
              //               FilledButton.icon(
              //                 onPressed: () {
              //                   Navigator.pop(
              //                     context,
              //                   );
              //
              //                   // TODO:
              //                   // Launch category assignment flow
              //                 },
              //                 icon: const Icon(
              //                   Icons.label,
              //                 ),
              //                 label: const Text(
              //                   'Categorize Transaction',
              //                 ),
              //               ),
              //             ),
              //           ],
              //         ),
              //       );
              //     },
              //   );
              // },
            ),
          );
        },
      ),
    );
  }

  Widget _detailRow(
      String label,
      String value,
      ) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}