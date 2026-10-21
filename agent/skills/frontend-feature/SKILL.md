---
name: frontend-feature
description: Guide for developing React + TypeScript + Vite features in apps/web following Ponytail minimalist principles and curated UI aesthetics.
---

# Frontend Feature Workflow

Use this workflow to build or update user interfaces in `apps/web`.

## 1. Minimalist Component Philosophy (Ponytail)
- Use standard HTML5 inputs (`<input type="date">`, `<select>`, `<dialog>`, `<form>`) before reaching for third-party widget libraries.
- Rely on TanStack Query (`@tanstack/react-query`) for server state management.
- Do not introduce Redux, Zustand, or complex global stores for simple UI state.
- Keep components organized under `src/features/<domain>/` and share only truly reusable components in `src/components/ui/`.

## 2. Design Aesthetics
- Respect the brand color system, font hierarchy, and card layouts extracted from the reference design.
- Support clean responsive layouts with CSS variables.
- Provide clear loading skeletons and accessible error states.

## 3. Verification
- Run `npm run build` to verify TypeScript typing and bundle compilation.
