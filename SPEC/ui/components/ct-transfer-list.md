# CtTransferList (component)

**SPEC/ui/components** — Reusable dual-list transfer composite for moving counted items (ships, regiments, generic typed tokens). Implementation: [`app/lib/widgets/ct_transfer_list.dart`](../../../app/lib/widgets/ct_transfer_list.dart). Catalog atoms: [`pixel-art-ui-catalog.md`](../pixel-art-ui-catalog.md) § *CtTransferList*, *CtNinePatchButton*, *CtPanel*.

This composite is **not** a screen and has **no** stable screen ID. It is the canonical dual-list transfer scaffold referenced by the screen specs under [Consumers](#consumers).

---

## Purpose

Consolidates the dual-panel quantity-transfer chrome shared by `SplitArmyDialog`, `SplitFleetDialog`, and `TransferToHomeFleetDialog`. Callers configure per-side titles, initial counts, item labels, and a `canConfirm` hook; the composite owns the side panels, per-row one / move-all controls, running totals, the Cancel / Confirm action row, and the narrow-viewport stack rule honouring `kMinViewportWidth = 320` dp (per [`mobile-adaptation.md`](../mobile-adaptation.md) § 7). Tracking issue: [#2914](https://github.com/waigore/colonizethisv3/issues/2914) S9.

---

## Widget contract

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `leftTitle` / `rightTitle` | `String` | required | Panel titles (`Theme.titleSmall`). |
| `leftSubtitle` / `rightSubtitle` | `String?` | `null` | Panel subtitles (`Theme.bodySmall`). |
| `initialLeftCounts` | `Map<String, int>` | required | Starting per-type counts; mutated locally. |
| `initialRightCounts` | `Map<String, int>` | `{}` | Starting per-type counts; mutated locally. |
| `itemLabelBuilder` | `String Function(String)?` | identity | Maps `itemId` → localized row label. |
| `canConfirm` | `bool Function(Map, Map)?` | `rightTotal > 0` | Confirm gate. |
| `onChanged` | `void Function(Map, Map)?` | `null` | Fires after every accepted move. |
| `onConfirm` | `void Function(Map, Map)` | required | Fires when `canConfirm` returns `true`. |
| `onCancel` | `VoidCallback?` | `null` | When supplied, Cancel renders. |
| `listHeight` | `double` | `150` | Pixel height of each scrollable list. |
| `totalLabelBuilder` | `String Function(int)?` | `'Total: $total items'` | Total-row formatter. |

Empty labels (`leftEmptyLabel` / `rightEmptyLabel`), move labels (`>`/`>>`/`<`/`<<`), and action button labels (`cancelLabel`, `confirmLabel`) are configurable `String` props defaulting to `'No items'`, the ASCII arrow glyphs, `'Cancel'`, and `'Confirm'`. Exposed constant: `kCtTransferListSideBySideMinWidth = 360` (logical px). Per-row widget keys: `CtTransferListKeys.{leftMoveOne, leftMoveAll, rightMoveOne, rightMoveAll}` keyed by `itemId`.

---

## Layout / wireframe

### Side-by-side (`constraints.maxWidth >= 360 dp`)

```text
Column(min, stretch)
  Row(start)
    Expanded(left panel — CtPanel: title · [subtitle?] · Divider · ListView · Divider · total)
    SizedBox(16) · Expanded(right panel — mirror)
  SizedBox(16)
  Row(end)                                -- right-aligned action row
    [Cancel?] · Confirm(enabled: canConfirm)
```

### Narrow stack (`constraints.maxWidth < 360 dp`)

```text
Column(min, stretch)
  left panel · SizedBox(16) · right panel · SizedBox(16)
  Wrap(end, spacing: 8)                   -- wraps to a second run when needed
    [Cancel?] · Confirm(enabled: canConfirm)
```

Row chrome — left panel: `[Expanded(label) [>] [>>]]`; right panel: `[[<<] [<] Expanded(label)]`. Move controls disable when their side's row count is zero.

---

## Behavior

1. **Local state only.** Two local count maps mirror the initial inputs; zero-count rows are cleaned up after every move. The composite never mutates host game state — persisted side effects flow through `onConfirm` only.
2. **Move semantics.** `>` / `<` move one unit across; `>>` / `<<` move every remaining unit of that row. `onChanged` fires after each accepted move with deep-copied maps.
3. **Confirm gate.** Confirm fires only when `canConfirm` returns `true`. The default (`rightTotal > 0`) suits split flows; `TransferToHomeFleetDialog` overrides it to require a positive source-side delta.
4. **Narrow stack.** Below `kCtTransferListSideBySideMinWidth` (`360` dp) the side panels stack vertically and the action row switches from a right-aligned `Row` to a `Wrap(alignment: end)` so the Cinzel `CtNinePatchButton` pair never overflows the ~`288` dp `CtDialogShell` content column at `kMinViewportWidth = 320` dp.
5. **Empty per-side.** With zero rows, the list area renders the per-side empty label centered in `Theme.bodyMedium` tinted by `colorScheme.onSurfaceVariant`.

---

## States and variants

No exposed variants. Run-time states are user-move driven (`initial → moving → reverted → confirm-eligible`). Hosts that need surrounding chrome wrap `CtTransferList` in a `CtDialogShell` or [`CtFullScreenDialogueShell`](ct-full-screen-dialogue-shell.md).

---

## Consumers

| Screen | Spec | Notes |
|--------|------|-------|
| `DLG40001` Transfer to Home Fleet | [`transfer-to-home-fleet-dialog.md`](../transfer-to-home-fleet-dialog.md) | Custom `canConfirm`: positive source delta. |
| Split Fleet dialog | [`naval-units-fleet-management.md`](../naval-units-fleet-management.md) § Split Fleet | Default `canConfirm`. |
| Split Army dialog | [`military-units-army-management.md`](../military-units-army-management.md) § Split Army Dialog | Mirrors Split Fleet with regiment labels. |

Consumer specs link back here instead of duplicating the wireframe.

---

## Acceptance criteria (Given–When–Then)

- **Given** `initialLeftCounts = { 'carrack': 2 }` / `initialRightCounts = { 'carrack': 1 }`, **When** the tree settles, **Then** the left total reads `Total: 3 items` and the right reads `Total: 1 items`.
- **Given** default `canConfirm` and `initialRightCounts = {}`, **When** the tree settles, **Then** Confirm reports `enabled == false`.
- **Given** the same instance with `initialLeftCounts = { 'carrack': 2 }`, **When** the user taps the left-side `>` for `carrack`, **Then** counts become `left = { 'carrack': 1 }` / `right = { 'carrack': 1 }`, `onChanged` fires once with those maps, and Confirm reports `enabled == true`.
- **Given** the host constrains `maxWidth == 320` dp, **When** the tree settles, **Then** the side panels mount inside a single `Column` (no `Row` ancestor between them) and the action row uses a `Wrap` ancestor.
- **Given** the host constrains `maxWidth == 600` dp, **When** the tree settles, **Then** the side panels mount inside one `Row` (each in an `Expanded`) and the action row uses a single right-aligned `Row`.
- **Given** `onCancel == null`, **When** the action row builds, **Then** no Cancel button is mounted and only Confirm is present.
- **Given** the source `app/lib/widgets/ct_transfer_list.dart`, **When** read, **Then** it contains `kCtTransferListSideBySideMinWidth = 360` and does **not** contain `Colors.black54` (canonical scrim contract regression guard).

---

## Tests

- `app/test/widgets/ct_transfer_list_test.dart` — widget contract tests pinning move semantics, totals, default `canConfirm`, and the narrow-stack threshold.
- `app/test/dialogs_320dp_min_viewport_test.dart` — pins the three hosted dialogs at `kMinViewportWidth = 320` dp without overflow.
- `app/test/spec_components_ct_transfer_list_test.dart` — spec-pinning tests asserting this spec exists, declares the canonical sections, enumerates the three consumers, and restates the `360` dp threshold.

---

## Related

- Catalog: [`pixel-art-ui-catalog.md`](../pixel-art-ui-catalog.md) § *CtTransferList*, *CtNinePatchButton*, *Editorial-monocle palette*, *Spacing tokens*.
- Hosting shells: [`ct_dialog_shell.dart`](../../../app/lib/widgets/ct_dialog_shell.dart), [`ct-full-screen-dialogue-shell.md`](ct-full-screen-dialogue-shell.md).
- Narrow-viewport policy: [`mobile-adaptation.md`](../mobile-adaptation.md) § 7.
- Tracking issue: [#2914](https://github.com/waigore/colonizethisv3/issues/2914) S9.
