// screens/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../widgets/date_range_selector.dart';
import '../models/category_summary.dart';
import '../models/transaction.dart';
import 'import_page.dart';
import 'transactions_page.dart';
import 'settings_page.dart';
import '../widgets/nav_bar.dart';

class DashboardPage extends StatefulWidget {
  final bool showAppBar;

  const DashboardPage({super.key, this.showAppBar = true});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showIncomeChart = false;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize provider on page load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<TransactionData>(context, listen: false);
      provider.initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          widget.showAppBar
              ? AppBar(
                title: const Text('Dashboard'),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                bottom: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Categories'),
                    Tab(text: 'Trends'),
                  ],
                ),
              )
              : PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Categories'),
                    Tab(text: 'Trends'),
                  ],
                ),
              ),
      drawer: widget.showAppBar ? const NavBar() : null,
      body: Consumer<TransactionData>(
        builder: (context, data, child) {
          if (data.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (data.transactions.isEmpty) {
            return _buildEmptyState();
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(data),
              _buildCategoriesTab(data),
              _buildTrendsTab(data),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder:
                (context) => Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Add Transaction',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ImportPage(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Import CSV'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // For future implementation of manual transaction entry
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Manual entry coming soon!'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add_circle_outline),
                              label: const Text('Manual Entry'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Transaction',
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.show_chart, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Import your bank statement CSV to get started',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ImportPage()),
              );
            },
            icon: const Icon(Icons.upload_file),
            label: const Text('Import Transactions'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(TransactionData data) {
    // Use currency symbol from provider
    final currencyFormat = NumberFormat.currency(symbol: data.currencySymbol);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DateRangeSelector(),
          const SizedBox(height: 16),

          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Income',
                  amount: data.totalIncome,
                  icon: Icons.arrow_upward,
                  color: Colors.green,
                  currencyFormat: currencyFormat,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Expenses',
                  amount: data.totalExpenses,
                  icon: Icons.arrow_downward,
                  color: Colors.red,
                  currencyFormat: currencyFormat,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSummaryCard(
            title: 'Net Cash Flow',
            amount: data.netCashFlow,
            icon: Icons.account_balance_wallet,
            color: data.netCashFlow >= 0 ? Colors.blue : Colors.deepOrange,
            fullWidth: true,
            currencyFormat: currencyFormat,
          ),

          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _showIncomeChart
                    ? 'Income by Category'
                    : 'Expenses by Category',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Switch(
                value: _showIncomeChart,
                onChanged: (value) {
                  setState(() {
                    _showIncomeChart = value;
                    _selectedCategoryId =
                        null; // Reset selection when switching views
                  });
                },
                activeColor: Colors.green,
                inactiveTrackColor: Colors.red,
              ),
            ],
          ),

          const SizedBox(height: 8),
          // Show pieChart for selected transaction type
          _buildPieChart(
            _showIncomeChart ? data.incomeSummaries : data.expenseSummaries,
            currencyFormat,
          ),

          const SizedBox(height: 16),
          // Recent Transactions
          Text(
            'Recent Transactions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (_selectedCategoryId != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Chip(
                label: const Text('Filtered by category'),
                deleteIcon: const Icon(Icons.close),
                onDeleted: () {
                  setState(() {
                    _selectedCategoryId = null;
                  });
                },
              ),
            ),
          _buildRecentTransactions(data, currencyFormat),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    required NumberFormat currencyFormat,
    bool fullWidth = false,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormat.format(amount),
                    style: TextStyle(
                      fontSize: 20,
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

  Widget _buildPieChart(
    List<CategorySummary> summaries,
    NumberFormat currencyFormat,
  ) {
    if (summaries.isEmpty) {
      return Container(
        height: 300,
        alignment: Alignment.center,
        child: const Text('No data available for the selected period'),
      );
    }

    final total = summaries.fold(0.0, (sum, item) => sum + item.totalAmount);

    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          PieChart(
            PieChartData(
              sections:
                  summaries.map((summary) {
                    return PieChartSectionData(
                      value: summary.totalAmount,
                      title: '', // Empty title - we'll show in the legend
                      color: summary.color,
                      radius:
                          _selectedCategoryId == summary.categoryId ? 110 : 100,
                      titleStyle: const TextStyle(
                        fontSize: 0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      badgeWidget:
                          _selectedCategoryId == summary.categoryId
                              ? _BadgeWidget(
                                icon: summary.icon,
                                color: summary.color,
                              )
                              : null,
                      badgePositionPercentageOffset: 1.05,
                    );
                  }).toList(),
              centerSpaceRadius: 40,
              sectionsSpace: 2,
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  // Only handle touch end events to prevent flickering
                  if (!event.isInterestedForInteractions ||
                      pieTouchResponse == null ||
                      pieTouchResponse.touchedSection == null ||
                      event is! FlTapUpEvent) {
                    return;
                  }

                  final index =
                      pieTouchResponse.touchedSection!.touchedSectionIndex;
                  if (index >= 0 && index < summaries.length) {
                    setState(() {
                      if (_selectedCategoryId == summaries[index].categoryId) {
                        _selectedCategoryId =
                            null; // Unselect if already selected
                      } else {
                        _selectedCategoryId = summaries[index].categoryId;
                      }
                    });
                  }
                },
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Total', style: TextStyle(fontSize: 16)),
                Text(
                  currencyFormat.format(total),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(
    TransactionData data,
    NumberFormat currencyFormat,
  ) {
    List<Transaction> transactions;

    if (_selectedCategoryId != null) {
      // Show transactions for selected category
      transactions = data.getTransactionsByCategory(_selectedCategoryId!);
    } else {
      // Show all filtered transactions, limited to most recent ones
      transactions = data.filteredTransactions;
    }

    // Sort by date (most recent first) and limit
    transactions.sort((a, b) => b.date.compareTo(a.date));
    final displayTransactions = transactions.take(5).toList();

    if (displayTransactions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: const Text('No transactions found for this category'),
          ),
        ),
      );
    }

    return Column(
      children: [
        Card(
          elevation: 2,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayTransactions.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final transaction = displayTransactions[index];
              final category = data.categories.firstWhere(
                (c) => c.id == transaction.category,
                orElse:
                    () => Category(
                      id: 'uncategorized',
                      name: 'Uncategorized',
                      color: Colors.grey,
                      icon: Icons.help_outline,
                      tags: [],
                    ),
              );

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: category.color.withOpacity(0.2),
                  child: Icon(category.icon, color: category.color, size: 20),
                ),
                title: Text(
                  transaction.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  DateFormat('MMM d, yyyy').format(transaction.date),
                ),
                trailing: Text(
                  currencyFormat.format(transaction.amount),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: transaction.amount < 0 ? Colors.red : Colors.green,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => TransactionsPage(
                            initialCategoryId: transaction.category,
                          ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        if (transactions.length > 5)
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => TransactionsPage(
                        initialCategoryId: _selectedCategoryId,
                      ),
                ),
              );
            },
            icon: const Icon(Icons.arrow_forward),
            label: Text('View all ${transactions.length} transactions'),
          ),
      ],
    );
  }

  Widget _buildCategoriesTab(TransactionData data) {
    final categorySummaries =
        _showIncomeChart ? data.incomeSummaries : data.expenseSummaries;
    final currencyFormat = NumberFormat.currency(symbol: data.currencySymbol);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _showIncomeChart ? 'Income Categories' : 'Expense Categories',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Switch(
                value: _showIncomeChart,
                onChanged: (value) {
                  setState(() {
                    _showIncomeChart = value;
                  });
                },
                activeColor: Colors.green,
                inactiveTrackColor: Colors.red,
              ),
            ],
          ),
        ),

        Expanded(
          child:
              categorySummaries.isEmpty
                  ? const Center(
                    child: Text('No data available for the selected period'),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: categorySummaries.length,
                    itemBuilder: (context, index) {
                      final summary = categorySummaries[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => TransactionsPage(
                                      initialCategoryId: summary.categoryId,
                                    ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: summary.color
                                          .withOpacity(0.2),
                                      child: Icon(
                                        summary.icon,
                                        color: summary.color,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        summary.category,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      currencyFormat.format(
                                        summary.totalAmount,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                // Progress bar showing portion of total
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value:
                                        summary.totalAmount /
                                        (_showIncomeChart
                                            ? data.totalIncome
                                            : data.totalExpenses),
                                    backgroundColor: Colors.grey.withOpacity(
                                      0.2,
                                    ),
                                    color: summary.color,
                                    minHeight: 8,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // Percentage text
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '${(summary.totalAmount * 100 / (_showIncomeChart ? data.totalIncome : data.totalExpenses)).toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
        ),

        // Add new category button
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () {
              _showCategoryDialog(context, data);
            },
            icon: const Icon(Icons.add),
            label: const Text('Add New Category'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showCategoryDialog(
    BuildContext context,
    TransactionData data,
  ) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final tagsController = TextEditingController();
    Color selectedColor = Colors.blue;
    IconData selectedIcon = Icons.category;

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add New Category'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Category Name',
                        hintText: 'E.g., Groceries, Utilities, etc.',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a category name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: tagsController,
                      decoration: const InputDecoration(
                        labelText: 'Keywords (comma separated)',
                        hintText: 'E.g., supermarket, grocery, etc.',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter at least one keyword';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Changed from Row to Column to fix overflow
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Color:'),
                        const SizedBox(height: 8),
                        // Simple color picker in a separate row from label
                        Wrap(
                          spacing: 8,
                          runSpacing: 8, // Added runSpacing for better wrapping
                          children:
                              [
                                    Colors.blue,
                                    Colors.red,
                                    Colors.green,
                                    Colors.orange,
                                    Colors.purple,
                                    Colors.teal,
                                  ]
                                  .map(
                                    (color) => GestureDetector(
                                      onTap: () {
                                        Navigator.pop(context);
                                        _showCategoryDialog(
                                          context,
                                          data,
                                        ); // Refresh dialog
                                        selectedColor = color;
                                      },
                                      child: CircleAvatar(
                                        backgroundColor: color,
                                        radius: 15,
                                        child:
                                            selectedColor == color
                                                ? const Icon(
                                                  Icons.check,
                                                  color: Colors.white,
                                                  size: 18,
                                                )
                                                : null,
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Changed from Row to Column to fix overflow
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Icon:'),
                        const SizedBox(height: 8),
                        // Simple icon picker in a separate row from label
                        Wrap(
                          spacing: 8,
                          runSpacing: 8, // Added runSpacing for better wrapping
                          children:
                              [
                                    Icons.shopping_cart,
                                    Icons.restaurant,
                                    Icons.directions_car,
                                    Icons.home,
                                    Icons.movie,
                                    Icons.credit_card,
                                  ]
                                  .map(
                                    (icon) => GestureDetector(
                                      onTap: () {
                                        Navigator.pop(context);
                                        _showCategoryDialog(
                                          context,
                                          data,
                                        ); // Refresh dialog
                                        selectedIcon = icon;
                                      },
                                      child: CircleAvatar(
                                        backgroundColor: selectedColor
                                            .withOpacity(0.2),
                                        radius: 15,
                                        child: Icon(
                                          icon,
                                          color: selectedColor,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final name = nameController.text.trim();
                    final tags =
                        tagsController.text
                            .split(',')
                            .map((t) => t.trim())
                            .where((t) => t.isNotEmpty)
                            .toList();

                    // Generate a unique ID from the name
                    final id =
                        name.toLowerCase().replaceAll(' ', '_') +
                        '_${DateTime.now().millisecondsSinceEpoch}';

                    final newCategory = Category(
                      id: id,
                      name: name,
                      color: selectedColor,
                      icon: selectedIcon,
                      tags: tags,
                    );

                    try {
                      await data.addCategory(newCategory);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Category added successfully'),
                        ),
                      );
                    } catch (e) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error adding category: $e')),
                      );
                    }
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  Widget _buildTrendsTab(TransactionData data) {
    final monthlyBalances = data.getMonthlyBalances(6);
    final spendingTrends = data.getMonthlySpendingTrends(6);
    final currencyFormat = NumberFormat.currency(symbol: data.currencySymbol);

    // Reverse order to show oldest first
    final months = monthlyBalances.keys.toList().reversed.toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Income vs. Expenses',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // Income vs Expenses Chart
          if (months.isEmpty)
            Center(
              heightFactor: 5,
              child: const Text('Not enough data to show trends'),
            )
          else
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY:
                      monthlyBalances.values
                          .expand(
                            (map) => [map['Income'] ?? 0, map['Expenses'] ?? 0],
                          )
                          .reduce((a, b) => a > b ? a : b) *
                      1.2,
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value < 0 || value >= months.length) {
                            return const Text('');
                          }
                          final monthText = months[value.toInt()];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              monthText,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final valueText = '\$${value.toInt()}';
                          return Text(
                            valueText,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          );
                        },
                        reservedSize: 50,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  groupsSpace: 12,
                  barGroups: _getBarGroups(months, monthlyBalances),
                ),
              ),
            ),

          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Income', Colors.green),
              const SizedBox(width: 24),
              _buildLegendItem('Expenses', Colors.red),
              const SizedBox(width: 24),
              _buildLegendItem('Net', Colors.blue),
            ],
          ),

          const SizedBox(height: 32),
          Text(
            'Top Spending Categories by Month',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // Category trends table
          if (spendingTrends.isEmpty)
            const Center(
              heightFactor: 3,
              child: Text('Not enough data to show category trends'),
            )
          else
            Card(
              elevation: 2,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    const DataColumn(label: Text('Category')),
                    ...months.map((month) => DataColumn(label: Text(month))),
                  ],
                  rows: _buildCategoryTrendsRows(
                    spendingTrends,
                    months,
                    data,
                    currencyFormat,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 16, height: 16, color: color),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  List<BarChartGroupData> _getBarGroups(
    List<String> months,
    Map<String, Map<String, double>> monthlyBalances,
  ) {
    List<BarChartGroupData> groups = [];

    for (int i = 0; i < months.length; i++) {
      final month = months[i];
      final data = monthlyBalances[month];

      if (data != null) {
        groups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: data['Income'] ?? 0,
                color: Colors.green,
                width: 16,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
                rodStackItems: [
                  BarChartRodStackItem(0, data['Income'] ?? 0, Colors.green),
                ],
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: (data['Income'] ?? 0) * 1.2,
                  color: Colors.green.withOpacity(0.1),
                ),
              ),
              BarChartRodData(
                toY: data['Expenses'] ?? 0,
                color: Colors.red,
                width: 16,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
                rodStackItems: [
                  BarChartRodStackItem(0, data['Expenses'] ?? 0, Colors.red),
                ],
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: (data['Expenses'] ?? 0) * 1.2,
                  color: Colors.red.withOpacity(0.1),
                ),
              ),
              BarChartRodData(
                toY: (data['Net'] ?? 0).abs(),
                color:
                    data['Net'] != null && data['Net']! >= 0
                        ? Colors.blue
                        : Colors.orange,
                width: 16,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
                rodStackItems: [
                  BarChartRodStackItem(
                    0,
                    (data['Net'] ?? 0).abs(),
                    data['Net'] != null && data['Net']! >= 0
                        ? Colors.blue
                        : Colors.orange,
                  ),
                ],
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: (data['Net'] ?? 0).abs() * 1.2,
                  color: Colors.blue.withOpacity(0.1),
                ),
              ),
            ],
          ),
        );
      }
    }

    return groups;
  }

  List<DataRow> _buildCategoryTrendsRows(
    Map<String, Map<String, double>> spendingTrends,
    List<String> months,
    TransactionData data,
    NumberFormat currencyFormat,
  ) {
    // Get all unique categories
    final allCategories = <String>{};
    for (var monthData in spendingTrends.values) {
      allCategories.addAll(monthData.keys);
    }

    // Sort categories by total spending (descending)
    final sortedCategories =
        allCategories.toList()..sort((a, b) {
          final totalA = spendingTrends.values.fold<double>(
            0,
            (sum, month) => sum + (month[a] ?? 0),
          );
          final totalB = spendingTrends.values.fold<double>(
            0,
            (sum, month) => sum + (month[b] ?? 0),
          );
          return totalB.compareTo(totalA);
        });

    // Take only top 5 categories
    final topCategories = sortedCategories.take(5).toList();

    return topCategories.map((category) {
      return DataRow(
        cells: [
          DataCell(
            Text(category, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          ...months.map((month) {
            final amount = spendingTrends[month]?[category] ?? 0;
            return DataCell(
              Text(
                currencyFormat.format(amount),
                style: TextStyle(color: amount > 0 ? Colors.red : Colors.black),
              ),
            );
          }),
        ],
      );
    }).toList();
  }
}

class _BadgeWidget extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _BadgeWidget({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Icon(icon, color: Colors.white, size: 16),
    );
  }
}
