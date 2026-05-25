---
name: document-app-ui
description: Documents player-app UI screens and UI changes with stable 8-char screen IDs, exhaustive layout/behavior/variant specs, Widgetbook linkage, and code bindings. Use when adding or modifying screens, dialogs, overlays, routes, or when the user asks to document app UI or reconcile UI specs with implementation.
---

# Document app UI (ColonizeThis)

## Authority

Normative policy: **[`.cursor/rules/colonizethis-ui-documentation.mdc`](../../../.cursor/rules/colonizethis-ui-documentation.mdc)**. Routing: **[`.cursor/rules/routing-index.md`](../../../.cursor/rules/routing-index.md)**. Style/pixel-art: **`colonizethis-ui-design.mdc`** (orthogonal to screen structure).

Registry: [`SPEC/ui/screen-registry.md`](../../../SPEC/ui/screen-registry.md). Code IDs: `app/lib/config/ui_screen_ids.dart`.

Cursor copy: [`.cursor/skills/document-app-ui/SKILL.md`](../../../.cursor/skills/document-app-ui/SKILL.md) — keep workflow in sync; policy changes belong in the `.mdc` only.

## When to use

- New or changed player-app **screen**, **dialog**, **overlay**, or **route host**.
- Document UI / add screen spec / align spec with implementation.
- PR changes layout, bus wiring, variants, or Widgetbook for a screen.

Not for ctdev (`SPEC/program/ctdev-app.md`).

## Workflow

1. **ID** — Category + sub-flow from registry; next `####`; add row + `UiScreenIds` + widget `screenId`. Variants: `ID` + `a`/`b`/….
2. **Spec** — `SPEC/ui/<kebab>.md` using the `.mdc` template (layout, exhaustive behavior tables, variants, Widgetbook, ACs).
3. **Components** — New composites → `SPEC/ui/components/<name>.md` before screen spec references.
4. **Widgetbook** — `catalog*.dart` use cases per variant; mobile when required.
5. **Tests** — Given–When–Then ACs → existing screen acceptance tests where applicable.

## Output

Report: screen title, ID, registry/spec/code/Widgetbook paths, `draft` vs `active` gaps.

## Related skills

- `implement-github-issue` — implementation after spec is ready
- `verify-github-issue` — AC closure
