import { create } from 'zustand';
import { format, parseISO, subDays, isAfter, isBefore, addDays, startOfMonth } from 'date-fns';
import {
  Transaction,
  TransactionType,
  Category,
  CategorySummary,
  AppSettings,
  ImportResult,
  MonthlyStats,
  MonthlyCategoryData,
} from '@/lib/types';
import { transactionFromJson, transactionToJson } from '@/lib/models/transaction';
import { DEFAULT_CATEGORIES } from '@/lib/constants/default-categories';
import {
  Command,
  AddTransactionCommand,
  DeleteTransactionCommand,
  UpdateTransactionCommand,
  UpdateTransactionCategoryCommand,
} from '@/lib/models/command';
import * as storage from '@/lib/services/storage-service';

interface TransactionState {
  transactions: Transaction[];
  categories: Category[];
  startDate: Date;
  endDate: Date;
  isLoading: boolean;
  currencySymbol: string;
  currencyCode: string;
  themeMode: 'light' | 'dark' | 'system';

  // Initialization
  initialize: () => void;

  // Date range
  setDateRange: (start: Date, end: Date) => void;

  // Transactions
  addTransaction: (tx: Transaction) => void;
  addTransactions: (txs: Transaction[]) => ImportResult;
  updateTransaction: (tx: Transaction) => void;
  deleteTransaction: (id: string) => void;
  updateTransactionCategory: (txId: string, catId: string) => void;

  // Categories
  addCategory: (cat: Category) => void;
  updateCategory: (cat: Category) => void;
  deleteCategory: (catId: string) => void;
  getCategoryById: (id: string) => Category | undefined;

  // Auto-categorization
  countTransactionsByKeywords: (keywords: string[]) => number;
  recategorizeTransactionsByKeywords: (catId: string, keywords: string[]) => number;
  calculateCategoryChanges: (catId: string, newKeywords: string[]) => { added: number; removed: number };
  updateCategoryAndRecategorize: (catId: string, newKeywords: string[]) => { added: number; removed: number };
  recalculateAllTransactions: (months?: number) => { recategorized: number; alreadyCategorized: number; total: number };

  // Computed
  getFilteredTransactions: () => Transaction[];
  getUncategorizedTransactions: () => Transaction[];
  getTotalIncome: () => number;
  getTotalExpenses: () => number;
  getNetCashFlow: () => number;
  getCategorySummaries: (incomeOnly?: boolean) => CategorySummary[];
  getMonthlyStats: (months: number) => MonthlyStats;
  getMonthlyCategoryData: () => MonthlyCategoryData;
  getCategoryColorsMap: () => Record<string, string>;
  getTransactionsByCategory: (catId: string) => Transaction[];
  getTransactionById: (id: string) => Transaction | undefined;

  // Settings
  setCurrency: (code: string, symbol: string) => void;
  setThemeMode: (mode: 'light' | 'dark' | 'system') => void;

  // Data management
  exportDataAsJson: () => string;
  importDataFromJson: (json: string) => boolean;
  clearAllData: () => void;

  // Command-based methods for undo/redo
  addTransactionInternal: (data: Record<string, unknown>) => Promise<void>;
  deleteTransactionInternal: (id: string) => Promise<void>;
  updateTransactionInternal: (data: Record<string, unknown>) => Promise<void>;
  updateTransactionCategoryInternal: (txId: string, catId: string) => Promise<void>;
  createAddTransactionCommand: (tx: Transaction) => Command;
  createDeleteTransactionCommand: (txId: string) => Command;
  createUpdateTransactionCommand: (oldTx: Transaction, newTx: Transaction) => Command;
  createUpdateTransactionCategoryCommand: (txId: string, newCatId: string) => Command;
}

function matchesKeywords(description: string, keywords: string[]): boolean {
  const lower = description.toLowerCase();
  return keywords.some((kw) => lower.includes(kw.toLowerCase()));
}

function findBestCategory(description: string, categories: Category[]): string {
  const lower = description.toLowerCase();
  for (const cat of categories) {
    if (cat.keywords.length > 0 && matchesKeywords(lower, cat.keywords)) {
      return cat.id;
    }
  }
  return 'uncategorized';
}

function transactionsMatch(a: Transaction, b: Transaction): boolean {
  return a.date === b.date && a.amount === b.amount && a.description === b.description;
}

function filterByDateRange(transactions: Transaction[], start: Date, end: Date): Transaction[] {
  return transactions
    .filter((t) => {
      const d = parseISO(t.date);
      return isAfter(d, subDays(start, 1)) && isBefore(d, addDays(end, 1));
    })
    .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());
}

