# TypeScript Rebuild Plan — Budget Tracker App

## Current State

The app is a Flutter/Dart budget tracker (~4,500 lines of application code) using:
- **Provider** for state management
- **SharedPreferences** for persistence (JSON key-value)
- **fl_chart** for data visualization (pie, bar, line charts)
- **Command pattern** for undo/redo
- **Material 3** design system

It has 6 screens, 10+ widgets, 3 models, 2 providers, 3 utility services, and a full test suite.

---

## Recommended Stack

| Concern | Technology | Rationale |
|---|---|---|
| Language | **TypeScript 5** | Strict mode, type-safe |
| Framework | **React 18 + Next.js 14** | File-based routing, SSR/SSG optional, huge ecosystem |
| Styling | **Tailwind CSS + shadcn/ui** | Rapid UI development, dark mode built-in, replaces Material 3 |
| State | **Zustand** | Lightweight, replaces Provider pattern cleanly |
| Charts | **Recharts** | Composable React charting, replaces fl_chart |
| Storage | **localStorage + IndexedDB (via Dexie.js)** | Replaces SharedPreferences, better for large datasets |
| Testing | **Vitest + React Testing Library** | Fast unit/integration tests |
| Build | **Vite (via Next.js)** | Fast dev server, HMR |
| Package Manager | **pnpm** | Fast, disk-efficient |

---

## Architecture Overview

```
src/
├── app/                          # Next.js App Router pages
│   ├── layout.tsx                # Root layout (providers, theme)
│   ├── page.tsx                  # Redirect to /dashboard
│   ├── dashboard/
│   │   └── page.tsx
│   ├── transactions/
│   │   └── page.tsx
│   ├── categories/
│   │   └── page.tsx
│   ├── trends/
│   │   └── page.tsx
│   └── settings/
│       └── page.tsx
├── components/
│   ├── layout/
│   │   ├── bottom-nav.tsx        # Bottom navigation bar
│   │   ├── app-shell.tsx         # Shared layout wrapper
│   │   └── undo-redo-controls.tsx
│   ├── transactions/
│   │   ├── add-transaction-dialog.tsx
│   │   ├── transaction-list.tsx
│   │   ├── transaction-item.tsx
│   │   ├── transaction-details-sheet.tsx
│   │   └── csv-import-dialog.tsx
│   ├── categories/
│   │   ├── category-form.tsx
│   │   ├── category-list.tsx
│   │   ├── icon-picker.tsx
│   │   └── color-picker.tsx
│   ├── charts/
│   │   ├── category-pie-chart.tsx
│   │   ├── monthly-category-bar-chart.tsx
│   │   ├── income-expense-line-chart.tsx
│   │   ├── category-growth-chart.tsx
│   │   ├── budget-analysis-chart.tsx
│   │   └── category-info-popup.tsx
│   ├── dashboard/
│   │   ├── summary-cards.tsx
│   │   └── recent-transactions.tsx
│   └── shared/
│       ├── date-range-selector.tsx
│       ├── search-input.tsx
│       └── confirm-dialog.tsx
├── lib/
│   ├── models/
│   │   ├── transaction.ts
│   │   ├── category.ts
│   │   └── command.ts
│   ├── stores/
│   │   ├── transaction-store.ts  # Zustand store (replaces TransactionProvider)
│   │   └── undo-redo-store.ts    # Zustand store (replaces UndoRedoProvider)
│   ├── services/
│   │   ├── storage-service.ts    # localStorage/IndexedDB persistence
│   │   └── statistics-service.ts # Analytics & projections
│   ├── utils/
│   │   ├── csv-parser.ts         # CSV parsing with flexible date formats
│   │   ├── currency.ts           # Currency formatting helpers
│   │   ├── date.ts               # Date formatting & range helpers
│   │   └── keyboard-handler.ts   # Ctrl+Z/Y hook
│   ├── constants/
│   │   ├── default-categories.ts
│   │   └── currencies.ts
│   └── types/
│       └── index.ts              # Shared TypeScript types & enums
├── hooks/
│   ├── use-keyboard-shortcuts.ts
│   ├── use-transactions.ts       # Convenience hook wrapping store
│   └── use-theme.ts
└── styles/
    └── globals.css               # Tailwind base + custom tokens
```

---

## Phase-by-Phase Implementation Plan

### Phase 1: Project Scaffolding & Core Types
**Estimated files: ~12**

