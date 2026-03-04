// widgets/trends/income_expense_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';

class IncomeExpenseChart extends StatelessWidget {
  const IncomeExpenseChart({super.key});

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
                const SizedBox(height: 20),
                SizedBox(
                  height: 300,
                  child: LineChart(
                    _buildLineChartData(data, provider.currencySymbol),
                  ),
                ),
                const SizedBox(height: 16),
                _buildLegend(),
                const SizedBox(height: 12),
                _buildSummaryStats(context, data, provider.currencySymbol),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return const Text(
      'Spending vs Income Over Time',
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
              Icons.timeline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No income/expense data available',
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

  LineChartData _buildLineChartData(
    Map<String, Map<String, Map<String, double>>> data,
    String currencySymbol,
  ) {
    final months = data.keys.toList();
    final incomePoints = <FlSpot>[];
    final expensePoints = <FlSpot>[];
    final netPoints = <FlSpot>[];

    double maxValue = 0;

    for (int i = 0; i < months.length; i++) {
      final monthData = data[months[i]]!;
      final totalIncome = monthData['income']!.values.fold(0.0, (sum, value) => sum + value);
      final totalExpense = monthData['expense']!.values.fold(0.0, (sum, value) => sum + value);
      final netValue = totalIncome - totalExpense;

      incomePoints.add(FlSpot(i.toDouble(), totalIncome));
      expensePoints.add(FlSpot(i.toDouble(), totalExpense));
      netPoints.add(FlSpot(i.toDouble(), netValue));

      maxValue = [maxValue, totalIncome, totalExpense].reduce((a, b) => a > b ? a : b);
    }

    return LineChartData(
      minY: netPoints.map((p) => p.y).reduce((a, b) => a < b ? a : b) - (maxValue * 0.1),
      maxY: maxValue * 1.1,
      lineBarsData: [
        // Income line
        LineChartBarData(
          spots: incomePoints,
          isCurved: true,
          color: Colors.green,
          barWidth: 3,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.green.withValues(alpha: 0.1),
          ),
        ),
        // Expense line
        LineChartBarData(
          spots: expensePoints,
          isCurved: true,
          color: Colors.red,
          barWidth: 3,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.red.withValues(alpha: 0.1),
          ),
        ),
        // Net savings line
        LineChartBarData(
          spots: netPoints,
          isCurved: true,
          color: Colors.blue,
          barWidth: 2,
          dotData: const FlDotData(show: true),
          dashArray: [5, 5], // Dashed line for net
        ),
      ],
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
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: Colors.blueGrey.withValues(alpha: 0.9),
          tooltipRoundedRadius: 8,
          tooltipPadding: const EdgeInsets.all(8),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final monthKey = months[spot.x.toInt()];
              String label;
              Color color;

              switch (spot.barIndex) {
                case 0:
                  label = 'Income';
                  color = Colors.green;
                  break;
                case 1:
                  label = 'Expenses';
                  color = Colors.red;
                  break;
                case 2:
                  label = 'Net Savings';
                  color = Colors.blue;
                  break;
                default:
                  label = 'Unknown';
                  color = Colors.grey;
              }

              return LineTooltipItem(
                '$monthKey\n$label: ${NumberFormat.currency(symbol: currencySymbol).format(spot.y)}',
                TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem('Income', Colors.green, Icons.trending_up),
        _buildLegendItem('Expenses', Colors.red, Icons.trending_down),
        _buildLegendItem('Net Savings', Colors.blue, Icons.savings),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Container(
          width: 20,
          height: 3,
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

  Widget _buildSummaryStats(
    BuildContext context,
    Map<String, Map<String, Map<String, double>>> data,
    String currencySymbol,
  ) {
    double totalIncome = 0;
    double totalExpense = 0;

    for (final monthData in data.values) {
      totalIncome += monthData['income']!.values.fold(0.0, (sum, value) => sum + value);
      totalExpense += monthData['expense']!.values.fold(0.0, (sum, value) => sum + value);
    }

    final netSavings = totalIncome - totalExpense;
    final savingsRate = totalIncome > 0 ? (netSavings / totalIncome * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            context,
            'Total Income',
            NumberFormat.currency(symbol: currencySymbol).format(totalIncome),
            Colors.green,
          ),
          _buildStatItem(
            context,
            'Total Expenses',
            NumberFormat.currency(symbol: currencySymbol).format(totalExpense),
            Colors.red,
          ),
          _buildStatItem(
            context,
            'Net Savings',
            NumberFormat.currency(symbol: currencySymbol).format(netSavings),
            netSavings >= 0 ? Colors.blue : Colors.orange,
          ),
          _buildStatItem(
            context,
            'Savings Rate',
            '${savingsRate.toStringAsFixed(1)}%',
            savingsRate >= 0 ? Colors.blue : Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
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