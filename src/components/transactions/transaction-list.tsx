'use client';

import { useMemo } from 'react';
import { parseISO, format } from 'date-fns';
import { TransactionType, type Transaction } from '@/lib/types';
import { useTransactionStore } from '@/lib/stores/transaction-store';
import { TransactionItem } from './transaction-item';
import { formatCurrency } from '@/lib/utils/currency';
import { cn } from '@/lib/utils/cn';

interface TransactionListProps {
  transactions: Transaction[];
  onSelect: (tx: Transaction) => void;
  onDelete: (tx: Transaction) => void;
}

interface DateGroup {
  dateKey: string;
  label: string;
  transactions: Transaction[];
  total: number;
}

export function TransactionList({ transactions, onSelect, onDelete }: TransactionListProps) {
  const { getCategoryById, currencySymbol } = useTransactionStore();

  const groups: DateGroup[] = useMemo(() => {
    const map = new Map<string, Transaction[]>();
    for (const tx of transactions) {
      const key = format(parseISO(tx.date), 'yyyy-MM-dd');
      const existing = map.get(key) ?? [];
      existing.push(tx);
      map.set(key, existing);
    }

    return Array.from(map.entries())
      .sort(([a], [b]) => b.localeCompare(a))
      .map(([dateKey, txs]) => {
        const total = txs.reduce((sum, t) => {
          const sign = t.type === TransactionType.Income ? 1 : -1;
          return sum + Math.abs(t.amount) * sign;
        }, 0);

        return {
          dateKey,
          label: format(parseISO(dateKey + 'T00:00:00'), 'EEEE, MMMM d, yyyy'),
          transactions: txs,
          total,
        };
      });
  }, [transactions]);

  if (transactions.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-12 text-gray-400">
        <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" className="mb-3">
          <rect x="2" y="3" width="20" height="18" rx="2" />
          <line x1="2" y1="9" x2="22" y2="9" />
        </svg>
        <p className="text-sm">No transactions found</p>
      </div>
    );
  }

  return (
    <div className="space-y-3">
      {groups.map((group) => (
        <div key={group.dateKey}>
          <div className="flex items-center justify-between px-3 py-1.5">
            <span className="text-xs font-medium text-gray-500 dark:text-gray-400">{group.label}</span>
            <span
              className={cn(
                'text-xs font-semibold',
                group.total >= 0 ? 'text-green-600' : 'text-red-600'
              )}
            >
              {group.total >= 0 ? '+' : ''}{formatCurrency(group.total, currencySymbol)}
            </span>
          </div>
          <div className="rounded-xl bg-white shadow-sm dark:bg-gray-800">
            {group.transactions.map((tx) => (
              <TransactionItem
                key={tx.id}
                transaction={tx}
                category={getCategoryById(tx.categoryId)}
                currencySymbol={currencySymbol}
                onClick={() => onSelect(tx)}
                onDelete={() => onDelete(tx)}
              />
            ))}
          </div>
        </div>
      ))}
    </div>
  );
}
