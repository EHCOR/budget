'use client';

import { useEffect, useRef } from 'react';
import { formatCurrency } from '@/lib/utils/currency';
import { TrendDirection, type CategoryStatistics } from '@/lib/types';
import { cn } from '@/lib/utils/cn';

interface CategoryInfoPopupProps {
  stats: CategoryStatistics;
  color: string;
  currencySymbol: string;
  position: { x: number; y: number };
  transactionType: 'income' | 'expense';
  onClose: () => void;
}

export function CategoryInfoPopup({
  stats,
  color,
  currencySymbol,
  position,
  transactionType,
  onClose,
}: CategoryInfoPopupProps) {
  const popupRef = useRef<HTMLDivElement>(null);

  // Auto-dismiss after 8 seconds
  useEffect(() => {
    const timer = setTimeout(onClose, 8000);
    return () => clearTimeout(timer);
  }, [onClose]);

  // Adjust position to stay within viewport
  const adjustedPosition = { ...position };
  if (typeof window !== 'undefined') {
    const popupWidth = 280;
    const popupHeight = 240;
    if (adjustedPosition.x + popupWidth > window.innerWidth - 10) {
      adjustedPosition.x = window.innerWidth - popupWidth - 10;
    }
    if (adjustedPosition.y + popupHeight > window.innerHeight - 10) {
      adjustedPosition.y = adjustedPosition.y - popupHeight - 10;
    }
    if (adjustedPosition.x < 10) adjustedPosition.x = 10;
    if (adjustedPosition.y < 10) adjustedPosition.y = 10;
  }

  const trendIcon = stats.trend === TrendDirection.Increasing ? '↑' : stats.trend === TrendDirection.Decreasing ? '↓' : '→';

  // For expenses, increasing is bad (red); for income, increasing is good (green)
  const trendColor =
    stats.trend === TrendDirection.Stable
      ? 'text-gray-500'
      : transactionType === 'expense'
        ? stats.trend === TrendDirection.Increasing ? 'text-red-500' : 'text-green-500'
        : stats.trend === TrendDirection.Increasing ? 'text-green-500' : 'text-red-500';

  const trendLabel =
    stats.trend === TrendDirection.Increasing ? 'Trending Up'
    : stats.trend === TrendDirection.Decreasing ? 'Trending Down'
    : 'Stable';

  return (
    <>
      {/* Dismiss overlay */}
      <div className="fixed inset-0 z-50" onClick={onClose} />

      {/* Popup */}
      <div
        ref={popupRef}
        className="fixed z-50 w-[280px] animate-in fade-in zoom-in-95 rounded-xl bg-white p-4 shadow-xl dark:bg-gray-800"
        style={{
          left: adjustedPosition.x,
          top: adjustedPosition.y,
          borderTop: `3px solid ${color}`,
        }}
      >
        <h4 className="mb-3 text-sm font-bold">{stats.categoryName}</h4>

        <div className="space-y-2">
          <div className="flex justify-between text-xs">
            <span className="text-gray-500">Current</span>
            <span className="font-semibold">{formatCurrency(stats.currentValue, currencySymbol)}</span>
          </div>
          <div className="flex justify-between text-xs">
            <span className="text-gray-500">Average</span>
            <span className="font-semibold">{formatCurrency(stats.average, currencySymbol)}</span>
          </div>
          <div className="flex justify-between text-xs">
            <span className="text-gray-500">Projected</span>
            <span className="font-semibold">{formatCurrency(stats.projected, currencySymbol)}</span>
          </div>
        </div>

        <div className="mt-3 border-t pt-3 dark:border-gray-700">
          <div className="flex items-center justify-between text-xs">
            <span className="text-gray-500">Trend</span>
            <span className={cn('font-semibold', trendColor)}>
              {trendIcon} {trendLabel}
            </span>
          </div>
          {stats.percentageChange !== 0 && (
            <div className="mt-1 flex justify-between text-xs">
              <span className="text-gray-500">Change</span>
              <span className={cn('font-semibold', stats.percentageChange > 0 ? 'text-red-500' : 'text-green-500')}>
                {stats.percentageChange > 0 ? '+' : ''}{stats.percentageChange.toFixed(1)}%
              </span>
            </div>
          )}
          <p className="mt-2 text-[10px] text-gray-400">{stats.dataPoints} data point{stats.dataPoints !== 1 ? 's' : ''}</p>
        </div>
      </div>
    </>
  );
}
