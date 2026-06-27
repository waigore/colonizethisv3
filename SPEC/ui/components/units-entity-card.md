# UnitsEntityCard (component)

**SPEC/ui/components** — Expandable bordered gradient **card** for army / fleet rows inside [`UnitsPanelShell`](units-panel-shell.md) panels. Implementation: [`app/lib/features/game/widgets/units/shared/units_entity_card.dart`](../../../app/lib/features/game/widgets/units/shared/units_entity_card.dart). Catalog atoms: [`pixel-art-ui-catalog.md`](../pixel-art-ui-catalog.md) § *Editorial-monocle palette*.

This composite is **not** a screen and has **no** stable screen ID. Tracking issue: [#3514](https://github.com/waigore/colonizethisv3/issues/3514) (AC-6).

---

## Purpose

Renders an expandable entity row as the mockup `.unit-row` / `.fleet-row` card (`SPEC/ui/mockups/UNIT20001-military-units-panel.html`), replacing the bare Material `ExpansionTile` chrome with the editorial-monocle bordered gradient card while preserving the `ExpansionTile` expand/collapse semantics — including the `RotationTransition` expand affordance the e2e helpers detect.

---

## Widget contract

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `title` | `Widget` | required | Header content (the [`UnitsEntityActionRow`](units-entity-action-row.md) title/actions cluster, hosted with `chrome: false`). |
| `subtitle` | `Widget?` | `null` | Optional secondary line(s) below the title. |
| `children` | `List<Widget>` | required | Detail content revealed when expanded. |
| `initiallyExpanded` | `bool` | `false` | Initial expansion state. |

`UnitsEntityCard.collapsedGradient` exposes the static collapsed-body gradient so widget tests pin it without re-deriving the tokens.

---

## Layout / wireframe

```text
Padding(bottom: CtSpacing.xs)
  DecoratedBox(card decoration — collapsed/expanded below)
    Theme(dividerColor: transparent)
      ExpansionTile(transparent: backgroundColor/collapsedBackgroundColor = transparent,
                    shape/collapsedShape = Border(), tilePadding: 0)
        title / subtitle
        children -> DecoratedBox(top: 1 dp border) > Column(children)
```

---

## Behavior

1. **Collapsed chrome.** Card paints `UnitsEntityCard.collapsedGradient` (vertical `EditorialMonoclePalette.bgDeep` → `surface`) with a 1 dp `EditorialMonoclePalette.border` outline (mockup `.unit-row`).
2. **Expanded chrome.** On expansion the card switches to a flat `EditorialMonoclePalette.surface` fill with a 1 dp `EditorialMonoclePalette.accentDim` outline (mockup `.unit-row.expanded`).
3. **Detail divider.** Expanded children sit under a 1 dp `EditorialMonoclePalette.border` top divider (mockup `.u-comp-table` `border-top`).
4. **Transparent tile.** The inner `ExpansionTile` paints no Material divider, background fill, or shape border, so only the card chrome shows; the default trailing `RotationTransition` arrow is retained for e2e expansion detection.
5. **State.** `StatefulWidget` tracking expansion via `onExpansionChanged`; no other internal state.

---

## States and variants

| State | Card fill | Card border |
|-------|-----------|-------------|
| Collapsed | `collapsedGradient` (`bgDeep` → `surface`) | 1 dp `border` |
| Expanded | flat `surface` | 1 dp `accentDim` |

---

## Consumers

| Screen ID | Spec | Notes |
|-----------|------|-------|
| `UNIT20001` | [`military-units-panel.md`](../military-units-panel.md) | Army rows (issue #3514 AC-6). |
| `UNIT30001` | [`naval-units-panel.md`](../naval-units-panel.md) | Fleet rows (issue #3514 AC-6). The hosted [`UnitsEntityActionRow`](units-entity-action-row.md) keeps `dense: true` so Move / Split / Locate stay on one inline row (R25), collapsing to icon-only when the cluster's flex share drops below the label+icon footprint under the card chrome. |

---

## Tests

- `app/test/units_entity_card_test.dart` — collapsed/expanded chrome and the transparent `ExpansionTile`.
- `app/test/military_units_panel_part1_test.dart` — army rows mount no `CtNinePatchButton` chrome.
- `app/test/naval_units_panel_mockup_fidelity_test.dart` — fleet rows render one `UnitsEntityCard` each, host the dense action row chrome-less, and lay out without `RenderFlex` overflow (issue #3514 AC-6 naval migration).

---

## Related

- Sibling composites: [`units-entity-action-row.md`](units-entity-action-row.md), [`units-panel-shell.md`](units-panel-shell.md).
- Catalog: [`pixel-art-ui-catalog.md`](../pixel-art-ui-catalog.md) § *Editorial-monocle palette*.
