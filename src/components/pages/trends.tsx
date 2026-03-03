'use client';

import { useState } from 'react';
import { BarChart3 } from 'lucide-react';
import { useTransactionStore } from '@/lib/stores/transaction-store';
import { DateRangeSelector } from '@/components/shared/date-range-selector';
import { MonthlyCategoryBarChart } from '@/components/charts/monthly-category-bar-chart';
import { IncomeExpenseLineChart } from '@/components/charts/income-expense-line-chart';
import { CategoryGrowthChart } from '@/components/charts/category-growth-chart';
import { BudgetAnalysisChart } from '@/components/charts/budget-analysis-chart';
import { cn } from '@/lib/utils/cn';

export function TrendsPage() {
  const { getMonthlyCategoryData, getFilteredTransactions } = useTransactionStore();
  const [hideIncomes, setHideIncomes] = useState(false);

  const monthlyData = getMonthlyCategoryData();
  const hasData = getFilteredTransactions().length > 0;

  return (
    <div className="space-y-4 p-4">
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-bold">Trends</h1>
        <label className="flex items-center gap-2 text-xs">
          <span className="text-gray-500">Hide Income</span>
          <button
            onClick={() => setHideIncomes(!hideIncomes)}
            className={cn(
              'relative h-5 w-9 rounded-full transition-colors',
              hideIncomes ? 'bg-blue-600' : 'bg-gray-300 dark:bg-gray-600'
            )}
          >
            <span
              className={cn(
                'absolute top-0.5 h-4 w-4 rounded-full bg-white transition-transform shadow',
                hideIncomes ? 'left-[18px]' : 'left-0.5'
              )}
            />
          </button>
        </label>
      </div>

      <DateRangeSelector showTrendsOptions />

      {!hasData ? (
        <div className="flex flex-col items-center justify-center py-16 text-gray-400">
          <BarChart3 size={48} className="mb-3" />
          <p className="text-sm">No data for this period</p>
          <p className="text-xs">Import or add transactions to see trends</p>
        </div>
      ) : (
        <div className="space-y-4">
          <div className="rounded-xl bg-white p-4 shadow-sm dark:bg-gray-800">
            <MonthlyCategoryBarChart data={monthlyData} hideIncomes={hideIncomes} />
          </div>

          <div className="rounded-xl bg-white p-4 shadow-sm dark:bg-gray-800">
            <IncomeExpenseLineChart data={monthlyData} />
          </div>

          <div className="rounded-xl bg-white p-4 shadow-sm dark:bg-gray-800">
            <CategoryGrowthChart data={monthlyData} hideIncomes={hideIncomes} />
          </div>

          <div className="rounded-xl bg-white p-4 shadow-sm dark:bg-gray-800">
            <BudgetAnalysisChart data={monthlyData} hideIncomes={hideIncomes} />
          </div>
        </div>
      )}
    </div>
  );
}
