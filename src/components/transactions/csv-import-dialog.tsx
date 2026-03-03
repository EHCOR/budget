'use client';

import { useState } from 'react';
import { X, Upload, FileText } from 'lucide-react';
import Papa from 'papaparse';
import { useTransactionStore } from '@/lib/stores/transaction-store';
import { transactionFromCsvRow } from '@/lib/models/transaction';
import { useToast } from '@/components/shared/toast';
import type { Transaction } from '@/lib/types';

interface CsvImportDialogProps {
  open: boolean;
  onClose: () => void;
}

function isHeaderRow(row: string[]): boolean {
  const headerKeywords = ['date', 'description', 'amount', 'transaction', 'debit', 'credit'];
  const joined = row.join(' ').toLowerCase();
  return headerKeywords.some((kw) => joined.includes(kw));
}

export function CsvImportDialog({ open, onClose }: CsvImportDialogProps) {
  const { addTransactions } = useTransactionStore();
  const { showToast } = useToast();

  const [csvText, setCsvText] = useState('');
  const [parsed, setParsed] = useState<Transaction[]>([]);
  const [isProcessing, setIsProcessing] = useState(false);
  const [previewText, setPreviewText] = useState('');

  if (!open) return null;

  function handleParse() {
    setIsProcessing(true);
    try {
      const result = Papa.parse<string[]>(csvText.trim(), {
        skipEmptyLines: true,
      });

      let rows = result.data;
      if (rows.length > 0 && isHeaderRow(rows[0])) {
        rows = rows.slice(1);
      }

      const transactions: Transaction[] = [];
      let skipped = 0;

      for (const row of rows) {
        const tx = transactionFromCsvRow(row);
        if (tx) {
          transactions.push(tx);
        } else {
          skipped++;
        }
      }

      setParsed(transactions);
      setPreviewText(
        `Parsed ${transactions.length} transaction${transactions.length !== 1 ? 's' : ''}${skipped > 0 ? ` (${skipped} row${skipped !== 1 ? 's' : ''} skipped)` : ''}`
      );
    } catch {
      setPreviewText('Failed to parse CSV data');
    } finally {
      setIsProcessing(false);
    }
  }

  function handleImport() {
    if (parsed.length === 0) return;
    setIsProcessing(true);
    try {
      const result = addTransactions(parsed);
      showToast(
        `Imported ${result.imported} transaction${result.imported !== 1 ? 's' : ''}${result.duplicates > 0 ? `, ${result.duplicates} duplicate${result.duplicates !== 1 ? 's' : ''} skipped` : ''}`
      );
      setCsvText('');
      setParsed([]);
      setPreviewText('');
      onClose();
    } finally {
      setIsProcessing(false);
    }
  }

  function handleFileUpload(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = (ev) => {
      const text = ev.target?.result as string;
      setCsvText(text);
      setParsed([]);
      setPreviewText('');
    };
    reader.readAsText(file);
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50" onClick={onClose}>
      <div
        className="w-full max-w-lg rounded-xl bg-white p-6 shadow-xl dark:bg-gray-800"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="mb-4 flex items-center justify-between">
          <h2 className="text-lg font-semibold">Import CSV</h2>
          <button onClick={onClose} className="rounded-lg p-1 hover:bg-gray-100 dark:hover:bg-gray-700">
            <X size={20} />
          </button>
        </div>

        <p className="mb-3 text-xs text-gray-500 dark:text-gray-400">
          Paste CSV data or upload a file. Expected format: Date, Description, Amount
        </p>

        {/* File upload */}
        <label className="mb-3 flex cursor-pointer items-center gap-2 rounded-lg border border-dashed p-3 hover:bg-gray-50 dark:border-gray-600 dark:hover:bg-gray-700">
          <Upload size={18} className="text-gray-400" />
          <span className="text-sm text-gray-600 dark:text-gray-400">Upload CSV file</span>
          <input
            type="file"
            accept=".csv,.txt"
            onChange={handleFileUpload}
            className="hidden"
          />
        </label>

        {/* Text area */}
        <textarea
          value={csvText}
          onChange={(e) => {
            setCsvText(e.target.value);
            setParsed([]);
            setPreviewText('');
          }}
          rows={8}
          placeholder="Paste CSV data here..."
          className="w-full rounded-lg border bg-white p-3 font-mono text-xs focus:outline-none focus:ring-2 focus:ring-blue-500 dark:border-gray-600 dark:bg-gray-700"
        />

        {/* Preview */}
        {previewText && (
          <div className="mt-3 flex items-center gap-2 rounded-lg bg-gray-100 px-3 py-2 dark:bg-gray-700">
            <FileText size={16} className="text-blue-500" />
            <span className="text-sm">{previewText}</span>
          </div>
        )}

        {/* Actions */}
        <div className="mt-4 flex justify-end gap-3">
          <button
            onClick={onClose}
            className="rounded-lg px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-700"
          >
            Cancel
          </button>
          {parsed.length === 0 ? (
            <button
              onClick={handleParse}
              disabled={!csvText.trim() || isProcessing}
              className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-50"
            >
              {isProcessing ? 'Parsing...' : 'Parse'}
            </button>
          ) : (
            <button
              onClick={handleImport}
              disabled={isProcessing}
              className="rounded-lg bg-green-600 px-4 py-2 text-sm font-medium text-white hover:bg-green-700 disabled:opacity-50"
            >
              {isProcessing ? 'Importing...' : `Import ${parsed.length}`}
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
