// widgets/trends/monthly_category_chart.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/statistics_service.dart';
import 'category_info_popup.dart';

class MonthlyCategoryChart extends StatefulWidget {
  const MonthlyCategoryChart({super.key});

  @override
  State<MonthlyCategoryChart> createState() => _MonthlyCategoryChartState();
}

class _MonthlyCategoryChartState extends State<MonthlyCategoryChart> {
  int? _touchedGroupIndex;
  int? _touchedRodIndex;
  String? _hoveredCategory;
  String? _pendingHoveredCategory;
  Timer? _hoverDebounceTimer;

  @override
  void dispose() {
    _hoverDebounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final data = provider.getMonthlyCategoryData();
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
                const SizedBox(height: 12),
                _buildInteractionHint(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return const Text(
      'Monthly Spending by Category',
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
              Icons.bar_chart,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No spending data available for the selected range',
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
        enabled: true,
        handleBuiltInTouches: true,
        touchTooltipData: BarTouchTooltipData(
          tooltipBgColor: Colors.blueGrey.withOpacity(0.9),
          tooltipRoundedRadius: 8,
          tooltipPadding: const EdgeInsets.all(8),
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final monthKey = months[group.x.toInt()];
            final type = rodIndex == 0 ? 'Income' : 'Expense';
            final monthData = data[monthKey]![type.toLowerCase()]!;

            final totalValue = NumberFormat.currency(symbol: provider.currencySymbol)
                .format(rod.toY);

            // Check if we have a specific hovered category
            if (_hoveredCategory != null && monthData.containsKey(_hoveredCategory)) {
              final categoryValue = monthData[_hoveredCategory]!;
              final categoryValueStr = NumberFormat.currency(symbol: provider.currencySymbol)
                  .format(categoryValue);
              final percentage = (categoryValue / rod.toY * 100).toStringAsFixed(1);

              return BarTooltipItem(
                '$monthKey\n$type: $totalValue\n\n$_hoveredCategory:\n$categoryValueStr ($percentage%)',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            }

            // Fallback: Show breakdown of top categories in this bar
            final sortedCategories = monthData.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            final topCategories = sortedCategories.take(3).toList();

            String tooltipText = '$monthKey\n$type: $totalValue\n';

            if (topCategories.isNotEmpty) {
              tooltipText += '\nTop Categories:';
              for (var entry in topCategories) {
                final categoryValueStr = NumberFormat.currency(symbol: provider.currencySymbol)
                    .format(entry.value);
                final percentage = (entry.value / rod.toY * 100).toStringAsFixed(0);
                tooltipText += '\n• ${entry.key}: $categoryValueStr ($percentage%)';
              }
            }

            return BarTooltipItem(
              tooltipText,
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            );
          },
        ),
        touchCallback: (event, response) {
          if (event is FlTapUpEvent && response?.spot != null) {
            _handleStackTap(event, response!, data, categoryColors, provider);
            return; // don't process tap as hover
          }

          if (event is FlPointerHoverEvent || event is FlPanUpdateEvent) {
            if (response?.spot != null) {
              if (_touchedGroupIndex != response!.spot!.touchedBarGroupIndex ||
                  _touchedRodIndex != response.spot!.touchedRodDataIndex) {
                setState(() {
                  _touchedGroupIndex = response.spot!.touchedBarGroupIndex;
                  _touchedRodIndex = response.spot!.touchedRodDataIndex;
                });
              }
              _updateHoveredCategoryFromTouch(response, data);
            } else {
              if (_touchedGroupIndex != null || _touchedRodIndex != null) {
                setState(() {
                  _touchedGroupIndex = null;
                  _touchedRodIndex = null;
                });
              }
              _clearHoverWithDebounce();
            }
          }
        },
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
          _buildStackedBar(monthData['income']!, categoryColors, true, index, 0),
          // Expense bar
          _buildStackedBar(monthData['expense']!, categoryColors, false, index, 1),
        ],
      );
    });
  }

  BarChartRodData _buildStackedBar(
    Map<String, double> categoryData,
    Map<String, Color> categoryColors,
    bool isIncome,
    int groupIndex,
    int rodIndex,
  ) {
    final sortedCategories = categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalValue = categoryData.values.fold(0.0, (sum, value) => sum + value);
    final isHighlighted = _touchedGroupIndex == groupIndex && _touchedRodIndex == rodIndex;

    List<BarChartRodStackItem> stackItems = [];
    double currentValue = 0;

    for (var entry in sortedCategories) {
      final categoryName = entry.key;
      final value = entry.value;
      final baseColor = categoryColors[categoryName] ?? Colors.grey;

      // Check if this specific category is being hovered
      final isHovered = _hoveredCategory == categoryName;

      Color color;
      if (_hoveredCategory != null) {
        if (isHovered && isHighlighted) {
          // This is the hovered section
          color = baseColor;
        } else {
          // This is not the hovered section, reduce its opacity
          color = baseColor.withOpacity(0.3);
        }
      } else {
        // No hover, normal state
        color = isIncome
            ? baseColor.withOpacity(0.8)
            : baseColor.withOpacity(0.9);
      }

      stackItems.add(BarChartRodStackItem(
        currentValue,
        currentValue + value,
        color,
      ));

      currentValue += value;
    }

    return BarChartRodData(
      toY: totalValue,
      color: Colors.transparent, // Use transparent as stack items provide the color
      width: isHighlighted ? 24 : 20, // Slightly wider when highlighted
      borderRadius: BorderRadius.circular(4),
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

  void _handleStackTap(
    FlTapUpEvent event,
    BarTouchResponse response,
    Map<String, Map<String, Map<String, double>>> data,
    Map<String, Color> categoryColors,
    TransactionProvider provider,
  ) {
    final spot = response.spot!;
    final groupIndex = spot.touchedBarGroupIndex;
    final rodIndex = spot.touchedRodDataIndex;

    if (groupIndex >= 0 && groupIndex < data.length) {
      final months = data.keys.toList();
      final monthKey = months[groupIndex];
      final type = rodIndex == 0 ? 'income' : 'expense';
      final monthData = data[monthKey]![type]!;

      if (monthData.isNotEmpty) {
        // Find which category was clicked based on the touch position and response
        final categoryName = _findTouchedCategoryAdvanced(
          response,
          groupIndex,
          rodIndex,
          monthData,
          data,
        );

        if (categoryName != null) {
          final categoryColor = categoryColors[categoryName] ?? Colors.grey;

          // Calculate statistics for this specific category
          final statistics = StatisticsService.getCategoryStatistics(
            categoryName,
            data,
            type,
          );

          // Convert local position to global screen coordinates
          final renderBox = context.findRenderObject() as RenderBox;
          final globalPosition = renderBox.localToGlobal(event.localPosition);

          // Show popup at global touch position
          CategoryInfoPopup.show(
            context,
            statistics,
            provider.currencySymbol,
            categoryColor,
            type,
            globalPosition,
          );
        }
      }
    }
  }

  String? _findTouchedCategoryAdvanced(
    BarTouchResponse response,
    int groupIndex,
    int rodIndex,
    Map<String, double> monthData,
    Map<String, Map<String, Map<String, double>>> data,
  ) {
    final spot = response.spot!;
    if (spot == null) return null;

    final stackItemIndex = spot.touchedStackItemIndex;

    if (monthData.isNotEmpty && stackItemIndex != -1) {
      final sortedCategories = monthData.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      if (stackItemIndex >= 0 && stackItemIndex < sortedCategories.length) {
        return sortedCategories[stackItemIndex].key;
      }
    }

    return null;
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

  void _updateHoveredCategoryFromTouch(
    BarTouchResponse response,
    Map<String, Map<String, Map<String, double>>> data,
  ) {
    final spot = response.spot!;
    if (spot == null) {
      _clearHoverWithDebounce();
      return;
    }

    final groupIndex = spot.touchedBarGroupIndex;
    final rodIndex = spot.touchedRodDataIndex;
    final stackItemIndex = spot.touchedStackItemIndex;

    String? newHoveredCategory;

    if (groupIndex >= 0 && groupIndex < data.length && stackItemIndex != -1) {
      final months = data.keys.toList();
      final monthKey = months[groupIndex];
      final type = rodIndex == 0 ? 'income' : 'expense';
      final monthData = data[monthKey]![type]!;

      if (monthData.isNotEmpty) {
        final sortedCategories = monthData.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        if (stackItemIndex >= 0 && stackItemIndex < sortedCategories.length) {
          newHoveredCategory = sortedCategories[stackItemIndex].key;
        }
      }
    }

    if (newHoveredCategory != _pendingHoveredCategory) {
      _pendingHoveredCategory = newHoveredCategory;

      _hoverDebounceTimer?.cancel();

      if (newHoveredCategory == null) {
        _clearHoverWithDebounce();
      } else {
        _hoverDebounceTimer = Timer(const Duration(milliseconds: 50), () {
          if (mounted) {
            setState(() {
              _hoveredCategory = _pendingHoveredCategory;
            });
          }
        });
      }
    }
  }

  void _clearHoverWithDebounce() {
    _pendingHoveredCategory = null;
    _hoverDebounceTimer?.cancel();

    _hoverDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _hoveredCategory = null;
        });
      }
    });
  }

  Widget _buildInteractionHint() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: Colors.blue.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Hover for details • Tap bars for statistics',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
