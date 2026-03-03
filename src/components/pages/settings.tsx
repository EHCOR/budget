'use client';

import { useState, useRef } from 'react';
import { ArrowLeft, Download, Upload, Trash2, Info } from 'lucide-react';
import { useTransactionStore } from '@/lib/stores/transaction-store';
import { useToast } from '@/components/shared/toast';
import { ConfirmDialog } from '@/components/shared/confirm-dialog';
import { CURRENCIES } from '@/lib/constants/currencies';
import { cn } from '@/lib/utils/cn';

interface SettingsPageProps {
  onBack: () => void;
}

export function SettingsPage({ onBack }: SettingsPageProps) {
  const store = useTransactionStore();
  const { showToast } = useToast();
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [showClearConfirm, setShowClearConfirm] = useState(false);
  const [showAbout, setShowAbout] = useState(false);

  function handleExport() {
    const json = store.exportDataAsJson();
    const blob = new Blob([json], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `budget-tracker-export-${new Date().toISOString().slice(0, 10)}.json`;
    a.click();
    URL.revokeObjectURL(url);
    showToast('Data exported successfully');
  }

  function handleImport(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = (ev) => {
      const text = ev.target?.result as string;
      const success = store.importDataFromJson(text);
      if (success) {
        showToast('Data imported successfully');
      } else {
        showToast('Failed to import data — invalid format');
      }
    };
    reader.readAsText(file);
    // Reset so the same file can be re-imported
    e.target.value = '';
  }

  function handleClear() {
    store.clearAllData();
    setShowClearConfirm(false);
    showToast('All data cleared');
  }

  return (
    <div className="space-y-4 p-4">
      <div className="flex items-center gap-3">
        <button onClick={onBack} className="rounded-lg p-2 hover:bg-gray-100 dark:hover:bg-gray-700">
          <ArrowLeft size={20} />
        </button>
        <h1 className="text-xl font-bold">Settings</h1>
      </div>

      {/* Currency */}
      <div className="rounded-xl bg-white p-4 shadow-sm dark:bg-gray-800">
        <h2 className="mb-3 text-sm font-semibold">Currency</h2>
        <select
          value={store.currencyCode}
          onChange={(e) => {
            const c = CURRENCIES.find((c) => c.code === e.target.value);
            if (c) store.setCurrency(c.code, c.symbol);
          }}
          className="w-full rounded-lg border px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
        >
          {CURRENCIES.map((c) => (
            <option key={c.code} value={c.code}>
              {c.symbol} — {c.name} ({c.code})
            </option>
          ))}
        </select>
      </div>

      {/* Theme */}
      <div className="rounded-xl bg-white p-4 shadow-sm dark:bg-gray-800">
        <h2 className="mb-3 text-sm font-semibold">Theme</h2>
        <div className="flex gap-3">
          {(['light', 'dark', 'system'] as const).map((mode) => (
            <label key={mode} className="flex items-center gap-2 text-sm">
              <input
                type="radio"
                name="theme"
                checked={store.themeMode === mode}
                onChange={() => store.setThemeMode(mode)}
                className="accent-blue-600"
              />
              <span className="capitalize">{mode === 'system' ? 'System Default' : mode}</span>
            </label>
          ))}
        </div>
      </div>

      {/* Data Management */}
      <div className="rounded-xl bg-white p-4 shadow-sm dark:bg-gray-800">
        <h2 className="mb-3 text-sm font-semibold">Data Management</h2>
        <div className="space-y-2">
          <button
            onClick={handleExport}
            className="flex w-full items-center gap-3 rounded-lg px-3 py-2.5 text-sm hover:bg-gray-50 dark:hover:bg-gray-700"
          >
            <Download size={18} className="text-blue-500" />
            <span>Export Data (JSON)</span>
          </button>

          <button
            onClick={() => fileInputRef.current?.click()}
            className="flex w-full items-center gap-3 rounded-lg px-3 py-2.5 text-sm hover:bg-gray-50 dark:hover:bg-gray-700"
          >
            <Upload size={18} className="text-green-500" />
            <span>Import Data (JSON)</span>
          </button>
          <input
            ref={fileInputRef}
            type="file"
            accept=".json"
            onChange={handleImport}
            className="hidden"
          />

          <button
            onClick={() => setShowClearConfirm(true)}
            className="flex w-full items-center gap-3 rounded-lg px-3 py-2.5 text-sm text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20"
          >
            <Trash2 size={18} />
            <span>Clear All Data</span>
          </button>
        </div>
      </div>

      {/* About */}
      <div className="rounded-xl bg-white p-4 shadow-sm dark:bg-gray-800">
        <button
          onClick={() => setShowAbout(!showAbout)}
          className="flex w-full items-center gap-3 text-sm"
        >
          <Info size={18} className="text-gray-400" />
          <span>About</span>
        </button>
        {showAbout && (
          <div className="mt-3 border-t pt-3 text-xs text-gray-500 dark:border-gray-700">
            <p className="font-medium">Budget Tracker v2.0.0</p>
            <p className="mt-1">Track expenses, manage categories, and visualize spending trends.</p>
          </div>
        )}
      </div>

      <ConfirmDialog
        open={showClearConfirm}
        title="Clear All Data"
        message="This will permanently delete all transactions and reset categories to defaults. Settings will be preserved. This action cannot be undone."
        confirmLabel="Clear Everything"
        destructive
        onConfirm={handleClear}
        onCancel={() => setShowClearConfirm(false)}
      />
    </div>
  );
}
