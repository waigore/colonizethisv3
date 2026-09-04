---
name: document-app-ui
description: Documents player-app UI screens and UI changes with stable 8-char screen IDs, exhaustive layout/behavior/variant specs, Widgetbook linkage, and code bindings. Use when adding or modifying screens, dialogs, overlays, routes, or when the user asks to document app UI or reconcile UI specs with implementation.
---

# Document app UI (ColonizeThis)

Follow **[`.cursor/rules/colonizethis-ui-documentation.mdc`](../../rules/colonizethis-ui-documentation.mdc)** — do not restate its template or ID rules. Style: `colonizethis-ui-design.mdc`. Registry: `SPEC/ui/screen-registry.md`. Code IDs: `app/lib/config/ui_screen_ids.dart`.

Use for new/changed player-app screen, dialog, overlay, or route host; skip ctdev (`SPEC/program/ctdev-app.md`).

1. **ID** — category + sub-flow from the registry; next `####`; registry row; `UiScreenIds` + widget `screenId`. Variants: suffix letter.
2. **Spec** — `SPEC/ui/<name>.md` using the rule template (including required-on-open loads and mount/dispose). Exhaustive behavior — every control. New composites: `SPEC/ui/components/<kebab>.md` first.
3. **Align** — `SPEC/program/app-ui-wiring.md` / `app-event-bus.md` for cross-screen work. Preserve the stable ID line. Wireframe matches the widget tree.
4. **Widgetbook** — `app/lib/widgetbook/catalog*.dart`; one use case per major variant; names must match the spec.
5. **Tests** — ACs point at existing screen-spec tests; cover new triggers/emissions.

```markdown
Screen: <title> (`<ID>`)
Registry: <updated | already registered>
Spec: SPEC/ui/<file>.md
Code: <dart path> + UiScreenIds.<const>
Widgetbook: <folder / use cases>
Gaps: <draft leftovers>
```