1. **Initialize Next.js project** with TypeScript strict mode
   - `npx create-next-app@latest budget-tracker --typescript --tailwind --app --src-dir`
   - Add pnpm, configure `tsconfig.json` (strict: true, paths)
   - Install dependencies: `zustand`, `recharts`, `dexie`, `lucide-react`, `date-fns`, `papaparse`
   - Install shadcn/ui components: button, dialog, dropdown-menu, input, select, sheet, tabs, card, badge, tooltip

2. **Define TypeScript types and models** (port from Dart models)
   - `src/lib/types/index.ts` — Core types:
     ```typescript
     enum TransactionType { Income = 'income', Expense = 'expense' }

     interface Transaction {
       id: string
       date: string              // ISO 8601
       description: string
       amount: number            // always positive
       categoryId: string
       type: TransactionType
     }

     interface Category {
       id: string
       name: string
       color: string             // hex color
       icon: string              // Lucide icon name (replaces Material Icons)
       keywords: string[]
     }

     interface CategorySummary {
       categoryId: string
       categoryName: string
       amount: number
       color: string
       icon: string
     }

     interface AppSettings {
       currencyCode: string
       currencySymbol: string
       themeMode: 'light' | 'dark' | 'system'
     }
     ```
   - `src/lib/models/transaction.ts` — Factory functions: `createTransaction()`, `transactionFromCsvRow()`, `transactionToJson()`, `transactionFromJson()`
   - `src/lib/models/category.ts` — Factory functions + default categories list
   - `src/lib/models/command.ts` — Command interface + concrete implementations (AddTransactionCommand, DeleteTransactionCommand, UpdateTransactionCommand, UpdateTransactionCategoryCommand)

3. **Set up default categories** with Lucide icon mappings
   - Map Flutter Material Icons → Lucide React icons:
     - `Icons.shopping_cart` → `ShoppingCart`
     - `Icons.restaurant` → `Utensils`
     - `Icons.directions_car` → `Car`
     - `Icons.bolt` → `Zap`
     - `Icons.movie` → `Film`
     - `Icons.medical_services` → `Heart`
     - `Icons.shopping_bag` → `ShoppingBag`
     - `Icons.attach_money` → `DollarSign`
     - `Icons.category` → `Tag`

### Phase 2: Storage & State Management
**Estimated files: ~6**

4. **Implement StorageService** (`src/lib/services/storage-service.ts`)
   - Use `localStorage` for settings and small data
   - Use `Dexie.js` (IndexedDB wrapper) for transactions and categories (better for large datasets)
   - Methods mirror Flutter version: `saveTransactions()`, `loadTransactions()`, `saveCategories()`, `loadCategories()`, `saveSettings()`, `loadSettings()`, `clearAllData()`, `exportData()`, `importData()`
   - Export produces same JSON format as Flutter app (cross-compatible backups)

5. **Implement Zustand transaction store** (`src/lib/stores/transaction-store.ts`)
   - Port all TransactionProvider logic:
     - Core state: transactions, categories, dateRange, currency, theme, isLoading
     - Computed selectors (Zustand `get()` pattern): filteredTransactions, uncategorizedTransactions, totalIncome, totalExpenses, netCashFlow, categorySummaries
     - Actions: addTransaction, addTransactions, updateTransaction, deleteTransaction, updateTransactionCategory
     - Auto-categorization: `findBestCategory()`, `recategorizeTransactionsByKeywords()`
     - Duplicate detection: `detectDuplicates()`
     - Analytics: `getMonthlyStats()`, `getMonthlyCategoryData()`
     - Import/export: `exportDataAsJson()`, `importDataFromJson()`
     - Settings: `setCurrency()`, `setThemeMode()`, `clearAllData()`
   - Use Zustand middleware for persistence (`persist` middleware with storage adapter)

6. **Implement Zustand undo/redo store** (`src/lib/stores/undo-redo-store.ts`)
   - Port UndoRedoProvider: undoStack, redoStack (max 50), executeCommand(), undo(), redo(), clearHistory()
   - Integrate with transaction store via command pattern

7. **Implement StatisticsService** (`src/lib/services/statistics-service.ts`)
   - Port all analytics: calculateAverage, calculatePercentageChange, projectNextValue (with linear regression, outlier detection, mean regression dampening, volatility adjustment), calculateVolatility, calculateTrend, getCategoryStatistics, getOverallStatistics

### Phase 3: Shared Components & Layout
**Estimated files: ~10**

8. **App shell and navigation**
   - `src/app/layout.tsx` — Root layout with Zustand providers, theme provider (next-themes), global keyboard listener
   - `src/components/layout/app-shell.tsx` — Page wrapper with bottom nav
   - `src/components/layout/bottom-nav.tsx` — 4-tab bottom navigation (Dashboard, Transactions, Categories, Trends) using Lucide icons
   - Mobile-first responsive design

