import { Transaction, TransactionType } from '@/lib/types';
import { parse, isValid, format } from 'date-fns';

export function createTransaction(params: {
  id?: string;
  date: string;
  description: string;
  amount: number;
  categoryId?: string;
  type?: TransactionType;
}): Transaction {
  return {
    id: params.id ?? Date.now().toString(),
    date: params.date,
    description: params.description,
    amount: params.amount,
    categoryId: params.categoryId ?? 'uncategorized',
    type: params.type ?? (params.amount >= 0 ? TransactionType.Income : TransactionType.Expense),
  };
}

export function transactionFromJson(json: Record<string, unknown>): Transaction {
  return {
    id: json.id as string,
    date: json.date as string,
    description: json.description as string,
    amount: Number(json.amount),
    categoryId: (json.categoryId as string) ?? 'uncategorized',
    type: json.type === 'income' ? TransactionType.Income : TransactionType.Expense,
  };
}

export function transactionToJson(t: Transaction): Record<string, unknown> {
  return {
    id: t.id,
    date: t.date,
    description: t.description,
    amount: t.amount,
    categoryId: t.categoryId,
    type: t.type,
  };
}

function tryParseDate(dateStr: string): Date | null {
  const trimmed = dateStr.trim();

  // YYYYMMDD format
  if (trimmed.length === 8 && /^\d{8}$/.test(trimmed)) {
    const y = parseInt(trimmed.substring(0, 4));
    const m = parseInt(trimmed.substring(4, 6));
    const d = parseInt(trimmed.substring(6, 8));
    const date = new Date(y, m - 1, d);
    if (isValid(date)) return date;
  }

  // yyyy-MM-dd
  const isoDate = parse(trimmed, 'yyyy-MM-dd', new Date());
  if (isValid(isoDate)) return isoDate;

  // MM/dd/yyyy
  const usDate = parse(trimmed, 'MM/dd/yyyy', new Date());
  if (isValid(usDate)) return usDate;

  // dd/MM/yyyy
  const euDate = parse(trimmed, 'dd/MM/yyyy', new Date());
  if (isValid(euDate)) return euDate;

  return null;
}

export function transactionFromCsvRow(
  row: string[],
  options: { dateIndex?: number; descriptionIndex?: number; amountIndex?: number } = {}
): Transaction | null {
  const { dateIndex = 0, descriptionIndex = 1, amountIndex = 2 } = options;

  try {
    if (row.length <= amountIndex) return null;

    const date = tryParseDate(row[dateIndex]);
    if (!date) return null;

    const description = row[descriptionIndex].trim();

    // Parse amount — handle comma-formatted numbers
    const amountStr = row[amountIndex].trim().replace(/[^\d.\-]/g, '');
    const amount = parseFloat(amountStr);
    if (isNaN(amount)) return null;

    const uniqueId = `${Date.now()}-${Math.random().toString(36).substring(2, 9)}`;

    return {
      id: uniqueId,
      date: format(date, "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"),
      description,
      amount,
      categoryId: 'uncategorized',
      type: amount >= 0 ? TransactionType.Income : TransactionType.Expense,
    };
  } catch {
    return null;
  }
}
