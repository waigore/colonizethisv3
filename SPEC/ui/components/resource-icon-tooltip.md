# ResourceIconTooltip (UI convention)

**SPEC/ui/components** — Discoverability convention for resource / treasury / worker icons rendered **without** an adjacent name label. Catalog atoms: [`pixel-art-ui-catalog.md`](../pixel-art-ui-catalog.md) § *ResourceIcon*, § *Editorial-monocle palette*. Mobile contract: [`mobile-adaptation.md`](../mobile-adaptation.md) § 1.

This is a **convention**, not a single widget. It governs how an icon-only resource glyph exposes its meaning to the player.

---

## Purpose

When a `ResourceIcon` (commodity), treasury coin, or `WorkerIcon` is drawn next to a bare number — with no visible name text — the player cannot tell what the glyph means without memorizing the icon set. On desktop there is no hover affordance; on mobile there is no tap affordance. This convention makes every such icon **self-describing** through a `Tooltip`, and reachable on touch devices through a minimum touch target.

---

## Convention (normative)

Any `ResourceIcon`, treasury coin icon, or `WorkerIcon` rendered **without** adjacent name text MUST:

1. **Carry a `Tooltip`** wrapping the icon (and, where the icon shares a compact `icon + number` segment, that whole segment), using `triggerMode: TooltipTriggerMode.tap` so the same control shows the tooltip on desktop hover **and** on mobile tap.
2. **Expose a name message.** The tooltip `message` is:
   - **Commodity icon:** `"{displayName} ({category})"` — display name from `CommodityCatalog`, category from the localized lowercase `CommodityCategory` name (e.g. `Fabric (manufactured)`, `Coal (raw material)`). Built by `commodityIconTooltip(l10n, commodityId)` in `app/lib/features/game/utils/commodity_ui_helpers.dart`.
   - **Treasury coin icon:** the localized `Treasury` label (`trainDialog_costTreasuryTooltip`).
   - **Worker (peasant) icon:** the localized `Peasants` label (`trainDialog_costPeasantsTooltip`).
3. **Meet the touch target.** The tooltip-trigger region is at least `kMinTouchTargetSize` (44 dp) in both dimensions (`SPEC/ui/mobile-adaptation.md` § 1), even though the underlying glyph is smaller (e.g. 14 dp).

Icons that already render an adjacent name label (for example `ResourceLabelInline`, `TrainDialogResourceChip` value lines) are **exempt** — the name is already discoverable.

---

## Category names

| `CommodityCategory` | Tooltip word | l10n key |
|---------------------|--------------|----------|
| `food` | `food` | `commodityCategory_food` |
| `rawMaterial` | `raw material` | `commodityCategory_rawMaterial` |
| `manufactured` | `manufactured` | `commodityCategory_manufactured` |
| `luxury` | `luxury` | `commodityCategory_luxury` |
| `riches` | `riches` | `commodityCategory_riches` |
| `advanced` | `advanced` | `commodityCategory_advanced` |

---

## Reference implementation

`TrainDialogInlineCost` ([`train-dialog-chrome.md`](train-dialog-chrome.md)) is the canonical shared widget applying this convention, consumed by the Train Military (`UNIT50001`) and Train Naval (`UNIT60001`) dialogs for each treasury / peasant / commodity cost segment.

---

## Consumers

| Screen ID | Spec | Icons covered |
|-----------|------|---------------|
| `UNIT50001` | [`train-military-dialog.md`](../train-military-dialog.md) | Treasury, peasant, regiment commodity costs. |
| `UNIT60001` | [`train-naval-dialog.md`](../train-naval-dialog.md) | Treasury, peasant, ship commodity costs. |

---

## Acceptance criteria (Given–When–Then)

- **Given** a commodity cost icon for `fabric` rendered with no adjacent name, **When** the user hovers (desktop) or taps (mobile) the icon, **Then** a `Tooltip` shows `Fabric (manufactured)`.
- **Given** a treasury coin cost icon rendered with no adjacent name, **When** the user hovers/taps it, **Then** a `Tooltip` shows `Treasury`.
- **Given** a peasant worker cost icon rendered with no adjacent name, **When** the user hovers/taps it, **Then** a `Tooltip` shows `Peasants`.
- **Given** any icon applying this convention, **When** its tooltip-trigger region resolves, **Then** the region's rendered height and width are each `>= 44` dp (`kMinTouchTargetSize`).
- **Given** `commodityIconTooltip(l10n, commodityId)` called with a `commodityId` absent from `CommodityCatalog`, **When** it resolves, **Then** it returns the raw `commodityId` string with no category suffix (no crash).

---

## Tests

- `app/test/train_dialog_inline_cost_tooltip_test.dart` — pins the tooltip message, tap trigger, 44 dp touch target, the `commodityIconTooltip` helper (including the unknown-id fallback), and the military/naval cost-icon tooltips.

---

## Related

- [`train-dialog-chrome.md`](train-dialog-chrome.md) — host chrome and `TrainDialogInlineCost`.
- Tracking issue: [#3631](https://github.com/waigore/colonizethisv3/issues/3631).
