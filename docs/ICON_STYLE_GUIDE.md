# Icon & Symbol Style Guide

UtilityKit now uses a shared icon strategy designed for attractive output without creating font-distribution headaches.

## Design rules

1. Prefer standard Unicode symbols that render in common terminal fonts.
2. Always provide plain ASCII fallbacks.
3. Avoid bundling third-party icon font assets directly in the repository.
4. Use color as enhancement, not as the only way to communicate state.
5. Keep semantic meaning consistent across tools.

## Shared semantic icons

- success → `✔` / `[OK]`
- warning → `⚠` / `[!]`
- error → `✖` / `[X]`
- info → `ℹ` / `i`
- action / processing → `⚙` / `*`
- prompt / next step → `❯` / `>`

## Tool icon suggestions used across the dashboard

- apply changes → sync / rotate arrow
- batch rename → pencil / edit symbol
- cache cleaner → trash symbol
- symlink manager → arrow link symbol
- disk analyzer → diamond/disk marker
- env manager → key or shield style semantic labeling
- git sweep → branch/janitor wording instead of fragile private-use glyphs
- docker janitor → container wording plus cleanup visuals
- port inspector → network/port semantics
- ssl checker → lock semantics
- api tester → request/response semantics
- password generator → shield/key semantics
- zen mode → animation-focused, minimal labels

## Why no bundled icon font files?

The suite deliberately avoids shipping patched icon fonts. That keeps the repository light and ensures the tools still work in:

- plain SSH sessions
- CI logs
- Termux
- minimal Linux TTYs
- terminals without Nerd Fonts installed

## Optional richer environments

If a user already runs a terminal with Nerd Font or fallback symbol support, UtilityKit still looks good, but it does not require those fonts to function.
