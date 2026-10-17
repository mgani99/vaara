import 'package:my_app/property/domain/property_model.dart';
import 'package:my_app/utils/plaid_service.dart';

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

  double get totalIncome =>
      incomeCategorized + incomeUncategorized;

  double get totalExpenses =>
      expenseCategorized + expenseUncategorized;

  double get totalDebt =>
      debtCategorized + debtUncategorized;

  int get totalUncategorizedCount =>
      incomeUncategorizedCount +
          expenseUncategorizedCount +
          debtUncategorizedCount;

  bool get hasUncategorizedTransactions =>
      totalUncategorizedCount > 0;

  double get categorizedAmount =>
      incomeCategorized +
          expenseCategorized +
          debtCategorized;

  double get uncategorizedAmount =>
      incomeUncategorized +
          expenseUncategorized +
          debtUncategorized;

  double get totalActivity =>
      categorizedAmount + uncategorizedAmount;

  double get categorizedPercentage {
    if (totalActivity <= 0) return 0;
    return categorizedAmount / totalActivity;
  }

  FinancialDashboardSummary copyWith({
    double? incomeCategorized,
    double? incomeUncategorized,
    int? incomeUncategorizedCount,
    double? expenseCategorized,
    double? expenseUncategorized,
    int? expenseUncategorizedCount,
    double? debtCategorized,
    double? debtUncategorized,
    int? debtUncategorizedCount,
    List<PlaidTransaction>? uncategorizedTransactions,
  }) {
    return FinancialDashboardSummary(
      incomeCategorized:
      incomeCategorized ?? this.incomeCategorized,
      incomeUncategorized:
      incomeUncategorized ?? this.incomeUncategorized,
      incomeUncategorizedCount:
      incomeUncategorizedCount ??
          this.incomeUncategorizedCount,
      expenseCategorized:
      expenseCategorized ?? this.expenseCategorized,
      expenseUncategorized:
      expenseUncategorized ?? this.expenseUncategorized,
      expenseUncategorizedCount:
      expenseUncategorizedCount ??
          this.expenseUncategorizedCount,
      debtCategorized:
      debtCategorized ?? this.debtCategorized,
      debtUncategorized:
      debtUncategorized ?? this.debtUncategorized,
      debtUncategorizedCount:
      debtUncategorizedCount ??
          this.debtUncategorizedCount,
      uncategorizedTransactions:
      uncategorizedTransactions ??
          this.uncategorizedTransactions,
    );
  }

  factory FinancialDashboardSummary.empty() {
    return const FinancialDashboardSummary(
      incomeCategorized: 0,
      incomeUncategorized: 0,
      incomeUncategorizedCount: 0,
      expenseCategorized: 0,
      expenseUncategorized: 0,
      expenseUncategorizedCount: 0,
      debtCategorized: 0,
      debtUncategorized: 0,
      debtUncategorizedCount: 0,
      uncategorizedTransactions: [],
    );
  }
}