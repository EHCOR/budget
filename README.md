# Budget Tracker

A vibe-coded personal finance tracker for managing transactions, visualizing spending patterns, and tracking budgets. Built with Next.js and TypeScript.

## Features

- **Transaction Management**: Import via CSV, create, view, and categorize transactions
- **Budget Dashboard**: Interactive charts and spending summaries
- **Smart Categorization**: Auto-categorize transactions based on description
- **Filter & Search**: Filter by category, date, amount, or description
- **Multiple Currencies**: USD, EUR, GBP, ZAR, and more
- **Light & Dark Mode**: Theme toggle or system default
- **Data Management**: Backup and restore transaction data
- **Undo / Redo**: Full action history via buttons and hotkeys

## Getting Started

```bash
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

## Tech Stack

- **Framework**: Next.js 14 (App Router)
- **Language**: TypeScript
- **Styling**: Tailwind CSS
- **Charts**: Recharts
- **State**: Zustand
- **Testing**: Vitest + React Testing Library

## Scripts

| Command | Description |
|---|---|
| `npm run dev` | Start development server |
| `npm run build` | Production build |
| `npm test` | Run tests |
| `npm run lint` | Lint code |

## Legacy

The original Flutter implementation is preserved in the `flutter/` directory.

## License

MIT — see [LICENSE](LICENSE) for details.
