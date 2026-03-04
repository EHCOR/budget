'use client';

import { useState, useMemo } from 'react';
import { X, Trash2, Tag } from 'lucide-react';
import { TransactionType, type Transaction } from '@/lib/types';
import { useTransactionStore } from '@/lib/stores/transaction-store';
import { useUndoRedoStore } from '@/lib/stores/undo-redo-store';
import { useToast } from '@/components/shared/toast';
import { getIcon } from '@/lib/utils/icons';
import { formatCurrency } from '@/lib/utils/currency';
import { formatDate } from '@/lib/utils/date';
import { SearchInput } from '@/components/shared/search-input';
import { ConfirmDialog } from '@/components/shared/confirm-dialog';
import { cn } from '@/lib/utils/cn';

interface TransactionDetailsSheetProps {
  transaction: Transaction;
  onClose: () => void;
}

export function TransactionDetailsSheet({ transaction, onClose }: TransactionDetailsSheetProps) {
  const {
    categories,
    getCategoryById,
    currencySymbol,
    createDeleteTransactionCommand,
    createUpdateTransactionCategoryCommand,
  } = useTransactionStore();
  const { executeCommand } = useUndoRedoStore();
  const { showToast } = useToast();

  const [search, setSearch] = useState('');
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);

  const category = getCategoryById(transaction.categoryId);
  const isIncome = transaction.type === TransactionType.Income;

  const sortedCategories = useMemo(() => {
    const cats = [...categories];
    // Move uncategorized to the top
    const uncatIdx = cats.findIndex((c) => c.id === 'uncategorized');
    if (uncatIdx > 0) {
      const [uncat] = cats.splice(uncatIdx, 1);
      cats.unshift(uncat);
    }
    return cats;
  }, [categories]);

  const filteredCategories = useMemo(() => {
    if (!search) return sortedCategories;
    const q = search.toLowerCase();
    return sortedCategories.filter(
      (c) => c.name.toLowerCase().includes(q) || c.keywords.some((kw) => kw.toLowerCase().includes(q))
    );
  }, [search, sortedCategories]);

  async function handleCategoryChange(catId: string) {
    if (catId === transaction.categoryId) return;
    const command = createUpdateTransactionCategoryCommand(transaction.id, catId);
    await executeCommand(command);
    showToast(`Moved to ${getCategoryById(catId)?.name ?? catId}`);
  }

  async function handleDelete() {
    const command = createDeleteTransactionCommand(transaction.id);
    await executeCommand(command);
    showToast('Transaction deleted');
    onClose();
  }

  return (
    <>
      <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/50 sm:items-center" onClick={onClose}>
        <div
          className="max-h-[80vh] w-full max-w-md overflow-y-auto rounded-t-2xl bg-white p-5 shadow-xl sm:rounded-2xl dark:bg-gray-800"
          onClick={(e) => e.stopPropagation()}
        >
          {/* Header */}
          <div className="mb-4 flex items-center justify-between">
            <h3 className="text-lg font-semibold">Transaction Details</h3>
            <button onClick={onClose} className="rounded-lg p-1 hover:bg-gray-100 dark:hover:bg-gray-700">
              <X size={20} />
            </button>
          </div>

          {/* Details */}
          <div className="space-y-3 rounded-xl bg-gray-50 p-4 dark:bg-gray-700/50">
            <div className="flex justify-between">
              <span className="text-sm text-gray-500">Date</span>
              <span className="text-sm font-medium">{formatDate(transaction.date)}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-sm text-gray-500">Amount</span>
              <span className={cn('text-sm font-bold', isIncome ? 'text-green-600' : 'text-red-600')}>
                {isIncome ? '+' : '-'}{formatCurrency(Math.abs(transaction.amount), currencySymbol)}
              </span>
            </div>
            <div className="flex justify-between">
              <span className="text-sm text-gray-500">Type</span>
              <span className="text-sm font-medium">{isIncome ? 'Income' : 'Expense'}</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-sm text-gray-500">Category</span>
              <div className="flex items-center gap-1.5">
                {(() => {
                  const CatIcon = getIcon(category?.icon || 'Tag');
                  return <CatIcon size={14} style={{ color: category?.color || '#9e9e9e' }} />;
                })()}
                <span className="text-sm font-medium">{category?.name ?? 'Uncategorized'}</span>
              </div>
            </div>
            <div>
              <span className="text-sm text-gray-500">Description</span>
              <p className="mt-0.5 text-sm font-medium">{transaction.description}</p>
            </div>
          </div>

          {/* Smart tag hint for uncategorized */}
          {transaction.categoryId === 'uncategorized' && (
            <div className="mt-3 flex items-center gap-2 rounded-lg bg-blue-50 px-3 py-2 text-xs text-blue-700 dark:bg-blue-900/20 dark:text-blue-300">
              <Tag size={14} />
              <span>Select a category below to organize this transaction</span>
            </div>
          )}

          {/* Category selection */}
          <div className="mt-4">
            <p className="mb-2 text-sm font-medium">Change Category</p>
            <SearchInput value={search} onChange={setSearch} placeholder="Search categories..." />
            <div className="mt-2 max-h-48 overflow-y-auto">
              {filteredCategories.map((cat) => {
                const CatIcon = getIcon(cat.icon);
                const isActive = cat.id === transaction.categoryId;
                return (
                  <button
                    key={cat.id}
                    onClick={() => handleCategoryChange(cat.id)}
                    className={cn(
                      'flex w-full items-center gap-3 rounded-lg px-3 py-2 text-left text-sm transition-colors',
                      isActive
                        ? 'bg-blue-50 font-medium text-blue-700 dark:bg-blue-900/30 dark:text-blue-300'
                        : 'hover:bg-gray-50 dark:hover:bg-gray-700/50'
                    )}
                  >
                    <CatIcon size={16} style={{ color: cat.color }} />
                    <span>{cat.name}</span>
                    {isActive && <span className="ml-auto text-xs text-blue-500">Current</span>}
                  </button>
                );
              })}
            </div>
          </div>

          {/* Delete */}
          <button
            onClick={() => setShowDeleteConfirm(true)}
            className="mt-4 flex w-full items-center justify-center gap-2 rounded-lg border border-red-200 py-2.5 text-sm font-medium text-red-600 transition-colors hover:bg-red-50 dark:border-red-800 dark:hover:bg-red-900/20"
          >
            <Trash2 size={16} />
            Delete Transaction
          </button>
        </div>
      </div>

      <ConfirmDialog
        open={showDeleteConfirm}
        title="Delete Transaction"
        message={`Are you sure you want to delete "${transaction.description}"? This action can be undone.`}
        confirmLabel="Delete"
        destructive
        onConfirm={handleDelete}
        onCancel={() => setShowDeleteConfirm(false)}
      />
    </>
  );
}
