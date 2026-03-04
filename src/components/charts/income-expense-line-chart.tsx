'use client';

import { useMemo } from 'react';
import { LineChart, Line, XAxis, YAxis, Tooltip, Legend, ResponsiveContainer, Area, ComposedChart } from 'recharts';
import { useTransactionStore } from '@/lib/stores/transaction-store';
import { useChartTheme } from '@/hooks/use-chart-theme';
import { formatCompact, formatCurrency } from '@/lib/utils/currency';
import type { MonthlyCategoryData } from '@/lib/types';

interface IncomeExpenseLineChartProps {
  data: MonthlyCategoryData;
}

export function IncomeExpenseLineChart({ data }: IncomeExpenseLineChartProps) {
  const { currencySymbol } = useTransactionStore();
  const theme = useChartTheme();

  const { chartData, totalIncome, totalExpenses } = useMemo(() => {
    const months = Object.keys(data);
    let totalIncome = 0;
    let totalExpenses = 0;

    const chartData = months.map((month) => {
      const income = Object.values(data[month].income).reduce((a, b) => a + b, 0);
      const expense = Object.values(data[month].expense).reduce((a, b) => a + b, 0);
      totalIncome += income;
      totalExpenses += expense;
      return { month, Income: income, Expenses: expense, Net: income - expense };
    });

    return { chartData, totalIncome, totalExpenses };
  }, [data]);

  if (chartData.length === 0) {
    return <div className="flex h-48 items-center justify-center text-sm text-gray-400">No data</div>;
  }

  const netSavings = totalIncome - totalExpenses;
  const savingsRate = totalIncome > 0 ? ((netSavings / totalIncome) * 100).toFixed(1) : '0.0';

  return (
    <div>
      <h3 className="mb-3 text-sm font-semibold">Income vs Expenses</h3>

      <ResponsiveContainer width="100%" height={250}>
        <ComposedChart data={chartData}>
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
          <Area type="monotone" dataKey="Income" fill="#4caf50" fillOpacity={0.19} stroke="#4caf50" strokeWidth={2} />
          <Area type="monotone" dataKey="Expenses" fill="#f44336" fillOpacity={0.19} stroke="#f44336" strokeWidth={2} />
          <Line type="monotone" dataKey="Net" stroke="#2196f3" strokeWidth={2} strokeDasharray="5 5" dot={false} />
        </ComposedChart>
      </ResponsiveContainer>

      {/* Summary */}
      <div className="mt-3 grid grid-cols-4 gap-2 text-center">
        <div>
          <p className="text-[10px] text-gray-500">Total Income</p>
          <p className="text-xs font-bold text-green-600">{formatCurrency(totalIncome, currencySymbol)}</p>
        </div>
        <div>
          <p className="text-[10px] text-gray-500">Total Expenses</p>
          <p className="text-xs font-bold text-red-600">{formatCurrency(totalExpenses, currencySymbol)}</p>
        </div>
        <div>
          <p className="text-[10px] text-gray-500">Net Savings</p>
          <p className="text-xs font-bold text-blue-600">{formatCurrency(netSavings, currencySymbol)}</p>
        </div>
        <div>
          <p className="text-[10px] text-gray-500">Savings Rate</p>
          <p className="text-xs font-bold text-blue-600">{savingsRate}%</p>
        </div>
      </div>
    </div>
  );
}
