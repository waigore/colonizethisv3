# Empire Overview (in-game shell)

**Screen ID:** `MAP10001` — stable; do not reassign.
**SPEC/ui** — In-game map shell (region tabs, map widget, HUD). Implementation: `app/lib/features/game/flame/map_state/game_map_area.dart`.
**Widgetbook:** `Map Widget` → `app/lib/widgetbook/catalog.dart`. Host orchestration: [`game-screen.md`](game-screen.md).

**Mockup:** [mockups/MAP10001-empire-overview.html](mockups/MAP10001-empire-overview.html)
---

## Widget contract

`GameMapArea` hosts region tabs, `CtRegionMap` / map stack, sidebars, and panel slots. Province selection drives [`province-sea-zone-detail-overlay.md`](province-sea-zone-detail-overlay.md) via `mapProvincePanelProvider`.

---

## Trigger conditions

- **Entry:** After game init success or load into play ([`game-screen.md`](game-screen.md) mounts `GameMapArea` when `mapViewDataProvider != null`).

---

## Purpose

- **Entry:** Reached from Game Initializing screen on success (or from Load Game when loading a save into play).
- **Role:** In-game shell. Map-centric view with region tabs; HUD/sidebar and panels (units, development, production, etc.) are defined by separate specs or later. This spec focuses on the map area and region switching.
- **Map:** Each region has its own map view. The reusable [map-widget](map-widget.md) is used for each; viewport is the widget size; pan, fixed zoom levels, smooth zoom; base layer (terrain, optional resource icons and improvement/road labels, towns, capitals) plus togglable political overlay; tap/click selects province and triggers a callback. Province details (what to show and where) are to be defined; the map widget only reports selection.

---

## Region tabs

- **Tabs:** One tab per region (e.g. "Old World", "New World"). Selecting a tab shows that region's map in the map area.
- **Desktop:** Tab bar visible; map widget fills the map area for the active region. Layout may include sidebar and HUD (separate spec).
- **Mobile:** One region per map. Same tab system: user switches regions via tabs. Each tab shows the full map widget for that region; no side-by-side regions on small screens. See [mobile-adaptation.md](mobile-adaptation.md) for touch targets and layout.
- **Treasury indicator:** In the same control row as the region tabs, the UI shows a treasury indicator between the `New World` tab and the cargo hold indicator. The indicator renders a dedicated coin icon (`ui_icon_treasury_coin.png`), the human player's current `Player.treasury` value (fallback first player if no `isHuman`), and an optional projected delta suffix.
- **Treasury formatting modes:** The treasury numeric text has two deterministic display modes: **exact** (`12,345`, `-1,000`) and **abbreviated** (`12.3k`, `-1.0k`). Exact mode uses thousands separators and no currency symbol. Abbreviated mode uses compact decimal formatting and no currency symbol. Tapping/clicking the treasury indicator toggles modes.
- **Treasury projected delta:** The delta uses unresolved-order projection semantics from [order-projections.md](../program/order-projections.md) (`projectOrderEffects(...).treasuryDelta`) for the same human-player identity rule. Delta text is shown as `+N` for positive and `-N` for negative, hidden when zero or unavailable. Delta color is green when positive and red when negative.
- **Cargo hold indicator:** In the same control row as the region tabs, the UI shows a **player-initiated** cargo hold indicator with a crate icon and a numeric value in the exact format `used/capacity` (no spaces). `capacity` is the total cargo holds from all ships in the human player's Home Fleet (`cargoHoldsForHomeFleet`), and `used` is the total overseas resources extracted for that player in the current world state (sum of `computeExtraction(...).overseas` values for the player). The indicator is global (single total, not per-region) and remains visible when switching region tabs.
- **Cargo hold colour tiers:** When `capacity > 0` and overseas used is reliable, only the numeric `used/capacity` text (not the crate icon) resolves colour: **normal** (`used < ceil(0.8 × capacity)`) → `--muted`; **tight** (`used ≥ ceil(0.8 × capacity)` and `used < capacity`) → `--accent`; **full / over** (`used ≥ capacity`) → `--danger`. When `capacity == 0`, cargo used is unreliable, or observe mode marks cargo not-defined, numeric text stays `--muted`.
- **Cargo hold teaching surface:** Tapping/clicking the indicator opens a small dismissible floating panel (not a full-screen dialog) anchored below the indicator. The panel lists overseas extraction **N**, Home Fleet holds **C**, free for trade bids `max(0, C − N)`, and one fixed counsel line (`mapControls_cargoHold_details_counsel`). Dismiss via ×, outside tap on the map scrim, or Esc. Reopen on the next tap. No auto-open on load, turn end, or cargo pressure; no persistent “don’t show again” preference; no deep-link buttons. Desktop hover shows `mapControls_cargoHold_tooltip`; semantics use `mapControls_cargoHold_semanticsLabel`.
- **Update contract:** The cargo hold indicator updates when cargo-relevant game state changes (for example, fleet composition changes or extraction-relevant state changes) through the app's event bus/provider wiring; no animation is applied beyond colour-tier transitions on rebuild.

### Tab bar chrome (dark editorial-monocle)

Implementation: [`GameTabBar`](../../app/lib/features/game/widgets/shell/game_tab_bar.dart) hosted by [`GameMapControls`](../../app/lib/features/game/flame/controls/game_map_controls.dart) directly under [`GameTopBar`](../../app/lib/features/game/widgets/shell/game_top_bar.dart). Mockup: [GAME10001-game-screen.html](mockups/GAME10001-game-screen.html) (`.tabbar`, `.region-tab`, `.treasury`, `.cargo-hold`).

- **Height:** Fixed **34 dp** (`GameTabBar.height`).
- **Chrome:** `--surface` fill with a **1 px** `--border` bottom edge (no gradient on the bar itself).
- **Region tabs:** Inactive tabs paint a vertical `--bg-deep` → `--surface` gradient with a **1 px** `--border` outline on the top/left/right edges; label colour `--muted`. Active tab paints `--bg` fill, `--accent-dim` top/left/right borders, and a **2 px** `--accent` bottom border; label colour `--accent`.
- **Treasury:** Coin icon (`ui_icon_treasury_coin.png`, 18×18 dp) + monospace value in `--accent-dim`; optional projected delta in `--success` (positive) or `--danger` (negative) at 10 sp. Tapping toggles exact/abbreviated formatting (unchanged behaviour).
- **Cargo:** Crate icon (18×18 dp) + monospace `used/capacity`; numeric text colour follows the tight/full tier rules above (crate icon stays default). Separated from treasury by a **1 px** `--border` left rule. Tap opens the cargo details popover; desktop hover shows the tooltip string.
- **News toggle:** Trailing slot on the tab bar row (see [player-turn-event-feed.md](player-turn-event-feed.md)); not restyled in this slice.

---

## Map area

- **Background chrome:** The map stack paints a non-interactive backdrop behind [CtRegionMap](../../app/lib/widgets/ct_region_map.dart) via [GameMapAreaBackground](../../app/lib/features/game/flame/map_area/game_map_area_background.dart). The surface fills with `--bg-deep`, adds two low-opacity radial washes (mockup `.map-area` ellipses), and overlays a **48 dp** square grid at **60%** opacity with lines tinted from `--border` at **8%** alpha (mockup `.map-grid`). No hard-coded light-theme hex literals; the grid must not intercept pointer events.
- **Content:** One instance of the map widget per active view. When the user switches tabs, the map widget is updated or swapped to show the selected region's map.
- **Layers:** Base tile layer always; **province overlay** (province/sea boundary strokes), **province ownership** (Great Power land tint), and **political** overlay togglable by the user where the shell exposes them (see Map display options). **Base layer display mode** and related map tools sit in a **horizontal icon row** at the **bottom-left** of the map (see below). **Empire actions** (Production, units, Diplomacy, Technology) use an **always-visible icon column** along the **left** of the map (east of the edge-swipe strip); see [empire-buttons.md](empire-buttons.md).
- **Interaction:** Pan, zoom (fit-relative continuous band per [map-widget.md](map-widget.md) § Viewport, scale, pan, zoom), tap/click for province selection. Human **army stack markers** on town tiles start Move (field armies) or open `UNIT20001` (Home Army only) without opening `MAP20001` — see [map-widget.md](map-widget.md) § Human army markers. Map widget fires `onProvinceSelected`; the Empire overview screen responds (e.g. show province details in a panel or bottom sheet; content TBD).
- **Data:** Region map data from game state / view model (PlayerView or equivalent for human player). Province identity: prefixed id per [world-model-identity.md](../game/world-model-identity.md).

### Base layer display cycle (in-game map only)

