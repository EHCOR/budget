'use client';

import { useState, useMemo } from 'react';
import { Settings } from 'lucide-react';
import { useTransactionStore } from '@/lib/stores/transaction-store';
import { DateRangeSelector } from '@/components/shared/date-range-selector';
import { SummaryCards } from '@/components/dashboard/summary-cards';
import { CategoryPieChart } from '@/components/charts/category-pie-chart';
import { TransactionItem } from '@/components/transactions/transaction-item';
import { TransactionDetailsSheet } from '@/components/transactions/transaction-details-sheet';
import { UndoRedoControls } from '@/components/layout/undo-redo-controls';
import { SettingsPage } from '@/components/pages/settings';
import type { Transaction } from '@/lib/types';

export function DashboardPage() {
  const store = useTransactionStore();
  const [selectedCategoryId, setSelectedCategoryId] = useState<string | null>(null);
  const [selectedTx, setSelectedTx] = useState<Transaction | null>(null);
  const [showSettings, setShowSettings] = useState(false);

  const filtered = store.getFilteredTransactions();
  const income = store.getTotalIncome();
  const expenses = store.getTotalExpenses();
  const net = store.getNetCashFlow();
  const summaries = store.getCategorySummaries();

  const recentTransactions = useMemo(() => {
    const list = selectedCategoryId
      ? filtered.filter((t) => t.categoryId === selectedCategoryId)
      : filtered;
    return list.slice(0, 10);
  }, [filtered, selectedCategoryId]);

  if (showSettings) {
    return <SettingsPage onBack={() => setShowSettings(false)} />;
  }

  return (
    <div className="space-y-4 p-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-bold">Dashboard</h1>
        <div className="flex items-center gap-1">
          <UndoRedoControls />
          <button
            onClick={() => setShowSettings(true)}
            className="rounded-lg p-2 text-gray-500 hover:bg-gray-100 dark:hover:bg-gray-700"
          >
            <Settings size={20} />
          </button>
        </div>
      </div>

      <DateRangeSelector />
      <SummaryCards income={income} expenses={expenses} net={net} currencySymbol={store.currencySymbol} />

      {/* Pie Chart */}
      <div className="rounded-xl bg-white p-4 shadow-sm dark:bg-gray-800">
        <h2 className="mb-2 text-sm font-semibold">Spending by Category</h2>
        <CategoryPieChart
          data={summaries}
          currencySymbol={store.currencySymbol}
          onCategorySelect={setSelectedCategoryId}
        />
      </div>

      {/* Category filter indicator */}
      {selectedCategoryId && (
        <div className="flex items-center justify-between rounded-lg bg-blue-50 px-3 py-2 dark:bg-blue-900/20">
          <span className="text-xs font-medium text-blue-700 dark:text-blue-300">
            Showing: {store.getCategoryById(selectedCategoryId)?.name}
          </span>
          <button
            onClick={() => setSelectedCategoryId(null)}
            className="text-xs text-blue-600 hover:underline dark:text-blue-400"
          >
            Clear
          </button>
        </div>
      )}

      {/* Recent Transactions */}
      <div className="rounded-xl bg-white p-4 shadow-sm dark:bg-gray-800">
        <h2 className="mb-2 text-sm font-semibold">Recent Transactions</h2>
        {recentTransactions.length === 0 ? (
          <p className="py-6 text-center text-sm text-gray-400">No transactions yet</p>
        ) : (
          <div className="-mx-1">
            {recentTransactions.map((tx) => (
              <TransactionItem
                key={tx.id}
                transaction={tx}
                category={store.getCategoryById(tx.categoryId)}
                currencySymbol={store.currencySymbol}
                onClick={() => setSelectedTx(tx)}
                onDelete={() => {
                  const cmd = store.createDeleteTransactionCommand(tx.id);
                  cmd.execute();
                }}
              />
            ))}
          </div>
        )}
      </div>

      {selectedTx && (
        <TransactionDetailsSheet
          transaction={selectedTx}
          onClose={() => setSelectedTx(null)}
        />
      )}
    </div>
  );
}
