'use client';

import { TransactionType, type Transaction, type Category } from '@/lib/types';
import { getIcon } from '@/lib/utils/icons';
import { formatCurrency } from '@/lib/utils/currency';
import { cn } from '@/lib/utils/cn';

interface TransactionItemProps {
  transaction: Transaction;
  category: Category | undefined;
  currencySymbol: string;
  onClick: () => void;
  onDelete: () => void;
}

export function TransactionItem({ transaction, category, currencySymbol, onClick, onDelete }: TransactionItemProps) {
  const Icon = getIcon(category?.icon || 'Tag');
  const isIncome = transaction.type === TransactionType.Income;

  return (
    <div
      className="group flex cursor-pointer items-center gap-3 rounded-lg px-3 py-2.5 transition-colors hover:bg-gray-50 dark:hover:bg-gray-700/50"
      onClick={onClick}
    >
      <div
        className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full"
        style={{ backgroundColor: `${category?.color || '#9e9e9e'}20` }}
      >
        <Icon size={18} style={{ color: category?.color || '#9e9e9e' }} />
      </div>

      <div className="min-w-0 flex-1">
        <p className="truncate text-sm font-medium">{transaction.description}</p>
        <p className="text-xs text-gray-500 dark:text-gray-400">{category?.name ?? 'Uncategorized'}</p>
      </div>

      <div className="text-right">
        <p className={cn('text-sm font-semibold', isIncome ? 'text-green-600' : 'text-red-600')}>
          {isIncome ? '+' : '-'}{formatCurrency(Math.abs(transaction.amount), currencySymbol)}
        </p>
      </div>

      <button
        onClick={(e) => {
          e.stopPropagation();
          onDelete();
        }}
        className="ml-1 hidden rounded p-1 text-gray-400 hover:bg-red-50 hover:text-red-500 group-hover:block dark:hover:bg-red-900/20"
        title="Delete"
      >
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <path d="M3 6h18M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" />
        </svg>
      </button>
    </div>
  );
}
