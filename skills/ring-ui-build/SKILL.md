---
name: ring-ui-build
description: Use when an agent needs to add, replace, or debug JetBrains Ring UI components in a non-ring-ui React project, especially when working with @jetbrains/ring-ui-built imports, global style.css setup, component selection, or Ring UI composition patterns.
---

# Ring UI Build

## Overview

Use this skill as a router and usage guide for `@jetbrains/ring-ui-built`. The main file stays small on purpose; concrete imports, component inventory, and snippets live in `references/`.

## Reading Order

- Start with `references/getting-started.md` for install, global CSS, icon, and import rules.
- Read `references/components.md` when the main question is "which Ring UI component should I use?"
- Read `references/patterns.md` when the main question is "how do I compose this component correctly?"

## Quick Routing By Intent

| Intent | Start here |
| --- | --- |
| Install Ring UI into a React app | `references/getting-started.md` |
| Fix broken Ring UI imports | `references/getting-started.md` |
| Pick the right component for a feature | `references/components.md` |
| Build a form, modal, menu, table, tabs, or picker | `references/patterns.md` |
| Understand specialized or service-style APIs | `references/components.md` |

## Working Rules

1. Assume the consumer project should use `@jetbrains/ring-ui-built` unless the user explicitly asks for source-package integration.
2. Import `@jetbrains/ring-ui-built/components/style.css` exactly once at the app root before adding individual components.
3. Prefer existing Ring UI components over recreating similar UI with custom markup.
4. Match the target project's React state, routing, and styling patterns instead of copying Ring UI Storybook code literally.
5. If a component needs glyph props such as `icon` or `glyph`, check whether the consumer project already depends on `@jetbrains/icons`; add it only when the project needs explicit icon imports.
6. Validate with the target project's existing build, lint, and test commands. Do not start a dev server just to verify Ring UI wiring.

## Workflow

1. Inspect the target project for existing Ring UI usage, root stylesheet imports, package manager, and React patterns.
2. If Ring UI is not installed, follow `references/getting-started.md`.
3. Choose a component from `references/components.md` instead of inventing custom UI first.
4. Pull the closest code shape from `references/patterns.md` and adapt it to the host project.
5. Run the narrowest available verification command that proves the integration still builds.
