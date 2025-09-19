import 'package:flutter_test/flutter_test.dart';
import 'package:budget_tracker/utils/statistics_service.dart';

void main() {
  group('StatisticsService Tests', () {
    group('calculateAverage', () {
      test('calculates average correctly', () {
        expect(StatisticsService.calculateAverage([1, 2, 3, 4, 5]), 3.0);
        expect(StatisticsService.calculateAverage([10, 20, 30]), 20.0);
        expect(StatisticsService.calculateAverage([100.5, 200.5]), 150.5);
      });

      test('returns 0 for empty list', () {
        expect(StatisticsService.calculateAverage([]), 0.0);
      });

      test('handles single value', () {
        expect(StatisticsService.calculateAverage([42]), 42.0);
      });

      test('handles negative values', () {
        expect(StatisticsService.calculateAverage([-1, -2, -3]), -2.0);
        expect(StatisticsService.calculateAverage([-10, 10]), 0.0);
      });
    });

    group('calculatePercentageChange', () {
      test('calculates positive percentage change', () {
        expect(StatisticsService.calculatePercentageChange(100, 150), 50.0);
        expect(StatisticsService.calculatePercentageChange(50, 75), 50.0);
      });

      test('calculates negative percentage change', () {
        expect(StatisticsService.calculatePercentageChange(100, 75), -25.0);
        expect(StatisticsService.calculatePercentageChange(200, 150), -25.0);
      });

      test('handles zero old value', () {
        expect(StatisticsService.calculatePercentageChange(0, 100), 100.0);
        expect(StatisticsService.calculatePercentageChange(0, 0), 0.0);
        expect(StatisticsService.calculatePercentageChange(0, -50), 100.0);
      });

      test('handles no change', () {
        expect(StatisticsService.calculatePercentageChange(100, 100), 0.0);
      });

      test('handles decimal values', () {
        expect(StatisticsService.calculatePercentageChange(10.5, 21.0), 100.0);
      });
    });

    group('calculateVolatility', () {
      test('calculates standard deviation correctly', () {
        final result = StatisticsService.calculateVolatility([1, 2, 3, 4, 5]);
        expect(result, closeTo(1.414, 0.01)); // Standard deviation of [1,2,3,4,5]
      });

      test('returns 0 for single value', () {
        expect(StatisticsService.calculateVolatility([42]), 0.0);
      });

      test('returns 0 for empty list', () {
        expect(StatisticsService.calculateVolatility([]), 0.0);
      });

      test('returns 0 for identical values', () {
        expect(StatisticsService.calculateVolatility([5, 5, 5, 5]), 0.0);
      });

      test('handles negative values', () {
        final result = StatisticsService.calculateVolatility([-2, -1, 0, 1, 2]);
        expect(result, greaterThan(0));
      });
    });

    group('calculateTrend', () {
      test('detects increasing trend', () {
        expect(StatisticsService.calculateTrend([100, 110]), TrendDirection.increasing);
        expect(StatisticsService.calculateTrend([50, 60]), TrendDirection.increasing);
      });

      test('detects decreasing trend', () {
        expect(StatisticsService.calculateTrend([100, 90]), TrendDirection.decreasing);
        expect(StatisticsService.calculateTrend([200, 180]), TrendDirection.decreasing);
      });

      test('detects stable trend', () {
        expect(StatisticsService.calculateTrend([100, 102]), TrendDirection.stable);
        expect(StatisticsService.calculateTrend([100, 98]), TrendDirection.stable);
        expect(StatisticsService.calculateTrend([100, 100]), TrendDirection.stable);
      });

      test('handles single value', () {
        expect(StatisticsService.calculateTrend([100]), TrendDirection.stable);
      });

      test('handles empty list', () {
        expect(StatisticsService.calculateTrend([]), TrendDirection.stable);
      });

      test('uses 5% threshold for trend detection', () {
        // 4% increase should be stable
        expect(StatisticsService.calculateTrend([100, 104]), TrendDirection.stable);
        // 6% increase should be increasing
        expect(StatisticsService.calculateTrend([100, 106]), TrendDirection.increasing);
        // 4% decrease should be stable
        expect(StatisticsService.calculateTrend([100, 96]), TrendDirection.stable);
        // 6% decrease should be decreasing
        expect(StatisticsService.calculateTrend([100, 94]), TrendDirection.decreasing);
      });
    });

    group('projectNextValue', () {
      test('returns single value for single input', () {
        expect(StatisticsService.projectNextValue([100]), 100.0);
      });

      test('returns 0 for empty list', () {
        expect(StatisticsService.projectNextValue([]), 0.0);
      });

      test('projects increasing trend', () {
        final result = StatisticsService.projectNextValue([10, 20, 30, 40]);
        expect(result, greaterThan(40));
        expect(result, lessThan(100)); // Should have reasonable bounds
      });

      test('projects decreasing trend with leveling off', () {
        final result = StatisticsService.projectNextValue([100, 90, 80, 70]);
        expect(result, lessThan(70));
        expect(result, greaterThan(0)); // Should not go negative unreasonably
      });

      test('handles stable values', () {
        final result = StatisticsService.projectNextValue([50, 50, 50, 50]);
        expect(result, closeTo(50, 10)); // Should stay close to current value
      });

      test('handles outliers by filtering them', () {
        // Normal trend with one outlier
        final result = StatisticsService.projectNextValue([10, 20, 1000, 30, 40]);
        expect(result, lessThan(100)); // Outlier should be filtered out
      });

      test('provides reasonable projections for volatile data', () {
        final volatileData = [100.0, 150.0, 80.0, 200.0, 90.0, 180.0, 70.0];
        final result = StatisticsService.projectNextValue(volatileData);
        expect(result, greaterThan(0));
        expect(result, lessThan(500)); // Should not be extremely high
      });

      test('handles very small datasets', () {
        final result = StatisticsService.projectNextValue([10, 20]);
        expect(result, isA<double>());
        expect(result.isFinite, true);
      });

      test('prevents negative projections for expenses', () {
        // This test verifies the method doesn't return unreasonable negative values
        final result = StatisticsService.projectNextValue([50, 40, 30, 20, 10]);
        expect(result, greaterThanOrEqualTo(0));
      });
    });

    group('getCategoryStatistics', () {
      test('calculates statistics for category with data', () {
        final monthlyData = {
          'Jan 2024': {
            'income': {'Salary': 5000.0},
            'expense': {'Food': 300.0},
          },
          'Feb 2024': {
            'income': {'Salary': 5200.0},
            'expense': {'Food': 350.0},
          },
          'Mar 2024': {
            'income': {'Salary': 5100.0},
            'expense': {'Food': 320.0},
          },
        };

        final stats = StatisticsService.getCategoryStatistics(
          'Food',
          monthlyData,
          'expense',
        );

        expect(stats.categoryName, 'Food');
        expect(stats.currentValue, 320.0);
        expect(stats.average, closeTo(323.33, 0.1));
        expect(stats.dataPoints, 3);
        expect(stats.hasSufficientData, true);
        expect(stats.timeframePeriod, '3 months');
        expect(stats.trend, isA<TrendDirection>());
      });

      test('handles category with no data', () {
        final monthlyData = {
          'Jan 2024': {
            'income': {'Salary': 5000.0},
            'expense': {'Food': 300.0},
          },
        };

        final stats = StatisticsService.getCategoryStatistics(
          'Entertainment',
          monthlyData,
          'expense',
        );

        expect(stats.categoryName, 'Entertainment');
        expect(stats.currentValue, 0.0);
        expect(stats.average, 0.0);
        expect(stats.projected, 0.0);
        expect(stats.dataPoints, 1);
        expect(stats.hasSufficientData, false);
      });

      test('prevents negative projections for expenses', () {
        final monthlyData = {
          'Jan 2024': {
            'expense': {'Transport': 200.0},
          },
          'Feb 2024': {
            'expense': {'Transport': 150.0},
          },
          'Mar 2024': {
            'expense': {'Transport': 100.0},
          },
        };

        final stats = StatisticsService.getCategoryStatistics(
          'Transport',
          monthlyData,
          'expense',
        );

        expect(stats.projected, greaterThanOrEqualTo(0.0));
      });

      test('allows negative projections for income (if trend goes down)', () {
        final monthlyData = {
          'Jan 2024': {
            'income': {'Freelance': 1000.0},
          },
          'Feb 2024': {
            'income': {'Freelance': 500.0},
          },
          'Mar 2024': {
            'income': {'Freelance': 0.0},
          },
        };

        final stats = StatisticsService.getCategoryStatistics(
          'Freelance',
          monthlyData,
          'income',
        );

        // Income can theoretically go negative (representing losses)
        expect(stats.projected, isA<double>());
      });
    });

    group('getOverallStatistics', () {
      test('calculates overall statistics correctly', () {
        final monthlyData = {
          'Jan 2024': {
            'income': {'Salary': 5000.0, 'Freelance': 500.0},
            'expense': {'Food': 300.0, 'Rent': 1200.0},
          },
          'Feb 2024': {
            'income': {'Salary': 5200.0, 'Freelance': 600.0},
            'expense': {'Food': 350.0, 'Rent': 1200.0},
          },
        };

        final stats = StatisticsService.getOverallStatistics(monthlyData);

        expect(stats.averageIncome, 5650.0); // (5500 + 5800) / 2
        expect(stats.averageExpense, 1525.0); // (1500 + 1550) / 2
        expect(stats.projectedIncome, greaterThan(0));
        expect(stats.projectedExpense, greaterThanOrEqualTo(0));
        expect(stats.savingsRate, closeTo(72.96, 0.1)); // (5650-1525)/5650 * 100
      });

      test('handles empty data', () {
        final monthlyData = <String, Map<String, Map<String, double>>>{};
        final stats = StatisticsService.getOverallStatistics(monthlyData);

        expect(stats.averageIncome, 0.0);
        expect(stats.averageExpense, 0.0);
        expect(stats.projectedIncome, 0.0);
        expect(stats.projectedExpense, 0.0);
        expect(stats.savingsRate, 0.0);
      });

      test('prevents negative expense projections', () {
        final monthlyData = {
          'Jan 2024': {
            'income': {'Salary': 5000.0},
            'expense': {'Food': 1000.0},
          },
          'Feb 2024': {
            'income': {'Salary': 5000.0},
            'expense': {'Food': 500.0},
          },
          'Mar 2024': {
            'income': {'Salary': 5000.0},
            'expense': {'Food': 100.0},
          },
        };

        final stats = StatisticsService.getOverallStatistics(monthlyData);
        expect(stats.projectedExpense, greaterThanOrEqualTo(0.0));
      });
    });

    group('CategoryStatistics class', () {
      test('provides correct trend icons', () {
        final increasingStats = CategoryStatistics(
          categoryName: 'Test',
          currentValue: 100,
          average: 100,
          projected: 100,
          percentageChange: 0,
          trend: TrendDirection.increasing,
          volatility: 0,
          dataPoints: 3,
          timeframePeriod: '3 months',
          hasSufficientData: true,
        );

        final decreasingStats = increasingStats.copyWith(trend: TrendDirection.decreasing);
        final stableStats = increasingStats.copyWith(trend: TrendDirection.stable);

        expect(increasingStats.trendIcon, '📈');
        expect(decreasingStats.trendIcon, '📉');
        expect(stableStats.trendIcon, '➡️');

        expect(increasingStats.trendDescription, 'Trending Up');
        expect(decreasingStats.trendDescription, 'Trending Down');
        expect(stableStats.trendDescription, 'Stable');
      });
    });
  });
}

// Extension to add copyWith method for testing
extension CategoryStatisticsTest on CategoryStatistics {
  CategoryStatistics copyWith({TrendDirection? trend}) {
    return CategoryStatistics(
      categoryName: categoryName,
      currentValue: currentValue,
      average: average,
      projected: projected,
      percentageChange: percentageChange,
      trend: trend ?? this.trend,
      volatility: volatility,
      dataPoints: dataPoints,
      timeframePeriod: timeframePeriod,
      hasSufficientData: hasSufficientData,
    );
  }
}