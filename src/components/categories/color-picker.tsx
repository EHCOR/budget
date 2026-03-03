'use client';

import { cn } from '@/lib/utils/cn';

const PRESET_COLORS = [
  '#4caf50', '#ff9800', '#2196f3', '#f44336',
  '#9c27b0', '#e91e63', '#009688', '#2e7d32',
];

interface ColorPickerProps {
  selected: string;
  onSelect: (color: string) => void;
}

export function ColorPicker({ selected, onSelect }: ColorPickerProps) {
  return (
    <div className="flex gap-2">
      {PRESET_COLORS.map((color) => (
        <button
          key={color}
          onClick={() => onSelect(color)}
          className={cn(
            'h-8 w-8 rounded-full border-2 transition-transform',
            selected === color ? 'scale-110 border-gray-800 dark:border-white' : 'border-transparent hover:scale-105'
          )}
          style={{ backgroundColor: color }}
          title={color}
        />
      ))}
    </div>
  );
}
