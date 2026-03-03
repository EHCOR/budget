import {
  TrendDirection,
  CategoryStatistics,
  OverallStatistics,
  MonthlyCategoryData,
} from '@/lib/types';

export function calculateAverage(values: number[]): number {
  if (values.length === 0) return 0;
  return values.reduce((a, b) => a + b, 0) / values.length;
}

export function calculatePercentageChange(oldValue: number, newValue: number): number {
  if (oldValue === 0) return newValue > 0 ? 100 : 0;
  return ((newValue - oldValue) / oldValue) * 100;
}

function removeOutliers(values: number[]): number[] {
  if (values.length < 4) return [...values];

  const sorted = [...values].sort((a, b) => a - b);
  const q1Index = Math.floor(sorted.length * 0.25);
  const q3Index = Math.floor(sorted.length * 0.75);
  const q1 = sorted[q1Index];
  const q3 = sorted[q3Index];
  const iqr = q3 - q1;

  const lowerBound = q1 - 1.5 * iqr;
  const upperBound = q3 + 1.5 * iqr;

  const filtered = values.filter((v) => v >= lowerBound && v <= upperBound);

  if (filtered.length < Math.ceil(values.length * 0.6)) {
    const relaxedLower = q1 - 2.5 * iqr;
    const relaxedUpper = q3 + 2.5 * iqr;
    return values.filter((v) => v >= relaxedLower && v <= relaxedUpper);
  }

  return filtered;
}

function getRecentAverage(values: number[], count: number): number {
  if (values.length === 0) return 0;
  const recentCount = Math.min(count, values.length);
  const recentValues = values.slice(values.length - recentCount);
  return calculateAverage(recentValues);
}

export function calculateVolatility(values: number[]): number {
  if (values.length < 2) return 0;
  const avg = calculateAverage(values);
  const variance = values.reduce((sum, v) => sum + Math.pow(v - avg, 2), 0) / values.length;
  return Math.sqrt(variance);
}

export function calculateTrend(values: number[]): TrendDirection {
  if (values.length < 2) return TrendDirection.Stable;
  const first = values[0];
  const last = values[values.length - 1];
  if (last > first * 1.05) return TrendDirection.Increasing;
  if (last < first * 0.95) return TrendDirection.Decreasing;
  return TrendDirection.Stable;
}

function calculateMeanRegressionFactor(volatility: number, dataPoints: number): number {
  const volatilityFactor = Math.min(volatility / 100, 0.5);
  const confidenceFactor = Math.max(0.1, 1.0 - dataPoints / 20);
  return volatilityFactor * confidenceFactor;
}

function calculateProjectionBounds(values: number[]): { min: number; max: number } {
  const average = calculateAverage(values);
  const volatility = calculateVolatility(values);
  const maxValue = Math.max(...values);
  const minValue = Math.min(...values);
  const bufferFactor = 1.0 + Math.min(1.0, Math.max(0.2, volatility / average));
  return {
    min: Math.max(0, minValue * 0.3),
    max: maxValue * bufferFactor,
  };
}

function handleDecliningTrend(
  projection: number,
  currentValue: number,
  average: number,
  _slope: number
): number {
  const projectedDrop = currentValue - projection;
  if (projectedDrop > currentValue * 0.3) {
    const reasonableFloor = Math.max(average * 0.2, currentValue * 0.4);
    const dampenedDrop = currentValue * 0.2;
    return Math.max(reasonableFloor, currentValue - dampenedDrop);
  }
  return projection;
}

function applyProjectionDampening(
  rawProjection: number,
  values: number[],
  slope: number
): number {
  const currentValue = values[values.length - 1];
  const average = calculateAverage(values);
  const volatility = calculateVolatility(values);

  const meanRegressionFactor = calculateMeanRegressionFactor(volatility, values.length);
  const meanAdjusted = rawProjection + (average - rawProjection) * meanRegressionFactor;

  const bounds = calculateProjectionBounds(values);
  const bounded = Math.min(Math.max(meanAdjusted, bounds.min), bounds.max);

  if (slope < 0) {
    return handleDecliningTrend(bounded, currentValue, average, slope);
  }

  const maxGrowthRate = 0.5;
  const maxIncrease = currentValue * maxGrowthRate;
  return Math.min(bounded, currentValue + maxIncrease);
}

