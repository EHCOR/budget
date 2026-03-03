'use client';

import { useEffect, type ReactNode } from 'react';

interface ThemeProviderProps {
  themeMode: 'light' | 'dark' | 'system';
  children: ReactNode;
}

export function ThemeProvider({ themeMode, children }: ThemeProviderProps) {
  useEffect(() => {
    const root = document.documentElement;

    if (themeMode === 'dark') {
      root.classList.add('dark');
    } else if (themeMode === 'light') {
      root.classList.remove('dark');
    } else {
      // System preference
      const mq = window.matchMedia('(prefers-color-scheme: dark)');
      const apply = () => {
        if (mq.matches) root.classList.add('dark');
        else root.classList.remove('dark');
      };
      apply();
      mq.addEventListener('change', apply);
      return () => mq.removeEventListener('change', apply);
    }
  }, [themeMode]);

  return <>{children}</>;
}