- **Overlay:** A single toggle button is overlaid at the **bottom-left** of the map area as the **leftmost** control in a **horizontal row** of three map tool buttons. **Inset** from the map stack’s **left** and **bottom** edges is the **same** value (matches the inset previously used for the left edge of the top-left cluster: **0** unless implementation introduces a shared padding constant). Icon only: pixel-art stacked layers icon (`ui_icon_layer_toggle.png` from [game-toolbar-icons.md](game-toolbar-icons.md)). The button is a **shortcut** through four persisted information-layer presets; it is shown only on the in-game Empire overview map, not in Widgetbook or debug map stories.
- **Flags (source of truth):** `MapViewState.showMapResources`, `showMapImprovements`, and `showMapRoads` (defaults all **ON**). Paint uses these flags; the exclusive `BaseLayerDisplayMode` enum is a Widgetbook convenience only (see [map-widget.md](map-widget.md) § Base layer display mode).
- **Presets the cycle writes (order, wrap 4 → 1):** 1) terrain only (all off); 2) resources on, improvements off, roads off; 3) resources on, improvements on, roads off; 4) all three on. If the current flags match none of those four (dialog-only combinations), the next tap writes **terrain only**.
- **Tooltip/semantics:** name the **current** combination in player words (e.g. “Map marks: terrain only” / “resources” / “resources and improvements” / “resources, improvements, and roads” / “improvements” / “improvements and roads”).
- **Default at game start / load:** persisted flags drive paint immediately. Missing fields load as all-on (full detail).
- **Spec reference:** [map-widget.md](map-widget.md) § Base layer display mode.

### Initial map viewport (shell entry)

When the in-game map mounts (every entry path: new game after init, load save into play, resume from main menu), the shell performs a **one-shot auto-center** on the **current player's** capital so the player starts looking at their own territory rather than the map geometric center.

- **Current player resolution:** Uses `ShellPlayerContext.mapPlayerIdFor(game)` semantics (`viewingPlayerId`). The auto-center is **skipped** entirely when there is no viewing player (`viewingPlayerId == null`, i.e. **global observe**).
- **Effect when the current player has a `capitalTile`:** the shell (1) switches the active region tab to the capital's region (`oldWorld` → index `0`, `newWorld` → index `1`), (2) centers the camera on the capital tile using the same mechanism as the home-to-capital button (`CtRegionMap.centerOnTileKey`), and (3) places the **secondary highlight** on the capital tile. It does **not** open the province/sea detail overlay and does **not** change zoom (the existing entry zoom contract applies: `m = 4.0` for new campaigns, persisted value on load).
- **No capital:** when the current player has no `capitalTile`, the shell skips auto-centering and leaves the default region tab (`0`) and default clamped camera.
- **Timing:** auto-center runs on map mount even when `GameStartIntroOverlay` is visible above the map (it is not deferred to intro dismissal). Centering is scheduled after the first frame so the map size is known (same post-frame pattern as `centerOnTileKey`).
- **One-shot:** the auto-center fires once per game per `GameMapArea` mount. On save load the target is always the save's **current** `capitalTile` (capital reassignment mid-campaign is honored); restoring the last camera pan / region tab is **out of scope** (not persisted in `MapViewState`).

### Home-to-capital button (in-game map only)

- **Overlay:** A second button in the **same horizontal row** at the **bottom-left**, **immediately to the right** of the base-layer cycle button (small fixed gap between icons). Icon only: pixel-art home/flag icon (`ui_icon_home_capital.png` from [game-toolbar-icons.md](game-toolbar-icons.md)). The button is shown only on the in-game Empire overview map, not in Widgetbook or debug map stories.
- **Target:** Always uses the **current player** — the shell viewing context resolved by `ShellPlayerContext.mapPlayerIdFor(game)` (`viewingPlayerId` when set, else `effectiveHumanPlayerId`, else the first player). In **player observe** (`ObserveMode.player`) this is the observed `viewingPlayerId`; in **normal play** it is the human player. This is **not** `debugCommandTargetPlayerId` / `lastControlledPlayerId` (which can point at the prior controller in observe).
- **Enablement (observe carve-out):** The button is **enabled** when `ShellPlayerContext.viewingPlayerId != null` (normal play and player observe) and **disabled** when `viewingPlayerId == null` (**global observe**, `ObserveMode.global`). See [observe-mode.md](observe-mode.md).
- **Behavior:** When tapped, the button **switches the active region** (Old World / New World) if necessary so that the map shows the current player's **capital region**, then **centers the camera** on the current player's **capital tile** and moves the **selection/highlight cursor** onto that tile. Capital identity comes from `Player.capitalTile` (tile key format `regionId|provinceId|x|y` per [world-model-identity.md](../game/world-model-identity.md) and [map-visualization.md](../program/map-visualization.md)). If the current player has no `capitalTile`, the button is a no-op.

### Map display options button and dialog (in-game map only)

