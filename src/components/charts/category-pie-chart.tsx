'use client';

import { useState } from 'react';
import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip } from 'recharts';
import { formatCurrency } from '@/lib/utils/currency';
import type { CategorySummary } from '@/lib/types';

interface CategoryPieChartProps {
  data: CategorySummary[];
  currencySymbol: string;
  onCategorySelect?: (catId: string | null) => void;
}

export function CategoryPieChart({ data, currencySymbol, onCategorySelect }: CategoryPieChartProps) {
  const [activeIndex, setActiveIndex] = useState<number | null>(null);

  if (data.length === 0) {
    return (
      <div className="flex h-48 items-center justify-center text-sm text-gray-400">
        No data to display
      </div>
    );
  }

  const total = data.reduce((sum, d) => sum + d.amount, 0);

  return (
    <div>
      <ResponsiveContainer width="100%" height={200}>
        <PieChart>
          <Pie
            data={data}
            dataKey="amount"
            nameKey="categoryName"
            cx="50%"
            cy="50%"
            innerRadius={50}
            outerRadius={80}
            paddingAngle={2}
            onClick={(_, index) => {
              if (activeIndex === index) {
                setActiveIndex(null);
                onCategorySelect?.(null);
              } else {
                setActiveIndex(index);
                onCategorySelect?.(data[index].categoryId);
              }
            }}
          >
            {data.map((entry, index) => (
              <Cell
                key={entry.categoryId}
                fill={entry.color}
                opacity={activeIndex === null || activeIndex === index ? 1 : 0.4}
                stroke={activeIndex === index ? entry.color : 'transparent'}
                strokeWidth={activeIndex === index ? 3 : 0}
                cursor="pointer"
              />
            ))}
          </Pie>
          <Tooltip
            formatter={(value: number) => formatCurrency(value, currencySymbol)}
            contentStyle={{
              backgroundColor: 'var(--tooltip-bg, #fff)',
              border: '1px solid #e5e7eb',
              borderRadius: '8px',
              fontSize: '12px',
            }}
          />
        </PieChart>
      </ResponsiveContainer>

      {/* Legend */}
      <div className="mt-2 flex flex-wrap gap-x-4 gap-y-1 px-2">
        {data.slice(0, 5).map((entry) => (
          <div key={entry.categoryId} className="flex items-center gap-1.5">
            <div className="h-2.5 w-2.5 rounded-full" style={{ backgroundColor: entry.color }} />
            <span className="text-xs text-gray-600 dark:text-gray-400">
              {entry.categoryName} ({((entry.amount / total) * 100).toFixed(0)}%)
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}
