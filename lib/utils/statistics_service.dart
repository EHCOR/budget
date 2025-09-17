// utils/statistics_service.dart
import 'dart:math';
import 'dart:math' as math;

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

  // Project next value using improved regression with outlier detection and dampening
  static double projectNextValue(List<double> values) {
    if (values.length < 2) return values.isNotEmpty ? values.first : 0.0;

    // Step 1: Outlier detection and filtering
    final cleanedValues = _removeOutliers(values);

    // If we removed too many values, fall back to recent average
    if (cleanedValues.length < 2) {
      return _getRecentAverage(values, 2);
    }

    // Step 2: Calculate linear regression on cleaned data
    final n = cleanedValues.length;
    final x = List.generate(n, (index) => index.toDouble());
    final y = cleanedValues;

    final sumX = x.reduce((a, b) => a + b);
    final sumY = y.reduce((a, b) => a + b);
    final sumXY = List.generate(n, (i) => x[i] * y[i]).reduce((a, b) => a + b);
    final sumXX = x.map((xi) => xi * xi).reduce((a, b) => a + b);

    final denominator = n * sumXX - sumX * sumX;
    if (denominator.abs() < 1e-10) {
      // Avoid division by zero - data is too linear
      return _getRecentAverage(values, 3);
    }

    final slope = (n * sumXY - sumX * sumY) / denominator;
    final intercept = (sumY - slope * sumX) / n;

    // Step 3: Raw projection
    final rawProjection = slope * n + intercept;

    // Step 4: Apply dampening and bounds
    return _applyProjectionDampening(rawProjection, values, slope);
  }

  // Remove statistical outliers using Interquartile Range (IQR) method
  static List<double> _removeOutliers(List<double> values) {
    if (values.length < 4) return List.from(values); // Too few points for outlier detection

    final sortedValues = List.from(values)..sort();
    final q1Index = (sortedValues.length * 0.25).floor();
    final q3Index = (sortedValues.length * 0.75).floor();

    final q1 = sortedValues[q1Index];
    final q3 = sortedValues[q3Index];
    final iqr = q3 - q1;

    final lowerBound = q1 - 1.5 * iqr;
    final upperBound = q3 + 1.5 * iqr;

    // Keep values within bounds, but preserve at least 60% of original data
    final filtered = values.where((v) => v >= lowerBound && v <= upperBound).toList();

    // If we filtered out too much, be less aggressive
    if (filtered.length < (values.length * 0.6).ceil()) {
      final relaxedLowerBound = q1 - 2.5 * iqr;
      final relaxedUpperBound = q3 + 2.5 * iqr;
      return values.where((v) => v >= relaxedLowerBound && v <= relaxedUpperBound).toList();
    }

    return filtered;
  }

  // Get average of most recent N values
  static double _getRecentAverage(List<double> values, int count) {
    if (values.isEmpty) return 0.0;
    final recentCount = math.min(count, values.length);
    final recentValues = values.sublist(values.length - recentCount);
    return calculateAverage(recentValues);
  }

  // Apply dampening based on volatility and trend characteristics
  static double _applyProjectionDampening(double rawProjection, List<double> values, double slope) {
    final currentValue = values.last;
    final average = calculateAverage(values);
    final volatility = calculateVolatility(values);

    // Step 1: Regression to mean - dampen extreme projections
    final meanRegressionFactor = _calculateMeanRegressionFactor(volatility, values.length);
    final meanAdjustedProjection = rawProjection + (average - rawProjection) * meanRegressionFactor;

    // Step 2: Apply bounds based on historical data
    final projectionBounds = _calculateProjectionBounds(values);
    final boundedProjection = meanAdjustedProjection.clamp(projectionBounds['min']!, projectionBounds['max']!);

    // Step 3: Special handling for declining trends
    if (slope < 0) {
      return _handleDecliningTrend(boundedProjection, currentValue, average, slope);
    }

    // Step 4: Limit extreme growth
    final maxGrowthRate = 0.5; // 50% max increase from current value
    final maxIncrease = currentValue * maxGrowthRate;

    return math.min(boundedProjection, currentValue + maxIncrease);
  }

  // Calculate how much to regress toward the mean based on data volatility
  static double _calculateMeanRegressionFactor(double volatility, int dataPoints) {
    // More volatile data gets more regression to mean
    // More data points get less regression to mean (more confidence in trend)
    final volatilityFactor = math.min(volatility / 100.0, 0.5); // Cap at 50%
    final confidenceFactor = math.max(0.1, 1.0 - (dataPoints / 20.0)); // More data = more confidence

    return volatilityFactor * confidenceFactor;
  }

  // Calculate reasonable bounds for projections based on historical data
  static Map<String, double> _calculateProjectionBounds(List<double> values) {
    final average = calculateAverage(values);
    final volatility = calculateVolatility(values);
    final maxValue = values.reduce(math.max);
    final minValue = values.reduce(math.min);

    // Bounds based on historical range plus some volatility buffer
    final bufferFactor = 1.0 + (volatility / average).clamp(0.2, 1.0);

    return {
      'min': math.max(0.0, minValue * 0.3), // Don't project below 30% of historical minimum
      'max': maxValue * bufferFactor, // Don't exceed max by more than buffer
    };
  }

  // Special handling for declining trends to prevent unrealistic projections
  static double _handleDecliningTrend(double projection, double currentValue, double average, double slope) {
    // For declining trends, we assume they will level off rather than continue indefinitely
    final projectedDrop = currentValue - projection;

    // If projection shows a huge drop, dampen it significantly
    if (projectedDrop > currentValue * 0.3) { // More than 30% drop
      // Project a more moderate decline that levels off toward a reasonable floor
      final reasonableFloor = math.max(average * 0.2, currentValue * 0.4);
      final dampenedDrop = currentValue * 0.2; // Max 20% drop per projection
      return math.max(reasonableFloor, currentValue - dampenedDrop);
    }

    return projection;
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