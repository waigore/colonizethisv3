# Province Economic Extraction and Available

**SPEC/ui** — Condensed Extraction / Available lines on the province detail Economic section (MAP20001 overlay). Parent: [province-sea-zone-detail-overlay.md](province-sea-zone-detail-overlay.md). Projection: [province-extraction-snapshot.md](../program/province-extraction-snapshot.md). Multi-highlight: [map-widget.md](map-widget.md). Refs #4064.

**Scope:** Province Economic only (wide side panel + narrow bottom sheet share the overlay). Sea zones: no Extraction/Available.

## Layout

Under Economic full intel (including observe / omniscient), **above Town production**:

1. Heading `Extraction` (localized)
2. Condensed commodity line or muted `—`
3. Heading `Available` (localized)
4. Condensed commodity line or muted `—`
5. Existing Town production block (unchanged)

When Economic intel fails and not observe/omniscient: existing `???` body only — no Extraction/Available quantities.

Existing improved/improvable tile rows remain; these subsections are additive.

## Condensed line

- Segments in fixed `CommodityCatalog.all` order; comma-separated; wrap, never truncate/ellipsis.
- Each segment: resource icon + quantity text + localized commodity display name.
- Extraction full: `N Name`. Partial when province effective < full: `effective (full) Name`.
- Available: tile counts (`3 Grain`), not yields.
- Empty projection (no extractable contribution and no capital bonus) → heading + muted `—` (same token as Town production empty).
- When **any** commodity has `effective < full`, render **one** muted reason line immediately under the Extraction condensed line (plain language; localized ARB). Omit when all commodities are full-yield or Extraction is empty `—`.
- Live data text uses `EditorialMonoclePalette.fg`; empty `—` uses `muted`.

### Capital grain bonus indication

When `capitalGrainBonus > 0` on the projection, the UI **must** show a player-visible indication that those units are a **capital grain bonus** (special non-tile case), not farm-tile extraction. Required form:

- Grain quantity in the main Extraction line includes the bonus (full == effective for bonus units).
- A distinct muted annotation immediately after the grain segment uses localized copy such as `incl. +{N} capital grain bonus` (exact ARB key implementer-chosen).
- The annotation is **not** a hover-highlight target (bonus has no tile key). Tile grain hover still highlights contributing farm `tileKeys` only.

## Data binding

- **Extraction:** display-time **post-resolution projection** for `displayId` from current `Game` + tile maps + connectivity (see program SPEC). Unchanged by mid-turn draft orders. Refreshes when world state updates after turn resolution.
- **Available:** `provinceImprovableResourceTileCounts` on current post-resolution world state for the province owner.

## Map highlight

Hover (pointer enter) on a commodity segment sets multi-tile secondary highlight to that commodity’s related `tileKeys`; exit clears. Extraction uses projection tile keys; Available uses improvable tile keys. Capital grain bonus annotation alone has no highlight tile.

Map panel state exposes `secondaryHighlightTileKeys` (`Set`/`List`); the map draws the secondary outline on **each** key. Single-key-only highlight does not satisfy this contract.

## Widgetbook

Use case **Standalone — extraction & available** with partial-bracket fixture, capital-bonus annotation fixture, and multi-commodity wrap under Province Overlay folder.

## Acceptance criteria

- Given Economic full intel, when the section renders, then Extraction and Available headings appear above Town production and existing tile rows / Town production remain.
- Given intel gate fails and not observe/omniscient, when Economic renders, then the body is `???` with no Extraction/Available quantities.
- Given a new game after setup with bootstrap improved grain in the capital province, when Economic full intel is shown for that province, then Extraction shows projected grain quantities (not `—`).
- Given projection grain effective 1 full 5 and iron 5/5, when Extraction renders, then the line shows partial grain and full iron in catalog order with icons.
- Given any commodity has effective < full, when Extraction renders, then exactly one muted reason line appears under the Extraction condensed line.
- Given all commodities have effective == full (and Extraction is non-empty), when Extraction renders, then no reason line appears.
- Given capital grain bonus B > 0 included in grain totals, when Extraction renders, then the UI shows a muted capital-grain-bonus annotation distinct from tile extraction.
- Given capital grain bonus with tile grain keys, when the player hovers the grain segment then the bonus annotation, then map multi-highlight uses only farm tile keys for grain hover and does not invent tiles for the bonus annotation.
- Given zero extractable contribution and zero capital bonus, when Extraction renders, then heading + muted `—` and no reason line.
- Given Available counts for grain and timber, when Available renders, then counts show in catalog order with icons.
- Given a commodity segment with tile keys, when the pointer enters then exits that segment, then the map secondary-highlights all those keys then clears.
- Given many commodities on a narrow panel, when the line lays out, then segments wrap and none are ellipsized.
- Given Town production bonuses, when Economic renders, then Town production still shows icon + `+N` rows (or `—`) below the new subsections.
- Given the partial-bracket Extraction fixture and Available grain/timber counts under Economic full intel, when the System runs the province overlay Extraction/Available widget golden suite, then `matchesGoldenFile` baselines match committed PNGs under `app/test/goldens/`.
- Given Extraction grain with `capitalGrainBonus > 0` under Economic full intel, when the System runs the capital-bonus widget golden, then `matchesGoldenFile` shows the muted capital-grain-bonus annotation immediately after the grain segment.