9. **Shared components**
   - `src/components/shared/date-range-selector.tsx` — Quick presets (Last 7/30 days, This Month, Last Month, Last 3/6/12 Months, All Time, Custom) + custom date picker dialog
   - `src/components/shared/search-input.tsx` — Debounced search with clear button
   - `src/components/shared/confirm-dialog.tsx` — Reusable confirmation modal

10. **Undo/redo controls** (`src/components/layout/undo-redo-controls.tsx`)
    - Undo/Redo buttons in header bar with tooltips
    - `src/hooks/use-keyboard-shortcuts.ts` — Ctrl+Z / Ctrl+Y / Ctrl+Shift+Z global handler

### Phase 4: Transaction Features
**Estimated files: ~8**

11. **Add Transaction Dialog** (`src/components/transactions/add-transaction-dialog.tsx`)
    - shadcn Dialog with form: description, amount (with currency prefix), income/expense toggle, date picker, category dropdown
    - Form validation (required fields, positive amount)
    - Integrates with undo/redo store

12. **CSV Import Dialog** (`src/components/transactions/csv-import-dialog.tsx`)
    - Textarea for CSV paste
    - Header detection, column index configuration (date, description, amount)
    - Preview table of parsed transactions
    - Duplicate detection display
    - Use `papaparse` for CSV parsing
    - Support date formats: YYYYMMDD, yyyy-MM-dd, MM/dd/yyyy, dd/MM/yyyy

13. **Transaction List** (`src/components/transactions/transaction-list.tsx` + `transaction-item.tsx`)
    - Virtualized list for performance (use `@tanstack/react-virtual` if needed)
    - Grouped by date with daily totals
    - Swipe-to-delete (or delete button on hover/click)
    - Category badge with icon and color
    - Currency-formatted amounts

14. **Transaction Details Sheet** (`src/components/transactions/transaction-details-sheet.tsx`)
    - shadcn Sheet (bottom sheet on mobile)
    - Display: date, amount, type, description, category
    - Category search + selection list
    - Smart tag creation for uncategorized items
    - Delete with confirmation
    - Undo/redo integration

### Phase 5: Dashboard & Categories
**Estimated files: ~8**

15. **Dashboard page** (`src/app/dashboard/page.tsx`)
    - Date range selector
    - Summary cards: Total Income, Total Expenses, Net Balance (with color coding)
    - Pie chart with category breakdown (interactive)
    - Recent transactions list (last 5-10)
    - Settings navigation link

16. **Summary cards** (`src/components/dashboard/summary-cards.tsx`)
    - Three cards: Income (green), Expenses (red), Net (blue/green/red)
    - Formatted with currency symbol

17. **Category pie chart** (`src/components/charts/category-pie-chart.tsx`)
    - Recharts PieChart with custom tooltip
    - Category colors from store
    - Toggle income vs expense view

18. **Categories page** (`src/app/categories/page.tsx` + components)
    - Search bar
    - Category cards with: transaction count, total amount, edit/delete buttons
    - `src/components/categories/category-form.tsx` — Add/edit dialog with name, icon picker, color picker, keywords input
    - `src/components/categories/icon-picker.tsx` — Grid of Lucide icons with search (map ~100 Material icons to Lucide equivalents)
    - `src/components/categories/color-picker.tsx` — 8 preset color swatches
    - Keyword recategorization preview (shows count of matching transactions)

### Phase 6: Charts & Trends
**Estimated files: ~7**

19. **Trends page** (`src/app/trends/page.tsx`)
    - Date range selector (with 6-month, 1-year presets)
    - Toggle to hide income
    - Container for 4 chart components

20. **Monthly Category Bar Chart** (`src/components/charts/monthly-category-bar-chart.tsx`)
    - Recharts StackedBarChart — monthly spending by category
    - Legend with category colors
    - Tooltip with category breakdown

21. **Income vs Expense Line Chart** (`src/components/charts/income-expense-line-chart.tsx`)
    - Recharts LineChart — dual lines for income and expense over time
    - Month-by-month X axis

22. **Category Growth Chart** (`src/components/charts/category-growth-chart.tsx`)
    - Recharts LineChart — per-category spending trend lines
    - Category selector toggle

23. **Budget Analysis Chart** (`src/components/charts/budget-analysis-chart.tsx`)
    - Projected vs actual spending with variance display
    - Uses StatisticsService projections

