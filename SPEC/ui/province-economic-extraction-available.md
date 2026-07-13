# Province Economic Extraction and Available

**SPEC/ui** — Condensed Extraction / Available lines on the province detail Economic section (MAP20001 overlay). Parent: [province-sea-zone-detail-overlay.md](province-sea-zone-detail-overlay.md). Snapshot: [province-extraction-snapshot.md](../program/province-extraction-snapshot.md). Multi-highlight: [map-widget.md](map-widget.md).

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
- Empty / missing / ownership-gated snapshot → heading + muted `—` (same token as Town production empty).
- Live data text uses `EditorialMonoclePalette.fg`; empty `—` uses `muted`.

## Data binding

- **Extraction:** last-turn `ProvinceExtractionSnapshot` for `displayId`; unchanged by mid-turn draft orders.
- **Available:** `provinceImprovableResourceTileCounts` on current post-resolution world state for the province owner.

## Map highlight

Hover (pointer enter) on a commodity segment sets multi-tile secondary highlight to that commodity’s related `tileKeys`; exit clears. Extraction uses snapshot tile keys; Available uses improvable tile keys. Capital grain bonus alone has no highlight tile.

Map panel state exposes `secondaryHighlightTileKeys` (`Set`/`List`); the map draws the secondary outline on **each** key. Single-key-only highlight does not satisfy this contract.

## Widgetbook

Add use case **Standalone — extraction & available** with partial-bracket fixture and multi-commodity wrap under Province Overlay folder.

## Acceptance criteria

- Given Economic full intel, when the section renders, then Extraction and Available headings appear above Town production and existing tile rows / Town production remain.
- Given intel gate fails and not observe/omniscient, when Economic renders, then the body is `???` with no Extraction/Available quantities.
- Given snapshot grain effective 1 full 5 and iron 5/5, when Extraction renders, then the line shows partial grain and full iron in catalog order with icons.
- Given empty or ownership-mismatched snapshot, when Extraction renders, then heading + muted `—`.
- Given Available counts for grain and timber, when Available renders, then counts show in catalog order with icons.
- Given a commodity segment with tile keys, when the pointer enters then exits that segment, then the map secondary-highlights all those keys then clears.
- Given many commodities on a narrow panel, when the line lays out, then segments wrap and none are ellipsized.
- Given Town production bonuses, when Economic renders, then Town production still shows icon + `+N` rows (or `—`) below the new subsections.
