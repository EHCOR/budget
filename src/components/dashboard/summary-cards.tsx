'use client';

import { TrendingUp, TrendingDown, Wallet } from 'lucide-react';
import { formatCurrency } from '@/lib/utils/currency';
import { cn } from '@/lib/utils/cn';

interface SummaryCardsProps {
  income: number;
  expenses: number;
  net: number;
  currencySymbol: string;
}

export function SummaryCards({ income, expenses, net, currencySymbol }: SummaryCardsProps) {
  return (
    <div className="grid grid-cols-3 gap-2">
      <div className="rounded-xl bg-gradient-to-br from-green-50 to-green-100 p-3 dark:from-green-900/20 dark:to-green-800/20">
        <div className="mb-1 flex items-center gap-1.5">
          <TrendingUp size={14} className="text-green-600" />
          <span className="text-xs font-medium text-green-700 dark:text-green-400">Income</span>
        </div>
        <p className="text-sm font-bold text-green-700 dark:text-green-300">
          {formatCurrency(income, currencySymbol)}
        </p>
      </div>

      <div className="rounded-xl bg-gradient-to-br from-red-50 to-red-100 p-3 dark:from-red-900/20 dark:to-red-800/20">
        <div className="mb-1 flex items-center gap-1.5">
          <TrendingDown size={14} className="text-red-600" />
          <span className="text-xs font-medium text-red-700 dark:text-red-400">Expenses</span>
        </div>
        <p className="text-sm font-bold text-red-700 dark:text-red-300">
          {formatCurrency(expenses, currencySymbol)}
        </p>
      </div>

      <div className={cn(
        'rounded-xl p-3',
        net >= 0
          ? 'bg-gradient-to-br from-blue-50 to-blue-100 dark:from-blue-900/20 dark:to-blue-800/20'
          : 'bg-gradient-to-br from-orange-50 to-orange-100 dark:from-orange-900/20 dark:to-orange-800/20'
      )}>
        <div className="mb-1 flex items-center gap-1.5">
          <Wallet size={14} className={net >= 0 ? 'text-blue-600' : 'text-orange-600'} />
          <span className={cn('text-xs font-medium', net >= 0 ? 'text-blue-700 dark:text-blue-400' : 'text-orange-700 dark:text-orange-400')}>
            Net
          </span>
        </div>
        <p className={cn('text-sm font-bold', net >= 0 ? 'text-blue-700 dark:text-blue-300' : 'text-orange-700 dark:text-orange-300')}>
          {net >= 0 ? '+' : ''}{formatCurrency(net, currencySymbol)}
        </p>
      </div>
    </div>
  );
}
