'use client';

import { useState, useMemo, useCallback } from 'react';
import { Plus, SlidersHorizontal, FileText, PenLine, RefreshCw } from 'lucide-react';
import { useTransactionStore } from '@/lib/stores/transaction-store';
import { useUndoRedoStore } from '@/lib/stores/undo-redo-store';
import { useToast } from '@/components/shared/toast';
import { DateRangeSelector } from '@/components/shared/date-range-selector';
import { SearchInput } from '@/components/shared/search-input';
import { TransactionList } from '@/components/transactions/transaction-list';
import { TransactionDetailsSheet } from '@/components/transactions/transaction-details-sheet';
import { AddTransactionDialog } from '@/components/transactions/add-transaction-dialog';
import { CsvImportDialog } from '@/components/transactions/csv-import-dialog';
import { ConfirmDialog } from '@/components/shared/confirm-dialog';
import { UndoRedoControls } from '@/components/layout/undo-redo-controls';
import { TransactionType, type Transaction } from '@/lib/types';
import { cn } from '@/lib/utils/cn';

export function TransactionsPage() {
  const store = useTransactionStore();
  const { executeCommand } = useUndoRedoStore();
  const { showToast } = useToast();

  const [search, setSearch] = useState('');
  const [showFilters, setShowFilters] = useState(false);
  const [filterType, setFilterType] = useState<TransactionType | null>(null);
  const [filterCategoryId, setFilterCategoryId] = useState<string | null>(null);
  const [selectedTx, setSelectedTx] = useState<Transaction | null>(null);
  const [showAddDialog, setShowAddDialog] = useState(false);
  const [showCsvDialog, setShowCsvDialog] = useState(false);
  const [showAddOptions, setShowAddOptions] = useState(false);
  const [deleteTx, setDeleteTx] = useState<Transaction | null>(null);

  const filtered = store.getFilteredTransactions();

  const displayedTransactions = useMemo(() => {
    let result = filtered;

    if (filterType) {
      result = result.filter((t) => t.type === filterType);
    }

    if (filterCategoryId) {
      result = result.filter((t) => t.categoryId === filterCategoryId);
    }

    if (search) {
      const q = search.toLowerCase();
      result = result.filter((t) => {
        if (t.description.toLowerCase().includes(q)) return true;
        const cat = store.getCategoryById(t.categoryId);
        if (cat?.name.toLowerCase().includes(q)) return true;
        if (cat?.keywords.some((kw) => kw.toLowerCase().includes(q))) return true;
        return false;
      });
    }

    return result;
  }, [filtered, filterType, filterCategoryId, search, store]);

  const activeFilterCount = (filterType ? 1 : 0) + (filterCategoryId ? 1 : 0);

  const handleDelete = useCallback(async (tx: Transaction) => {
    setDeleteTx(tx);
  }, []);

  async function confirmDelete() {
    if (!deleteTx) return;
    const command = store.createDeleteTransactionCommand(deleteTx.id);
    await executeCommand(command);
    showToast('Transaction deleted');
    setDeleteTx(null);
  }

  function handleRecalculate() {
    const result = store.recalculateAllTransactions();
    showToast(
      `Recategorized ${result.recategorized} of ${result.total} transactions`
    );
  }

  return (
    <div className="space-y-4 p-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-bold">Transactions</h1>
        <div className="flex items-center gap-1">
          <UndoRedoControls />
          <button
            onClick={handleRecalculate}
            className="rounded-lg p-2 text-gray-500 hover:bg-gray-100 dark:hover:bg-gray-700"
            title="Recategorize uncategorized transactions"
          >
            <RefreshCw size={18} />
          </button>
          <button
            onClick={() => setShowAddOptions(true)}
            className="rounded-lg bg-blue-600 p-2 text-white hover:bg-blue-700"
          >
            <Plus size={20} />
          </button>
        </div>
      </div>

      <DateRangeSelector />

      {/* Search & Filters */}
      <div className="flex gap-2">
        <div className="flex-1">
          <SearchInput value={search} onChange={setSearch} placeholder="Search transactions..." />
        </div>
        <button
          onClick={() => setShowFilters(!showFilters)}
          className={cn(
            'rounded-lg border px-3 py-2 transition-colors',
            activeFilterCount > 0
              ? 'border-blue-300 bg-blue-50 text-blue-700 dark:border-blue-700 dark:bg-blue-900/20 dark:text-blue-300'
              : 'border-gray-200 dark:border-gray-600'
          )}
        >
          <SlidersHorizontal size={18} />
        </button>
      </div>

      {/* Filter panel */}
      {showFilters && (
        <div className="space-y-3 rounded-xl bg-white p-4 shadow-sm dark:bg-gray-800">
          <div>
            <p className="mb-2 text-xs font-medium text-gray-500">Type</p>
            <div className="flex gap-2">
              {[null, TransactionType.Income, TransactionType.Expense].map((t) => (
                <button
                  key={String(t)}
                  onClick={() => setFilterType(t)}
                  className={cn(
                    'rounded-full px-3 py-1 text-xs font-medium',
                    filterType === t
                      ? 'bg-blue-600 text-white'
                      : 'bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300'
                  )}
                >
                  {t === null ? 'All' : t === TransactionType.Income ? 'Income' : 'Expense'}
                </button>
              ))}
            </div>
          </div>

          <div>
            <p className="mb-2 text-xs font-medium text-gray-500">Category</p>
            <select
              value={filterCategoryId ?? ''}
              onChange={(e) => setFilterCategoryId(e.target.value || null)}
              className="w-full rounded-lg border px-3 py-2 text-sm dark:border-gray-600 dark:bg-gray-700"
            >
              <option value="">All Categories</option>
              {store.categories.map((cat) => (
                <option key={cat.id} value={cat.id}>{cat.name}</option>
              ))}
            </select>
          </div>

          {activeFilterCount > 0 && (
            <button
              onClick={() => { setFilterType(null); setFilterCategoryId(null); }}
              className="text-xs text-blue-600 hover:underline dark:text-blue-400"
            >
              Clear filters
            </button>
          )}
        </div>
      )}

      {/* Active filter chips */}
      {activeFilterCount > 0 && !showFilters && (
        <div className="flex flex-wrap gap-1.5">
          {filterType && (
            <span className="rounded-full bg-blue-100 px-2.5 py-0.5 text-xs font-medium text-blue-700 dark:bg-blue-900/30 dark:text-blue-300">
              {filterType === TransactionType.Income ? 'Income' : 'Expense'}
            </span>
          )}
          {filterCategoryId && (
            <span className="rounded-full bg-blue-100 px-2.5 py-0.5 text-xs font-medium text-blue-700 dark:bg-blue-900/30 dark:text-blue-300">
              {store.getCategoryById(filterCategoryId)?.name}
            </span>
          )}
        </div>
      )}

      {/* Transaction count */}
      <p className="text-xs text-gray-500">
        {displayedTransactions.length} transaction{displayedTransactions.length !== 1 ? 's' : ''}
      </p>

      <TransactionList
        transactions={displayedTransactions}
        onSelect={setSelectedTx}
        onDelete={handleDelete}
      />

      {/* Add options modal */}
      {showAddOptions && (
        <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/50" onClick={() => setShowAddOptions(false)}>
          <div
            className="w-full max-w-md rounded-t-2xl bg-white p-5 shadow-xl dark:bg-gray-800"
            onClick={(e) => e.stopPropagation()}
          >
            <h3 className="mb-4 text-center text-sm font-semibold">Add Transactions</h3>
            <div className="space-y-2">
              <button
                onClick={() => { setShowAddOptions(false); setShowAddDialog(true); }}
                className="flex w-full items-center gap-3 rounded-lg p-3 hover:bg-gray-50 dark:hover:bg-gray-700"
              >
                <PenLine size={20} className="text-blue-500" />
                <div className="text-left">
                  <p className="text-sm font-medium">Manual Entry</p>
                  <p className="text-xs text-gray-500">Add a single transaction</p>
                </div>
              </button>
              <button
                onClick={() => { setShowAddOptions(false); setShowCsvDialog(true); }}
                className="flex w-full items-center gap-3 rounded-lg p-3 hover:bg-gray-50 dark:hover:bg-gray-700"
              >
                <FileText size={20} className="text-green-500" />
                <div className="text-left">
                  <p className="text-sm font-medium">Import CSV</p>
                  <p className="text-xs text-gray-500">Import from bank statement</p>
                </div>
              </button>
            </div>
          </div>
        </div>
      )}

      <AddTransactionDialog open={showAddDialog} onClose={() => setShowAddDialog(false)} />
      <CsvImportDialog open={showCsvDialog} onClose={() => setShowCsvDialog(false)} />

      {selectedTx && (
        <TransactionDetailsSheet transaction={selectedTx} onClose={() => setSelectedTx(null)} />
      )}

      <ConfirmDialog
        open={!!deleteTx}
        title="Delete Transaction"
        message={`Delete "${deleteTx?.description}"? This can be undone.`}
        confirmLabel="Delete"
        destructive
        onConfirm={confirmDelete}
        onCancel={() => setDeleteTx(null)}
      />
    </div>
  );
}
