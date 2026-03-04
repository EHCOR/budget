// widgets/trends/category_growth_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/statistics_service.dart';

class CategoryGrowthChart extends StatefulWidget {
  const CategoryGrowthChart({super.key});

  @override
  State<CategoryGrowthChart> createState() => _CategoryGrowthChartState();
}

class _CategoryGrowthChartState extends State<CategoryGrowthChart> {
  String _selectedTransactionType = 'expense';
  bool _showPercentage = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final data = provider.getMonthlyCategoryData();
        final categoryColors = provider.getCategoryColorsMap();

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
                _buildControls(),
                const SizedBox(height: 20),
                SizedBox(
                  height: 300,
                  child: LineChart(
                    _buildLineChartData(data, categoryColors, provider.currencySymbol),
                  ),
                ),
                const SizedBox(height: 16),
                _buildCategoryLegend(data, categoryColors),
                const SizedBox(height: 12),
                _buildGrowthSummary(data, provider.currencySymbol),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return const Text(
      'Category Growth Trends',
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
              Icons.trending_up,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No category growth data available',
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

  Widget _buildControls() {
    return Row(
      children: [
        // Transaction type toggle
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildToggleButton(
                'Expenses',
                _selectedTransactionType == 'expense',
                () => setState(() => _selectedTransactionType = 'expense'),
              ),
              _buildToggleButton(
                'Income',
                _selectedTransactionType == 'income',
                () => setState(() => _selectedTransactionType = 'income'),
              ),
            ],
          ),
        ),
        const Spacer(),
        // Percentage toggle
        Row(
          children: [
            Text(
              'Show %',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: _showPercentage,
              onChanged: (value) => setState(() => _showPercentage = value),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToggleButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ),
    );
  }

  LineChartData _buildLineChartData(
    Map<String, Map<String, Map<String, double>>> data,
    Map<String, Color> categoryColors,
    String currencySymbol,
  ) {
    final months = data.keys.toList();

    // Get top categories for the selected transaction type
    final topCategories = _getTopCategories(data, _selectedTransactionType, 5);

    final lines = <LineChartBarData>[];
    double maxValue = 0;
    double minValue = 0;

    for (final category in topCategories) {
      final spots = <FlSpot>[];
      final categoryValues = <double>[];

      // Collect values for this category across all months
      for (int i = 0; i < months.length; i++) {
        final monthData = data[months[i]]![_selectedTransactionType]!;
        final value = monthData[category] ?? 0.0;
        categoryValues.add(value);
      }

      // Calculate percentage change if requested
      if (_showPercentage && categoryValues.isNotEmpty) {
        final baseValue = categoryValues.first;
        for (int i = 0; i < categoryValues.length; i++) {
          final percentageChange = baseValue > 0
              ? ((categoryValues[i] - baseValue) / baseValue * 100)
              : 0.0;
          spots.add(FlSpot(i.toDouble(), percentageChange));
          maxValue = [maxValue, percentageChange].reduce((a, b) => a > b ? a : b);
          minValue = [minValue, percentageChange].reduce((a, b) => a < b ? a : b);
        }
      } else {
        for (int i = 0; i < categoryValues.length; i++) {
          spots.add(FlSpot(i.toDouble(), categoryValues[i]));
          maxValue = [maxValue, categoryValues[i]].reduce((a, b) => a > b ? a : b);
        }
      }

      lines.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: categoryColors[category] ?? Colors.grey,
          barWidth: 2.5,
          dotData: const FlDotData(show: true),
        ),
      );
    }

    return LineChartData(
      minY: _showPercentage ? minValue - 10 : 0,
      maxY: maxValue * 1.1,
      lineBarsData: lines,
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
              if (_showPercentage) {
                return Text(
                  '${value.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                );
              } else {
                return Text(
                  NumberFormat.compact().format(value),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        show: true,
        horizontalInterval: _showPercentage
            ? _calculatePercentageInterval(maxValue, minValue)
            : maxValue / 5,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Theme.of(context).dividerColor,
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
              final categoryName = topCategories[spot.barIndex];

              String valueText;
              if (_showPercentage) {
                valueText = '${spot.y.toStringAsFixed(1)}%';
              } else {
                valueText = NumberFormat.currency(symbol: currencySymbol).format(spot.y);
              }

              return LineTooltipItem(
                '$monthKey\n$categoryName: $valueText',
                TextStyle(
                  color: categoryColors[categoryName] ?? Colors.white,
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

  List<String> _getTopCategories(
    Map<String, Map<String, Map<String, double>>> data,
    String transactionType,
    int count,
  ) {
    final categoryTotals = <String, double>{};

    // Sum up totals for each category
    for (final monthData in data.values) {
      final typeData = monthData[transactionType]!;
      for (final entry in typeData.entries) {
        categoryTotals[entry.key] = (categoryTotals[entry.key] ?? 0.0) + entry.value;
      }
    }

    // Sort by total and return top N
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedCategories
        .take(count)
        .map((entry) => entry.key)
        .toList();
  }

  Widget _buildCategoryLegend(
    Map<String, Map<String, Map<String, double>>> data,
    Map<String, Color> categoryColors,
  ) {
    final topCategories = _getTopCategories(data, _selectedTransactionType, 5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top ${_selectedTransactionType == 'expense' ? 'Expense' : 'Income'} Categories',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: topCategories.map((category) {
            final color = categoryColors[category] ?? Colors.grey;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 2,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(1),
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

  Widget _buildGrowthSummary(
    Map<String, Map<String, Map<String, double>>> data,
    String currencySymbol,
  ) {
    final topCategories = _getTopCategories(data, _selectedTransactionType, 3);

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
            'Growth Analysis',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          ...topCategories.map((category) {
            final stats = StatisticsService.getCategoryStatistics(
              category,
              data,
              _selectedTransactionType,
            );

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      category,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Text(
                    stats.trendIcon,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${stats.percentageChange >= 0 ? '+' : ''}${stats.percentageChange.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _selectedTransactionType == 'expense'
                          ? (stats.percentageChange < 0 ? Colors.green : Colors.red)
                          : (stats.percentageChange > 0 ? Colors.green : Colors.red),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // Calculate appropriate interval for percentage view to avoid too dense grid lines
  double _calculatePercentageInterval(double maxValue, double minValue) {
    final range = maxValue - minValue;

    if (range <= 10) {
      return 2; // 2% intervals for small ranges (-5% to 5%)
    } else if (range <= 20) {
      return 5; // 5% intervals for small-medium ranges (-10% to 10%)
    } else if (range <= 50) {
      return 10; // 10% intervals for medium ranges (-25% to 25%)
    } else if (range <= 100) {
      return 20; // 20% intervals for large ranges (-50% to 50%)
    } else if (range <= 200) {
      return 25; // 25% intervals for very large ranges (-100% to 100%)
    } else {
      return 50; // 50% intervals for extreme ranges
    }
  }
}