// widgets/trends/monthly_category_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';

class MonthlyCategoryChart extends StatefulWidget {
  const MonthlyCategoryChart({super.key});

  @override
  State<MonthlyCategoryChart> createState() => _MonthlyCategoryChartState();
}

class _MonthlyCategoryChartState extends State<MonthlyCategoryChart> {
  int _selectedMonths = 6;

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final data = provider.getMonthlyCategoryData(_selectedMonths);
        final categoryColors = provider.getCategoryColorsMap();

        if (data.isEmpty || data.values.every((month) =>
          month['income']!.isEmpty && month['expense']!.isEmpty)) {
          return _buildEmptyChart();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                SizedBox(
                  height: 300,
                  child: BarChart(
                    _buildBarChartData(data, categoryColors, provider),
                  ),
                ),
                const SizedBox(height: 16),
                _buildLegend(data, categoryColors),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Monthly Spending by Category',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        DropdownButton<int>(
          value: _selectedMonths,
          items: [3, 6, 12].map((months) {
            return DropdownMenuItem(
              value: months,
              child: Text('$months months'),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedMonths = value;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildEmptyChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.bar_chart,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No spending data available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add some transactions to see monthly trends',
              style: TextStyle(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartData _buildBarChartData(
    Map<String, Map<String, Map<String, double>>> data,
    Map<String, Color> categoryColors,
    TransactionProvider provider,
  ) {
    final months = data.keys.toList();
    final maxValue = _getMaxValue(data);

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxValue * 1.1,
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          tooltipBgColor: Colors.blueGrey,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final monthKey = months[group.x.toInt()];
            final type = rodIndex == 0 ? 'Income' : 'Expense';
            final value = NumberFormat.currency(symbol: provider.currencySymbol)
                .format(rod.toY);
            return BarTooltipItem(
              '$monthKey\n$type: $value',
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
      ),
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
      barGroups: _buildBarGroups(data, categoryColors),
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
    );
  }

  List<BarChartGroupData> _buildBarGroups(
    Map<String, Map<String, Map<String, double>>> data,
    Map<String, Color> categoryColors,
  ) {
    final months = data.keys.toList();

    return List.generate(months.length, (index) {
      final monthKey = months[index];
      final monthData = data[monthKey]!;

      return BarChartGroupData(
        x: index,
        barsSpace: 4,
        barRods: [
          // Income bar
          _buildStackedBar(monthData['income']!, categoryColors, true),
          // Expense bar
          _buildStackedBar(monthData['expense']!, categoryColors, false),
        ],
      );
    });
  }

  BarChartRodData _buildStackedBar(
    Map<String, double> categoryData,
    Map<String, Color> categoryColors,
    bool isIncome,
  ) {
    final sortedCategories = categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalValue = categoryData.values.fold(0.0, (sum, value) => sum + value);

    List<BarChartRodStackItem> stackItems = [];
    double currentValue = 0;

    for (var entry in sortedCategories) {
      final categoryName = entry.key;
      final value = entry.value;
      final color = categoryColors[categoryName] ?? Colors.grey;

      stackItems.add(BarChartRodStackItem(
        currentValue,
        currentValue + value,
        isIncome ? color.withOpacity(0.8) : color,
      ));

      currentValue += value;
    }

    return BarChartRodData(
      toY: totalValue,
      color: isIncome ? Colors.green : Colors.red,
      width: 20,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(4),
        topRight: Radius.circular(4),
      ),
      rodStackItems: stackItems,
    );
  }

  Widget _buildLegend(
    Map<String, Map<String, Map<String, double>>> data,
    Map<String, Color> categoryColors,
  ) {
    // Collect all categories from all months
    final Set<String> allCategories = {};
    for (var monthData in data.values) {
      allCategories.addAll(monthData['income']!.keys);
      allCategories.addAll(monthData['expense']!.keys);
    }

    final sortedCategories = allCategories.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categories',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: sortedCategories.map((category) {
            final color = categoryColors[category] ?? Colors.grey;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  category,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  double _getMaxValue(Map<String, Map<String, Map<String, double>>> data) {
    double maxValue = 0;

    for (var monthData in data.values) {
      final incomeTotal = monthData['income']!.values.fold(0.0, (sum, value) => sum + value);
      final expenseTotal = monthData['expense']!.values.fold(0.0, (sum, value) => sum + value);
      final monthMax = [incomeTotal, expenseTotal].reduce((a, b) => a > b ? a : b);

      if (monthMax > maxValue) {
        maxValue = monthMax;
      }
    }

    return maxValue > 0 ? maxValue : 100;
  }
}