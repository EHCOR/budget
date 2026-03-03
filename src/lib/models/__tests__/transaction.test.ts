import { describe, it, expect } from 'vitest';
import { createTransaction, transactionFromJson, transactionToJson, transactionFromCsvRow } from '../transaction';
import { TransactionType } from '@/lib/types';

describe('createTransaction', () => {
  it('creates a transaction with defaults', () => {
    const tx = createTransaction({
      date: '2024-03-01T00:00:00.000Z',
      description: 'Grocery Store',
      amount: -45.50,
    });
    expect(tx.description).toBe('Grocery Store');
    expect(tx.amount).toBe(-45.50);
    expect(tx.categoryId).toBe('uncategorized');
    expect(tx.type).toBe(TransactionType.Expense);
    expect(tx.id).toBeDefined();
  });

  it('infers income type for positive amount', () => {
    const tx = createTransaction({
      date: '2024-03-01T00:00:00.000Z',
      description: 'Salary',
      amount: 5000,
    });
    expect(tx.type).toBe(TransactionType.Income);
  });

  it('uses provided type over inference', () => {
    const tx = createTransaction({
      date: '2024-03-01T00:00:00.000Z',
      description: 'Refund',
      amount: 100,
      type: TransactionType.Expense,
    });
    expect(tx.type).toBe(TransactionType.Expense);
  });
});

describe('transactionFromJson / transactionToJson', () => {
  it('round-trips correctly', () => {
    const original = createTransaction({
      id: 'test-123',
      date: '2024-03-15T10:00:00.000Z',
      description: 'Coffee Shop',
      amount: -4.50,
      categoryId: 'dining',
      type: TransactionType.Expense,
    });

    const json = transactionToJson(original);
    const restored = transactionFromJson(json as Record<string, unknown>);

    expect(restored.id).toBe('test-123');
    expect(restored.description).toBe('Coffee Shop');
    expect(restored.amount).toBe(-4.50);
    expect(restored.categoryId).toBe('dining');
    expect(restored.type).toBe(TransactionType.Expense);
  });

  it('defaults categoryId to uncategorized', () => {
    const tx = transactionFromJson({
      id: '1',
      date: '2024-01-01T00:00:00.000Z',
      description: 'Test',
      amount: 10,
      type: 'income',
    });
    expect(tx.categoryId).toBe('uncategorized');
  });
});

describe('transactionFromCsvRow', () => {
  it('parses yyyy-MM-dd format', () => {
    const tx = transactionFromCsvRow(['2024-03-15', 'Grocery Store', '-45.50']);
    expect(tx).not.toBeNull();
    expect(tx!.description).toBe('Grocery Store');
    expect(tx!.amount).toBe(-45.50);
    expect(tx!.type).toBe(TransactionType.Expense);
  });

  it('parses YYYYMMDD format', () => {
    const tx = transactionFromCsvRow(['20240315', 'Gas Station', '-30.00']);
    expect(tx).not.toBeNull();
    expect(tx!.description).toBe('Gas Station');
  });

  it('parses MM/dd/yyyy format', () => {
    const tx = transactionFromCsvRow(['03/15/2024', 'Netflix', '-15.99']);
    expect(tx).not.toBeNull();
    expect(tx!.description).toBe('Netflix');
  });

  it('returns null for invalid rows', () => {
    expect(transactionFromCsvRow(['not-a-date', 'desc', '10'])).toBeNull();
    expect(transactionFromCsvRow(['2024-03-15', 'desc'])).toBeNull(); // missing amount column
    expect(transactionFromCsvRow([])).toBeNull();
  });

  it('parses positive amounts as income', () => {
    const tx = transactionFromCsvRow(['2024-03-15', 'Salary Deposit', '5000.00']);
    expect(tx).not.toBeNull();
    expect(tx!.type).toBe(TransactionType.Income);
    expect(tx!.amount).toBe(5000);
  });

  it('supports custom column indices', () => {
    const tx = transactionFromCsvRow(
      ['ignored', '2024-03-15', 'ignored2', 'Purchase', '-50'],
      { dateIndex: 1, descriptionIndex: 3, amountIndex: 4 }
    );
    expect(tx).not.toBeNull();
    expect(tx!.description).toBe('Purchase');
    expect(tx!.amount).toBe(-50);
  });
});
