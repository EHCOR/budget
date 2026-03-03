import { describe, it, expect, beforeEach } from 'vitest';
import {
  saveTransactions,
  loadTransactions,
  saveCategories,
  loadCategories,
  saveSettings,
  loadSettings,
  clearAllData,
  exportData,
  importData,
} from '../storage-service';
import { TransactionType, type Transaction } from '@/lib/types';
import { DEFAULT_CATEGORIES } from '@/lib/constants/default-categories';

describe('StorageService', () => {
  beforeEach(() => {
    localStorage.clear();
  });

  describe('transactions', () => {
    const tx: Transaction = {
      id: '1',
      date: '2024-03-15T00:00:00.000Z',
      description: 'Test',
      amount: -50,
      categoryId: 'groceries',
      type: TransactionType.Expense,
    };

    it('saves and loads transactions', () => {
      saveTransactions([tx]);
      const loaded = loadTransactions();
      expect(loaded).toHaveLength(1);
      expect(loaded[0].id).toBe('1');
      expect(loaded[0].description).toBe('Test');
    });

    it('returns empty array when no data', () => {
      expect(loadTransactions()).toEqual([]);
    });
  });

  describe('categories', () => {
    it('returns defaults when no data', () => {
      const cats = loadCategories();
      expect(cats.length).toBeGreaterThan(0);
      expect(cats[0].id).toBe(DEFAULT_CATEGORIES[0].id);
    });

    it('saves and loads categories', () => {
      const custom = [{ id: 'x', name: 'X', color: '#f00', icon: 'Star', keywords: [] }];
      saveCategories(custom);
      const loaded = loadCategories();
      expect(loaded).toHaveLength(1);
      expect(loaded[0].id).toBe('x');
    });
  });

  describe('settings', () => {
    it('returns defaults when no data', () => {
      const settings = loadSettings();
      expect(settings.currencyCode).toBe('USD');
      expect(settings.themeMode).toBe('system');
    });

    it('saves and loads settings', () => {
      saveSettings({ currencyCode: 'EUR', currencySymbol: '€', themeMode: 'dark' });
      const settings = loadSettings();
      expect(settings.currencyCode).toBe('EUR');
      expect(settings.themeMode).toBe('dark');
    });
  });

  describe('clearAllData', () => {
    it('clears transactions and categories but not settings', () => {
      saveTransactions([{ id: '1', date: '', description: '', amount: 0, categoryId: '', type: TransactionType.Expense }]);
      saveSettings({ currencyCode: 'EUR', currencySymbol: '€', themeMode: 'dark' });
      clearAllData();

      expect(loadTransactions()).toEqual([]);
      // Settings should still be there
      expect(loadSettings().currencyCode).toBe('EUR');
    });
  });

  describe('export/import', () => {
    it('exports valid JSON', () => {
      const json = exportData(
        [{ id: '1', date: '2024-01-01', description: 'T', amount: -10, categoryId: 'x', type: TransactionType.Expense }],
        DEFAULT_CATEGORIES,
        { currencyCode: 'USD', currencySymbol: '$', themeMode: 'system' }
      );
      const parsed = JSON.parse(json);
      expect(parsed.transactions).toHaveLength(1);
      expect(parsed.categories.length).toBeGreaterThan(0);
      expect(parsed.exportDate).toBeDefined();
    });

    it('imports valid JSON', () => {
      const json = JSON.stringify({
        transactions: [{ id: '1', date: '2024-01-01', description: 'T', amount: -10, categoryId: 'x', type: 'expense' }],
        categories: [{ id: 'y', name: 'Y', color: '#0f0', icon: 'Tag', keywords: [] }],
        settings: { currencyCode: 'GBP', currencySymbol: '£', themeMode: 'light' },
      });
      const result = importData(json);
      expect(result).not.toBeNull();
      expect(result!.transactions).toHaveLength(1);
      expect(result!.settings.currencyCode).toBe('GBP');
    });

    it('returns null for invalid JSON', () => {
      expect(importData('not json')).toBeNull();
    });
  });
});