export function projectNextValue(values: number[]): number {
  if (values.length < 2) return values.length > 0 ? values[0] : 0;

  const cleaned = removeOutliers(values);
  if (cleaned.length < 2) return getRecentAverage(values, 2);

  const n = cleaned.length;
  const x = Array.from({ length: n }, (_, i) => i);
  const y = cleaned;

  const sumX = x.reduce((a, b) => a + b, 0);
  const sumY = y.reduce((a, b) => a + b, 0);
  const sumXY = x.reduce((acc, xi, i) => acc + xi * y[i], 0);
  const sumXX = x.reduce((acc, xi) => acc + xi * xi, 0);

  const denominator = n * sumXX - sumX * sumX;
  if (Math.abs(denominator) < 1e-10) return getRecentAverage(values, 3);

  const slope = (n * sumXY - sumX * sumY) / denominator;
  const intercept = (sumY - slope * sumX) / n;
  const rawProjection = slope * n + intercept;

  return applyProjectionDampening(rawProjection, values, slope);
}

export function getCategoryStatistics(
  categoryName: string,
  monthlyData: MonthlyCategoryData,
  transactionType: 'income' | 'expense'
): CategoryStatistics {
  const values: number[] = [];
  const months = Object.keys(monthlyData);

  for (const monthKey of months) {
    const categoryData = monthlyData[monthKey][transactionType];
    values.push(categoryData[categoryName] ?? 0);
  }

  const currentValue = values.length > 0 ? values[values.length - 1] : 0;
  const average = calculateAverage(values);
  const rawProjected = projectNextValue(values);
  const projected = transactionType === 'expense' && rawProjected < 0 ? 0 : rawProjected;
  const trend = calculateTrend(values);
  const volatility = calculateVolatility(values);

  let percentageChange = 0;
  if (values.length >= 2) {
    percentageChange = calculatePercentageChange(values[values.length - 2], currentValue);
  }

  return {
    categoryName,
    currentValue,
    average,
    projected,
    percentageChange,
    trend,
    volatility,
    dataPoints: values.length,
    timeframePeriod: `${months.length} months`,
    hasSufficientData: values.length >= 2,
  };
}

export function getOverallStatistics(monthlyData: MonthlyCategoryData): OverallStatistics {
  const totalIncomeValues: number[] = [];
  const totalExpenseValues: number[] = [];

  for (const monthData of Object.values(monthlyData)) {
    const incomeTotal = Object.values(monthData.income).reduce((sum, v) => sum + v, 0);
    const expenseTotal = Object.values(monthData.expense).reduce((sum, v) => sum + v, 0);
    totalIncomeValues.push(incomeTotal);
    totalExpenseValues.push(expenseTotal);
  }

  const projectedExpense = projectNextValue(totalExpenseValues);

  return {
    averageIncome: calculateAverage(totalIncomeValues),
    averageExpense: calculateAverage(totalExpenseValues),
    projectedIncome: projectNextValue(totalIncomeValues),
    projectedExpense: projectedExpense < 0 ? 0 : projectedExpense,
    incomeVolatility: calculateVolatility(totalIncomeValues),
    expenseVolatility: calculateVolatility(totalExpenseValues),
    savingsRate: calculateSavingsRate(totalIncomeValues, totalExpenseValues),
  };
}

function calculateSavingsRate(income: number[], expenses: number[]): number {
  if (income.length === 0 || expenses.length === 0) return 0;
  const avgIncome = calculateAverage(income);
  const avgExpense = calculateAverage(expenses);
  if (avgIncome === 0) return 0;
  return ((avgIncome - avgExpense) / avgIncome) * 100;
}
