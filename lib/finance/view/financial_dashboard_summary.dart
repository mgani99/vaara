import 'package:my_app/property/domain/property_model.dart';

class FinancialDashboardSummary {
  final double incomeCategorized;
  final double incomeUncategorized;
  final int incomeUncategorizedCount;

  final double expenseCategorized;
  final double expenseUncategorized;
  final int expenseUncategorizedCount;

  final double debtCategorized;
  final double debtUncategorized;
  final int debtUncategorizedCount;

  final List<PlaidTransaction> uncategorizedTransactions;

  const FinancialDashboardSummary({
    required this.incomeCategorized,
    required this.incomeUncategorized,
    required this.incomeUncategorizedCount,
    required this.expenseCategorized,
    required this.expenseUncategorized,
    required this.expenseUncategorizedCount,
    required this.debtCategorized,
    required this.debtUncategorized,
    required this.debtUncategorizedCount,
    required this.uncategorizedTransactions,
  });
}