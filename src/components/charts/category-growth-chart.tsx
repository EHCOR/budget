'use client';

import { useMemo, useState } from 'react';
import { LineChart, Line, XAxis, YAxis, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import { useTransactionStore } from '@/lib/stores/transaction-store';
import { useChartTheme } from '@/hooks/use-chart-theme';
import { formatCompact, formatCurrency } from '@/lib/utils/currency';
import { calculateTrend } from '@/lib/services/statistics-service';
import { TrendDirection, type MonthlyCategoryData } from '@/lib/types';
import { cn } from '@/lib/utils/cn';

interface CategoryGrowthChartProps {
  data: MonthlyCategoryData;
  hideIncomes: boolean;
}

export function CategoryGrowthChart({ data, hideIncomes }: CategoryGrowthChartProps) {
  const { getCategoryColorsMap, currencySymbol } = useTransactionStore();
  const colorMap = getCategoryColorsMap();
  const theme = useChartTheme();
  const [txType, setTxType] = useState<'expense' | 'income'>('expense');
  const [showPercent, setShowPercent] = useState(false);

  const { chartData, topCategories } = useMemo(() => {
    const months = Object.keys(data);
    const catTotals: Record<string, number> = {};
    const type = hideIncomes ? 'expense' : txType;

    for (const month of months) {
      for (const [cat, amount] of Object.entries(data[month][type])) {
        catTotals[cat] = (catTotals[cat] ?? 0) + amount;
      }
    }

    const topCats = Object.entries(catTotals)
      .sort(([, a], [, b]) => b - a)
      .slice(0, 5)
      .map(([name]) => name);

    const chartData = months.map((month) => {
      const row: Record<string, string | number> = { month };
      for (const cat of topCats) {
        const val = data[month][type][cat] ?? 0;
        if (showPercent && topCats.length > 0) {
          const firstMonth = months[0];
          const baseline = data[firstMonth][type][cat] ?? 0;
          row[cat] = baseline > 0 ? ((val - baseline) / baseline) * 100 : 0;
        } else {
          row[cat] = val;
        }
      }
      return row;
    });

    return { chartData, topCategories: topCats };
  }, [data, txType, showPercent, hideIncomes]);

  if (chartData.length === 0) {
    return <div className="flex h-48 items-center justify-center text-sm text-gray-400">No data</div>;
  }

  return (
    <div>
      <div className="mb-3 flex items-center justify-between">
        <h3 className="text-sm font-semibold">Category Growth</h3>
        <div className="flex gap-2">
          {!hideIncomes && (
            <div className="flex rounded-lg bg-gray-100 p-0.5 text-xs dark:bg-gray-700">
              {(['expense', 'income'] as const).map((t) => (
                <button
                  key={t}
                  onClick={() => setTxType(t)}
                  className={cn(
                    'rounded-md px-2 py-1 capitalize',
                    txType === t ? 'bg-white shadow dark:bg-gray-600' : ''
                  )}
                >
                  {t}s
                </button>
              ))}
            </div>
          )}
          <button
            onClick={() => setShowPercent(!showPercent)}
            className={cn(
              'rounded-lg px-2 py-1 text-xs',
              showPercent ? 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300' : 'bg-gray-100 dark:bg-gray-700'
            )}
          >
            %
          </button>
        </div>
      </div>

      <ResponsiveContainer width="100%" height={250}>
        <LineChart data={chartData}>
          <XAxis dataKey="month" tick={{ fontSize: 10, fill: theme.textColor }} stroke={theme.gridColor} />
          <YAxis
            tickFormatter={(v) => showPercent ? `${v.toFixed(0)}%` : formatCompact(v)}
            tick={{ fontSize: 10, fill: theme.textColor }}
            stroke={theme.gridColor}
          />
          <Tooltip
            formatter={(value: number, name: string) => [
              showPercent ? `${value.toFixed(1)}%` : formatCurrency(value, currencySymbol),
              name,
            ]}
            contentStyle={theme.tooltipStyle}
          />
          <Legend wrapperStyle={theme.legendStyle} />
          {topCategories.map((cat) => (
            <Line
              key={cat}
              type="monotone"
              dataKey={cat}
              stroke={colorMap[cat] || '#9e9e9e'}
              strokeWidth={2}
              dot={{ r: 3 }}
            />
          ))}
        </LineChart>
      </ResponsiveContainer>

      {/* Growth summary */}
      <div className="mt-3 space-y-1">
        {topCategories.map((cat) => {
          const months = Object.keys(data);
          const type = hideIncomes ? 'expense' : txType;
          const values = months.map((m) => data[m][type][cat] ?? 0);
          const trend = calculateTrend(values);
          const trendIcon = trend === TrendDirection.Increasing ? '↑' : trend === TrendDirection.Decreasing ? '↓' : '→';
          const trendColor = trend === TrendDirection.Increasing ? 'text-red-500' : trend === TrendDirection.Decreasing ? 'text-green-500' : 'text-gray-500';

          return (
            <div key={cat} className="flex items-center justify-between text-xs">
              <div className="flex items-center gap-1.5">
                <div className="h-2 w-2 rounded-full" style={{ backgroundColor: colorMap[cat] }} />
                <span>{cat}</span>
              </div>
              <span className={trendColor}>{trendIcon} {trend}</span>
            </div>
          );
        })}
      </div>
    </div>
  );
}
