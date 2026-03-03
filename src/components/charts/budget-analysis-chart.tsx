'use client';

import { useMemo, useState } from 'react';
import { BarChart, Bar, XAxis, YAxis, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import { useTransactionStore } from '@/lib/stores/transaction-store';
import { formatCompact, formatCurrency } from '@/lib/utils/currency';
import { calculateAverage } from '@/lib/services/statistics-service';
import type { MonthlyCategoryData } from '@/lib/types';
import { cn } from '@/lib/utils/cn';

type BudgetType = 'historical' | 'conservative' | 'target';

interface BudgetAnalysisChartProps {
  data: MonthlyCategoryData;
  hideIncomes: boolean;
}

export function BudgetAnalysisChart({ data, hideIncomes }: BudgetAnalysisChartProps) {
  const { getCategoryColorsMap, currencySymbol } = useTransactionStore();
  const colorMap = getCategoryColorsMap();
  const [budgetType, setBudgetType] = useState<BudgetType>('historical');

  const { chartData, latestVariance } = useMemo(() => {
    const months = Object.keys(data);
    const catTotals: Record<string, number[]> = {};

    for (const month of months) {
      for (const [cat, amount] of Object.entries(data[month].expense)) {
        if (!catTotals[cat]) catTotals[cat] = [];
        catTotals[cat].push(amount);
      }
    }

    // Top 6 expense categories
    const topCats = Object.entries(catTotals)
      .map(([name, values]) => ({ name, total: values.reduce((a, b) => a + b, 0) }))
      .sort((a, b) => b.total - a.total)
      .slice(0, 6)
      .map((c) => c.name);

    const budgetMultiplier = budgetType === 'conservative' ? 0.8 : budgetType === 'target' ? 0.7 : 1.0;

    const chartData = topCats.map((cat) => {
      const values = catTotals[cat] ?? [];
      const avg = calculateAverage(values);
      const latest = values.length > 0 ? values[values.length - 1] : 0;
      const budget = avg * budgetMultiplier;
      return { category: cat, Actual: latest, Budget: budget };
    });

    // Variance for latest month
    const latestVariance = chartData.map((row) => {
      const variance = row.Actual - row.Budget;
      const pct = row.Budget > 0 ? (variance / row.Budget) * 100 : 0;
      return { category: row.category, variance, pct };
    });

    return { chartData, latestVariance };
  }, [data, budgetType]);

  if (chartData.length === 0) {
    return <div className="flex h-48 items-center justify-center text-sm text-gray-400">No data</div>;
  }

  const budgetLabels: Record<BudgetType, string> = {
    historical: 'Historical Avg',
    conservative: 'Conservative (80%)',
    target: 'Target (70%)',
  };

  return (
    <div>
      <div className="mb-3 flex items-center justify-between">
        <h3 className="text-sm font-semibold">Budget Analysis</h3>
        <div className="flex rounded-lg bg-gray-100 p-0.5 text-xs dark:bg-gray-700">
          {(['historical', 'conservative', 'target'] as const).map((t) => (
            <button
              key={t}
              onClick={() => setBudgetType(t)}
              className={cn(
                'rounded-md px-2 py-1 capitalize',
                budgetType === t ? 'bg-white shadow dark:bg-gray-600' : ''
              )}
            >
              {t === 'historical' ? 'Avg' : t === 'conservative' ? '80%' : '70%'}
            </button>
          ))}
        </div>
      </div>

      <ResponsiveContainer width="100%" height={250}>
        <BarChart data={chartData} layout="vertical">
          <XAxis type="number" tickFormatter={(v) => formatCompact(v)} tick={{ fontSize: 10 }} />
          <YAxis dataKey="category" type="category" tick={{ fontSize: 10 }} width={80} />
          <Tooltip
            formatter={(value: number, name: string) => [
              formatCurrency(value, currencySymbol),
              name,
            ]}
            contentStyle={{ fontSize: '11px', borderRadius: '8px' }}
          />
          <Legend wrapperStyle={{ fontSize: '10px' }} />
          <Bar dataKey="Actual" fill="#2196f3" radius={[0, 4, 4, 0]} />
          <Bar dataKey="Budget" fill="#9e9e9e" radius={[0, 4, 4, 0]} />
        </BarChart>
      </ResponsiveContainer>

      {/* Variance summary */}
      <div className="mt-3 space-y-1">
        <p className="text-xs font-medium text-gray-500">
          Budget Variance ({budgetLabels[budgetType]})
        </p>
        {latestVariance.map((v) => (
          <div key={v.category} className="flex items-center justify-between text-xs">
            <div className="flex items-center gap-1.5">
              <div className="h-2 w-2 rounded-full" style={{ backgroundColor: colorMap[v.category] ?? '#9e9e9e' }} />
              <span>{v.category}</span>
            </div>
            <span className={v.variance > 0 ? 'text-red-500' : 'text-green-500'}>
              {v.variance > 0 ? '+' : ''}{formatCurrency(v.variance, currencySymbol)} ({v.pct.toFixed(0)}%)
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}
