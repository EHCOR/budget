import { describe, it, expect, beforeEach } from 'vitest';
import { useTransactionStore } from '../transaction-store';
import { TransactionType, type Transaction } from '@/lib/types';

function makeTx(overrides: Partial<Transaction> = {}): Transaction {
  return {
    id: `tx-${Date.now()}-${Math.random()}`,
    date: '2024-03-15T00:00:00.000Z',
    description: 'Test Transaction',
    amount: -50,
    categoryId: 'uncategorized',
    type: TransactionType.Expense,
    ...overrides,
  };
}

describe('useTransactionStore', () => {
  beforeEach(() => {
    // Reset store
    useTransactionStore.setState({
      transactions: [],
      categories: useTransactionStore.getState().categories,
      startDate: new Date('2024-01-01'),
      endDate: new Date('2024-12-31'),
    });
    // Clear localStorage
    if (typeof localStorage !== 'undefined') {
      localStorage.clear();
    }
  });

  describe('addTransaction', () => {
    it('adds a transaction', () => {
      const tx = makeTx({ id: 'add-1' });
      useTransactionStore.getState().addTransaction(tx);
      expect(useTransactionStore.getState().transactions).toHaveLength(1);
      expect(useTransactionStore.getState().transactions[0].id).toBe('add-1');
    });
  });

  describe('addTransactions (bulk import)', () => {
    it('imports unique transactions', () => {
      const txs = [
        makeTx({ id: 'bulk-1', description: 'A' }),
        makeTx({ id: 'bulk-2', description: 'B' }),
      ];
      const result = useTransactionStore.getState().addTransactions(txs);
      expect(result.imported).toBe(2);
      expect(result.duplicates).toBe(0);
      expect(useTransactionStore.getState().transactions).toHaveLength(2);
    });

    it('detects duplicates by date+amount+description', () => {
      const tx = makeTx({ id: 'dup-1', description: 'Same', amount: -25, date: '2024-03-10T00:00:00.000Z' });
      useTransactionStore.getState().addTransaction(tx);

      const txs = [makeTx({ id: 'dup-2', description: 'Same', amount: -25, date: '2024-03-10T00:00:00.000Z' })];
      const result = useTransactionStore.getState().addTransactions(txs);
      expect(result.duplicates).toBe(1);
      expect(result.imported).toBe(0);
      expect(useTransactionStore.getState().transactions).toHaveLength(1);
    });

    it('auto-categorizes by keywords', () => {
      const txs = [makeTx({ description: 'Walmart grocery shopping' })];
      const result = useTransactionStore.getState().addTransactions(txs);
      expect(result.imported).toBe(1);
      // 'grocery' keyword should match 'groceries' category
      const imported = useTransactionStore.getState().transactions[0];
      expect(imported.categoryId).toBe('groceries');
    });
  });

  describe('updateTransaction', () => {
    it('updates an existing transaction', () => {
      const tx = makeTx({ id: 'upd-1', description: 'Old' });
      useTransactionStore.getState().addTransaction(tx);
      useTransactionStore.getState().updateTransaction({ ...tx, description: 'New' });
      expect(useTransactionStore.getState().transactions[0].description).toBe('New');
    });
  });

  describe('deleteTransaction', () => {
    it('removes a transaction', () => {
      const tx = makeTx({ id: 'del-1' });
      useTransactionStore.getState().addTransaction(tx);
      useTransactionStore.getState().deleteTransaction('del-1');
      expect(useTransactionStore.getState().transactions).toHaveLength(0);
    });
  });

  describe('updateTransactionCategory', () => {
    it('changes category', () => {
      const tx = makeTx({ id: 'cat-1', categoryId: 'uncategorized' });
      useTransactionStore.getState().addTransaction(tx);
      useTransactionStore.getState().updateTransactionCategory('cat-1', 'dining');
      expect(useTransactionStore.getState().transactions[0].categoryId).toBe('dining');
    });
  });

  describe('computed getters', () => {
    it('filters transactions by date range', () => {
      useTransactionStore.getState().addTransaction(
        makeTx({ id: 'f1', date: '2024-03-15T00:00:00.000Z' })
      );
      useTransactionStore.getState().addTransaction(
        makeTx({ id: 'f2', date: '2023-01-01T00:00:00.000Z' })
      );
      useTransactionStore.setState({
        startDate: new Date('2024-03-01'),
        endDate: new Date('2024-03-31'),
      });

      const filtered = useTransactionStore.getState().getFilteredTransactions();
      expect(filtered).toHaveLength(1);
      expect(filtered[0].id).toBe('f1');
    });

    it('computes totals', () => {
      useTransactionStore.getState().addTransaction(
        makeTx({ id: 't1', amount: 1000, type: TransactionType.Income })
      );
      useTransactionStore.getState().addTransaction(
        makeTx({ id: 't2', amount: -300, type: TransactionType.Expense })
      );

      expect(useTransactionStore.getState().getTotalIncome()).toBe(1000);
      expect(useTransactionStore.getState().getTotalExpenses()).toBe(300);
      expect(useTransactionStore.getState().getNetCashFlow()).toBe(700);
    });
  });

  describe('category management', () => {
    it('adds a category', () => {
      const count = useTransactionStore.getState().categories.length;
      useTransactionStore.getState().addCategory({
        id: 'custom',
        name: 'Custom',
        color: '#ff0000',
        icon: 'Star',
        keywords: ['custom'],
      });
      expect(useTransactionStore.getState().categories).toHaveLength(count + 1);
    });

    it('deletes a category and uncategorizes transactions', () => {
      const tx = makeTx({ id: 'cat-del-1', categoryId: 'dining' });
      useTransactionStore.getState().addTransaction(tx);
      useTransactionStore.getState().deleteCategory('dining');

      expect(useTransactionStore.getState().transactions[0].categoryId).toBe('uncategorized');
      expect(useTransactionStore.getState().categories.find((c) => c.id === 'dining')).toBeUndefined();
    });
  });

  describe('recategorization', () => {
    it('recategorizes uncategorized transactions by keywords', () => {
      useTransactionStore.getState().addTransaction(
        makeTx({ id: 'rc-1', description: 'Netflix subscription', categoryId: 'uncategorized' })
      );
      const count = useTransactionStore.getState().recategorizeTransactionsByKeywords('entertainment', ['netflix']);
      expect(count).toBe(1);
      expect(useTransactionStore.getState().transactions[0].categoryId).toBe('entertainment');
    });

    it('counts matching transactions', () => {
      useTransactionStore.getState().addTransaction(
        makeTx({ id: 'cnt-1', description: 'uber ride', categoryId: 'uncategorized' })
      );
      useTransactionStore.getState().addTransaction(
        makeTx({ id: 'cnt-2', description: 'uber eats', categoryId: 'uncategorized' })
      );
      expect(useTransactionStore.getState().countTransactionsByKeywords(['uber'])).toBe(2);
    });
  });

  describe('data management', () => {
    it('exports and imports data', () => {
      useTransactionStore.getState().addTransaction(makeTx({ id: 'exp-1', description: 'Export Test' }));
      const json = useTransactionStore.getState().exportDataAsJson();

      // Clear and reimport
      useTransactionStore.getState().clearAllData();
      expect(useTransactionStore.getState().transactions).toHaveLength(0);

      const success = useTransactionStore.getState().importDataFromJson(json);
      expect(success).toBe(true);
      expect(useTransactionStore.getState().transactions).toHaveLength(1);
      expect(useTransactionStore.getState().transactions[0].description).toBe('Export Test');
    });

    it('handles invalid import data', () => {
      const success = useTransactionStore.getState().importDataFromJson('not valid json');
      expect(success).toBe(false);
    });
  });

  describe('settings', () => {
    it('changes currency', () => {
      useTransactionStore.getState().setCurrency('EUR', '€');
      expect(useTransactionStore.getState().currencyCode).toBe('EUR');
      expect(useTransactionStore.getState().currencySymbol).toBe('€');
    });

    it('changes theme mode', () => {
      useTransactionStore.getState().setThemeMode('dark');
      expect(useTransactionStore.getState().themeMode).toBe('dark');
    });
  });
});
