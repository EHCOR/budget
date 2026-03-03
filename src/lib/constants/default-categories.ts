import { Category } from '@/lib/types';

export const DEFAULT_CATEGORIES: Category[] = [
  {
    id: 'groceries',
    name: 'Groceries',
    color: '#4caf50',
    icon: 'ShoppingCart',
    keywords: ['grocery', 'supermarket', 'food', 'market', 'store'],
  },
  {
    id: 'dining',
    name: 'Dining Out',
    color: '#ff9800',
    icon: 'Utensils',
    keywords: ['restaurant', 'cafe', 'coffee', 'dining', 'food', 'eat'],
  },
  {
    id: 'transport',
    name: 'Transportation',
    color: '#2196f3',
    icon: 'Car',
    keywords: ['gas', 'fuel', 'uber', 'taxi', 'bus', 'train', 'transport'],
  },
  {
    id: 'utilities',
    name: 'Utilities',
    color: '#f44336',
    icon: 'Lightbulb',
    keywords: ['electric', 'water', 'utility', 'phone', 'internet', 'bill'],
  },
  {
    id: 'entertainment',
    name: 'Entertainment',
    color: '#9c27b0',
    icon: 'Film',
    keywords: ['movie', 'netflix', 'spotify', 'game', 'entertainment', 'show'],
  },
  {
    id: 'health',
    name: 'Healthcare',
    color: '#e91e63',
    icon: 'Heart',
    keywords: ['doctor', 'medicine', 'pharmacy', 'health', 'medical', 'hospital'],
  },
  {
    id: 'shopping',
    name: 'Shopping',
    color: '#009688',
    icon: 'ShoppingBag',
    keywords: ['amazon', 'walmart', 'target', 'shopping', 'buy', 'purchase'],
  },
  {
    id: 'income',
    name: 'Income',
    color: '#2e7d32',
    icon: 'DollarSign',
    keywords: ['salary', 'deposit', 'paycheck', 'income', 'payment', 'transfer'],
  },
  {
    id: 'uncategorized',
    name: 'Uncategorized',
    color: '#9e9e9e',
    icon: 'HelpCircle',
    keywords: [],
  },
];
