'use client';

import { useState, useRef, useEffect } from 'react';
import { format } from 'date-fns';
import { Calendar } from 'lucide-react';
import { useTransactionStore } from '@/lib/stores/transaction-store';
import { getPresetRange } from '@/lib/utils/date';
import { cn } from '@/lib/utils/cn';

interface DateRangeSelectorProps {
  showTrendsOptions?: boolean;
}

const BASE_PRESETS = [
  { key: 'last7', label: 'Last 7 Days' },
  { key: 'last30', label: 'Last 30 Days' },
  { key: 'thisMonth', label: 'This Month' },
  { key: 'lastMonth', label: 'Last Month' },
  { key: 'last3Months', label: 'Last 3 Months' },
];

const TRENDS_PRESETS = [
  { key: 'last6Months', label: 'Last 6 Months' },
  { key: 'last1Year', label: 'Last 1 Year' },
];

export function DateRangeSelector({ showTrendsOptions = false }: DateRangeSelectorProps) {
  const { startDate, endDate, setDateRange, transactions } = useTransactionStore();
  const [activePreset, setActivePreset] = useState<string | null>('last30');
  const [showCustom, setShowCustom] = useState(false);
  const [customStart, setCustomStart] = useState(format(startDate, 'yyyy-MM-dd'));
  const [customEnd, setCustomEnd] = useState(format(endDate, 'yyyy-MM-dd'));
  const customRef = useRef<HTMLDivElement>(null);
  const [customHeight, setCustomHeight] = useState<number | string>(0);

  useEffect(() => {
    if (showCustom) {
      const h = customRef.current?.scrollHeight ?? 0;
      setCustomHeight(h);
    } else {
      setCustomHeight(0);
    }
  }, [showCustom]);

  const presets = showTrendsOptions ? [...BASE_PRESETS, ...TRENDS_PRESETS] : BASE_PRESETS;

  function handlePreset(key: string) {
    if (key === 'allTime') {
      if (transactions.length > 0) {
        const dates = transactions.map((t) => new Date(t.date));
        const earliest = new Date(Math.min(...dates.map((d) => d.getTime())));
        setDateRange(earliest, new Date());
      }
      setActivePreset('allTime');
      return;
    }
    const range = getPresetRange(key);
    setDateRange(range.start, range.end);
    setActivePreset(key);
  }

  function handleCustomApply() {
    setDateRange(new Date(customStart), new Date(customEnd));
    setActivePreset(null);
    setShowCustom(false);
  }

  return (
    <div className="rounded-xl bg-white p-3 shadow-sm dark:bg-gray-800">
      <div className="mb-2 flex items-center justify-between">
        <span className="text-xs font-medium text-gray-500 dark:text-gray-400">
          {format(startDate, 'MMM d, yyyy')} - {format(endDate, 'MMM d, yyyy')}
        </span>
        <button
          onClick={() => setShowCustom(!showCustom)}
          className="rounded-lg p-1.5 text-gray-500 hover:bg-gray-100 dark:hover:bg-gray-700"
        >
          <Calendar size={16} />
        </button>
      </div>

      <div className="flex flex-wrap gap-1.5">
        {presets.map((p) => (
          <button
            key={p.key}
            onClick={() => handlePreset(p.key)}
            className={cn(
              'rounded-full px-3 py-1 text-xs font-medium transition-colors',
              activePreset === p.key
                ? 'bg-blue-600 text-white'
                : 'bg-gray-100 text-gray-700 hover:bg-gray-200 dark:bg-gray-700 dark:text-gray-300 dark:hover:bg-gray-600'
            )}
          >
            {p.label}
          </button>
        ))}
        <button
          onClick={() => handlePreset('allTime')}
          className={cn(
            'rounded-full px-3 py-1 text-xs font-medium transition-colors',
            activePreset === 'allTime'
              ? 'bg-blue-600 text-white'
              : 'bg-gray-100 text-gray-700 hover:bg-gray-200 dark:bg-gray-700 dark:text-gray-300 dark:hover:bg-gray-600'
          )}
        >
          All Time
        </button>
      </div>

      <div
        ref={customRef}
        className="overflow-hidden transition-all duration-300 ease-in-out"
        style={{ height: customHeight }}
      >
        <div className="flex items-end gap-2 border-t pb-1 pt-3 mt-3 dark:border-gray-700">
          <div className="flex-1">
            <label className="mb-1 block text-xs text-gray-500">Start</label>
            <input
              type="date"
              value={customStart}
              onChange={(e) => setCustomStart(e.target.value)}
              className="w-full rounded-lg border bg-white px-2 py-1.5 text-sm dark:border-gray-600 dark:bg-gray-700"
            />
          </div>
          <div className="flex-1">
            <label className="mb-1 block text-xs text-gray-500">End</label>
            <input
              type="date"
              value={customEnd}
              onChange={(e) => setCustomEnd(e.target.value)}
              className="w-full rounded-lg border bg-white px-2 py-1.5 text-sm dark:border-gray-600 dark:bg-gray-700"
            />
          </div>
          <button
            onClick={handleCustomApply}
            className="rounded-lg bg-blue-600 px-3 py-1.5 text-sm font-medium text-white hover:bg-blue-700"
          >
            Apply
          </button>
        </div>
      </div>
    </div>
  );
}
