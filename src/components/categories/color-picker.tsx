'use client';

import { cn } from '@/lib/utils/cn';

const PRESET_COLORS = [
  // Row 1: Core
  '#f44336', '#e91e63', '#9c27b0', '#673ab7',
  '#3f51b5', '#2196f3', '#03a9f4', '#00bcd4',
  // Row 2: Nature & warm
  '#009688', '#4caf50', '#8bc34a', '#cddc39',
  '#ffeb3b', '#ffc107', '#ff9800', '#ff5722',
  // Row 3: Neutrals & extras
  '#795548', '#607d8b', '#2e7d32', '#1565c0',
  '#ad1457', '#6a1b9a', '#00838f', '#ef6c00',
];

interface ColorPickerProps {
  selected: string;
  onSelect: (color: string) => void;
}

export function ColorPicker({ selected, onSelect }: ColorPickerProps) {
  return (
    <div className="grid grid-cols-8 gap-2">
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