24. **Category Info Popup** (`src/components/charts/category-info-popup.tsx`)
    - Tooltip/popover showing category details on chart interaction

### Phase 7: Settings & Data Management
**Estimated files: ~4**

25. **Settings page** (`src/app/settings/page.tsx`)
    - Currency dropdown (USD, EUR, GBP, JPY, ZAR, CAD, AUD, INR)
    - Theme toggle (Light / Dark / System) using `next-themes`
    - Export Data button → triggers JSON file download
    - Import Data button → file input for JSON upload
    - Clear All Data with confirmation dialog
    - About section (version info)

26. **File download utility** — Generate JSON blob, create download link
27. **File upload handler** — Parse uploaded JSON, validate structure, import via store

### Phase 8: Transactions Page Assembly
**Estimated files: ~2**

28. **Transactions page** (`src/app/transactions/page.tsx`)
    - Date range selector
    - Search bar + filter controls (type: income/expense, category dropdown)
    - Transaction list (from Phase 4)
    - FAB-style add button → opens add dialog or shows choice sheet (Manual / CSV Import)

### Phase 9: Testing
**Estimated files: ~10**

29. **Unit tests** (Vitest)
    - `src/lib/models/__tests__/transaction.test.ts` — Serialization, CSV parsing, factory functions
    - `src/lib/models/__tests__/category.test.ts` — Default categories, serialization
    - `src/lib/stores/__tests__/transaction-store.test.ts` — All store actions, computed values, duplicate detection, auto-categorization
    - `src/lib/stores/__tests__/undo-redo-store.test.ts` — Command execution, undo/redo stacks
    - `src/lib/services/__tests__/statistics-service.test.ts` — All analytics functions, edge cases
    - `src/lib/services/__tests__/storage-service.test.ts` — Persistence layer

30. **Component tests** (React Testing Library)
    - `src/components/__tests__/add-transaction-dialog.test.tsx` — Form validation, submission
    - `src/components/__tests__/date-range-selector.test.tsx` — Preset selection, custom range
    - `src/components/__tests__/csv-import-dialog.test.tsx` — CSV parsing, preview

31. **Integration tests**
    - `src/__tests__/app-integration.test.tsx` — Full user flows: add transaction, categorize, view charts, export/import

### Phase 10: Polish & Parity Check
**Estimated files: ~3**

32. **Cross-platform testing** — Verify on Chrome, Firefox, Safari, mobile viewports
33. **Accessibility** — Keyboard navigation, ARIA labels, color contrast
34. **Performance audit** — Lighthouse check, bundle size review
35. **Data migration** — Ensure JSON export from Flutter app can be imported into TypeScript app (same format)
36. **PWA setup** (optional) — Service worker, manifest for installable web app

---

## Feature Parity Checklist

| Feature | Flutter | TypeScript Plan |
|---|---|---|
| Manual transaction entry | AddTransactionDialog | add-transaction-dialog.tsx |
| CSV import with date format detection | CsvImportDialog | csv-import-dialog.tsx + papaparse |
| Auto-categorization by keywords | TransactionProvider._findBestCategory | transaction-store.ts |
| Duplicate detection | TransactionProvider._detectDuplicates | transaction-store.ts |
| Category CRUD | CategoriesPage | categories/page.tsx |
| Icon picker (100+ icons) | CategoriesPage icon grid | icon-picker.tsx (Lucide) |
| Color picker (8 colors) | CategoriesPage color grid | color-picker.tsx |
| Keyword recategorization preview | TransactionProvider.countTransactionsByKeywords | transaction-store.ts |
| Undo/Redo (50-deep stacks) | UndoRedoProvider + Command | undo-redo-store.ts + command.ts |
| Ctrl+Z / Ctrl+Y shortcuts | KeyboardHandler | use-keyboard-shortcuts.ts |
| Date range filtering | DateRangeSelector | date-range-selector.tsx |
| Search & filter transactions | TransactionsPage | transactions/page.tsx |
| Pie chart (category breakdown) | DashboardPage | category-pie-chart.tsx |
| Stacked bar chart (monthly) | MonthlyCategoryChart | monthly-category-bar-chart.tsx |
| Income vs Expense line chart | IncomeExpenseChart | income-expense-line-chart.tsx |
| Category growth trends | CategoryGrowthChart | category-growth-chart.tsx |
| Budget analysis / projections | BudgetAnalysisChart + StatisticsService | budget-analysis-chart.tsx |
| Statistical projections | StatisticsService (linear regression, dampening) | statistics-service.ts |
| JSON export/import (backup) | StorageService + SettingsPage | storage-service.ts + settings |
| Currency selection (8 currencies) | TransactionProvider | transaction-store.ts |
| Light/Dark/System theme | TransactionProvider + ThemeData | next-themes |
| Grouped transaction list | TransactionsPage | transaction-list.tsx |
| Swipe-to-delete | Dismissible | delete button (web-appropriate) |
| Bottom navigation (4 tabs) | HomePage BottomNavigationBar | bottom-nav.tsx |
| Summary cards (income/expense/net) | DashboardPage | summary-cards.tsx |
| Category info popup | CategoryInfoPopup | category-info-popup.tsx |
| Transaction detail editing | TransactionDetailsPopup | transaction-details-sheet.tsx |
| Smart tag creation | TransactionDetailsPopup | transaction-details-sheet.tsx |
| Clear all data | SettingsPage | settings/page.tsx |
| About dialog | SettingsPage | settings/page.tsx |

