'use client';

import { useState } from 'react';
import { ICON_MAP, ICON_NAMES } from '@/lib/utils/icons';
import { SearchInput } from '@/components/shared/search-input';
import { cn } from '@/lib/utils/cn';

interface IconPickerProps {
  selected: string;
  onSelect: (iconName: string) => void;
}

export function IconPicker({ selected, onSelect }: IconPickerProps) {
  const [search, setSearch] = useState('');

  const filtered = search
    ? ICON_NAMES.filter((n) => n.toLowerCase().includes(search.toLowerCase()))
    : ICON_NAMES;

  return (
    <div>
      <SearchInput value={search} onChange={setSearch} placeholder="Search icons..." />
      <div className="mt-2 grid max-h-48 grid-cols-8 gap-1 overflow-y-auto">
        {filtered.map((name) => {
          const Icon = ICON_MAP[name];
          return (
            <button
              key={name}
              onClick={() => onSelect(name)}
              title={name}
              className={cn(
                'flex h-9 w-9 items-center justify-center rounded-lg transition-colors',
                selected === name
                  ? 'bg-blue-100 text-blue-700 dark:bg-blue-900/40 dark:text-blue-300'
                  : 'text-gray-600 hover:bg-gray-100 dark:text-gray-400 dark:hover:bg-gray-700'
              )}
            >
              <Icon size={18} />
            </button>
          );
        })}
      </div>
    </div>
  );
}
