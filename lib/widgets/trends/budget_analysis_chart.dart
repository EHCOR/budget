// widgets/trends/budget_analysis_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/statistics_service.dart';

class BudgetAnalysisChart extends StatefulWidget {
  const BudgetAnalysisChart({super.key});

  @override
  State<BudgetAnalysisChart> createState() => _BudgetAnalysisChartState();
}

class _BudgetAnalysisChartState extends State<BudgetAnalysisChart> {
  String _selectedBudgetType = 'historical'; // 'historical', 'conservative', 'target'

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final data = provider.getMonthlyCategoryData();

        if (data.isEmpty || data.length < 2) {
          return _buildEmptyChart();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildBudgetTypeSelector(),
                const SizedBox(height: 20),
                SizedBox(
                  height: 300,
                  child: BarChart(
                    _buildBarChartData(data, provider),
                  ),
                ),
                const SizedBox(height: 16),
                _buildLegend(),
                const SizedBox(height: 12),
                _buildBudgetSummary(data, provider.currencySymbol),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return const Text(
      'Budget vs Actual Analysis',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildEmptyChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.assessment,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Need at least 2 months of data for budget analysis',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget Baseline:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBudgetToggle(
                'Historical Avg',
                'historical',
                'Based on your spending history',
              ),
              _buildBudgetToggle(
                'Conservative',
                'conservative',
                '80% of historical average',
              ),
              _buildBudgetToggle(
                'Target',
                'target',
                '70% of historical average',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetToggle(String text, String value, String description) {
    final isSelected = _selectedBudgetType == value;
    return Tooltip(
      message: description,
      child: GestureDetector(
        onTap: () => setState(() => _selectedBudgetType = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ),
      ),
    );
  }

  BarChartData _buildBarChartData(
    Map<String, Map<String, Map<String, double>>> data,
    TransactionProvider provider,
  ) {
    final months = data.keys.toList();
    final topCategories = _getTopExpenseCategories(data, 6);

    // Calculate budget baselines for each category
    final budgetBaselines = <String, double>{};
    for (final category in topCategories) {
      final categoryValues = <double>[];
      for (final monthData in data.values) {
        categoryValues.add(monthData['expense']![category] ?? 0.0);
      }

      final average = StatisticsService.calculateAverage(categoryValues);
      switch (_selectedBudgetType) {
        case 'conservative':
          budgetBaselines[category] = average * 0.8;
          break;
        case 'target':
          budgetBaselines[category] = average * 0.7;
          break;
        default: // historical
          budgetBaselines[category] = average;
      }
    }

    double maxValue = 0;

    // Build bar groups for each month
    final barGroups = <BarChartGroupData>[];
    for (int monthIndex = 0; monthIndex < months.length; monthIndex++) {
      final monthKey = months[monthIndex];
      final monthData = data[monthKey]!['expense']!;

      final bars = <BarChartRodData>[];

      for (int categoryIndex = 0; categoryIndex < topCategories.length; categoryIndex++) {
        final category = topCategories[categoryIndex];
        final actualValue = monthData[category] ?? 0.0;
        final budgetValue = budgetBaselines[category] ?? 0.0;

        maxValue = [maxValue, actualValue, budgetValue].reduce((a, b) => a > b ? a : b);

        // Actual spending bar
        bars.add(
          BarChartRodData(
            toY: actualValue,
            color: _getCategoryColor(provider, category),
            width: 8,
            borderRadius: BorderRadius.circular(2),
          ),
        );

        // Budget baseline bar (translucent)
        bars.add(
          BarChartRodData(
            toY: budgetValue,
            color: Colors.grey.withOpacity(0.5),
            width: 8,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }

      barGroups.add(
        BarChartGroupData(
          x: monthIndex,
          barRods: bars,
          barsSpace: 2,
        ),
      );
    }

    return BarChartData(
      maxY: maxValue * 1.1,
      barGroups: barGroups,
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < months.length) {
                final monthKey = months[value.toInt()];
                final parts = monthKey.split(' ');
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${parts[0]}\n${parts[1]}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return const Text('');
            },
            reservedSize: 40,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 60,
            getTitlesWidget: (value, meta) {
              return Text(
                NumberFormat.compact().format(value),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        show: true,
        horizontalInterval: maxValue / 5,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.shade300,
            strokeWidth: 1,
          );
        },
        drawVerticalLine: false,
      ),
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          tooltipBgColor: Colors.blueGrey.withOpacity(0.9),
          tooltipRoundedRadius: 8,
          tooltipPadding: const EdgeInsets.all(8),
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final monthKey = months[group.x.toInt()];
            final categoryIndex = rodIndex ~/ 2; // Each category has 2 bars
            final isActual = rodIndex % 2 == 0; // Even indices are actual, odd are budget

            if (categoryIndex < topCategories.length) {
              final category = topCategories[categoryIndex];
              final type = isActual ? 'Actual' : 'Budget';
              final value = NumberFormat.currency(symbol: provider.currencySymbol).format(rod.toY);

              return BarTooltipItem(
                '$monthKey\n$category\n$type: $value',
                TextStyle(
                  color: isActual ? Colors.white : Colors.grey.shade300,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            }
            return null;
          },
        ),
      ),
    );
  }

  List<String> _getTopExpenseCategories(
    Map<String, Map<String, Map<String, double>>> data,
    int count,
  ) {
    final categoryTotals = <String, double>{};

    for (final monthData in data.values) {
      final expenseData = monthData['expense']!;
      for (final entry in expenseData.entries) {
        categoryTotals[entry.key] = (categoryTotals[entry.key] ?? 0.0) + entry.value;
      }
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedCategories
        .take(count)
        .map((entry) => entry.key)
        .toList();
  }

  Color _getCategoryColor(TransactionProvider provider, String category) {
    final categoryColors = provider.getCategoryColorsMap();
    return categoryColors[category] ?? Colors.grey;
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Actual Spending', Colors.blue),
        const SizedBox(width: 24),
        _buildLegendItem('Budget Baseline', Colors.grey.withOpacity(0.5)),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetSummary(
    Map<String, Map<String, Map<String, double>>> data,
    String currencySymbol,
  ) {
    final latestMonth = data.values.last;
    final totalActual = latestMonth['expense']!.values.fold(0.0, (sum, value) => sum + value);

    // Calculate total budget for latest month
    double totalBudget = 0.0;
    final topCategories = _getTopExpenseCategories(data, 6);

    for (final category in topCategories) {
      final categoryValues = <double>[];
      for (final monthData in data.values) {
        categoryValues.add(monthData['expense']![category] ?? 0.0);
      }

      final average = StatisticsService.calculateAverage(categoryValues);
      switch (_selectedBudgetType) {
        case 'conservative':
          totalBudget += average * 0.8;
          break;
        case 'target':
          totalBudget += average * 0.7;
          break;
        default: // historical
          totalBudget += average;
      }
    }

    final variance = totalActual - totalBudget;
    final variancePercentage = totalBudget > 0 ? (variance / totalBudget * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Latest Month Summary',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                'Budget Baseline',
                NumberFormat.currency(symbol: currencySymbol).format(totalBudget),
                Colors.grey.shade600,
              ),
              _buildSummaryItem(
                'Actual Spending',
                NumberFormat.currency(symbol: currencySymbol).format(totalActual),
                Colors.blue,
              ),
              _buildSummaryItem(
                'Variance',
                '${variance >= 0 ? '+' : ''}${NumberFormat.currency(symbol: currencySymbol).format(variance)}',
                variance >= 0 ? Colors.red : Colors.green,
              ),
              _buildSummaryItem(
                'vs Budget',
                '${variancePercentage >= 0 ? '+' : ''}${variancePercentage.toStringAsFixed(1)}%',
                variancePercentage >= 0 ? Colors.red : Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}