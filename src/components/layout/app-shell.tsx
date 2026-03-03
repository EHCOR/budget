'use client';

import { useState, useCallback } from 'react';
import { BottomNav, type TabKey } from './bottom-nav';
import { useKeyboardShortcuts } from '@/hooks/use-keyboard-shortcuts';
import { useToast } from '@/components/shared/toast';
import { DashboardPage } from '@/components/pages/dashboard';
import { TransactionsPage } from '@/components/pages/transactions';
import { CategoriesPage } from '@/components/pages/categories';
import { TrendsPage } from '@/components/pages/trends';

export function AppShell() {
  const [activeTab, setActiveTab] = useState<TabKey>('dashboard');
  const { showToast } = useToast();
  useKeyboardShortcuts(showToast);

  const handleTabChange = useCallback((tab: TabKey) => {
    setActiveTab(tab);
  }, []);

  return (
    <div className="min-h-screen bg-gray-50 pb-16 dark:bg-gray-900">
      <div className="mx-auto max-w-2xl">
        {activeTab === 'dashboard' && <DashboardPage />}
        {activeTab === 'transactions' && <TransactionsPage />}
        {activeTab === 'categories' && <CategoriesPage />}
        {activeTab === 'trends' && <TrendsPage />}
      </div>
      <BottomNav activeTab={activeTab} onChange={handleTabChange} />
    </div>
  );
}
