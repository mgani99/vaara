import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/finance/view/uncategorized_transaction_page.dart';
import 'package:my_app/portfolio/model/linked_bank_repository.dart';
import 'package:my_app/property/domain/property_model.dart';
import 'package:my_app/session/app_data.dart';
import 'package:my_app/utils/plaid_service.dart';
import 'package:provider/provider.dart';

import '../../banktransaction/view/transaction_view_page.dart';

class FinancialDashboardPage extends StatefulWidget {
  const FinancialDashboardPage({super.key});

  @override
  State<FinancialDashboardPage> createState() =>
      _FinancialDashboardPageState();
}

class _FinancialDashboardPageState
    extends State<FinancialDashboardPage>
    with TickerProviderStateMixin {

  late TabController _mainTabController;

  DateTime selectedMonth =
  DateTime(DateTime.now().year, DateTime.now().month, 1);

  FinancialDashboardSummary? summary;
  bool loadingSummary = true;
  bool _isSearching = false;
  final TextEditingController _searchController =
  TextEditingController();
  @override
  void initState() {
    super.initState();

    _loadDashboard();

    _mainTabController = TabController(
      length: 2,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    final session = context.read<AppSession>();
    final repo = context.read<LinkedBankRepository>();

    final dashboardSummary =
    await repo.buildFinancialDashboardSummary(
      orgId: session.activeOrgId!,
      month: selectedMonth,
    );

    if (!mounted) return;

    setState(() {
      summary = dashboardSummary;
      loadingSummary = false;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fa),
      body: SafeArea(
        child: Column(
          children: [

            _FinancialHeader(
              selectedMonth: selectedMonth,
              isSearching: _isSearching,
              searchController: _searchController,
              onSearchToggle: () {
                setState(() {
                  if (_isSearching) {
                    _searchController.clear();
                  }
                  _isSearching = !_isSearching;
                });
              },
              onPreviousMonth: () async{
                setState(() {
                  selectedMonth = DateTime(
                    selectedMonth.year,
                    selectedMonth.month - 1,
                    1,
                  );
                });
                await _loadDashboard();();
              },
              onNextMonth: () async{
                setState(() {
                  selectedMonth = DateTime(
                    selectedMonth.year,
                    selectedMonth.month + 1,
                    1,
                  );
                });
                await _loadDashboard();
              },
            ),

            Container(
              color: Colors.white,
              child: TabBar(
                controller: _mainTabController,
                labelColor: Colors.blue.shade700,
                unselectedLabelColor: Colors.grey.shade600,
                indicatorColor: Colors.blue.shade700,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Banking'),

                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _mainTabController,
                children: [
                  loadingSummary || summary == null
                      ? const Center(
                    child: CircularProgressIndicator(),
                  )
                      : FinancialOverviewTab(
                    summary: summary!,
                  ),
                  const FinancialBankingTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinancialHeader extends StatelessWidget {
  final DateTime selectedMonth;
  final bool isSearching;
  final TextEditingController searchController;

  final VoidCallback onSearchToggle;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  const _FinancialHeader({
    required this.selectedMonth,
    required this.isSearching,
    required this.searchController,
    required this.onSearchToggle,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    final monthName =
    DateFormat('MMMM yyyy').format(selectedMonth);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          // ------------------------------------------------
          // TITLE + SEARCH + MENU
          // ------------------------------------------------
          Row(
            children: [
              Expanded(
                child: isSearching
                    ? TextField(
                  controller: searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search financials...',
                    border: InputBorder.none,
                  ),
                )
                    : Text(
                  'Financials',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),

              IconButton(
                icon: Icon(
                  isSearching ? Icons.clear : Icons.search,
                  size: 22,
                  color: Colors.blue.shade700,
                ),
                onPressed: onSearchToggle,
              ),

              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                    case 'expenseSummary':
                      break;
                    case 'incomeSummary':
                      break;
                    case 'profitLoss':
                      break;
                    case 'cashFlow':
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'expenseSummary',
                    child: Text('Expense Summary'),
                  ),
                  PopupMenuItem(
                    value: 'incomeSummary',
                    child: Text('Income Summary'),
                  ),
                  PopupMenuItem(
                    value: 'profitLoss',
                    child: Text('Profit & Loss'),
                  ),
                  PopupMenuItem(
                    value: 'cashFlow',
                    child: Text('Cash Flow'),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ------------------------------------------------
          // MONTH NAVIGATION
          // ------------------------------------------------
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 18,
                ),
                onPressed: onPreviousMonth,
              ),

              Expanded(
                child: Center(
                  child: Text(
                    monthName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              IconButton(
                icon: const Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                ),
                onPressed: onNextMonth,
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class FinancialOverviewTab extends StatelessWidget {
  final FinancialDashboardSummary summary;

  const FinancialOverviewTab({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FinancialCategorySection(
          title: 'Income',
          total:
          summary.incomeCategorized +
              summary.incomeUncategorized,
          categorizedAmount:
          summary.incomeCategorized,
          uncategorizedAmount:
          summary.incomeUncategorized,
          uncategorizedCount:
          summary.incomeUncategorizedCount,
          color: Colors.green,
          onUncategorizedTap: () {
            final txs = summary.uncategorizedTransactions
                .where((t) => t.amount < 0)
                .toList();

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UncategorizedTransactionsPage(
                  title: 'Uncategorized Income',
                  transactions: txs,
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 12),

        FinancialCategorySection(
          title: 'Expenses',
          total:
          summary.expenseCategorized +
              summary.expenseUncategorized,
          categorizedAmount:
          summary.expenseCategorized,
          uncategorizedAmount:
          summary.expenseUncategorized,
          uncategorizedCount:
          summary.expenseUncategorizedCount,
          color: Colors.red,
          onUncategorizedTap: () {
            final txs = summary.uncategorizedTransactions
                .where((t) => t.amount > 0)
                .toList();

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UncategorizedTransactionsPage(
                  title: 'Uncategorized Expenses',
                  transactions: txs,
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 12),

        FinancialCategorySection(
          title: 'Debt Servicing',
          total:
          summary.debtCategorized +
              summary.debtUncategorized,
          categorizedAmount:
          summary.debtCategorized,
          uncategorizedAmount:
          summary.debtUncategorized,
          uncategorizedCount:
          summary.debtUncategorizedCount,
          color: Colors.orange,
          onUncategorizedTap: () {
            final txs = summary.uncategorizedTransactions
                .where((t) => _isDebtTransaction(t))
                .toList();

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UncategorizedTransactionsPage(
                  title: 'Uncategorized Debt',
                  transactions: txs,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  static bool _isDebtTransaction(
      PlaidTransaction tx,
      ) {
    final categoryText = tx.category
        .join(' ')
        .toLowerCase();

    return categoryText.contains('loan') ||
        categoryText.contains('mortgage') ||
        categoryText.contains('debt') ||
        categoryText.contains('credit');
  }
}
class FinancialCategorySection extends StatelessWidget {
  final String title;
  final double total;
  final double categorizedAmount;
  final double uncategorizedAmount;
  final int uncategorizedCount;
  final Color color;
  final VoidCallback? onUncategorizedTap;

  const FinancialCategorySection({
    super.key,
    required this.title,
    required this.total,
    required this.categorizedAmount,
    required this.uncategorizedAmount,
    required this.uncategorizedCount,
    required this.color,
    this.onUncategorizedTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header

          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                NumberFormat.currency(
                  symbol: '\$',
                  decimalDigits: 0,
                ).format(total),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Categorized

          _row(
            label: 'Categorized',
            amount: categorizedAmount,
            valueColor: color,
          ),

          const SizedBox(height: 8),

          // Uncategorized

          InkWell(
            onTap: uncategorizedCount > 0
                ? onUncategorizedTap
                : null,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 4,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Uncategorized ($uncategorizedCount)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: uncategorizedCount > 0
                            ? Colors.blue.shade700
                            : Colors.black54,
                      ),
                    ),
                  ),

                  Text(
                    NumberFormat.currency(
                      symbol: '\$',
                      decimalDigits: 0,
                    ).format(uncategorizedAmount),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  if (uncategorizedCount > 0) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: Colors.blue.shade700,
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          LinearProgressIndicator(
            value: total == 0
                ? 0
                : categorizedAmount / total,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(
              color,
            ),
            borderRadius: BorderRadius.circular(4),
          ),

          const SizedBox(height: 6),

          Text(
            total == 0
                ? '0% categorized'
                : '${((categorizedAmount / total) * 100).toStringAsFixed(0)}% categorized',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row({
    required String label,
    required double amount,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black87,
            ),
          ),
        ),
        Text(
          NumberFormat.currency(
            symbol: '\$',
            decimalDigits: 0,
          ).format(amount),
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
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

  final List<PlaidTransaction>
  uncategorizedTransactions;

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
class FinancialReportsTab extends StatelessWidget {
  const FinancialReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ReportCard(
          title: 'Expense Summary',
        ),
        ReportCard(
          title: 'Income Summary',
        ),
        ReportCard(
          title: 'Profit & Loss',
        ),
        ReportCard(
          title: 'Cash Flow',
        ),
      ],
    );
  }
}
class ReportCard extends StatelessWidget {
  final String title;

  const ReportCard({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const Icon(Icons.description_outlined),
        title: Text(title),
        trailing: const Icon(
          Icons.chevron_right,
        ),
      ),
    );
  }
}

class FinancialBankingTab extends StatefulWidget {
  const FinancialBankingTab({super.key});

  @override
  State<FinancialBankingTab> createState() =>
      _FinancialBankingTabState();
}

class _FinancialBankingTabState
    extends State<FinancialBankingTab> {
  bool loading = true;

  Map<String, List<BankAccount>> bankData = {};

  @override
  void initState() {
    super.initState();
    _loadBanks();
  }

  Future<void> _loadBanks() async {
    final session = context.read<AppSession>();
    final repo = context.read<LinkedBankRepository>();

    final data = await repo.getAllOrgBanks(
      session.activeOrgId!,
    );

    setState(() {
      bankData = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (bankData.isEmpty) {
      return const Center(
        child: Text("No linked bank accounts"),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...bankData.entries.map(
              (entry) => _InstitutionSection(
            institutionName: entry.key,
            accounts: entry.value,
          ),
        ),
      ],
    );
  }
}
class _InstitutionSection extends StatelessWidget {
  final String institutionName;
  final List<BankAccount> accounts;

  const _InstitutionSection({
    required this.institutionName,
    required this.accounts,
  });

  @override
  Widget build(BuildContext context) {
    for (final a in accounts) {
      print(
          "name = ${a.name} "
          "acct=${a.accountId} "
              "subtype=${a.subtype} "
              "mask=${a.mask} "
      );
    }
    final debitAccounts = accounts.where((a) {
      return a.subtype?.toLowerCase() == "checking" || a.subtype?.toLowerCase() == "savings"  ;
    }).toList();

    final creditAccounts = accounts.where((a) {
      return a.subtype?.toLowerCase() == "credit card";
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          institutionName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 10),

        if (debitAccounts.isNotEmpty) ...[
          const Text(
            "Debit Accounts",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 6),

          ...debitAccounts.map(
                (a) => BankingAccountCard(
              institution: institutionName,
              account: a,
            ),
          ),
        ],

        if (creditAccounts.isNotEmpty) ...[
          const SizedBox(height: 8),

          const Text(
            "Credit Cards",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),

          const SizedBox(height: 6),

          ...creditAccounts.map(
                (a) => BankingAccountCard(
              institution: institutionName,
              account: a,
            ),
          ),
        ],

        const SizedBox(height: 20),
      ],
    );
  }
}
class BankingAccountCard extends StatelessWidget {
  final String institution;
  final BankAccount account;

  const BankingAccountCard({
    super.key,
    required this.institution,
    required this.account,
  });

  @override
  Widget build(BuildContext context) {
    final isCredit =
        account.subtype?.toLowerCase() == "credit";

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          isCredit
              ? Icons.credit_card
              : Icons.account_balance,
          color:
          isCredit ? Colors.red : Colors.green,
        ),

        title: Text(
          institution,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),

        subtitle: Text(
          "${account.subtype ?? ''} • ****${account.mask ?? ''}",
        ),

        trailing: IconButton(
          icon: const Icon(
            Icons.refresh,
            color: Colors.blue,
          ),
          onPressed: () async {
            final session = context.read<AppSession>();
            final repo = context.read<LinkedBankRepository>();

            final userId = await repo.findUserIdForAccount(
              orgId: session.activeOrgId!,
              institutionName: institution,
              acctId: account.accountId,
            );

            if (userId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Bank owner not found"),
                ),
              );
              return;
            }

            final result = await PlaidService.getBalance(
              orgId: session.activeOrgId!,
              userId: userId,
              institutionName: institution,
              mask: account.mask ?? "",
              acctId: account.accountId,
            );

            if (context.mounted) {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Account Balance"),
                  content: Text(
                    result["error"] != null
                        ? result["error"]
                        : "\$${(result["balance"] ?? 0).toStringAsFixed(2)}",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("OK"),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }
}