---

## Key Mapping Decisions

### Flutter → TypeScript Equivalents

| Flutter Concept | TypeScript Equivalent |
|---|---|
| `ChangeNotifier` + `Provider` | Zustand store |
| `StatefulWidget` | React component with hooks |
| `StatelessWidget` | React functional component |
| `SharedPreferences` | localStorage + IndexedDB (Dexie) |
| `fl_chart` | Recharts |
| `Material 3 widgets` | shadcn/ui + Tailwind |
| `showDialog()` / `showModalBottomSheet()` | shadcn Dialog / Sheet |
| `Navigator.push()` | Next.js App Router |
| `TextEditingController` | `useState` / React Hook Form |
| `DateFormat` (intl) | `date-fns` format |
| `NumberFormat` (intl) | `Intl.NumberFormat` (native) |
| `Dismissible` widget | Delete button / swipe library |
| `IndexedStack` | Next.js layout (automatic) |
| `ListView.builder` | Virtualized list or mapped array |
| `Theme.of(context)` | `next-themes` + Tailwind dark: |
| Material Icons | Lucide React icons |
| `file_picker` | `<input type="file">` |
| `csv` package | `papaparse` |
| `Color(0xFFRRGGBB)` | `#RRGGBB` hex string |
| `IconData(codePoint)` | Lucide icon component name |

### Data Format Compatibility

The TypeScript app will use the **same JSON backup format** as the Flutter app, with minor adaptations:
- Colors stored as hex strings instead of ARGB integers (conversion on import)
- Icons stored as Lucide icon names instead of Material codepoints (mapping table on import)
- Dates remain ISO 8601 strings
- Transaction structure is identical

---

## Dependencies (package.json)

```json
{
  "dependencies": {
    "next": "^14",
    "react": "^18",
    "react-dom": "^18",
    "zustand": "^4",
    "recharts": "^2",
    "dexie": "^4",
    "lucide-react": "^0.300",
    "date-fns": "^3",
    "papaparse": "^5",
    "next-themes": "^0.3",
    "@radix-ui/react-dialog": "latest",
    "@radix-ui/react-dropdown-menu": "latest",
    "@radix-ui/react-select": "latest",
    "@radix-ui/react-tooltip": "latest",
    "class-variance-authority": "latest",
    "clsx": "latest",
    "tailwind-merge": "latest"
  },
  "devDependencies": {
    "typescript": "^5",
    "tailwindcss": "^3",
    "@types/react": "^18",
    "@types/papaparse": "^5",
    "vitest": "^1",
    "@testing-library/react": "^14",
    "@testing-library/jest-dom": "latest",
    "jsdom": "latest"
  }
}
```

---

## Implementation Order Summary

| Phase | What | Key Risk |
|---|---|---|
| 1 | Scaffolding + Types + Models | Low — foundational setup |
| 2 | Storage + State (Zustand) | Medium — core logic port, must match Flutter behavior |
| 3 | Layout + Shared Components | Low — UI scaffolding |
| 4 | Transaction CRUD + CSV Import | Medium — CSV parsing edge cases, undo/redo integration |
| 5 | Dashboard + Categories | Medium — chart integration, icon mapping |
| 6 | Charts & Trends | Medium — Recharts API differs from fl_chart |
| 7 | Settings & Data Management | Low — straightforward port |
| 8 | Transactions Page Assembly | Low — composing existing components |
| 9 | Testing | Medium — test all ported business logic |
| 10 | Polish & Parity | Low — verification pass |

Each phase builds on the previous. Phases are designed so the app is functional (if incomplete) after Phase 5, with charts added in Phase 6 and full parity by Phase 8.
