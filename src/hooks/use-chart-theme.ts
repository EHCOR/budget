'use client';

import { useState, useEffect } from 'react';

export function useChartTheme() {
  const [isDark, setIsDark] = useState(false);

  useEffect(() => {
    const root = document.documentElement;
    setIsDark(root.classList.contains('dark'));

    const observer = new MutationObserver(() => {
      setIsDark(root.classList.contains('dark'));
    });
    observer.observe(root, { attributes: true, attributeFilter: ['class'] });
    return () => observer.disconnect();
  }, []);

  return {
    textColor: isDark ? '#d1d5db' : '#374151',
    gridColor: isDark ? '#374151' : '#e5e7eb',
    tooltipStyle: {
      fontSize: '11px',
      borderRadius: '8px',
      backgroundColor: isDark ? '#1f2937' : '#ffffff',
      borderColor: isDark ? '#4b5563' : '#e5e7eb',
      color: isDark ? '#d1d5db' : '#374151',
    },
    legendStyle: {
      fontSize: '10px',
      color: isDark ? '#d1d5db' : '#374151',
    },
  };
}
