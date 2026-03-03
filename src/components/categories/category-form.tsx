'use client';

import { useState, useEffect } from 'react';
import { X } from 'lucide-react';
import { IconPicker } from './icon-picker';
import { ColorPicker } from './color-picker';
import { useTransactionStore } from '@/lib/stores/transaction-store';
import { useToast } from '@/components/shared/toast';
import type { Category } from '@/lib/types';

interface CategoryFormProps {
  open: boolean;
  onClose: () => void;
  editCategory?: Category;
}

export function CategoryForm({ open, onClose, editCategory }: CategoryFormProps) {
  const { addCategory, updateCategory, updateCategoryAndRecategorize, countTransactionsByKeywords } = useTransactionStore();
  const { showToast } = useToast();

  const [name, setName] = useState('');
  const [icon, setIcon] = useState('Tag');
  const [color, setColor] = useState('#4caf50');
  const [keywordsText, setKeywordsText] = useState('');

  useEffect(() => {
    if (editCategory) {
      setName(editCategory.name);
      setIcon(editCategory.icon);
      setColor(editCategory.color);
      setKeywordsText(editCategory.keywords.join(', '));
    } else {
      setName('');
      setIcon('Tag');
      setColor('#4caf50');
      setKeywordsText('');
    }
  }, [editCategory, open]);

  if (!open) return null;

  const keywords = keywordsText
    .split(',')
    .map((k) => k.trim())
    .filter(Boolean);

  const matchCount = countTransactionsByKeywords(keywords);

  function handleSubmit() {
    if (!name.trim()) return;

    if (editCategory) {
      const updated: Category = { ...editCategory, name: name.trim(), icon, color, keywords };
      updateCategory(updated);
      const result = updateCategoryAndRecategorize(editCategory.id, keywords);
      showToast(
        `Updated "${name}"${result.added > 0 ? ` (+${result.added} transactions)` : ''}${result.removed > 0 ? ` (-${result.removed} transactions)` : ''}`
      );
    } else {
      const id = name.trim().toLowerCase().replace(/\s+/g, '-');
      addCategory({ id, name: name.trim(), icon, color, keywords });
      showToast(`Created "${name}"`);
    }
    onClose();
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50" onClick={onClose}>
      <div
        className="max-h-[85vh] w-full max-w-md overflow-y-auto rounded-xl bg-white p-6 shadow-xl dark:bg-gray-800"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="mb-4 flex items-center justify-between">
          <h2 className="text-lg font-semibold">{editCategory ? 'Edit Category' : 'Add Category'}</h2>
          <button onClick={onClose} className="rounded-lg p-1 hover:bg-gray-100 dark:hover:bg-gray-700">
            <X size={20} />
          </button>
        </div>

        <div className="space-y-4">
          <div>
            <label className="mb-1 block text-sm font-medium">Name</label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="w-full rounded-lg border px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
              placeholder="Category name"
            />
          </div>

          <div>
            <label className="mb-1 block text-sm font-medium">Color</label>
            <ColorPicker selected={color} onSelect={setColor} />
          </div>

          <div>
            <label className="mb-1 block text-sm font-medium">Icon</label>
            <IconPicker selected={icon} onSelect={setIcon} />
          </div>

          <div>
            <label className="mb-1 block text-sm font-medium">Keywords (comma-separated)</label>
            <input
              type="text"
              value={keywordsText}
              onChange={(e) => setKeywordsText(e.target.value)}
              className="w-full rounded-lg border px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
              placeholder="e.g. grocery, supermarket, food"
            />
            {keywords.length > 0 && matchCount > 0 && (
              <p className="mt-1 text-xs text-blue-600 dark:text-blue-400">
                {matchCount} uncategorized transaction{matchCount !== 1 ? 's' : ''} will match
              </p>
            )}
          </div>
        </div>

        <div className="mt-6 flex justify-end gap-3">
          <button
            onClick={onClose}
            className="rounded-lg px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-700"
          >
            Cancel
          </button>
          <button
            onClick={handleSubmit}
            disabled={!name.trim()}
            className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-50"
          >
            {editCategory ? 'Save' : 'Add'}
          </button>
        </div>
      </div>
    </div>
  );
}
