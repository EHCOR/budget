// utils/statistics_service.dart
import 'dart:math';

class StatisticsService {
  // Calculate average of a list of values
  static double calculateAverage(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  // Calculate percentage change between two values
  static double calculatePercentageChange(double oldValue, double newValue) {
    if (oldValue == 0) return newValue > 0 ? 100.0 : 0.0;
    return ((newValue - oldValue) / oldValue) * 100;
  }

  // Project next value using linear regression
  static double projectNextValue(List<double> values) {
    if (values.length < 2) return values.isNotEmpty ? values.first : 0.0;

    // Simple linear regression
    final n = values.length;
    final x = List.generate(n, (index) => index.toDouble());
    final y = values;

    final sumX = x.reduce((a, b) => a + b);
    final sumY = y.reduce((a, b) => a + b);
    final sumXY = List.generate(n, (i) => x[i] * y[i]).reduce((a, b) => a + b);
    final sumXX = x.map((xi) => xi * xi).reduce((a, b) => a + b);

    final slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
    final intercept = (sumY - slope * sumX) / n;

    // Project next value (x = n)
    return slope * n + intercept;
  }

  // Calculate trend direction
  static TrendDirection calculateTrend(List<double> values) {
    if (values.length < 2) return TrendDirection.stable;

    final first = values.first;
    final last = values.last;

    if (last > first * 1.05) return TrendDirection.increasing;
    if (last < first * 0.95) return TrendDirection.decreasing;
    return TrendDirection.stable;
  }

  // Calculate volatility (standard deviation)
  static double calculateVolatility(List<double> values) {
    if (values.length < 2) return 0.0;

    final average = calculateAverage(values);
    final variance = values
        .map((value) => pow(value - average, 2))
        .reduce((a, b) => a + b) / values.length;

    return sqrt(variance);
  }

  // Get category statistics for a specific timeframe
  static CategoryStatistics getCategoryStatistics(
    String categoryName,
    Map<String, Map<String, Map<String, double>>> monthlyData,
    String transactionType, // 'income' or 'expense'
  ) {
    final List<double> values = [];
    final List<String> months = monthlyData.keys.toList();

    // Extract values for this category across all months
    for (final monthKey in months) {
      final categoryData = monthlyData[monthKey]![transactionType]!;
      values.add(categoryData[categoryName] ?? 0.0);
    }

    final currentValue = values.isNotEmpty ? values.last : 0.0;
    final average = calculateAverage(values);
    final rawProjected = projectNextValue(values);
    // For expenses, prevent negative projections (can't make money from spending)
    final projected = (transactionType == 'expense' && rawProjected < 0) ? 0.0 : rawProjected;
    final trend = calculateTrend(values);
    final volatility = calculateVolatility(values);

    double percentageChange = 0.0;
    if (values.length >= 2) {
      percentageChange = calculatePercentageChange(values[values.length - 2], currentValue);
    }

    return CategoryStatistics(
      categoryName: categoryName,
      currentValue: currentValue,
      average: average,
      projected: projected,
      percentageChange: percentageChange,
      trend: trend,
      volatility: volatility,
      dataPoints: values.length,
      timeframePeriod: '${months.length} months',
      hasSufficientData: values.length >= 2, // Need at least 2 data points for meaningful trends
    );
  }

  // Get overall spending statistics
  static OverallStatistics getOverallStatistics(
    Map<String, Map<String, Map<String, double>>> monthlyData,
  ) {
    final List<double> totalIncomeValues = [];
    final List<double> totalExpenseValues = [];

    for (final monthData in monthlyData.values) {
      final incomeTotal = monthData['income']!.values.fold(0.0, (sum, value) => sum + value);
      final expenseTotal = monthData['expense']!.values.fold(0.0, (sum, value) => sum + value);

      totalIncomeValues.add(incomeTotal);
      totalExpenseValues.add(expenseTotal);
    }

    // Ensure projected expenses can't go negative (making money from spending)
    final projectedExpense = projectNextValue(totalExpenseValues);
    final clampedProjectedExpense = projectedExpense < 0 ? 0.0 : projectedExpense;

    return OverallStatistics(
      averageIncome: calculateAverage(totalIncomeValues),
      averageExpense: calculateAverage(totalExpenseValues),
      projectedIncome: projectNextValue(totalIncomeValues),
      projectedExpense: clampedProjectedExpense,
      incomeVolatility: calculateVolatility(totalIncomeValues),
      expenseVolatility: calculateVolatility(totalExpenseValues),
      savingsRate: _calculateSavingsRate(totalIncomeValues, totalExpenseValues),
    );
  }

  static double _calculateSavingsRate(List<double> income, List<double> expenses) {
    if (income.isEmpty || expenses.isEmpty) return 0.0;

    final avgIncome = calculateAverage(income);
    final avgExpense = calculateAverage(expenses);

    if (avgIncome == 0) return 0.0;
    return ((avgIncome - avgExpense) / avgIncome) * 100;
  }
}

enum TrendDirection {
  increasing,
  decreasing,
  stable,
}

class CategoryStatistics {
  final String categoryName;
  final double currentValue;
  final double average;
  final double projected;
  final double percentageChange;
  final TrendDirection trend;
  final double volatility;
  final int dataPoints;
  final String timeframePeriod;
  final bool hasSufficientData;

  CategoryStatistics({
    required this.categoryName,
    required this.currentValue,
    required this.average,
    required this.projected,
    required this.percentageChange,
    required this.trend,
    required this.volatility,
    required this.dataPoints,
    required this.timeframePeriod,
    required this.hasSufficientData,
  });

  String get trendIcon {
    switch (trend) {
      case TrendDirection.increasing:
        return '📈';
      case TrendDirection.decreasing:
        return '📉';
      case TrendDirection.stable:
        return '➡️';
    }
  }

  String get trendDescription {
    switch (trend) {
      case TrendDirection.increasing:
        return 'Trending Up';
      case TrendDirection.decreasing:
        return 'Trending Down';
      case TrendDirection.stable:
        return 'Stable';
    }
  }
}

class OverallStatistics {
  final double averageIncome;
  final double averageExpense;
  final double projectedIncome;
  final double projectedExpense;
  final double incomeVolatility;
  final double expenseVolatility;
  final double savingsRate;

  OverallStatistics({
    required this.averageIncome,
    required this.averageExpense,
    required this.projectedIncome,
    required this.projectedExpense,
    required this.incomeVolatility,
    required this.expenseVolatility,
    required this.savingsRate,
  });
}