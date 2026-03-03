'use client';

import { useState, useMemo } from 'react';
import { Plus, Pencil, Trash2 } from 'lucide-react';
import { useTransactionStore } from '@/lib/stores/transaction-store';
import { SearchInput } from '@/components/shared/search-input';
import { ConfirmDialog } from '@/components/shared/confirm-dialog';
import { CategoryForm } from '@/components/categories/category-form';
import { UndoRedoControls } from '@/components/layout/undo-redo-controls';
import { getIcon } from '@/lib/utils/icons';
import { formatCurrency } from '@/lib/utils/currency';
import type { Category } from '@/lib/types';

export function CategoriesPage() {
  const store = useTransactionStore();
  const [search, setSearch] = useState('');
  const [showForm, setShowForm] = useState(false);
  const [editCat, setEditCat] = useState<Category | undefined>();
  const [deleteCat, setDeleteCat] = useState<Category | null>(null);

  const filteredCategories = useMemo(() => {
    if (!search) return store.categories;
    const q = search.toLowerCase();
    return store.categories.filter(
      (c) =>
        c.name.toLowerCase().includes(q) ||
        c.keywords.some((kw) => kw.toLowerCase().includes(q))
    );
  }, [search, store.categories]);

  function handleEdit(cat: Category) {
    setEditCat(cat);
    setShowForm(true);
  }

  function handleDelete() {
    if (!deleteCat) return;
    store.deleteCategory(deleteCat.id);
    setDeleteCat(null);
  }

  return (
    <div className="space-y-4 p-4">
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-bold">Categories</h1>
        <div className="flex items-center gap-1">
          <UndoRedoControls />
          <button
            onClick={() => {
              setEditCat(undefined);
              setShowForm(true);
            }}
            className="rounded-lg bg-blue-600 p-2 text-white hover:bg-blue-700"
          >
            <Plus size={20} />
          </button>
        </div>
      </div>

      <SearchInput value={search} onChange={setSearch} placeholder="Search categories..." />

      <div className="space-y-2">
        {filteredCategories.map((cat) => {
          const Icon = getIcon(cat.icon);
          const txs = store.getTransactionsByCategory(cat.id);
          const total = txs.reduce((sum, t) => sum + Math.abs(t.amount), 0);

          return (
            <div
              key={cat.id}
              className="flex items-center gap-3 rounded-xl bg-white p-3 shadow-sm dark:bg-gray-800"
            >
              <div
                className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full"
                style={{ backgroundColor: `${cat.color}20` }}
              >
                <Icon size={20} style={{ color: cat.color }} />
              </div>

              <div className="min-w-0 flex-1">
                <p className="text-sm font-semibold">{cat.name}</p>
                <p className="text-xs text-gray-500 dark:text-gray-400">
                  {txs.length} transaction{txs.length !== 1 ? 's' : ''} &middot;{' '}
                  {formatCurrency(total, store.currencySymbol)}
                </p>
                {cat.keywords.length > 0 && (
                  <div className="mt-1 flex flex-wrap gap-1">
                    {cat.keywords.slice(0, 4).map((kw) => (
                      <span
                        key={kw}
                        className="rounded-full bg-gray-100 px-2 py-0.5 text-[10px] text-gray-500 dark:bg-gray-700 dark:text-gray-400"
                      >
                        {kw}
                      </span>
                    ))}
                    {cat.keywords.length > 4 && (
                      <span className="text-[10px] text-gray-400">+{cat.keywords.length - 4} more</span>
                    )}
                  </div>
                )}
              </div>

              <div className="flex shrink-0 gap-1">
                <button
                  onClick={() => handleEdit(cat)}
                  className="rounded-lg p-1.5 text-gray-400 hover:bg-gray-100 hover:text-gray-600 dark:hover:bg-gray-700"
                >
                  <Pencil size={16} />
                </button>
                {cat.id !== 'uncategorized' && (
                  <button
                    onClick={() => setDeleteCat(cat)}
                    className="rounded-lg p-1.5 text-gray-400 hover:bg-red-50 hover:text-red-500 dark:hover:bg-red-900/20"
                  >
                    <Trash2 size={16} />
                  </button>
                )}
              </div>
            </div>
          );
        })}
      </div>

      <CategoryForm
        open={showForm}
        onClose={() => {
          setShowForm(false);
          setEditCat(undefined);
        }}
        editCategory={editCat}
      />

      <ConfirmDialog
        open={!!deleteCat}
        title="Delete Category"
        message={`Delete "${deleteCat?.name}"? All transactions in this category will become uncategorized.`}
        confirmLabel="Delete"
        destructive
        onConfirm={handleDelete}
        onCancel={() => setDeleteCat(null)}
      />
    </div>
  );
}
