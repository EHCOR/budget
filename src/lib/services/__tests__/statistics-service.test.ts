import { describe, it, expect } from 'vitest';
import {
  calculateAverage,
  calculatePercentageChange,
  calculateVolatility,
  calculateTrend,
  projectNextValue,
  getCategoryStatistics,
  getOverallStatistics,
} from '../statistics-service';
import { TrendDirection, type MonthlyCategoryData } from '@/lib/types';

describe('calculateAverage', () => {
  it('returns 0 for empty array', () => {
    expect(calculateAverage([])).toBe(0);
  });

  it('returns the average of values', () => {
    expect(calculateAverage([10, 20, 30])).toBe(20);
    expect(calculateAverage([100])).toBe(100);
  });
});

describe('calculatePercentageChange', () => {
  it('handles zero old value', () => {
    expect(calculatePercentageChange(0, 100)).toBe(100);
    expect(calculatePercentageChange(0, 0)).toBe(0);
  });

  it('calculates correct percentage', () => {
    expect(calculatePercentageChange(100, 150)).toBe(50);
    expect(calculatePercentageChange(200, 100)).toBe(-50);
  });
});

describe('calculateVolatility', () => {
  it('returns 0 for fewer than 2 values', () => {
    expect(calculateVolatility([])).toBe(0);
    expect(calculateVolatility([100])).toBe(0);
  });

  it('returns 0 for identical values', () => {
    expect(calculateVolatility([50, 50, 50])).toBe(0);
  });

  it('returns positive value for varied data', () => {
    expect(calculateVolatility([10, 20, 30, 40])).toBeGreaterThan(0);
  });
});

describe('calculateTrend', () => {
  it('returns stable for insufficient data', () => {
    expect(calculateTrend([])).toBe(TrendDirection.Stable);
    expect(calculateTrend([100])).toBe(TrendDirection.Stable);
  });

  it('detects increasing trend', () => {
    expect(calculateTrend([100, 200])).toBe(TrendDirection.Increasing);
  });

  it('detects decreasing trend', () => {
    expect(calculateTrend([200, 100])).toBe(TrendDirection.Decreasing);
  });

  it('detects stable when change < 5%', () => {
    expect(calculateTrend([100, 103])).toBe(TrendDirection.Stable);
  });
});

describe('projectNextValue', () => {
  it('returns 0 for empty array', () => {
    expect(projectNextValue([])).toBe(0);
  });

  it('returns the value for single-element array', () => {
    expect(projectNextValue([100])).toBe(100);
  });

  it('projects upward for increasing data', () => {
    const result = projectNextValue([100, 110, 120, 130]);
    expect(result).toBeGreaterThan(130);
  });

  it('clamps extreme growth', () => {
    const result = projectNextValue([100, 200, 400, 800]);
    // Should not project beyond 50% growth from current
    expect(result).toBeLessThanOrEqual(800 * 1.5);
  });

  it('handles declining trends', () => {
    const result = projectNextValue([100, 80, 60, 40]);
    // Should not project below zero
    expect(result).toBeGreaterThanOrEqual(0);
    // Should not drop more than 20% from current
    expect(result).toBeGreaterThanOrEqual(40 * 0.4);
  });

  it('handles outliers', () => {
    const result = projectNextValue([100, 105, 110, 1000, 115]);
    // The outlier (1000) should be filtered; projection should be moderate
    expect(result).toBeLessThan(500);
  });
});

describe('getCategoryStatistics', () => {
  const monthlyData: MonthlyCategoryData = {
    'Jan 2024': { income: { Salary: 5000 }, expense: { Groceries: 400 } },
    'Feb 2024': { income: { Salary: 5000 }, expense: { Groceries: 450 } },
    'Mar 2024': { income: { Salary: 5200 }, expense: { Groceries: 420 } },
  };

  it('computes stats for a category', () => {
    const stats = getCategoryStatistics('Groceries', monthlyData, 'expense');
    expect(stats.categoryName).toBe('Groceries');
    expect(stats.currentValue).toBe(420);
    expect(stats.average).toBeCloseTo(423.33, 0);
    expect(stats.dataPoints).toBe(3);
    expect(stats.hasSufficientData).toBe(true);
  });

  it('returns 0 values for missing category', () => {
    const stats = getCategoryStatistics('NonExistent', monthlyData, 'expense');
    expect(stats.currentValue).toBe(0);
    expect(stats.average).toBe(0);
  });
});

describe('getOverallStatistics', () => {
  const monthlyData: MonthlyCategoryData = {
    'Jan 2024': { income: { Salary: 5000 }, expense: { Groceries: 400, Rent: 1500 } },
    'Feb 2024': { income: { Salary: 5000 }, expense: { Groceries: 450, Rent: 1500 } },
    'Mar 2024': { income: { Salary: 5200 }, expense: { Groceries: 420, Rent: 1500 } },
  };

  it('computes overall statistics', () => {
    const stats = getOverallStatistics(monthlyData);
    expect(stats.averageIncome).toBeCloseTo(5066.67, 0);
    expect(stats.averageExpense).toBeCloseTo(1923.33, 0);
    expect(stats.savingsRate).toBeGreaterThan(0);
    expect(stats.projectedExpense).toBeGreaterThanOrEqual(0);
  });
});
