// screens/trends_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/trends/monthly_category_chart.dart';
import '../widgets/trends/income_expense_chart.dart';
import '../widgets/trends/category_growth_chart.dart';
import '../widgets/trends/budget_analysis_chart.dart';
import '../widgets/date_range_selector.dart';
import 'settings_page.dart';

class TrendsPage extends StatefulWidget {
  const TrendsPage({super.key});

  @override
  State<TrendsPage> createState() => _TrendsPageState();
}

class _TrendsPageState extends State<TrendsPage> {
  bool _hideIncomes = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trends'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
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
                  const DateRangeSelector(showTrendsOptions: true),
                  const SizedBox(height: 16),

                  // Hide Incomes Toggle
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Hide Income Transactions',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          Switch(
                            value: _hideIncomes,
                            onChanged: (value) {
                              setState(() {
                                _hideIncomes = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Monthly Category Spending Chart
                  MonthlyCategoryChart(hideIncomes: _hideIncomes),
                  const SizedBox(height: 24),

                  // Spending vs Income Over Time
                  const IncomeExpenseChart(),
                  const SizedBox(height: 24),

                  // Category Growth Trends
                  const CategoryGrowthChart(),
                  const SizedBox(height: 24),

                  // Budget vs Actual Analysis
                  BudgetAnalysisChart(hideIncomes: _hideIncomes),
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
            Icons.trending_up,
            size: 100,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            'No data for trends analysis',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Add some transactions to see spending trends',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

}