- **Overlay:** A third button in the **same horizontal row** at the **bottom-left**, **immediately to the right** of the home-to-capital button. Icon only: pixel-art gear icon (`ui_icon_map_options.png` from [game-toolbar-icons.md](game-toolbar-icons.md)). The button is shown only on the in-game Empire overview map, not in Widgetbook or debug map stories.
- **Dialog type:** Tapping the button opens a modal **“Map display options”** dialog that blocks interaction with the underlying map and closes when the user taps the dialog’s **Close** button, taps outside the dialog, or presses the back key. The dialog renders inside a `CtDialogShell` (default 2px `--accent-dim` border, `surface-lite → surface → bg-deep` panel gradient) over the canonical dialog scrim (`oklch(8% 0.01 30 / 0.7)`); the **Close** button is a `CtNinePatchButton`. No Material `AlertDialog`, `Dialog`, `SwitchListTile`, or `TextButton` chrome paints the dialog (catalog ban per [pixel-art-ui-catalog.md](pixel-art-ui-catalog.md) § Material design ban). Implementation: `app/lib/features/game/widgets/dialogs/game_map_options_dialog.dart` (`GameMapOptionsDialog`).
- **Toggles:** The dialog contains a **Map marks** heading with three information-layer `CtToggleSwitch` rows — **Show resources**, **Show improvements**, **Show roads and rails** — then four cartographic rows: **Show province and sea borders** (province and sea-zone boundary strokes; formerly “Show province overlay”), **Show province ownership** (Great Power land ownership tint at fixed alpha **0.5** per [map-widget.md](map-widget.md)), **Show province names**, and **Highlight land not bound to the capital** (diagonal hatch on viewing-player owned land tiles that are not capital-connected; Refs #4370). Each controls its own global layer for all in-game Empire overview maps (Old World and New World). **Roads require improvements:** when **Show improvements** is off, **Show roads and rails** is off and disabled (`CtToggleSwitch.onChanged == null`); turning improvements off auto-offs roads; turning improvements on leaves roads off until the player or the cycle turns them on. Resources are never auto-changed by the improvements/roads pair.
- **Default behavior:** For saves with no prior persisted map view state, **Show resources**, **Show improvements**, **Show roads and rails**, **Show province and sea borders**, **Show province names**, and **Highlight land not bound to the capital** default to **ON**, and **Show province ownership** defaults to **OFF**. When the user changes any toggle, the new values are reflected immediately in the dialog affordance and persisted in savegame map view state (`MapViewState.showCapitalLinkDisconnectedHighlight`; missing JSON field defaults **ON**).
- **Effect on rendering:** When **Show province and sea borders** is ON, the map widget draws province and sea-zone boundary strokes per [map-widget.md](map-widget.md). When OFF, those strokes are not drawn. When **Show province ownership** is ON, the map draws the Great Power land tint per [map-widget.md](map-widget.md) § Province ownership (GP tint). When OFF, no GP tint is drawn. When **Highlight land not bound to the capital** is ON and `ShellPlayerContext.panelPlayerId != null`, the map draws the capital-link disconnected hatch per [map-widget.md](map-widget.md) § Capital-link disconnected land highlight. When OFF, or in **global observe** (`panelPlayerId == null`), no hatch is drawn. Hover selectors, hover province glows, capitals, ports, warp zone indicators, and (per the province-names toggle) labels remain according to their own toggles. When **Show province names** is ON, land province labels are drawn per [map-widget.md](map-widget.md) § Layer model (province names row). When OFF, no province name labels are drawn. Resource icons and extraction discs follow **Show resources**; `I{n}` labels follow **Show improvements**; road/rail sprites follow **Show roads and rails** and **Show improvements** (both required).

### Corner controls chrome (dark editorial-monocle)

- **Container:** [GameMapCornerControls](../../app/lib/features/game/flame/controls/game_map_corner_controls.dart) renders the three map tool buttons (base-layer cycle, home-to-capital, map display options) in a horizontal row at the bottom-left of the map `Stack`. The row uses a horizontal gap of **3 dp** between adjacent buttons (`.corner-controls gap: 3px` in [`SPEC/ui/mockups/GAME10001-game-screen.html`](mockups/GAME10001-game-screen.html)).
- **Per-button surface:** Each button is a **32 × 32 dp** tap target whose decoration paints `CtGradients.railButtonGradient` (vertical `--surface-lite` → `--bg-deep` per [`pixel-art-ui-catalog.md`](pixel-art-ui-catalog.md) § Editorial-monocle palette) with a 1 px `--border` outline. The same gradient backs [GameMapEmpireLeftRail](../../app/lib/features/game/flame/controls/game_map_empire_left_rail.dart) so left rail and corner controls form a single visual family.
- **Glyph:** A centered **22 × 22 dp** [`StrictAssetIcon`](../../app/lib/widgets/strict_asset_icon.dart) rendered in native full-colour pixel art (`image-rendering: pixelated` via the asset widget). The glyph must **not** be wrapped in a `ColorFiltered` / `ColorFilter.mode(..., BlendMode.srcIn)` tint that collapses the multi-colour asset to a single accent colour (mockup `.corner-btn img` has no colour filter); the icon colours are unchanged across interaction states.
- **Hover and pressed states:** Border outline shifts to `--accent-dim` when the pointer is over the button or while the button is held (`.corner-btn:hover { border-color: var(--accent-dim); }` in the mockup; pressed mirrors hover because the mockup CSS does not define a separate pressed state). The full-colour glyph is **not** recoloured in any state. Transitions animate over **120 ms** (`Curves.easeOut`) to match `GameMapEmpireLeftRail`.
- **Disabled state:** When the underlying callback is `null` (e.g. `homeToCapitalEnabled == false`) the button wraps its tooltip + surface in `IgnorePointer` + `Opacity(0.4)` — the canonical disabled-control opacity shared with `CtNinePatchButton`, `CtBackButton`, `CtToggleSwitch`, and `CtProgressBar`. The border outline freezes on the default-state color and the glyph renders in its native full colour (no hover/press color resolution, no `srcIn` tint).
- **Material ban:** The legacy `Material(color: Colors.white …)` overlay around the corner-button row is removed; no white-tinted Material surfaces, raw Material `ElevatedButton`/`IconButton` chrome, or hard-coded light-theme hex literals may paint inside the row. Pointer plumbing remains an `InkWell` under a transparent `Material` (catalog-compatible per [`SPEC/ui/pixel-art-ui-catalog.md`](pixel-art-ui-catalog.md) § Material design ban — `InkWell` itself is not banned, only Material chrome backgrounds).

#### Narrow corner-control measurements (`< kNarrowBreakpoint`)

When the in-game map renders on a narrow viewport (`MediaQuery.size.width < kNarrowBreakpoint`, `600 dp`), the host constructs [GameMapCornerControls](../../app/lib/features/game/flame/controls/game_map_corner_controls.dart) with `narrow: true`. The row then renders at the narrow measurements defined in [mobile-adaptation.md](mobile-adaptation.md) § In-game shell, normative for issue #2870 S3:

- **Tap target:** **24 × 24 dp** per button (mockup `.corner-btn @media (max-width:600px) { width:24px; height:24px }`).
- **Horizontal gap:** **2 dp** between consecutive buttons (tightened from the wide `3 dp` value to match the compressed `.corner-controls @media (max-width:600px) { left:2px; bottom:2px }` chrome).
- **Glyph:** Unchanged at **22 × 22 dp** (mockup keeps `.corner-btn img { 22 × 22 }` at narrow); the visible padding around the glyph compresses to 1 dp per side.
- **Chrome tokens:** Unchanged — narrow buttons keep the wide gradient/border/full-colour icon and hover/press contracts above.

### Extraction disc legend (in-game map only)

Compact teaching chrome for gold vs brown **extraction discs** (Refs #4367; disc paint contract in [map-widget.md](map-widget.md) § Per-tile extraction throughput indicators).

- **Placement:** Above the bottom-left [GameMapCornerControls](../../app/lib/features/game/flame/controls/game_map_corner_controls.dart) row in the map `Stack` ([ExtractionDiscLegend](../../app/lib/features/game/flame/controls/extraction_disc_legend.dart)). Does not replace the three 24×24 / 32×32 corner tools.
- **Visibility:** Shown when `baseLayerDisplayMode != terrainOnly` **and** `ShellPlayerContext.viewingPlayerId != null` (normal play and player observe), **including when zero discs are painted**. Hidden in **terrain only** and **global observe** (`viewingPlayerId == null`). Visibility does **not** depend on disc count.
- **Wide:** Two swatches (gold `0xFFFFD700` / brown `0xFF5C4033` with dark stroke matching disc paint) plus plain labels (“Reaches capital” / “Blocked — will not extract”).
- **Narrow (`< kNarrowBreakpoint`):** Collapses to a tappable two-disc chip; popover stacks above the bottom province sheet when open.
- **Tap:** Opens a dismissible floating panel (cargo-hold family: ×, outside tap, Esc) restating both meanings plus one counsel line about restoring roads/towns/ports toward the capital. No orders staged; no new screen ID (extends `MAP10001`).

### Improvement headroom legend (in-game map only)

Compact teaching chrome for `{n} of {cap}` improvement marks (Refs #4408; paint contract in [map-widget.md](map-widget.md) § Improvement headroom). No new screen ID.

- **Placement:** Above the extraction-disc legend (when present) and the bottom-left [GameMapCornerControls](../../app/lib/features/game/flame/controls/game_map_corner_controls.dart) row ([ImprovementHeadroomLegend](../../app/lib/features/game/flame/controls/improvement_headroom_legend.dart)). Must not cover Next turn.
- **Visibility:** Shown when **Show improvements** is on **and** `ShellPlayerContext.viewingPlayerId != null`. Hidden when improvements are off and in **global observe**. Independent of resource icons. `#4388` flags stay “improvements on/off”.
- **Wide:** Sample muted `1 of 1` plus “at this court’s limit”; sample accented `1 of 2` plus “can still raise”.
- **Narrow (`< kNarrowBreakpoint`):** Collapses to a tappable `{n} of {cap}` chip.
- **Tap:** Opens a dismissible floating panel (extraction-legend family: ×, outside tap, Esc) restating that `{n} of {cap}` is improvement level versus what this court can extract now, and that muted means at the current limit.

### Tile owner / sight hover readout (in-game map only)

Compact MAP10001 teaching chrome (Refs #4406). No new screen ID; does not default-on GP tint (`#1521`) or the players bar (`#3986`); not a second always-visible legend beside extraction discs.

- **Placement:** Top-start of the map canvas stack ([MapTileHoverReadout](../../app/lib/features/game/flame/controls/map_tile_hover_readout.dart)), `IgnorePointer` so it does not steal map hover. Cargo-hold / extraction-legend family: `--surface` at alpha 0.92, 1 px `--border`, `CtSpacing.m` padding, max width 260 dp (clamped to viewport − 16 dp).
- **Visibility:** Shown while `onTileHovered` reports a tile key and work-target selection is **off**. Hidden on pointer leave and while work-target selection is active.
- **Copy:** Place + Owner (or Sea zone identity) + Sight phrases from [map-widget.md](map-widget.md) § Hover; warp water adds one passage line. Owner uses `ownerNameForProvinceOverlay`.

### Tile context radial (in-game map only)

Right-click or long-press a tile (after army / fleet / civilian markers miss) opens `MAP30001` for overlay Tile shortcuts (Explore, Prospect, Build improvement) plus More. Primary tap still opens `MAP20001`. Details: [tile-context-radial.md](tile-context-radial.md), [tile-more-actions-dialog.md](tile-more-actions-dialog.md).

**Acceptance (narrow corner controls):**

- **Given** the in-game map is rendered on the narrow layout (`MediaQuery.size.width < kNarrowBreakpoint`), **when** `GameMapCornerControls` is constructed with `narrow: true` and lays out the three corner buttons, **then** every visible corner button paints a **24 × 24 dp** square surface.
- **Given** the narrow corner controls are rendered, **when** the layout resolves the row, **then** consecutive corner buttons have a **2 dp** horizontal gap between them.
- **Given** the narrow corner controls are rendered, **when** the chrome painter resolves a corner button's glyph, **then** the glyph paints `StrictAssetIcon` at exactly **22 × 22 dp** (icon size is unchanged from the wide layout).

### Region minimap (in-game map stack)

- **Placement:** Bottom-right of the map `Stack` in [GameMapArea](../../app/lib/features/game/flame/map_state/game_map_area.dart); does not replace bottom-left [GameMapCornerControls](../../app/lib/features/game/flame/controls/game_map_corner_controls.dart) or [GameMapEmpireLeftRail](../../app/lib/features/game/flame/controls/game_map_empire_left_rail.dart).
- **Wide shell + province panel:** When the viewport is **not** narrow (side panel layout) and the province detail panel is **open** (`mapProvincePanelProvider.overlayOpen`), the minimap stack’s **horizontal inset from the right** increases by the **province panel width (320 dp)** so the minimap and its zoom slider stay **above** the panel column and remain usable. When the panel is closed, use the normal corner inset only.

### Narrow layout: province detail above map chrome

- **Z-order:** On narrow viewports, the province/sea zone detail host ([GameMapNarrowDetailOverlaySlot](../../app/lib/features/game/flame/overlays/game_map_narrow_detail_overlay.dart)) is a **sibling stacked above** the map `Stack` so the bottom detail **paints above** bottom-left map tool buttons and may **partially overlap** them; the detail layer receives hit testing above those buttons when visible.
- **Widget:** [GameRegionMinimap](../../app/lib/features/game/flame/minimap/game_region_minimap.dart) — full active region grid (flat terrain colors), visibility per `CellViewData.visibility` (unrevealed = black; fogged = same terrain hue at alpha **0.55**; visible = full opacity). Sea uses deep blue `#0D47A1`; land terrains: plains `#A5D6A7`, forest `#2E7D32`, hills `#B0BEC5`, mountain `#546E7A`, swamp `#6D4C41`, desert `#D7CCC8`.
- **Viewport:** White stroke rectangle aligned with main map camera (world center, zoom, logical viewport size, `cellSizePx`); see [map-widget.md](map-widget.md) § Region minimap camera sync.
- **Interaction:** **Tap-up** sets main map camera center to world position under the pointer (clamped), so a press-and-drag does not first jump the camera to the press point. **Pointer movement while down** applies world-space pan to camera center (clamped). Does not change tile/province selection.
- **Zoom slider:** Bottom row of the minimap stack: a **horizontal slider** sits **immediately left of** the minimap toggle. The **left edge of the slider track** aligns with the **left edge** of the minimap `CustomPaint` (same width reference as `mapSize.width`). The control is semantic-labelled **Map zoom**; the thumb/track meet [mobile-adaptation.md](mobile-adaptation.md) touch guidance (≥ 44 dp smallest interactive dimension where applicable). **Displayed scale:** **50%–800%** where **100% = fit the full region map** (`m = 1` vs `z_fit` per [map-widget.md](map-widget.md)). Dragging updates the main map **continuously** (not only on drag end). The fit-relative zoom multiplier is global across region tabs, clamped per active region map bounds, and persisted in savegame map view state.
- **Toggle:** Icon-only `ui_icon_region_minimap.png` ([game-toolbar-icons.md](game-toolbar-icons.md)), same padding/hit target pattern as corner controls. **Default ON** when entering the shell; show/hide is **session-only** (Riverpod `regionMinimapVisibleProvider`).
- **Coordination:** Minimap → map uses typed **`RequestRegionMapCameraCenterWorldEvent`**, **`RequestRegionMapCameraPanWorldDeltaEvent`**, and **`RequestRegionMapSetZoomMultiplierEvent`** on `AppEventBus` ([app-event-bus.md](../program/app-event-bus.md)). Map → shell pushes `RegionMapViewportSnapshot` via `CtRegionMap.onViewportSnapshotChanged` (shell coalesces updates per frame; not cross-panel callbacks). Narrow layout: overlap with bottom detail is acceptable.

**Acceptance (minimap):** Given the in-game shell map is visible, when the minimap toggle is on, then the UI shows the active region grid with visibility rules above and a white viewport indicator when the main map has published a matching snapshot. When the user taps the toggle, then the minimap hides or shows for the session only (default on at shell entry). When the user drags on the minimap or the bus emits a pan event for that region, then the main map host remains without exceptions. When the side menu is open, then the minimap stack order keeps it interactive above the scrim.

#### Narrow minimap measurements (`< kNarrowBreakpoint`)

When the in-game map renders on a narrow viewport (`MediaQuery.size.width < kNarrowBreakpoint`, `600 dp`), the host constructs [GameRegionMinimap](../../app/lib/features/game/flame/minimap/game_region_minimap.dart) with `narrow: true`. The active region grid then fits its aspect ratio into the narrow bounding box defined in [mobile-adaptation.md](mobile-adaptation.md) § In-game shell, normative for issue #2870 S3:

- **Bounding box:** **90 × 70 dp** (mockup `.minimap-panel @media (max-width:600px) { width:90px; height:70px }`).
- **Aspect-preserving fit:** Given `aspect = region.width / region.height` and `boxAspect = 90 / 70`, the grid renders at `(90, 90 / aspect)` when `aspect >= boxAspect` (width-limited) and `(70 * aspect, 70)` otherwise (height-limited). The longer side never exceeds `90 dp` and the shorter side never exceeds `70 dp`.
- **Chrome unchanged:** Panel padding (`panelPadding = 2`), 1 px `--border` outline, toggle button (`32 × 32 dp`), zoom slider, and viewport indicator stroke all keep their wide-layout values. Only the inner grid `mapSize` adapts.

**Acceptance (narrow minimap):**

- **Given** the in-game map is rendered on the narrow layout (`MediaQuery.size.width < kNarrowBreakpoint`) and the minimap toggle is on, **when** `GameRegionMinimap` is constructed with `narrow: true`, **then** the inner `CustomPaint` grid lays out at a `Size` whose width is at most `GameRegionMinimap.narrowMaxWidth` (`90 dp`) and whose height is at most `GameRegionMinimap.narrowMaxHeight` (`70 dp`).
- **Given** the active region has aspect ratio `>= 90 / 70`, **when** the narrow minimap renders, **then** the grid width equals `GameRegionMinimap.narrowMaxWidth` and the grid height equals `GameRegionMinimap.narrowMaxWidth / aspect` (width-limited fit).
- **Given** the active region has aspect ratio `< 90 / 70`, **when** the narrow minimap renders, **then** the grid height equals `GameRegionMinimap.narrowMaxHeight` and the grid width equals `GameRegionMinimap.narrowMaxHeight * aspect` (height-limited fit).
- **Given** the host omits the `narrow` flag (default `false`), **when** the wide minimap renders, **then** the inner grid keeps the pre-#2870 baseline: longer side capped at `GameRegionMinimap.defaultMaxExtent` (`132 dp`), shorter side scaled by aspect (regression guard).

### Region minimap chrome (dark editorial-monocle)

- **Panel surface:** When the minimap is visible, the region grid sits inside a flat panel surface that paints `--bg-deep` fill with a 1 px `--border` outline and 2 dp internal padding around the grid. The mockup `.minimap-panel` (`SPEC/ui/mockups/GAME10001-game-screen.html`) is the visual source of truth; no `Material` overlay paints with `Colors.black`, `Colors.white`, or any other hard-coded light-theme background under the panel. The legacy elevation drop shadow is removed (the dark panel reads against the map without a Material shadow).
- **Toggle button:** The minimap show/hide toggle (key `region_minimap_toggle`, asset `ui_icon_region_minimap.png`) paints a 32 × 32 dp tap target whose decoration is a flat `--bg-deep` fill with a 1 px `--border` outline (matches mockup `.minimap-toggle`). The centered glyph is a 20 × 20 dp [`StrictAssetIcon`](../../app/lib/widgets/strict_asset_icon.dart) tinted via `ColorFiltered(BlendMode.srcIn)` to `--accent-dim` in the default state. On hover or press the outline shifts to `--accent-dim` and the glyph tint shifts to `--accent-bright`, animated over **120 ms** (`Curves.easeOut`) to match [GameMapCornerControls](../../app/lib/features/game/flame/controls/game_map_corner_controls.dart). No `Material(color: Colors.white …)` background, raw `IconButton`/`ElevatedButton` chrome, or hard-coded light-theme hex literal may paint under the toggle (catalog ban per [pixel-art-ui-catalog.md](pixel-art-ui-catalog.md) § Material design ban).
- **Viewport indicator:** Remains a white 1.5 px stroke aligned with the main map camera (preserved from the existing minimap contract); the dark chrome here does not change the indicator colour.
- **Zoom slider chrome:** Continues to use [`CtSlider`](../../app/lib/widgets/ct_slider.dart) and the dark-theme label tokens; no new chrome introduced in this slice.

**Acceptance (minimap chrome):**

- **Given** the in-game shell map is visible and the minimap is in its visible state, **when** the [GameRegionMinimap](../../app/lib/features/game/flame/minimap/game_region_minimap.dart) widget tree is inspected, **then** the panel surface around the minimap `CustomPaint` resolves a `DecoratedBox` whose `BoxDecoration.color` equals `EditorialMonoclePalette.bgDeep` and whose `border.top.color` equals `EditorialMonoclePalette.border` (a 1 px outline on all four sides), and no ancestor `Material` widget inside `GameRegionMinimap` paints with `Colors.white` or `Colors.black`.
- **Given** the in-game shell map is visible, **when** the minimap toggle (key `region_minimap_toggle`) is rendered in its default (unhovered, unpressed) state, **then** its decoration resolves a `BoxDecoration.color == EditorialMonoclePalette.bgDeep` with a 1 px `EditorialMonoclePalette.border` outline and the centered glyph paints under a `ColorFiltered(BlendMode.srcIn)` resolved to `EditorialMonoclePalette.accentDim`.
- **Given** the in-game shell map is visible and the minimap toggle is in its default state, **when** the user moves the pointer over the toggle, **then** the outline animates to `EditorialMonoclePalette.accentDim` and the glyph tint animates to `EditorialMonoclePalette.accentBright` over `120 ms` (`Curves.easeOut`).
- **Given** the in-game shell map is visible, **when** the widget tree under [GameRegionMinimap](../../app/lib/features/game/flame/minimap/game_region_minimap.dart) is inspected, **then** no `Material` widget paints with `Colors.white`, `Colors.black`, or any other hard-coded light-theme `Color` literal as its background, and no `ElevatedButton`, `FilledButton`, `OutlinedButton`, or `IconButton` paints inside the minimap stack (Material design ban per [`SPEC/ui/pixel-art-ui-catalog.md`](pixel-art-ui-catalog.md) § Material design ban; light-theme color regression per [`colonizethis-ui-design.mdc`](../../.cursor/rules/colonizethis-ui-design.mdc)).

**Acceptance (minimap ↔ main map):** Given the active region’s `RegionMapViewData.cellSize` matches the main `CtRegionMap` cell size, when the minimap is visible and a viewport snapshot exists for that region, then the white viewport rectangle matches the main map’s visible world area (center and span within tolerance for rounding). When the user taps a point on the minimap, then the main map camera centers on the corresponding world position (clamped). When the user drags on the minimap, then the camera pans in the same direction with world delta consistent with the snapshot’s world scale (same `cellSizePx` / map extents as [map-widget.md](map-widget.md) § Region minimap camera sync).

### Players bar (in-game map stack)

- **Toggle:** Tab-bar trailing cluster order is `treasury → cargo → players-bar toggle → news toggle`. Toggle chrome matches the news toggle (`28 × 22 dp`, dark editorial-monocle border/hover/active). Persisted in `MapViewState.showPlayersBar`. **New-game default:** `false` (set only in standard game setup; bar starts hidden). **Legacy / model default:** `true` when `mapViewState` or `showPlayersBar` is missing on load (`MapViewState.defaults` / `fromJson` `?? true`). Functional in **global observe** (explicit carve-out from observe sentinel pattern).
- **Placement:** Floating column anchored below the top bar + tab bar chrome. **Wide:** `top: 78 dp`, `right: 6 dp` (respects province-panel right inset). **Narrow:** below the news-feed anchor (`top: 56 dp` region); stacks vertically beneath an open `PlayerTurnEventFeedCard` when both are visible.
- **Visibility:** Shown when `mapViewState.showPlayersBar == true` and `Game.victory == null`. Hidden when toggled off or during victory overlay.
- **Order:** One chip per **Great Power** (`Game.players` filtered to non-tribe entries). Sorted by **`greatPowerPowerScore` descending**; tie-break `player.id` ascending.
- **Chip content:** `8 × 8 dp` swatch, `displayName`, and **power score** formatted with `NumberFormat.decimalPattern('en_US')`, monospace `--accent-dim` (not OW province count).
- **Name emphasis:** Normal play — human GP name in **bold accent** (`FontWeight.w600`). Player observe — observed GP bold accent. Global observe — all names muted (no bold accent).
- **Swatch colour:** `factionOwnershipColorMapForOldWorld(game)` (same as map ownership tint).
- **Interaction:** Chip column is non-interactive (pointer pass-through).

**Acceptance (players bar):**

- Given a brand-new campaign created through standard game setup, when the map shell loads on a wide viewport (≥600 dp), then `mapViewState.showPlayersBar == false`, `GameMapPlayersBar` is not mounted, and the players-bar toggle remains visible in the tab bar trailing cluster.
- Given a brand-new campaign, when the player toggles the players bar on and saves, then reload restores `showPlayersBar == true` and the bar is mounted.
- Given a save with `showPlayersBar == false`, when loaded, then the bar remains hidden until toggled on.
- Given a legacy save envelope with no `mapViewState` (or `mapViewState` without `showPlayersBar`), when loaded, then `showPlayersBar == true` and the bar is visible on wide layout.
- Given a legacy save loaded with implicit `showPlayersBar == true`, when the player saves without toggling, then the saved envelope includes explicit `mapViewState.showPlayersBar: true`.
- Given narrow viewport (<600 dp) and `showPlayersBar == false` on a new game, when the map renders, then `GameMapPlayersBar` is not mounted.
- Given global or player observe mode and `showPlayersBar == false`, when the map renders, then the bar is hidden and the players-bar toggle remains functional.
- Given `showPlayersBar == false`, when the wide map renders, then `GameMapPlayersBar` is not mounted.
- Given two GPs with deterministic `greatPowerPowerScore` values, when the bar renders, then chips appear in descending score order with formatted power scores.
- Given normal play for human `gp1`, when the bar renders, then `gp1` display name uses bold accent and other GP names use muted style.
- Given player observe for `gp2`, when the bar renders, then `gp2` name is bold accent.
- Given global observe, when the bar renders, then all GP names use muted style.
- Given narrow viewport and `showPlayersBar == true`, when the map renders, then the players bar mounts below the news-feed anchor region.
- Given `Game.victory != null`, when the map renders, then the players bar is not mounted regardless of `showPlayersBar`.
- Given non-default `showPlayersBar`, when save then load, then the value round-trips (`SPEC/program/save-load.md`).

---

## Layout / wireframe

```text
+------------------------------------------------------------------+
|  [ Old World ]  [ New World ]   (region tabs)                     |
+------------------------------------------------------------------+
| [E]   Map widget (viewport = this area)                          |
| [E]   – empire icons (left rail, always visible)                 |
| [E]   – base: terrain [+ resources + labels per 4-step cycle]    |
| [E]   – bottom-left: [layer][home][map options] (horizontal)     |
|       – minimap bottom-right                                     |
|       – players bar top-right (wide only)                        |
+------------------------------------------------------------------+
|  (narrow: province detail may overlay bottom of map stack)        |
+------------------------------------------------------------------+
```

On mobile: same tab row; map area fills available space; one region visible at a time; province detail overlays the bottom of the map stack when open (narrow).

---

## Behavior

### Incoming (what shows this UI)

| Source | Condition | Result |
|--------|-----------|--------|
| `GameScreen` | `mapViewDataProvider != null` | `GameMapArea` mounted as primary in-game surface. |

### User actions → outcomes

| Control / gesture | When enabled | Emits / calls | Side effects |
|-------------------|--------------|---------------|--------------|
| Region tab | Always | Switches active region map | Updates `mapViewData`. |
| Map tile tap | Map visible | Updates `mapProvincePanelProvider` | Opens province overlay. |
| Toolbar / empire icons | Per [empire-buttons.md](empire-buttons.md) | Bus events for panels | — |
| Next turn | Host [`game-screen.md`](game-screen.md) | Turn resolution flow | — |

---

## States and variants

| Variant | Trigger | Render difference |
|---------|---------|-------------------|
| Desktop wide | Viewport | Side-by-side chrome; side panel for detail. |
| Mobile narrow | Viewport | Bottom overlay for province detail. |

---

## Components

- `GameMapArea`, `CtRegionMap`, map tool row, treasury/cargo indicators — see [map-widget.md](map-widget.md), [empire-buttons.md](empire-buttons.md).

---

## Widgetbook

Folder: **Map Widget** — stories for map area with fixture topology and view data.

Folder: **Region Minimap** — stories for [GameRegionMinimap](../../app/lib/features/game/flame/minimap/game_region_minimap.dart) registered from [`gameRegionMinimapDirectories`](../../app/lib/widgetbook/catalog_part7.dart) and aggregated into `_ctWidgetbookDirectories` in [`catalog.dart`](../../app/lib/widgetbook/catalog.dart). Issue #2861 S12 story (5) "region minimap visible / hidden".

| Story | Purpose | Authority |
|-------|---------|-----------|
| Visible — wide chrome with viewport rectangle | Pins § Region minimap chrome: `--bg-deep` panel surface, 1 px `--border` outline, 32 × 32 dp toggle button with `--accent-dim` glyph, white viewport rectangle. | § Region minimap, § Region minimap chrome |
| Hidden — toggle-only (zoom + show button) | Exercises the collapsed state when `regionMinimapVisibleProvider == false`: only the zoom slider and "show minimap" toggle paint; the grid + viewport rectangle are not mounted. | § Region minimap (Toggle, session-only) |
| Narrow — 90 × 70 dp grid (issue #2870 S3) | Pins § Narrow minimap measurements: width-or-height-limited fit inside the 90 × 70 dp bounding box; panel chrome unchanged from wide. | § Narrow minimap measurements; [mobile-adaptation.md](mobile-adaptation.md) § In-game shell |

Stories drive a deterministic [`RegionMapViewportSnapshot`](../../app/lib/features/game/flame/region_map_viewport_snapshot.dart) (`zoom = fitMapZoom × 1.6`) so the viewport rectangle reads as a visible window inside the minimap grid in the visible-chrome story.

Folder: **Game Map Province Side Panel** — stories for [GameMapProvinceDetailSidePanel](../../app/lib/features/game/flame/overlays/game_map_province_detail_side_panel.dart) registered from [`gameMapProvinceDetailSidePanelDirectories`](../../app/lib/widgetbook/catalog_part7.dart). Issue #2861 S12 story (9) province panel open/closed on wide layout (≥ 600 dp).

| Story | Purpose | Authority |
|-------|---------|-----------|
| Open — wide layout panel visible | Pins the 320 dp right column with province detail chrome when `mapProvincePanelProvider.overlayOpen` is true after a sample tile tap. | § Province panel (wide shell); [in-game-shell-narrow.md](in-game-shell-narrow.md) § Province/sea zone detail overlay |
| Closed — panel collapsed | Exercises the `SizedBox.shrink()` path when the panel provider is closed so reviewers compare against the open chrome. | § Province panel (wide shell) |

Folder: **Game Map Corner Controls** — stories for [GameMapCornerControls](../../app/lib/features/game/flame/controls/game_map_corner_controls.dart) registered from [`gameMapCornerControlsDirectories`](../../app/lib/widgetbook/catalog_part7.dart) and aggregated into `_ctWidgetbookDirectories` in [`catalog.dart`](../../app/lib/widgetbook/catalog.dart). Issue #2861 S4 + S12 story (4) corner controls row, plus the issue #2870 S9 narrow-layout variant.

| Story | Purpose | Authority |
|-------|---------|-----------|
| Default — all three buttons enabled | Pins § Corner controls chrome: 32 × 32 dp surface, `CtGradients.railButtonGradient`, 22 × 22 dp full-colour glyph (no `srcIn` tint), hover/press accent-dim border shift. | § Corner controls chrome |
| Home-to-capital disabled (no human capital) | Exercises the disabled-state path when the underlying callback is `null`: tooltip + surface wrap in `IgnorePointer` + `Opacity(0.4)`. | § Corner controls chrome — Disabled state |
| Narrow (360 dp) — 24 × 24 dp buttons, 2 dp gap | Pins § Narrow corner-control measurements: 24 × 24 dp surface, 2 dp gap, glyph unchanged at 22 × 22 dp. | § Narrow corner-control measurements; [mobile-adaptation.md](mobile-adaptation.md) § In-game shell |

Folder: **Extraction disc legend** — chrome host for [ExtractionDiscLegend](../../app/lib/features/game/flame/controls/extraction_disc_legend.dart) above [GameMapCornerControls](../../app/lib/features/game/flame/controls/game_map_corner_controls.dart), registered from [`extractionDiscLegendDirectories`](../../widgetbook_host/lib/catalogs/catalog_game_chrome.dart) (Refs #4367 AC7). Isolated wide/narrow/panel stories remain under **Game Tab Bar**.

| Story | Purpose | Authority |
|-------|---------|-----------|
| Visible — legend above corner controls | Resource-including mode + viewing player (zero-disc teaching). | § Extraction disc legend |
| Hidden — terrain only | Legend omitted; corner controls stay, home-to-capital enabled. | § Extraction disc legend |
| Hidden — global observe | Legend omitted; home-to-capital disabled (`viewingPlayerId == null`). | § Extraction disc legend |

Folder: **Improvement headroom legend** — chrome host for [ImprovementHeadroomLegend](../../app/lib/features/game/flame/controls/improvement_headroom_legend.dart) above corner controls, registered from [`improvementHeadroomLegendDirectories`](../../widgetbook_host/lib/catalogs/catalog_improvement_headroom.dart) (Refs #4408). Folder: **Improvement headroom marks** — map-tile goldens for at-cap, has-headroom, foreign `{level}`-only, owned hidden-resource `{level}`-only, unimproved unmarked, unrevealed, and improvements-off.

| Story | Purpose | Authority |
|-------|---------|-----------|
| Visible — legend above corner controls | Improvements on + viewing player. | § Improvement headroom legend |
| Hidden — improvements off | Legend omitted; corner controls stay. | § Improvement headroom legend |
| Hidden — global observe | Legend omitted. | § Improvement headroom legend |
| 320 dp narrow | Chip does not overflow or cover Next turn. | § Improvement headroom legend |

Folder: **Map tile hover readout** — isolated MAP10001 owner/sight chrome ([MapTileHoverReadout](../../app/lib/features/game/flame/controls/map_tile_hover_readout.dart)), registered from [`mapTileHoverReadoutDirectories`](../../widgetbook_host/lib/catalogs/catalog_game_chrome.dart) (Refs #4406).

| Story | Purpose | Authority |
|-------|---------|-----------|
| Fully visible owned land | Place + Owner + Fully visible. | § Tile owner / sight hover readout |
| Fogged rival land | Authoritative owner + Fogged — terrain only. | § Tile owner / sight hover readout |
| Unrevealed land | Owner or Unclaimed + Unknown — no intel yet. | § Tile owner / sight hover readout |
| Unclaimed land | Owner: Unclaimed. | § Tile owner / sight hover readout |
| Sea zone | Place + Sea zone identity (no owner row). | § Tile owner / sight hover readout |
| Warp sea | Extra passage-to-the-other-world line. | § Tile owner / sight hover readout |
| 320 dp narrow | No horizontal overflow. | § Tile owner / sight hover readout |

Folder: **Game Map Options Dialog** — stories for [GameMapOptionsDialog](../../app/lib/features/game/widgets/dialogs/game_map_options_dialog.dart) registered from [`gameMapOptionsDialogDirectories`](../../widgetbook_host/lib/catalogs/catalog_game_chrome.dart).

| Story | Purpose | Authority |
|-------|---------|-----------|
| Defaults — overlay on, ownership off, names on | Pins cartographic defaults (capital-link highlight ON, ownership OFF) plus Map marks all-on. | § Map display options |
| All toggles on | Ownership tint on with all marks on. | § Map display options |
| All toggles off | Terrain-only marks + cartographic off. | § Map display options |
| Resources only | Cycle preset: resources on, improvements/roads off. | § Map display options — cycle presets |
| Improvements without resources | Dialog-only combination (resources off, improvements on, roads off). | § Map display options — new legal combinations |
| Roads disabled when improvements off | Roads switch `onChanged == null`. | § Map display options — roads disable+auto-off |

---

## Acceptance criteria

- **Given** the player has just completed game initialization (or loaded a save into play), **when** the app navigates to the in-game shell, **then** the Empire overview screen is shown with region tabs and the map widget for the active region (e.g. human capital's region first).
- **Given** the Empire overview is mounted with at least two region tabs (e.g., Old World and New World), **when** the user taps a region tab that is not currently active, **then** the UI layer replaces the map area with that region's map (one region per map; no side-by-side rendering, including on mobile).
- **Given** the Empire overview map widget is visible, **when** the user pans the map with a drag gesture (pointer drag or touch drag), **then** the map widget translates its viewport per [map-widget.md](map-widget.md) without changing the active region.
- **Given** the Empire overview map widget is visible, **when** the user zooms the map (mouse wheel, pinch gesture, or in-map zoom controls), **then** the map widget changes its zoom level along the continuous band versus fit-map baseline defined in [map-widget.md](map-widget.md).
- **Given** the Empire overview map widget is visible and the political-overlay toggle control is mounted, **when** the user activates that toggle, **then** the map widget shows or hides the political ownership overlay accordingly per [map-widget.md](map-widget.md).
- **Given** the Empire overview map widget is visible, **when** the user taps or clicks on a province tile, **then** the map widget invokes its province-selection callback with that province's tile key.
- **Given** the Empire overview map widget has invoked the province-selection callback with a province tile key, **when** the shell handles that callback, **then** the screen can render province details for that selection (details content TBD per [province-sea-zone-detail-overlay.md](province-sea-zone-detail-overlay.md)).
- **Given** the Empire overview screen is displayed on either a desktop viewport (≥ shell breakpoint width) or a mobile viewport (< shell breakpoint width), **when** the user switches between regions, **then** the UI layer uses the same tab-based region-switching control on both viewports, and on mobile renders only one region's map at a time (no side-by-side regions; tab system only).
- **Given** the in-game shell map chrome is visible, **when** the UI renders the tab bar, **then** the tab bar surface is exactly **34 dp** tall and paints `--surface` with a **1 px** `--border` bottom edge.
- **Given** the Old World region tab is active, **when** the tab bar renders, **then** the Old World tab label resolves to `--accent` and the tab paints a **2 px** `--accent` bottom border.
- **Given** the New World region tab is inactive, **when** the tab bar renders, **then** the New World tab label resolves to `--muted` and the tab does not paint a **2 px** `--accent` bottom border.
- **Given** unresolved orders project a treasury delta of `250` for the human player, **when** the treasury indicator renders on the tab bar, **then** the delta suffix resolves to `--success`.
- **Given** unresolved orders project a treasury delta of `-400` for the human player, **when** the treasury indicator renders on the tab bar, **then** the delta suffix resolves to `--danger`.
- **Given** the in-game shell control row is visible, **when** the UI renders region tabs, **then** the UI layer also renders an interactive cargo hold indicator beside the tabs with a crate icon and text formatted exactly as `used/capacity` (no spaces).
- **Given** the in-game shell control row is visible, **when** the UI renders region tabs, **then** the UI layer also renders a treasury indicator between the `New World` tab and cargo hold indicator using icon `ui_icon_treasury_coin.png`.
- **Given** the human player's treasury is `12345`, **when** the treasury indicator is in exact mode, **then** the UI layer displays `12,345` with no currency symbol.
- **Given** the human player's treasury is `12345`, **when** the user taps/clicks the treasury indicator once, **then** the UI layer switches to abbreviated mode and displays compact numeric text (for example `12.3k`) with no currency symbol.
- **Given** the human player's treasury is `-1000`, **when** the treasury indicator renders in exact mode and abbreviated mode, **then** the UI layer displays a leading minus sign in both modes.
- **Given** unresolved orders project a treasury delta of `250` for the human player, **when** the treasury indicator renders, **then** the UI layer displays `+250` beside treasury in green.
- **Given** unresolved orders project a treasury delta of `-400` for the human player, **when** the treasury indicator renders, **then** the UI layer displays `-400` beside treasury in red.
- **Given** unresolved orders project treasury delta `0` or projection data is unavailable, **when** the treasury indicator renders, **then** the UI layer hides delta text.
- **Given** the in-game shell control row is visible for a human player, **when** the cargo hold indicator is computed, **then** `used` equals the sum of that player's overseas extraction totals in the current world state and `capacity` equals the total home-fleet cargo holds for that player.
- **Given** the player switches between Old World and New World tabs, **when** the region tab changes, **then** the cargo hold indicator value remains a single global total and does not switch to per-region values.
- **Given** fleet composition or extraction-relevant state changes and the app event bus/provider flow publishes those changes into the in-game shell state, **when** the map controls rebuild, **then** the cargo hold indicator updates to the new `used/capacity` value without animation.
- **Given** the human player has reliable overseas used `3` and Home Fleet capacity `12`, **when** the player taps the tab-bar cargo indicator, **then** the UI layer opens a dismissible floating panel showing overseas `3`, Home Fleet holds `12`, free for trade `9`, and the counsel line — with no deep-link buttons.
- **Given** `capacity > 0`, reliable used, and `used < ceil(0.8 × capacity)`, **when** the cargo indicator renders, **then** only the numeric text resolves to `--muted`.
- **Given** `capacity > 0`, reliable used, `used ≥ ceil(0.8 × capacity)`, and `used < capacity`, **when** the cargo indicator renders, **then** only the numeric text resolves to `--accent`.
- **Given** `capacity > 0` and reliable `used ≥ capacity`, **when** the cargo indicator renders, **then** only the numeric text resolves to `--danger`.
- **Given** the cargo details panel is open, **when** the player dismisses it via ×, outside tap on the map scrim, or Esc, **then** the panel closes and tapping cargo again reopens it.
- **Given** the in-game shell at viewport width `< kNarrowBreakpoint` (600 dp), **when** the cargo details panel is open, **then** the `GameTopBar` Next turn control remains tappable (barrier scrim starts below shell chrome).
- **Given** the player has just entered the in-game shell (after init or load), **when** the map area is first shown, **then** `showMapResources`, `showMapImprovements`, and `showMapRoads` are all **ON** (full detail per [map-widget.md](map-widget.md) § Base layer display mode) unless the save already persisted other values.
- **Given** the Empire overview map is visible and the current flags equal a cycle preset, **when** the user taps the base-layer cycle button at the **bottom-left** of the map area (leftmost of the horizontal map tool row), **then** the UI layer writes the next preset in order terrain-only → resources → resources+improvements → full detail → terrain-only, persists those flags on `MapViewState`, and the button tooltip/semantics name the **current** combination.
- **Given** resources are off, improvements are on, and roads are off (non-preset), **when** the user taps the base-layer cycle button, **then** all three flags become off (terrain-only) and the tooltip/semantics name terrain only.
- **Given** the Empire overview map is visible, **then** the base-layer cycle button is visible at the **bottom-left** of the map area and displays the stacked layers icon (icon-only).
- **Given** the Empire overview map is in a resource-including base-layer mode and `ShellPlayerContext.viewingPlayerId != null`, **when** the map chrome renders (including zero discs), **then** the UI layer shows the extraction-disc legend above the corner controls with plain gold/brown meanings (Refs #4367).
- **Given** the player taps the extraction-disc legend, **when** the details popover opens, **then** the UI layer shows both colour meanings and a capital-link counsel line, and dismisses via ×, outside tap, or Esc without staging orders (Refs #4367).
- **Given** the base layer is **terrain only** or global observe (`viewingPlayerId == null`), **when** the map chrome renders, **then** the UI layer omits the extraction-disc legend (Refs #4367). Widget goldens: `app/test/extraction_disc_legend_goldens_test.dart` (`extraction_disc_legend_hidden_terrain_only.png`, `extraction_disc_legend_hidden_global_observe.png`); Widgetbook folder **Extraction disc legend**.
- **Given** the in-game map is not in work-target selection and the pointer hovers a map tile, **when** the owner/sight readout renders, **then** the UI layer shows Place, Owner or Sea zone identity, and Sight on MAP10001 without opening `MAP20001` (Refs #4406). Widget goldens: `app/test/map_tile_hover_readout_goldens_test.dart`; Widgetbook folder **Map tile hover readout**.

- **Given** the Empire overview map is visible, **then** a second icon-only button with the home/flag icon is visible **immediately to the right** of the base-layer cycle button in the same **bottom-left** horizontal row.
- **Given** the Empire overview map is visible and the current player has a defined capital tile, **when** the user taps the home-to-capital button, **then** the active region switches (if needed) to the current player's capital region and the map centers on the current player's capital tile with the selection/highlight cursor placed on that tile.

#### Initial map viewport (shell entry) — acceptance criteria

- **Given** the user enters the in-game shell via new game, load save, or resume and the current player (`ShellPlayerContext.mapPlayerIdFor(game)`) has a `capitalTile`, **when** `GameMapArea` mounts, **then** the UI layer resolves an auto-center target whose `tileKey` equals `capitalTile.toTileKey()` and whose `regionIndex` equals `0` for an `oldWorld` capital or `1` for a `newWorld` capital, sets the `mapProvincePanelProvider` secondary highlight to that `tileKey`, and does **not** open the province/sea detail overlay.
- **Given** `GameMapArea` mounts while `GameStartIntroOverlay` is visible and the current player has a `capitalTile`, **when** the first frame is scheduled, **then** the auto-center runs on map mount (it is not deferred until the intro overlay is dismissed).
- **Given** the current player has no `capitalTile`, **when** `GameMapArea` mounts, **then** the UI layer resolves a `null` auto-center target, leaves the active region index at the default `0`, and does not set a capital secondary highlight.
- **Given** global observe is active (`ObserveMode.global`, `ShellPlayerContext.viewingPlayerId == null`), **when** `GameMapArea` mounts, **then** the UI layer resolves a `null` auto-center target (no region switch, no capital secondary highlight) and the home-to-capital button is disabled (`homeToCapitalEnabled == false`).
- **Given** player observe is active for GP `gp2` (`ObserveMode.player`, `viewingPlayerId == 'gp2'`) and `gp2` has a `capitalTile`, **when** `GameMapArea` mounts, **then** the UI layer resolves an auto-center target for `gp2`'s `capitalTile` and the home-to-capital button is enabled (`homeToCapitalEnabled == true`).
- **Given** a save where the current player's `capitalTile` was reassigned since turn 0, **when** the user loads that save into play and `GameMapArea` mounts, **then** the resolved auto-center `tileKey` equals the save's current `capitalTile.toTileKey()` (not the turn-0 capital).

- **Given** the Empire overview map is visible, **then** a third icon-only button with the gear icon is visible **immediately to the right** of the home-to-capital button in the same **bottom-left** horizontal row.
- **Given** the Empire overview map is visible, **when** the user taps the third map display options button, **then** the UI layer shows a modal dialog titled `Map display options` with a dismiss action and the underlying map is not interactive until the dialog is closed.
- **Given** the Map display options dialog is visible, **when** the dialog tree is inspected, **then** the dialog is rendered by `GameMapOptionsDialog` inside a `CtDialogShell` (default `--accent-dim` 2px border, no override) with a **Map marks** heading, seven `CtToggleSwitch` rows, and a single `CtNinePatchButton` labelled `Close`, and no Material `AlertDialog`, `SwitchListTile`, or `TextButton` widgets paint anywhere inside the dialog (catalog ban per [pixel-art-ui-catalog.md](pixel-art-ui-catalog.md) § Material design ban).
- **Given** the player has just entered the in-game shell and the map is first shown, **when** no Map display options have been changed yet, **then** the map does not draw the Great Power ownership tint (default matches **Show province ownership** OFF) and does draw the capital-link disconnected hatch where applicable (default matches **Highlight land not bound to the capital** ON).
- **Given** the Map display options dialog is visible for the first time in a game session, **then** the dialog shows **Show resources**, **Show improvements**, **Show roads and rails**, **Show province and sea borders**, **Show province ownership**, **Show province names**, and **Highlight land not bound to the capital**, with all except **Show province ownership** in the ON state.
- **Given** `GameMapOptionsDialog` variants for Map marks all-on (defaults, including the renamed **Show province and sea borders** row), terrain-only, resources-only, improvements-without-resources, roads-disabled-when-improvements-off, and `kMinViewportWidth` 320 dp, **when** the host golden suite in `app/test/game_map_options_dialog_goldens_test.dart` captures each keyed `RepaintBoundary`, **then** each `matchesGoldenFile` baseline under `app/test/goldens/game_map_options_dialog_*.png` matches the committed PNG (Refs #4388).
- **Given** the player turns **Show resources** off, **when** the map re-renders, **then** commodity icons and extraction discs are not painted; improvements and roads follow their own flags.
- **Given** the player turns **Show improvements** off, **when** the map re-renders, **then** improvement marks are hidden, **Show roads and rails** is off and disabled (`onChanged == null`), and road/rail sprites do not paint; resources are unchanged.
- **Given** resources are off and improvements are on, **when** the map re-renders, **then** improvement marks paint and resource icons / discs do not.
- **Given** **Show improvements** is on and a viewing player is present, **when** the map chrome renders, **then** the UI layer shows a compact improvement-headroom teaching chip that opens a dismissible panel (× / outside tap / Esc) explaining `{n} of {cap}` as level versus this court’s current extraction limit; no new screen ID. Pins: `app/test/improvement_headroom_legend_test.dart`; goldens `app/test/improvement_headroom_legend_goldens_test.dart`; Widgetbook folder **Improvement headroom legend**.
- **Given** a 320 dp-wide viewport, **when** marks and the teaching chip render, **then** they do not overflow horizontally or block Next turn. Golden: `app/test/goldens/improvement_headroom_legend_320dp.png`.
- **Given** the Map display options dialog is visible, **when** the user toggles `Show province and sea borders` OFF, **then** the UI layer updates the global province-overlay visibility state so that all in-game Empire overview maps stop drawing province and sea-zone boundary strokes until that toggle is ON again (the Great Power ownership tint is unchanged and follows `Show province ownership`).
- **Given** the user has toggled `Show province and sea borders` OFF in the Map display options dialog and then closed the dialog, **when** the user reopens the Map display options dialog in the same app session, **then** that toggle appears in the OFF state and the in-game maps continue to omit province and sea-zone boundary strokes.
- **Given** the Map display options dialog is visible, **when** the user toggles `Show province ownership` OFF, **then** the UI layer updates global state so all in-game Empire overview maps stop drawing the Great Power land ownership tint until `Show province ownership` is toggled ON again (boundary strokes are unchanged and follow `Show province overlay`).
- **Given** the user has toggled `Show province ownership` ON and closed the dialog, **when** they reopen the Map display options dialog in the same session, **then** the `Show province ownership` toggle appears ON and maps continue to show the GP land tint.
- **Given** the user has toggled `Show province ownership` OFF after it was ON and closed the dialog, **when** they reopen the Map display options dialog in the same session, **then** the `Show province ownership` toggle appears OFF and maps continue to omit the GP land tint.
- **Given** the Map display options dialog is visible, **when** the user toggles `Show province names` OFF, **then** the UI layer updates global state so all in-game Empire overview maps stop drawing land province name labels until the toggle is ON again.
- **Given** the user has toggled `Show province names` OFF and closed the dialog, **when** they reopen the dialog in the same session, **then** the `Show province names` toggle appears OFF and maps continue to omit province name labels.
- **Given** the Map display options dialog is visible, **when** the user toggles `Highlight land not bound to the capital` OFF, **then** the UI layer updates global state so all in-game Empire overview maps stop drawing the capital-link disconnected hatch until the toggle is ON again.
- **Given** a legacy save JSON omits `showCapitalLinkDisconnectedHighlight`, **when** `MapViewState.fromJson` loads it, **then** the field defaults to **true** (ON).
- **Given** the player changes one or more map display options and then saves and later loads the same game, **when** the Empire overview map opens after load, **then** the map display options dialog and map rendering use the same persisted toggle values from savegame map view state.
- **Given** the player changes zoom on one region tab and then switches to the other region tab, **when** the other region map becomes active, **then** the same global fit-relative zoom multiplier is applied immediately and clamped to that region's map/camera limits.
- **Given** the player starts a brand-new campaign and no explicit default zoom preference is provided by setup config, **when** the Empire overview map first becomes visible, **then** the first visible map frame uses fit-relative zoom multiplier `m = 4.0` (or the current map clamp equivalent) and no prior visible frame at `m = 1.0` appears.
- **Given** the player starts a brand-new campaign and setup config provides an explicit preferred initial zoom multiplier `P`, **when** the Empire overview map first becomes visible, **then** the first visible map frame uses `clamp(P, 0.5, 8.0)` instead of forcing `m = 4.0`.
- **Given** the player changes map zoom and saves the game, **when** the player later loads that save, **then** the Empire overview map applies the persisted fit-relative zoom multiplier from savegame map view state (clamped to current active-region limits).
- **Given** `Show province and sea borders` is OFF and `Show province names` is ON, **when** the map renders, **then** province name labels are still visible (no dependency on the borders toggle).
- **Given** `Show province ownership` is OFF and `Show province names` is ON, **when** the map renders, **then** province name labels are still visible (no dependency on the province ownership toggle).
- **Given** the in-game shell map is visible, **when** the UI renders [GameMapCornerControls](../../app/lib/features/game/flame/controls/game_map_corner_controls.dart), **then** each of the three corner buttons paints a `32 × 32` dp surface whose decoration uses `CtGradients.railButtonGradient` (vertical `--surface-lite` → `--bg-deep`) with a 1 px outline that resolves to `EditorialMonoclePalette.border` in the default state, and the centered glyph is a `22 × 22` dp `StrictAssetIcon` rendered in native full colour and **not** wrapped in a `ColorFiltered` / `ColorFilter.mode(..., BlendMode.srcIn)` node.
- **Given** the corner controls are mounted and idle, **when** the descendant widget tree of any corner button is enumerated, **then** no corner button icon glyph node applies a `BlendMode.srcIn` (or equivalent single-colour) filter over the pixel-art asset.
- **Given** the in-game shell map is visible and a corner control button is rendered in its default (unhovered, unpressed, enabled) state, **when** the user moves the pointer over that button, **then** the button's outline color animates to `EditorialMonoclePalette.accentDim` over `120 ms` (`Curves.easeOut`) and the glyph colours are unchanged from the idle full-colour render.
- **Given** the in-game shell map is visible and the home-to-capital button is rendered with `homeToCapitalEnabled == false`, **when** the button paints, **then** the surrounding chrome wraps the surface in `IgnorePointer` and `Opacity(0.4)` (the canonical disabled-control opacity), the underlying gradient and 1 px `EditorialMonoclePalette.border` outline still resolve in the unhovered default state, the glyph renders in its native full colour (no `srcIn` tint), and pointer events do not invoke the home-to-capital callback.
- **Given** the in-game shell map is visible, **when** the widget tree under [GameMapCornerControls](../../app/lib/features/game/flame/controls/game_map_corner_controls.dart) is inspected, **then** no `Material` widget paints with `Colors.white` (or any other hard-coded light-theme color) as its background, and no `ElevatedButton`, `FilledButton`, `OutlinedButton`, or `IconButton` paints inside the corner-button row (Material design ban per [`SPEC/ui/pixel-art-ui-catalog.md`](pixel-art-ui-catalog.md) § Material design ban; light-theme color regression per [`colonizethis-ui-design.mdc`](../../.cursor/rules/colonizethis-ui-design.mdc)).

---

## Integration

- **Hosting screen:** [game-screen.md](game-screen.md). The `GameScreen` widget mounts `GameMapArea` (this screen's surface) when map view data is available, and the Flame canvas otherwise; it owns the next-turn flow, victory overlay, intro overlay, and pending diplomacy wrappers around this content.
- **Map widget:** [map-widget.md](map-widget.md). Reusable Flame component; this screen supplies data and handles `onProvinceSelected` (and optional `onRegionViewChanged`).
- **Data and events:** Same shared packages and event systems (colonizethis_logic, colonizethis_models, etc.). PlayerView or equivalent for human-player visibility. Game events may drive map updates or animations; see [game-events.md](../program/game-events.md) when wiring.
- **HUD, panels, orders:** Turn controls, unit panels, development, production, etc. are specified in [empire-buttons.md](empire-buttons.md) (toolbar actions) and [in-game-shell-narrow.md](in-game-shell-narrow.md) (narrow viewport: side menu, top bar). This spec defines the map-centric layout and region tabs.
- **Catalog:** Empire overview is a screen; map widget is registered as a reusable component. Register this screen in the app widget catalog when implemented.
