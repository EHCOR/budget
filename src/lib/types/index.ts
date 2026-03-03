export enum TransactionType {
  Income = 'income',
  Expense = 'expense',
}

export interface Transaction {
  id: string;
  date: string; // ISO 8601
  description: string;
  amount: number; // always positive in storage; type determines sign semantics
  categoryId: string;
  type: TransactionType;
}

export interface Category {
  id: string;
  name: string;
  color: string; // hex e.g. '#4caf50'
  icon: string; // lucide icon name
  keywords: string[];
}

export interface CategorySummary {
  categoryId: string;
  categoryName: string;
  amount: number;
  color: string;
  icon: string;
}

export interface AppSettings {
  currencyCode: string;
  currencySymbol: string;
  themeMode: 'light' | 'dark' | 'system';
}

export enum TrendDirection {
  Increasing = 'increasing',
  Decreasing = 'decreasing',
  Stable = 'stable',
}

export interface CategoryStatistics {
  categoryName: string;
  currentValue: number;
  average: number;
  projected: number;
  percentageChange: number;
  trend: TrendDirection;
  volatility: number;
  dataPoints: number;
  timeframePeriod: string;
  hasSufficientData: boolean;
}

export interface OverallStatistics {
  averageIncome: number;
  averageExpense: number;
  projectedIncome: number;
  projectedExpense: number;
  incomeVolatility: number;
  expenseVolatility: number;
  savingsRate: number;
}

export interface ImportResult {
  imported: number;
  duplicates: number;
  total: number;
}

export interface MonthlyStats {
  [monthKey: string]: {
    income: number;
    expenses: number;
    net: number;
  };
}

// month -> type -> categoryName -> amount
export interface MonthlyCategoryData {
  [monthKey: string]: {
    income: Record<string, number>;
    expense: Record<string, number>;
  };
}

export interface Currency {
  code: string;
  symbol: string;
  name: string;
}
