# Getting Started

This skill assumes the consumer project should use the prebuilt package:

- Package: `@jetbrains/ring-ui-built`
- Global stylesheet: `@jetbrains/ring-ui-built/components/style.css`
- Per-component imports: `@jetbrains/ring-ui-built/components/<folder>/<entry>`

## Install

Use the project's package manager:

```bash
npm install @jetbrains/ring-ui-built
pnpm add @jetbrains/ring-ui-built
yarn add @jetbrains/ring-ui-built
```

If the app needs explicit Ring UI glyph imports, also add `@jetbrains/icons`.

## Root CSS Import

Import Ring UI styles once in the app root, layout root, or shared entry file:

```tsx
import '@jetbrains/ring-ui-built/components/style.css';
```

Do not repeat this import in every component file.

## Import Pattern

Use direct per-component imports:

```tsx
import Button from '@jetbrains/ring-ui-built/components/button/button';
import Input from '@jetbrains/ring-ui-built/components/input/input';
import Select from '@jetbrains/ring-ui-built/components/select/select';
```

Service-style APIs use the same path pattern:

```tsx
import alertService from '@jetbrains/ring-ui-built/components/alert-service/alert-service';
import confirm from '@jetbrains/ring-ui-built/components/confirm-service/confirm-service';
```

## Minimal Smoke Example

```tsx
import '@jetbrains/ring-ui-built/components/style.css';
import Button from '@jetbrains/ring-ui-built/components/button/button';

export function SaveButton() {
  return <Button primary>Save</Button>;
}
```

## Host Project Checklist

Before editing code, check:

1. Does the project already use Ring UI or JetBrains styling tokens?
2. Is there already a root stylesheet import for Ring UI?
3. Is the app React-based and already able to import CSS from packages?
4. Are there existing local wrappers around Ring UI components that should be reused instead of importing raw components again?

## Common Pitfalls

- Missing global `style.css` import: components render without expected styling.
- Importing from `@jetbrains/ring-ui` instead of `@jetbrains/ring-ui-built`: that changes the integration model and may require custom bundler work.
- Copying Storybook demo code too literally: stories often show many variants at once, not the smallest production integration.
- Treating service APIs and visual components the same: `alert-service`, `confirm-service`, and auth services are not rendered like plain JSX elements.
