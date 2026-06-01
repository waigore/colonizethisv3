# CtFullScreenDialogueShell (component)

**SPEC/ui/components** — Reusable full-screen scrim + centered `CtDialogShell` wrapper for blocking dialogue overlays. Implementation: [`app/lib/widgets/ct_full_screen_dialogue_shell.dart`](../../../app/lib/widgets/ct_full_screen_dialogue_shell.dart). Catalog atoms: [`pixel-art-ui-catalog.md`](../pixel-art-ui-catalog.md) § *CtFullScreenDialogueShell* and § *Dialog scrim*.

This composite is **not** a screen and has **no** stable screen ID. It is the canonical scaffolding for full-screen modal dialogue overlays referenced by the screen specs listed under [Consumers](#consumers).

---

## Purpose

Consolidates the `Stack` → full-screen `Material(dialogScrim)` → `Center` → `CtDialogShell` → `Padding` scaffold previously inlined into four overlay files (issue [#2914](https://github.com/waigore/colonizethisv3/issues/2914) S2). Callers compose only the dialogue body; the shell guarantees the canonical editorial-monocle scrim token, dialog frame, and inner padding.

---

## Widget contract

| Prop | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `backdrop` | `Widget` | yes | — | Painted at the bottom of the outer `Stack`; typically the underlying game canvas / app shell that the overlay is dimming. |
| `body` | `Widget` | yes | — | Dialogue body wrapped in a single inner `Padding` and hosted inside the centered `CtDialogShell`. |
| `maxWidth` | `double` | no | `defaultMaxWidth = 520` | Forwarded verbatim to the inner `CtDialogShell.maxWidth`. |
| `maxHeight` | `double` | no | `defaultMaxHeight = 600` | Forwarded verbatim to the inner `CtDialogShell.maxHeight`. |
| `padding` | `EdgeInsetsGeometry` | no | `defaultPadding = EdgeInsets.all(CtSpacing.xl)` (20 dp) | Inner `Padding` wrapping `body` inside the dialog frame. |

The shell intentionally renders **no** title row, brass divider, or per-screen chrome — consumers compose those above `body` so each overlay can preserve its own title-ordering and divider placement.

---

## Layout / wireframe

```text
Stack
  backdrop                                            -- bottom layer
  Material(color: EditorialMonoclePalette.dialogScrim) -- canonical scrim token
    Center
      CtDialogShell(maxWidth, maxHeight)              -- accent-dim border + panel gradient
        Padding(padding)
          body
```

Single `Stack` with exactly two top-level children. The full-screen `Material` host paints the scrim color so the `CtDialogShell` can preserve its own (transparent or opaque) chrome without leaking light-theme defaults.

---

## Behavior

1. **Scrim token, always.** The full-screen `Material` is painted with `EditorialMonoclePalette.dialogScrim`. Hex literals such as `Colors.black54` are forbidden in this layer per [`pixel-art-ui-catalog.md`](../pixel-art-ui-catalog.md) § *Dialog scrim*.
2. **Dialog frame inheritance.** The inner `CtDialogShell` carries the canonical 2 px `--accent-dim` border and `CtGradients.panelGradient` background. The shell does not override either.
3. **Render order.** The `backdrop` widget is painted first (`Stack` bottom). The scrim and dialog overlay are painted on top.
4. **Single inner `Padding`.** The shell wraps `body` in exactly one `Padding` whose value equals the configured `padding` prop. Consumers must not add a redundant outer `Padding` of the same value.
5. **No animation, no dismissal logic.** The shell is a pure layout composite. Show / hide animations and dismissal callbacks belong to the consuming overlay.

---

## States and variants

The composite has no internal state and exposes no variants. Consumers drive variants by swapping the `body` widget (loading spinner, error card, decision list, etc.).

---

## Consumers

The following screen specs use this composite as their scrim + shell scaffold:

| Screen ID | Spec | Notes |
|-----------|------|-------|
| `OVL10001` | [`game-start-intro-overlay.md`](../game-start-intro-overlay.md) | Game-start intro Yarn overlay. |
| `OVL30001` | [`overture-dialogue-overlay.md`](../overture-dialogue-overlay.md) | Pending-overture decision overlay. |
| `OVL40001` | [`call-to-arms-dialogue-overlay.md`](../call-to-arms-dialogue-overlay.md) | Pending call-to-arms decision overlay. |
| Intervention overlay | [`screens/pending-intervention-overlay.md`](../screens/pending-intervention-overlay.md) | Pending-intervention dialogue overlay. |

Each consumer spec links back here for the scrim / shell / padding contract instead of duplicating the wireframe.

---

## Acceptance criteria (Given–When–Then)

- **Given** a `CtFullScreenDialogueShell` mounted with a non-empty `backdrop` and `body` and the default theme `AppThemes.editorialMonocle`,
  **When** the widget tree settles,
  **Then** the `backdrop` widget mounts in the subtree, exactly one `CtDialogShell` is mounted in the subtree, and the scrim `Material` immediately above the `CtDialogShell` reports `color == EditorialMonoclePalette.dialogScrim`.

- **Given** a `CtFullScreenDialogueShell` mounted with `backdrop` and `body` and the default theme,
  **When** every `Material` widget descendant of the shell is inspected,
  **Then** no descendant has `color == Colors.black54` (regression guard for the canonical `--dialog-scrim` token; see [`pixel-art-ui-catalog.md`](../pixel-art-ui-catalog.md) § *Dialog scrim*).

- **Given** a `CtFullScreenDialogueShell` mounted with `maxWidth == 300` and `maxHeight == 240`,
  **When** the inner `CtDialogShell` is inspected,
  **Then** `CtDialogShell.maxWidth == 300` and `CtDialogShell.maxHeight == 240`.

- **Given** a `CtFullScreenDialogueShell` mounted with a custom `padding == EdgeInsets.all(11)`,
  **When** every `Padding` ancestor of the `body` widget is inspected,
  **Then** exactly one ancestor `Padding` has `padding == EdgeInsets.all(11)` (the inner content padding the shell controls; the inner `CtDialogShell` may add its own outer padding which is not counted by this AC).

- **Given** a `CtFullScreenDialogueShell` mounted with all default values,
  **When** the constants are read,
  **Then** `CtFullScreenDialogueShell.defaultMaxWidth == 520`, `CtFullScreenDialogueShell.defaultMaxHeight == 600`, and `CtFullScreenDialogueShell.defaultPadding == EdgeInsets.all(CtSpacing.xl)` (20 dp), keeping the composite aligned with the `CtSpacing` token table in [`pixel-art-ui-catalog.md`](../pixel-art-ui-catalog.md) § *Spacing tokens*.

- **Given** the `CtFullScreenDialogueShell` source under `app/lib/widgets/ct_full_screen_dialogue_shell.dart`,
  **When** the file is read as a string,
  **Then** the source contains `EditorialMonoclePalette.dialogScrim` and does **not** contain the literal `Colors.black54` (regression guard pinning the canonical scrim token at the source level).

---

## Tests

- `app/test/ct_full_screen_dialogue_shell_test.dart` — widget-level contract tests pinning the backdrop / scrim / dialog composition, the canonical scrim token, prop forwarding, and default values.
- `app/test/spec_components_ct_full_screen_dialogue_shell_test.dart` — spec-pinning regression tests asserting that this component spec exists, declares the required sections (Widget contract, Layout, Acceptance criteria, Consumers), and points back to the canonical SPEC anchors.

---

## Related

- Catalog reference: [`pixel-art-ui-catalog.md`](../pixel-art-ui-catalog.md) § *CtFullScreenDialogueShell*, § *Dialog scrim*, § *Spacing tokens*.
- Inner shell: [`app/lib/widgets/ct_dialog_shell.dart`](../../../app/lib/widgets/ct_dialog_shell.dart).
- Tracking issue: [#2914](https://github.com/waigore/colonizethisv3/issues/2914) S2 (extraction) and S9 (component spec authoring).
