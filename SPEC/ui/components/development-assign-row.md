# Development assign row

**SPEC/ui/components** — Improvable commodity row on `GAME80001` (Assign preview, Show, disconnected warn). Screen: [development-panel.md](../development-panel.md). Costs: [extraction-and-improvements.md](../../game/extraction-and-improvements.md). Read model: [development-panel-read-model.md](../../program/development-panel-read-model.md). Refs #4472.

## Layout

```text
improvable_commodity_row
  Row: count_label | Show | Assign
  assign_preview_line (muted, wrap; only when Assign is enabled)
```

`assign_preview_line` is default-visible when Assign is enabled. Tooltip-only cost is not enough. On 320–360 dp the line wraps; **Show** / **Assign** stay tappable.

## Preview copy

Built from the cached `DevelopmentImproveAssignCandidate` (tile, connectivity, `currentImprovementLevel`, `materialCosts` from `previewWorkOrderAffordAtTile` after pending replay / feedstock waivers):

- Place: province display name plus player coordinates `(x, y)` — never a raw tile key, never `build_improvement`, never builder unit ids.
- Level: `{current} → {current+1}` (same improvement-level language as map `{n} of {cap}`, not `I{n}`).
- Cost: `formatWorkOrderMaterialCostSummary` when `materialCosts` is non-empty; omit the cost segment when waived to `{}`.
- Capital: append **not bound to the capital** when `isCapitalConnected == false`.
- Goods after work: append the shared next-yield gist (Refs #4627) when Assign is enabled.

Example: `Next: Avalon (0, 0) · 1 → 2 · Cast iron 4, Lumber 4` (commodity order from `formatWorkOrderMaterialCostSummary`).

Disabled Assign: existing plain refusal tooltip only (no Builder / insufficient materials / no valid tile). No spend-implying preview.

## Behavior

| Control | When enabled | Outcome |
|---------|--------------|---------|
| Show | Always on improvable rows | Highlights the commodity’s tile keys on the panel map (`secondaryHighlightTileKeys`). When a candidate exists, also sets `selectedTileKey` to that auto-pick so it is distinguishable. Preview line stays visible when Assign is enabled. Inbound Production/Counsel focus (Refs #4725) reuses this path with optional `highlightTileKey` as `selectedTileKey` and does not auto-tap Assign. |
| Assign (connected) | Candidate valid and affordable | One tap commits pending `build_improvement` (idle Builder by unit id; tile order connected → lower level → tile key). No extra confirm. |
| Assign (disconnected) | Same, `isCapitalConnected == false` | Opens warn dialog. Dialog may repeat the same preview line; it is not the only place those facts appear. |
| Improve anyway | Dialog | Commits pending `build_improvement` only. |
| Road first | Dialog; Engineer path legal | Commits pending `build_road` only. Disabled with plain reason otherwise. |
| Cancel | Dialog | No order. |

Auto-pick policy does not change. Do not auto-queue Road first. Do not nag idle Builders at Next turn (`DLG60001` UXD-001 / UXD-002 unchanged).

## Widgetbook

`Development Panel` → `Assign preview enabled` (and mobile): Land Enclosure, grain at level 1, enabled Assign showing `1 → 2` and lumber + cast iron 4. Next-yield gist variants (Refs #4627): **Assign preview — Build improvement next yield raise / road cap / town cap / disconnected**.

## Acceptance criteria

- Given an enabled Development **Assign** whose auto-pick is a capital-connected grain tile at improvement level 1 (next step costs 4 lumber + 4 cast iron), when the commodity row renders, then the UI layer shows a default-visible preview that names the place, `1 → 2`, and `Lumber 4, Cast iron 4` (or the shared cost-summary helper), and does not show a raw tile key or `build_improvement`.
- Given two improvable grain tiles and the documented priority policy, when the row renders, then the preview describes the same tile `selectDevelopmentImproveAssignCandidate` will commit.
- Given the player taps **Show** on that enabled row, when the panel map updates, then the auto-picked tile is the map `selectedTileKey` among the highlighted commodity tiles, and the preview line remains visible.
- Given the same tile would be a first improve with an active feedstock waiver that drops cast iron, when the row renders, then the preview matches `previewWorkOrderAffordAtTile` (lumber only or empty), not the full catalog pair.
- Given **Assign** is disabled for materials or no Builder, when the row renders, then the UI layer shows the existing plain refusal tooltip and does not show the enabled spend preview, and no order is committed.
- Given a disconnected auto-pick, when the row renders before tap, then the default preview states the tile is not bound to the capital; tapping **Assign** still opens Improve anyway / Road first / Cancel.
- Given an enabled Assign, when the preview line renders, then it appends the same next-yield gist as `MAP20001` Build improvement (raise / road limit / town limit / disconnected).
- Given a connected enabled **Assign**, when the player taps it, then the UI layer commits in one tap with no extra confirm dialog.