function saveSettingsToStorage(state: { currencyCode: string; currencySymbol: string; themeMode: 'light' | 'dark' | 'system' }) {
  storage.saveSettings({
    currencyCode: state.currencyCode,
    currencySymbol: state.currencySymbol,
    themeMode: state.themeMode,
  });
}

export const useTransactionStore = create<TransactionState>((set, get) => ({
  transactions: [],
  categories: DEFAULT_CATEGORIES,
  startDate: subDays(new Date(), 30),
  endDate: new Date(),
  isLoading: false,
  currencySymbol: '$',
  currencyCode: 'USD',
  themeMode: 'system',

  initialize: () => {
    set({ isLoading: true });
    try {
      const transactions = storage.loadTransactions();
      const categories = storage.loadCategories();
      const settings = storage.loadSettings();
      set({
        transactions,
        categories,
        currencyCode: settings.currencyCode,
        currencySymbol: settings.currencySymbol,
        themeMode: settings.themeMode,
        isLoading: false,
      });
    } catch {
      set({ isLoading: false });
    }
  },

  setDateRange: (start, end) => set({ startDate: start, endDate: end }),

  addTransaction: (tx) => {
    const transactions = [...get().transactions, tx];
    set({ transactions });
    storage.saveTransactions(transactions);
  },

  addTransactions: (newTxs) => {
    const existing = get().transactions;
    const categories = get().categories;
    const unique: Transaction[] = [];
    let duplicates = 0;

    for (const tx of newTxs) {
      if (existing.some((e) => transactionsMatch(e, tx))) {
        duplicates++;
      } else {
        const categorized = tx.categoryId === 'uncategorized'
          ? { ...tx, categoryId: findBestCategory(tx.description, categories) }
          : tx;
        unique.push(categorized);
      }
    }

    const transactions = [...existing, ...unique];
    set({ transactions });
    storage.saveTransactions(transactions);

    return { imported: unique.length, duplicates, total: newTxs.length };
  },

  updateTransaction: (tx) => {
    const transactions = get().transactions.map((t) => (t.id === tx.id ? tx : t));
    set({ transactions });
    storage.saveTransactions(transactions);
  },

  deleteTransaction: (id) => {
    const transactions = get().transactions.filter((t) => t.id !== id);
    set({ transactions });
    storage.saveTransactions(transactions);
  },

  updateTransactionCategory: (txId, catId) => {
    const transactions = get().transactions.map((t) =>
      t.id === txId ? { ...t, categoryId: catId } : t
    );
    set({ transactions });
    storage.saveTransactions(transactions);
  },

  addCategory: (cat) => {
    const categories = [...get().categories, cat];
    set({ categories });
    storage.saveCategories(categories);
  },

  updateCategory: (cat) => {
    const categories = get().categories.map((c) => (c.id === cat.id ? cat : c));
    set({ categories });
    storage.saveCategories(categories);
  },

  deleteCategory: (catId) => {
    const transactions = get().transactions.map((t) =>
      t.categoryId === catId ? { ...t, categoryId: 'uncategorized' } : t
    );
    const categories = get().categories.filter((c) => c.id !== catId);
    set({ transactions, categories });
    storage.saveTransactions(transactions);
    storage.saveCategories(categories);
  },

  getCategoryById: (id) => get().categories.find((c) => c.id === id),

  countTransactionsByKeywords: (keywords) => {
    if (keywords.length === 0) return 0;
    return get().transactions.filter(
      (t) => t.categoryId === 'uncategorized' && matchesKeywords(t.description, keywords)
    ).length;
  },

  recategorizeTransactionsByKeywords: (catId, keywords) => {
    if (keywords.length === 0) return 0;
    let count = 0;
    const transactions = get().transactions.map((t) => {
      if (t.categoryId === 'uncategorized' && matchesKeywords(t.description, keywords)) {
        count++;
        return { ...t, categoryId: catId };
      }
      return t;
    });
    if (count > 0) {
      set({ transactions });
      storage.saveTransactions(transactions);
    }
    return count;
  },

  calculateCategoryChanges: (catId, newKeywords) => {
    const state = get();
    const filtered = filterByDateRange(state.transactions, state.startDate, state.endDate);
    let added = 0;
    let removed = 0;

    for (const t of filtered) {
      if (t.categoryId === catId && !matchesKeywords(t.description, newKeywords)) {
        removed++;
      }
      if (t.categoryId !== catId && matchesKeywords(t.description, newKeywords)) {
        added++;
      }
    }

    return { added, removed };
  },

  updateCategoryAndRecategorize: (catId, newKeywords) => {
    let added = 0;
    let removed = 0;

    const transactions = get().transactions.map((t) => {
      if (t.categoryId === catId && !matchesKeywords(t.description, newKeywords)) {
        removed++;
        return { ...t, categoryId: 'uncategorized' };
      }
      if (t.categoryId !== catId && matchesKeywords(t.description, newKeywords)) {
        added++;
        return { ...t, categoryId: catId };
      }
      return t;
    });

    if (added > 0 || removed > 0) {
      set({ transactions });
      storage.saveTransactions(transactions);
    }
    return { added, removed };
  },

  recalculateAllTransactions: (months = 3) => {
    const now = new Date();
    const cutoff = new Date(now.getFullYear(), now.getMonth() - months, now.getDate());
    const categories = get().categories;
    let recategorized = 0;
    let alreadyCategorized = 0;

    const recent = get().transactions.filter((t) => isAfter(parseISO(t.date), cutoff));
    const total = recent.length;

    const transactions = get().transactions.map((t) => {
      if (!isAfter(parseISO(t.date), cutoff)) return t;
      if (t.categoryId === 'uncategorized') {
        const best = findBestCategory(t.description, categories);
        if (best !== 'uncategorized') {
          recategorized++;
          return { ...t, categoryId: best };
        }
      } else {
        alreadyCategorized++;
      }
      return t;
    });

    if (recategorized > 0) {
      set({ transactions });
      storage.saveTransactions(transactions);
    }

    return { recategorized, alreadyCategorized, total };
  },

  // Computed getters
  getFilteredTransactions: () => {
    const { transactions, startDate, endDate } = get();
    return filterByDateRange(transactions, startDate, endDate);
  },

  getUncategorizedTransactions: () => {
    return get().getFilteredTransactions().filter((t) => t.categoryId === 'uncategorized');
  },

  getTotalIncome: () => {
    return get()
      .getFilteredTransactions()
      .filter((t) => t.type === TransactionType.Income)
      .reduce((sum, t) => sum + Math.abs(t.amount), 0);
  },

  getTotalExpenses: () => {
    return get()
      .getFilteredTransactions()
      .filter((t) => t.type === TransactionType.Expense)
      .reduce((sum, t) => sum + Math.abs(t.amount), 0);
  },

  getNetCashFlow: () => get().getTotalIncome() - get().getTotalExpenses(),

  getCategorySummaries: (incomeOnly = false) => {
    const filtered = get().getFilteredTransactions();
    const totals: Record<string, number> = {};

    for (const t of filtered) {
      if (incomeOnly && t.type !== TransactionType.Income) continue;
      if (!incomeOnly && t.type !== TransactionType.Expense) continue;
      totals[t.categoryId] = (totals[t.categoryId] ?? 0) + Math.abs(t.amount);
    }

    return Object.entries(totals)
      .map(([catId, amount]) => {
        const cat = get().getCategoryById(catId);
        return {
          categoryId: catId,
          categoryName: cat?.name || 'Unknown',
          amount,
          color: cat?.color || '#9e9e9e',
          icon: cat?.icon || 'Tag',
        };
      })
      .sort((a, b) => b.amount - a.amount);
  },

  getMonthlyStats: (months) => {
    const stats: MonthlyStats = {};
    const now = new Date();
    const allTx = get().transactions;

    for (let i = 0; i < months; i++) {
      const month = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const monthKey = format(month, 'MMM yyyy');
      const start = startOfMonth(month);
      const end = new Date(month.getFullYear(), month.getMonth() + 1, 0);

      const monthTxs = allTx.filter((t) => {
        const d = parseISO(t.date);
        return isAfter(d, subDays(start, 1)) && isBefore(d, addDays(end, 1));
      });

      let income = 0;
      let expenses = 0;
      for (const t of monthTxs) {
        if (t.type === TransactionType.Income) income += Math.abs(t.amount);
        else expenses += Math.abs(t.amount);
      }

      stats[monthKey] = { income, expenses, net: income - expenses };
    }
    return stats;
  },

  getMonthlyCategoryData: () => {
    const result: MonthlyCategoryData = {};
    const filtered = get().getFilteredTransactions();
    if (filtered.length === 0) return result;

    const dates = filtered.map((t) => parseISO(t.date));
    const firstDate = dates.reduce((a, b) => (a < b ? a : b));
    const lastDate = dates.reduce((a, b) => (a > b ? a : b));

    let current = startOfMonth(firstDate);
    while (current <= lastDate) {
      const key = format(current, 'MMM yyyy');
      result[key] = { income: {}, expense: {} };
      current = new Date(current.getFullYear(), current.getMonth() + 1, 1);
    }

    for (const t of filtered) {
      const key = format(parseISO(t.date), 'MMM yyyy');
      const cat = get().getCategoryById(t.categoryId);
      const catName = cat?.name ?? 'Unknown';
      const type = t.type === TransactionType.Income ? 'income' : 'expense';
      const amount = Math.abs(t.amount);

      if (result[key]) {
        result[key][type][catName] = (result[key][type][catName] ?? 0) + amount;
      }
    }

    return result;
  },

  getCategoryColorsMap: () => {
    const colors: Record<string, string> = {};
    for (const cat of get().categories) {
      colors[cat.name] = cat.color || '#9e9e9e';
    }
    colors['Unknown'] = '#9e9e9e';
    return colors;
  },

  getTransactionsByCategory: (catId) => {
    return get().getFilteredTransactions().filter((t) => t.categoryId === catId);
  },

  getTransactionById: (id) => get().transactions.find((t) => t.id === id),

  // Settings
  setCurrency: (code, symbol) => {
    set({ currencyCode: code, currencySymbol: symbol });
    saveSettingsToStorage({ ...get(), currencyCode: code, currencySymbol: symbol });
  },

  setThemeMode: (mode) => {
    set({ themeMode: mode });
    saveSettingsToStorage({ ...get(), themeMode: mode });
  },

  // Data management
  exportDataAsJson: () => {
    const { transactions, categories, currencyCode, currencySymbol, themeMode } = get();
    return storage.exportData(transactions, categories, { currencyCode, currencySymbol, themeMode });
  },

  importDataFromJson: (json) => {
    const data = storage.importData(json);
    if (!data) return false;

    storage.saveTransactions(data.transactions);
    storage.saveCategories(data.categories);
    storage.saveSettings(data.settings);

    set({
      transactions: data.transactions,
      categories: data.categories,
      currencyCode: data.settings.currencyCode,
      currencySymbol: data.settings.currencySymbol,
      themeMode: data.settings.themeMode,
    });
    return true;
  },

  clearAllData: () => {
    storage.clearAllData();
    const categories = DEFAULT_CATEGORIES;
    storage.saveCategories(categories);
    set({ transactions: [], categories });
  },

  // Command-based methods for undo/redo
  addTransactionInternal: async (data) => {
    const tx = transactionFromJson(data);
    const transactions = [...get().transactions, tx];
    set({ transactions });
    storage.saveTransactions(transactions);
  },

  deleteTransactionInternal: async (id) => {
    const transactions = get().transactions.filter((t) => t.id !== id);
    set({ transactions });
    storage.saveTransactions(transactions);
  },

  updateTransactionInternal: async (data) => {
    const tx = transactionFromJson(data);
    const transactions = get().transactions.map((t) => (t.id === tx.id ? tx : t));
    set({ transactions });
    storage.saveTransactions(transactions);
  },

  updateTransactionCategoryInternal: async (txId, catId) => {
    const transactions = get().transactions.map((t) =>
      t.id === txId ? { ...t, categoryId: catId } : t
    );
    set({ transactions });
    storage.saveTransactions(transactions);
  },

  createAddTransactionCommand: (tx) => {
    const state = get();
    return new AddTransactionCommand(
      tx.id,
      transactionToJson(tx) as Record<string, unknown>,
      state.deleteTransactionInternal,
      state.addTransactionInternal
    );
  },

  createDeleteTransactionCommand: (txId) => {
    const state = get();
    const tx = state.transactions.find((t) => t.id === txId);
    if (!tx) throw new Error(`Transaction ${txId} not found`);
    return new DeleteTransactionCommand(
      txId,
      transactionToJson(tx) as Record<string, unknown>,
      state.deleteTransactionInternal,
      state.addTransactionInternal
    );
  },

  createUpdateTransactionCommand: (oldTx, newTx) => {
    const state = get();
    return new UpdateTransactionCommand(
      transactionToJson(oldTx) as Record<string, unknown>,
      transactionToJson(newTx) as Record<string, unknown>,
      state.updateTransactionInternal
    );
  },

  createUpdateTransactionCategoryCommand: (txId, newCatId) => {
    const state = get();
    const tx = state.transactions.find((t) => t.id === txId);
    if (!tx) throw new Error(`Transaction ${txId} not found`);
    return new UpdateTransactionCategoryCommand(
      txId,
      tx.categoryId,
      newCatId,
      state.updateTransactionCategoryInternal
    );
  },
}));
