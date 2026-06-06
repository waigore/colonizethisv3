# CtDarkScaffold (component)

**SPEC/ui/components** — Reusable dark editorial-monocle screen scaffold (top bar above an expanded body). Implementation: [`app/lib/widgets/ct_dark_scaffold.dart`](../../../app/lib/widgets/ct_dark_scaffold.dart). Catalog atoms: [`pixel-art-ui-catalog.md`](../pixel-art-ui-catalog.md) § *CtTopBar*, § *Editorial-monocle palette*.

This composite is **not** a screen and has **no** stable screen ID.

---

## Purpose

Provides the canonical dark-chrome screen wrapper: a `Scaffold` + `SafeArea` + `Column(crossAxisAlignment: stretch)` that stacks a caller-supplied top bar above an `Expanded` body. Promoted from the private `_DarkChromeShell` inside `CtGameFeatureScreenShell` (issue [#3279](https://github.com/waigore/colonizethisv3/issues/3279) §6) so any dark-theme screen can reuse the wrapper directly instead of hand-rolling a `Scaffold` (which would trip the `repo.app_no_material_scaffold` lint in `features/`). The widget carries no game/listener coupling.

---

## Widget contract

| Prop | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `topBar` | `Widget` | yes | — | Top chrome rendered as the first column child. Typically a `CtTopBar`. |
| `body` | `Widget` | yes | — | Screen body placed inside the `Expanded` region below `topBar`. |
| `backgroundColor` | `Color?` | no | `Theme.of(context).colorScheme.surface` | `Scaffold` background. Pass an explicit token (e.g. `EditorialMonoclePalette.bg`) for per-screen mockup backgrounds. |

---

## Layout / wireframe

```text
Scaffold(backgroundColor: backgroundColor ?? colorScheme.surface)
  SafeArea
    Column(crossAxisAlignment: stretch)
      topBar
      Expanded(child: body)
```

---

## Behavior

1. **Background resolution.** When `backgroundColor == null`, the `Scaffold` background is `Theme.of(context).colorScheme.surface` (the active theme — `AppThemes.editorialMonocle` in production per `colonizethis-ui-design.mdc` § *Dark theme*); otherwise the supplied colour is used verbatim.
2. **Stretch column.** `topBar` and the `Expanded(body)` are laid out in a `Column(crossAxisAlignment: stretch)` so both fill the available width.
3. **No internal state.** The composite is a `StatelessWidget`; it owns no chrome of its own beyond the scaffold/safe-area/column skeleton.

---

## Consumers

| Consumer | Notes |
|----------|-------|
| `CtGameFeatureScreenShell` | Dark-chrome path (`topBar != null`). See [`ct-game-feature-screen-shell.md`](ct-game-feature-screen-shell.md). |

Additional dark-theme screens may adopt `CtDarkScaffold` directly to reuse the wrapper.

---

## Acceptance criteria (Given–When–Then)

- **Given** a `CtDarkScaffold` mounted with a `topBar` and `body` widget and no `backgroundColor`, **When** the tree settles, **Then** exactly one `Scaffold` is mounted whose `backgroundColor` equals `Theme.of(context).colorScheme.surface`, and both the `topBar` and `body` widgets are reachable in the subtree.
- **Given** a `CtDarkScaffold` mounted with `backgroundColor: EditorialMonoclePalette.bg`, **When** the tree settles, **Then** the mounted `Scaffold.backgroundColor` equals `EditorialMonoclePalette.bg`.
- **Given** a `CtDarkScaffold`, **When** the tree settles, **Then** the `body` is rendered inside an `Expanded` that is a descendant of a `SafeArea`.

---

## Tests

- `app/test/ct_dark_scaffold_test.dart` — widget-level contract tests pinning the background resolution, the SafeArea + Expanded body placement, and the explicit-background override.

---

## Related

- Catalog: [`pixel-art-ui-catalog.md`](../pixel-art-ui-catalog.md) § *CtTopBar*, § *Editorial-monocle palette*.
- Host composite: [`ct-game-feature-screen-shell.md`](ct-game-feature-screen-shell.md).
- Tracking issue: [#3279](https://github.com/waigore/colonizethisv3/issues/3279) §6.
