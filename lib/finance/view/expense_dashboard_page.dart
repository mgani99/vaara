import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/property/model/property_repository.dart';
import 'package:my_app/session/app_data.dart';
import 'package:provider/provider.dart';

import '../../property/domain/property_model.dart';

class ExpenseDashboardPage extends StatefulWidget {
  const ExpenseDashboardPage({super.key});

  @override
  State<ExpenseDashboardPage> createState() =>
      _ExpenseDashboardPageState();
}

class _ExpenseDashboardPageState extends State<ExpenseDashboardPage> {
  DateTime selectedMonth = DateTime.now();

  List<PropertyModel> properties = [];
  String? selectedPropertyId;

  bool isLoading = false;
  void _changeMonth(int delta) {
    setState(() {
      selectedMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month + delta,
        1,
      );
    });

    _loadExpenses();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProperties();
      _loadExpenses();
    });
  }
  Future<void> _loadProperties() async {
    final session = context.read<AppSession>();
    final propertyRepo = context.read<PropertyRepository>();

    final orgId = session.activeOrgId;

    if (orgId == null || orgId.isEmpty) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final results =
      await propertyRepo.getPropertiesForOrg(orgId);

      if (!mounted) return;

      setState(() {
        properties = results;
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadExpenses() async {
    // TODO:
    // Call ExpenseRepository.loadMonth(
    //   ownerId,
    //   DateFormat('yyyy-MM').format(selectedMonth),
    // );
  }


  @override
  Widget build(BuildContext context) {
    final monthLabel =
    DateFormat('MMMM yyyy').format(selectedMonth);

    return Scaffold(
      backgroundColor: const Color(0xfff5f7fa),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(monthLabel),

            // Show property filter only when user
            // actually has multiple properties.
            if (properties.length > 1) ...[
              const SizedBox(height: 6),

              Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: 6,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Property',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ),

              _buildPropertyFilter(),
            ],

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  ExpenseCategoryCard(
                    category: 'Repairs & Maintenance',
                    total: 1820,
                    icon: Icons.build,
                  ),
                  ExpenseCategoryCard(
                    category: 'Utilities',
                    total: 912,
                    icon: Icons.electric_bolt,
                  ),
                  ExpenseCategoryCard(
                    category: 'Insurance',
                    total: 650,
                    icon: Icons.health_and_safety,
                  ),
                  ExpenseCategoryCard(
                    category: 'Property Taxes',
                    total: 550,
                    icon: Icons.account_balance,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _propertyChip({
    required String? id,
    required String label,
  }) {
    final selected = selectedPropertyId == id;

    final displayLabel =
    label.length > 12
        ? '${label.substring(0, 12)}...'
        : label;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        selected: selected,

        materialTapTargetSize:
        MaterialTapTargetSize.shrinkWrap,

        visualDensity: const VisualDensity(
          horizontal: -3,
          vertical: 1,
        ),

        labelPadding: const EdgeInsets.symmetric(
          horizontal: 2,
        ),

        label: Text(
          displayLabel,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),

        onSelected: (_) {
          setState(() {
            selectedPropertyId = id;
          });

          _loadExpenses();
        },
      ),
    );
  }

  Widget _buildHeader(String monthLabel) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        12,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _changeMonth(-1),
            icon: const Icon(Icons.chevron_left),
          ),

          Expanded(
            child: Column(
              children: [
                Text(
                  monthLabel,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  '\$4,592',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: () => _changeMonth(1),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }


  Widget _buildPropertyFilter() {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        children: [
          _propertyChip(
            id: null,
            label: 'All',
          ),

          ...properties.map(
                (property) => _propertyChip(
              id: property.propertyId,
              label: property.name,
            ),
          ),
        ],
      ),
    );
  }

}

class ExpenseCategoryCard extends StatelessWidget {
  final String category;
  final double total;
  final IconData icon;

  const ExpenseCategoryCard({
    super.key,
    required this.category,
    required this.total,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      child: ExpansionTile(
        leading: Icon(
          icon,
          color: Colors.blueGrey,
        ),
        title: Text(
          category,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Text(
          NumberFormat.currency(
            symbol: '\$',
            decimalDigits: 0,
          ).format(total),
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: const [
          ExpenseTransactionTile(
            description: 'HVAC Service',
            amount: 950,
          ),
          ExpenseTransactionTile(
            description: 'Locksmith',
            amount: 520,
          ),
          ExpenseTransactionTile(
            description: 'Plumbing Repair',
            amount: 350,
          ),
        ],
      ),
    );
  }
}
class ExpenseTransactionTile extends StatelessWidget {
  final String description;
  final double amount;

  const ExpenseTransactionTile({
    super.key,
    required this.description,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(description),
      subtitle: const Text('Sep 12, 2026'),
      trailing: Text(
        NumberFormat.currency(
          symbol: '\$',
          decimalDigits: 0,
        ).format(amount),
        style: const TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}