import { format, startOfMonth, endOfMonth, subDays, subMonths, isAfter, isBefore, parseISO, addDays } from 'date-fns';

export function formatMonthKey(date: Date): string {
  return format(date, 'MMM yyyy');
}

export function formatDate(dateStr: string): string {
  return format(parseISO(dateStr), 'MMM dd, yyyy');
}

export function formatDateShort(dateStr: string): string {
  return format(parseISO(dateStr), 'MM/dd/yyyy');
}

export function formatDateGroupKey(dateStr: string): string {
  return format(parseISO(dateStr), 'EEEE, MMMM d, yyyy');
}

export function isInDateRange(dateStr: string, start: Date, end: Date): boolean {
  const date = parseISO(dateStr);
  return (isAfter(date, subDays(start, 1)) && isBefore(date, addDays(end, 1)));
}

export interface DateRange {
  start: Date;
  end: Date;
}

export function getPresetRange(preset: string): DateRange {
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());

  switch (preset) {
    case 'last7':
      return { start: subDays(today, 7), end: today };
    case 'last30':
      return { start: subDays(today, 30), end: today };
    case 'thisMonth':
      return { start: startOfMonth(today), end: today };
    case 'lastMonth': {
      const lastMonth = subMonths(today, 1);
      return { start: startOfMonth(lastMonth), end: endOfMonth(lastMonth) };
    }
    case 'last3Months':
      return { start: subMonths(today, 3), end: today };
    case 'last6Months':
      return { start: subMonths(today, 6), end: today };
    case 'last1Year':
      return { start: subMonths(today, 12), end: today };
    default:
      return { start: subDays(today, 30), end: today };
  }
}
