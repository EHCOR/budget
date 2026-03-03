'use client';

import { LayoutDashboard, ArrowLeftRight, FolderOpen, TrendingUp } from 'lucide-react';
import { cn } from '@/lib/utils/cn';

export type TabKey = 'dashboard' | 'transactions' | 'categories' | 'trends';

const TABS: { key: TabKey; label: string; icon: React.ElementType }[] = [
  { key: 'dashboard', label: 'Dashboard', icon: LayoutDashboard },
  { key: 'transactions', label: 'Transactions', icon: ArrowLeftRight },
  { key: 'categories', label: 'Categories', icon: FolderOpen },
  { key: 'trends', label: 'Trends', icon: TrendingUp },
];

interface BottomNavProps {
  activeTab: TabKey;
  onChange: (tab: TabKey) => void;
}

export function BottomNav({ activeTab, onChange }: BottomNavProps) {
  return (
    <nav className="fixed bottom-0 left-0 right-0 z-40 border-t bg-white dark:border-gray-700 dark:bg-gray-800">
      <div className="mx-auto flex max-w-lg">
        {TABS.map(({ key, label, icon: Icon }) => (
          <button
            key={key}
            onClick={() => onChange(key)}
            className={cn(
              'flex flex-1 flex-col items-center gap-0.5 py-2 text-xs transition-colors',
              activeTab === key
                ? 'text-blue-600 dark:text-blue-400'
                : 'text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-300'
            )}
          >
            <Icon size={20} />
            <span>{label}</span>
          </button>
        ))}
      </div>
    </nav>
  );
}
