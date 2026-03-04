# Budget Tracker — TypeScript/Next.js

The primary codebase is TypeScript/Next.js in `src/`. The original Flutter implementation lives in `flutter/` for reference.

## Development Commands
- Run dev server: `npm run dev`
- Run all tests: `npm test`
- Build: `npm run build`
- Lint: `npm run lint`
- Type check: `npx tsc --noEmit`

## Code Style Guidelines
- **File Structure**: `src/app/` (pages/routes), `src/components/`, `src/hooks/`, `src/lib/`
- **Imports**: External packages first, then relative imports
- **Naming**: Components use PascalCase, hooks use camelCase with `use` prefix, files use kebab-case
- **Components**: Prefer server components; use `"use client"` only when needed
- **State Management**: React hooks and context; avoid prop drilling
- **Styling**: Tailwind CSS utility classes
- **Error Handling**: Use try/catch with user-friendly error messages
- **Testing**: Vitest + React Testing Library for components and logic

## Flutter (legacy)
The original Flutter app is in `flutter/`. Commands from that directory:
- Run: `flutter run`
- Test: `flutter test`
