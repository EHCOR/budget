'use client';

import { useMemo } from 'react';
import { BarChart, Bar, XAxis, YAxis, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import { useTransactionStore } from '@/lib/stores/transaction-store';
import { useChartTheme } from '@/hooks/use-chart-theme';
import { formatCompact, formatCurrency } from '@/lib/utils/currency';
import type { MonthlyCategoryData } from '@/lib/types';

interface MonthlyCategoryBarChartProps {
  data: MonthlyCategoryData;
  hideIncomes: boolean;
}

export function MonthlyCategoryBarChart({ data, hideIncomes }: MonthlyCategoryBarChartProps) {
  const { getCategoryColorsMap, currencySymbol } = useTransactionStore();
  const colorMap = getCategoryColorsMap();
  const theme = useChartTheme();

  const { chartData, expenseCategories } = useMemo(() => {
    const months = Object.keys(data);
    const catSet = new Set<string>();

    for (const month of months) {
      Object.keys(data[month].expense).forEach((c) => catSet.add(c));
      if (!hideIncomes) {
        Object.keys(data[month].income).forEach((c) => catSet.add(c));
      }
    }

    const categories = Array.from(catSet);
    const chartData = months.map((month) => {
      const row: Record<string, string | number> = { month };
      for (const cat of categories) {
        const expenseVal = data[month].expense[cat] ?? 0;
        const incomeVal = hideIncomes ? 0 : (data[month].income[cat] ?? 0);
        row[cat] = expenseVal + incomeVal;
      }
      return row;
    });

    return { chartData, expenseCategories: categories };
  }, [data, hideIncomes]);

  if (chartData.length === 0) {
    return <div className="flex h-48 items-center justify-center text-sm text-gray-400">No data</div>;
  }

  return (
    <div>
      <h3 className="mb-3 text-sm font-semibold">Monthly Category Spending</h3>
      <ResponsiveContainer width="100%" height={280}>
        <BarChart data={chartData}>
          <XAxis dataKey="month" tick={{ fontSize: 10, fill: theme.textColor }} stroke={theme.gridColor} />
          <YAxis tickFormatter={(v) => formatCompact(v)} tick={{ fontSize: 10, fill: theme.textColor }} stroke={theme.gridColor} />
          <Tooltip
            formatter={(value: number, name: string) => [
              formatCurrency(value, currencySymbol),
              name,
            ]}
            contentStyle={theme.tooltipStyle}
          />
          <Legend wrapperStyle={theme.legendStyle} />
          {expenseCategories.map((cat) => (
            <Bar
              key={cat}
              dataKey={cat}
              stackId="a"
              fill={colorMap[cat] || '#9e9e9e'}
              radius={[0, 0, 0, 0]}
            />
          ))}
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
}
