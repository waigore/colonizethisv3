---
name: document-app-ui
description: Documents player-app UI screens and UI changes with stable 8-char screen IDs, exhaustive layout/behavior/variant specs, Widgetbook linkage, and code bindings. Use when adding or modifying screens, dialogs, overlays, routes, or when the user asks to document app UI or reconcile UI specs with implementation.
---

# Document app UI (ColonizeThis)

## Authority

Follow **[`.cursor/rules/colonizethis-ui-documentation.mdc`](../../.cursor/rules/colonizethis-ui-documentation.mdc)** — do not restate its template or ID rules here. Style/pixel-art/theming stays in **`colonizethis-ui-design.mdc`**.

Registry: [`SPEC/ui/screen-registry.md`](../../SPEC/ui/screen-registry.md). Code IDs: `app/lib/config/ui_screen_ids.dart`.

## When to use

- New or changed **screen**, **dialog**, **overlay**, or **route host** in the player app.
- User asks to **document UI**, **add a screen spec**, or **align spec with code**.
- PR touches layout, bus wiring, variants, or Widgetbook for a screen.

Skip ctdev-only surfaces (`SPEC/program/ctdev-app.md`).

## Workflow

```
Task progress:
- [ ] 1. Identify surface type (route / overlay / dialog / panel)
- [ ] 2. Assign or confirm stable screen ID (registry + UiScreenIds)
- [ ] 3. Write or update SPEC/ui/<name>.md (rule template)
- [ ] 4. Add component spec if new composite (SPEC/ui/components/)
- [ ] 5. Bind screenId on widget; register Widgetbook use cases
- [ ] 6. Add Given–When–Then ACs; note test file paths
```

### 1. ID assignment

1. Open [`screen-registry.md`](../../SPEC/ui/screen-registry.md) — pick **category** (3 letters) and **sub-flow** (4th digit).
2. Allocate next `####` in that sub-flow; never reuse or renumber.
3. Add registry row (`draft` until spec + Widgetbook + code binding land).
4. Add `static const` on `UiScreenIds` and `static const screenId = ...` on the widget.

**Variants:** suffix letter (`GAME10001a`); document in **States and variants** unless split spec is required.

### 2. Spec content (checklist)

Per `colonizethis-ui-documentation.mdc`:

| Section | Must include |
|---------|----------------|
| Header | Screen ID, Dart path, Widgetbook folder |
| Trigger conditions | Every entry path (routes, bus, parent) |
| Layout / wireframe | ASCII hierarchy; Ct-* widgets; link composites |
| Behavior | Tables: incoming triggers; every control → emit/call |
| States and variants | IDs, suffix letters, render differences |
| Widgetbook | Folder, file, each use case + overrides |
| ACs | Given–When–Then (`colonizethis-acceptance-criteria.mdc`) |

**Exhaustive behavior:** No "etc." — list every button, slider, chip, and back gesture with enable/disable rules and bus event types.

**Composites:** New multi-part widgets → `SPEC/ui/components/<kebab>.md` first; screen spec links only.

### 3. Implementation alignment

- Cross-screen work → `SPEC/program/app-ui-wiring.md`, `app-event-bus.md`.
- Read existing spec for the screen before editing; preserve stable ID line.
- Match wireframe to actual widget tree (`app/lib/features/`, `app/lib/widgets/`).

### 4. Widgetbook

- Register in `app/lib/widgetbook/catalog*.dart`.
- One use case per major variant; mobile use case when [`mobile-adaptation.md`](../../SPEC/ui/mobile-adaptation.md) applies.
- Spec **Widgetbook** section must match catalog names exactly.

### 5. Tests

- Point ACs to `app/test/screen_spec_acceptance_test.dart` or focused `*_test.dart`.
- Do not add trivial tests; cover new triggers and emissions.

## Output to the user

```markdown
Screen: <title> (`<ID>`)

Registry: <updated | already registered>
Spec: SPEC/ui/<file>.md
Code: <dart path> + UiScreenIds.<const>
Widgetbook: <folder / use cases>
Gaps: <anything left draft>
```

## Related

- Implement behavior: `implement-github-issue` skill
- Style/assets only: `colonizethis-ui-design.mdc`
- Verify ACs: `verify-github-issue` skill
