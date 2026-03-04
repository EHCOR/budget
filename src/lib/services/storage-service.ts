import { Transaction, Category, AppSettings } from '@/lib/types';
import { DEFAULT_CATEGORIES } from '@/lib/constants/default-categories';

const TRANSACTIONS_KEY = 'budget_tracker_transactions';
const CATEGORIES_KEY = 'budget_tracker_categories';
const SETTINGS_KEY = 'budget_tracker_settings';

function getStorage(): Storage | null {
  if (typeof window === 'undefined') return null;
  return window.localStorage;
}

export function saveTransactions(transactions: Transaction[]): void {
  const storage = getStorage();
  if (!storage) return;
  try {
    storage.setItem(TRANSACTIONS_KEY, JSON.stringify(transactions));
  } catch {
    // storage full or unavailable
  }
}

export function loadTransactions(): Transaction[] {
  const storage = getStorage();
  if (!storage) return [];
  try {
    const json = storage.getItem(TRANSACTIONS_KEY);
    if (!json) return [];
    return JSON.parse(json) as Transaction[];
  } catch {
    return [];
  }
}

export function saveCategories(categories: Category[]): void {
  const storage = getStorage();
  if (!storage) return;
  try {
    storage.setItem(CATEGORIES_KEY, JSON.stringify(categories));
  } catch {
    // storage full or unavailable
  }
}

export function loadCategories(): Category[] {
  const storage = getStorage();
  if (!storage) return DEFAULT_CATEGORIES;
  try {
    const json = storage.getItem(CATEGORIES_KEY);
    if (!json) return DEFAULT_CATEGORIES;
    const categories = JSON.parse(json) as Category[];
    // Ensure every category has valid color and icon fields
    return categories.map((cat) => ({
      ...cat,
      color: cat.color || '#9e9e9e',
      icon: cat.icon || 'Tag',
      keywords: Array.isArray(cat.keywords) ? cat.keywords : [],
    }));
  } catch {
    return DEFAULT_CATEGORIES;
  }
}

export function saveSettings(settings: AppSettings): void {
  const storage = getStorage();
  if (!storage) return;
  try {
    storage.setItem(SETTINGS_KEY, JSON.stringify(settings));
  } catch {
    // storage full or unavailable
  }
}

export function loadSettings(): AppSettings {
  const storage = getStorage();
  if (!storage) return { currencyCode: 'USD', currencySymbol: '$', themeMode: 'system' };
  try {
    const json = storage.getItem(SETTINGS_KEY);
    if (!json) return { currencyCode: 'USD', currencySymbol: '$', themeMode: 'system' };
    return JSON.parse(json) as AppSettings;
  } catch {
    return { currencyCode: 'USD', currencySymbol: '$', themeMode: 'system' };
  }
}

export function clearAllData(): void {
  const storage = getStorage();
  if (!storage) return;
  storage.removeItem(TRANSACTIONS_KEY);
  storage.removeItem(CATEGORIES_KEY);
}

export function exportData(
  transactions: Transaction[],
  categories: Category[],
  settings: AppSettings
): string {
  return JSON.stringify({
    transactions,
    categories,
    settings,
    exportDate: new Date().toISOString(),
  });
}

export function importData(jsonString: string): {
  transactions: Transaction[];
  categories: Category[];
  settings: AppSettings;
} | null {
  try {
    const data = JSON.parse(jsonString);
    const result: {
      transactions: Transaction[];
      categories: Category[];
      settings: AppSettings;
    } = {
      transactions: [],
      categories: DEFAULT_CATEGORIES,
      settings: { currencyCode: 'USD', currencySymbol: '$', themeMode: 'system' },
    };

    if (data.transactions && Array.isArray(data.transactions)) {
      result.transactions = data.transactions;
    }
    if (data.categories && Array.isArray(data.categories)) {
      result.categories = data.categories;
    }
    if (data.settings) {
      result.settings = data.settings;
    }

    return result;
  } catch {
    return null;
  }
}
