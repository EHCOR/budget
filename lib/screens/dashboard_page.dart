// screens/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
import '../widgets/date_range_selector.dart';
import '../widgets/transaction_details_popup.dart';
import '../widgets/undo_redo_controls.dart';
import 'settings_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _showIncome = false;
  String? _selectedCategoryId;
  int? _touchedSectionIndex;

  void _clearSelection() {
    setState(() {
      _selectedCategoryId = null;
      _touchedSectionIndex = -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          const UndoRedoControls(),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.transactions.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              await provider.initialize();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Range Selector
                  const DateRangeSelector(),
                  const SizedBox(height: 20),

                  // Summary Cards
                  _buildSummaryCards(provider),
                  const SizedBox(height: 24),

                  // Category Chart
                  _buildCategoryChart(provider),
                  const SizedBox(height: 24),

                  // Recent Transactions
                  _buildTransactionsList(provider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 100,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            'No transactions yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your first transaction to get started',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(TransactionProvider provider) {
    final formatter = NumberFormat.currency(symbol: provider.currencySymbol);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'Income',
                amount: formatter.format(provider.totalIncome),
                color: Colors.green,
                icon: Icons.arrow_upward,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                title: 'Expenses',
                amount: formatter.format(provider.totalExpenses),
                color: Colors.red,
                icon: Icons.arrow_downward,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildSummaryCard(
          title: 'Net Balance',
          amount: formatter.format(provider.netCashFlow),
          color: provider.netCashFlow >= 0 ? Colors.blue : Colors.orange,
          icon: Icons.account_balance,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String amount,
    required Color color,
    required IconData icon,
    bool fullWidth = false,
  }) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    amount,
                    style: TextStyle(
                      fontSize: fullWidth ? 24 : 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChart(TransactionProvider provider) {
    final summaries = provider.getCategorySummaries(incomeOnly: _showIncome);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _showIncome ? 'Income Categories' : 'Expense Categories',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: _showIncome,
                  onChanged: (value) => setState(() => _showIncome = value),
                  activeColor: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (summaries.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text('No data for selected period'),
              )
            else
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        // Only handle tap events, not hover/move events
                        if (event is! FlTapUpEvent) return;

                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          return;
                        }

                        final touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;

                        // Only update state if something actually changed
                        if (_touchedSectionIndex == touchedIndex) {
                          if (_selectedCategoryId != null) {
                            setState(() {
                              _selectedCategoryId = null;
                              _touchedSectionIndex = -1;
                            });
                          }
                        } else {
                          final newCategoryId = summaries[touchedIndex].categoryId;
                          if (_selectedCategoryId != newCategoryId) {
                            setState(() {
                              _touchedSectionIndex = touchedIndex;
                              _selectedCategoryId = newCategoryId;
                            });
                          }
                        }
                      },
                    ),
                    sections: () {
                      final total = summaries.fold(0.0, (sum, s) => sum + s.amount);
                      return summaries.asMap().entries.map((entry) {
                        final index = entry.key;
                        final summary = entry.value;
                        final percentage = (summary.amount / total * 100);
                        final isSelected = index == _touchedSectionIndex;

                        return PieChartSectionData(
                          value: summary.amount,
                          title: percentage > 5 ? '${percentage.toStringAsFixed(0)}%' : '',
                          color: summary.color,
                          radius: isSelected ? 90 : 80,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList();
                    }(),
                    centerSpaceRadius: 0,
                    sectionsSpace: 2,
                  ),
                ),
              ),
            if (summaries.isNotEmpty && _selectedCategoryId != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Showing transactions for ${summaries.firstWhere((s) => s.categoryId == _selectedCategoryId).categoryName}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _clearSelection,
                      child: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.primary,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (summaries.isNotEmpty) ...[
              const SizedBox(height: 16),
              () {
                final total = summaries.fold(0.0, (sum, s) => sum + s.amount);
                return Column(
                  children: summaries.take(5).map((summary) {
                    final percentage = (summary.amount / total * 100);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: summary.color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Row(
                              children: [
                                Text(summary.categoryName),
                                const SizedBox(width: 8),
                                Text(
                                  '(${percentage.toStringAsFixed(0)}%)',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 100, // To align the amounts
                            child: Text(
                              NumberFormat.currency(symbol: provider.currencySymbol)
                                  .format(summary.amount),
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              }(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList(TransactionProvider provider) {
    // Cache transactions to avoid repeated filtering
    final transactions = _selectedCategoryId != null
        ? provider.getTransactionsByCategory(_selectedCategoryId!)
        : provider.filteredTransactions.take(5).toList();

    final selectedCategory = _selectedCategoryId != null
        ? provider.getCategoryById(_selectedCategoryId!)
        : null;

    final title = _selectedCategoryId != null
        ? '${selectedCategory?.name ?? 'Unknown'} Transactions'
        : 'Recent Transactions';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_selectedCategoryId != null)
                  GestureDetector(
                    onTap: _clearSelection,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (transactions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No transactions in selected period'),
                ),
              )
            else
              ...transactions.map((transaction) {
                final category = provider.getCategoryById(transaction.categoryId);
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: (category?.color ?? Colors.grey).withOpacity(0.2),
                    child: Icon(
                      category?.icon ?? Icons.help_outline,
                      color: category?.color ?? Colors.grey,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    transaction.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    DateFormat.MMMd().format(transaction.date),
                  ),
                  trailing: Text(
                    NumberFormat.currency(symbol: provider.currencySymbol)
                        .format(transaction.amount),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: transaction.type == TransactionType.income
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  onTap: () => TransactionDetailsPopup.show(context, transaction),
                );
              }),
          ],
        ),
      ),
    );
  }
}