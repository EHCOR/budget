'use client';

import { useEffect } from 'react';
import { useTransactionStore } from '@/lib/stores/transaction-store';
import { AppShell } from '@/components/layout/app-shell';
import { ToastProvider } from '@/components/shared/toast';
import { ThemeProvider } from '@/components/shared/theme-provider';

export default function Home() {
  const initialize = useTransactionStore((s) => s.initialize);
  const themeMode = useTransactionStore((s) => s.themeMode);
  const isLoading = useTransactionStore((s) => s.isLoading);

  useEffect(() => {
    initialize();
  }, [initialize]);

  if (isLoading) {
    return (
      <div className="flex h-screen items-center justify-center">
        <div className="h-8 w-8 animate-spin rounded-full border-2 border-blue-600 border-t-transparent" />
      </div>
    );
  }

  return (
    <ThemeProvider themeMode={themeMode}>
      <ToastProvider>
        <AppShell />
      </ToastProvider>
    </ThemeProvider>
  );
}
