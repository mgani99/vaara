import 'package:my_app/finance/model/transaction_repository.dart';
import 'package:my_app/finance/view/financial_dashboard_page.dart';
import 'package:my_app/portfolio/model/linked_bank_repository.dart';


class FinancialRepository {
  final LinkedBankRepository linkedBankRepository;
  final TransactionRepository transactionRepository;

  FinancialRepository({
    required this.linkedBankRepository,
    required this.transactionRepository,
  });

  Future<FinancialDashboardSummary>
  buildFinancialDashboardSummary({
    required String orgId,
    required DateTime month,
  }) async {
    //
    // Categorized Transactions
    //

    final realTransactions =
    await transactionRepository
        .getTransactionsForMonth(
      orgId: orgId,
      month: month,
    );

    //
    // Plaid Transactions
    //

    final plaidTransactions =
    await linkedBankRepository
        .getMonthlyTransactionsForOrg(
      orgId: orgId,
      month: month,
    );

    //
    // Build set of already-categorized
    // Plaid transaction ids
    //

    final categorizedPlaidIds =
    realTransactions
        .where(
          (t) =>
      t.plaidTransactionId
          .isNotEmpty,
    )
        .map(
          (t) =>
      t.plaidTransactionId,
    )
        .toSet();

    //
    // Uncategorized Plaid Transactions
    //

    final uncategorized =
    plaidTransactions.where(
          (plaidTx) {
        return !categorizedPlaidIds
            .contains(
          plaidTx.transactionId,
        );
      },
    ).toList();

    //
    // Categorized Totals
    //

    double incomeCategorized = 0;
    double expenseCategorized = 0;
    double debtCategorized = 0;

    for (final tx
    in realTransactions) {
      switch (
      tx.category.toLowerCase()) {
        case 'income':
          incomeCategorized +=
              tx.amount;
          break;

        case 'expense':
          expenseCategorized +=
              tx.amount;
          break;

        case 'debt':
        case 'debt servicing':
          debtCategorized +=
              tx.amount;
          break;
      }
    }

    //
    // Uncategorized Income
    //

    final incomeUncategorizedTx =
    uncategorized.where(
          (tx) => tx.amount < 0,
    ).toList();

    final incomeUncategorized =
    incomeUncategorizedTx
        .fold<double>(
      0,
          (total, tx) =>
      total +
          tx.amount.abs(),
    );

    //
    // Uncategorized Expenses
    //

    final expenseUncategorizedTx =
    uncategorized.where(
          (tx) => tx.amount > 0,
    ).toList();

    final expenseUncategorized =
    expenseUncategorizedTx
        .fold<double>(
      0,
          (total, tx) =>
      total +
          tx.amount.abs(),
    );

    //
    // Uncategorized Debt
    //

    final debtUncategorizedTx =
    uncategorized.where(
          (tx) {
        final text =
        tx.category
            .join(' ')
            .toLowerCase();

        return text.contains(
            'loan') ||
            text.contains(
                'mortgage') ||
            text.contains(
                'debt') ||
            text.contains(
                'credit');
      },
    ).toList();

    final debtUncategorized =
    debtUncategorizedTx
        .fold<double>(
      0,
          (total, tx) =>
      total +
          tx.amount.abs(),
    );

    //
    // Debug
    //

    print(
      'Real Transactions: ${realTransactions.length}',
    );

    print(
      'Plaid Transactions: ${plaidTransactions.length}',
    );

    print(
      'Uncategorized Transactions: ${uncategorized.length}',
    );

    //
    // Summary
    //

    return FinancialDashboardSummary(
      incomeCategorized:
      incomeCategorized,

      incomeUncategorized:
      incomeUncategorized,

      incomeUncategorizedCount:
      incomeUncategorizedTx.length,

      expenseCategorized:
      expenseCategorized,

      expenseUncategorized:
      expenseUncategorized,

      expenseUncategorizedCount:
      expenseUncategorizedTx.length,

      debtCategorized:
      debtCategorized,

      debtUncategorized:
      debtUncategorized,

      debtUncategorizedCount:
      debtUncategorizedTx.length,

      uncategorizedTransactions:
      uncategorized,
    );
  }
}