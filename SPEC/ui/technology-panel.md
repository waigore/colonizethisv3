# Technology Panel (Research Slots)

**Screen ID:** `GAME40001` — stable; do not reassign.
**SPEC/ui** — Technology panel: research slots and assignment. Implementation: `app/lib/features/game/screens/technology/technology_screen.dart`.
**Widgetbook:** `Tech Tree` → `app/lib/widgetbook/catalog.dart`. Game rules: [tech-tree.md](../game/tech-tree.md), [research-state.md](../game/research-state.md). Placement: [tech-tree-widget.md](tech-tree-widget.md) (slots tab).

**Mockup:** [mockups/GAME40001-technology-panel.html](mockups/GAME40001-technology-panel.html)
---

## Widget contract

Technology screen hosts research slots UI: slot count from `player.researchSlots`; assignment updates `Orders.researchOrdersByPlayerId`. The Tree tab may also assign a choosable tech into a seat (Refs #4498); see [tech-tree-widget.md](tech-tree-widget.md) § Description dialog — Slots remain the funding / Cancel / turn-preview surface.

---

## Trigger conditions

- **Toolbar / route:** Technology flow opened from in-game shell (Slots tab within technology screen).

---

## Layout / wireframe

### Top bar (dark editorial-monocle, all viewports)

- **Component:** `CtTopBar` (`SPEC/ui/pixel-art-ui-catalog.md` § Pixel-art component catalog → `CtTopBar` entry), supplied through the `topBar` slot of `CtGameFeatureScreenShell` so the screen reuses the shared `Scaffold` + `SafeArea` + `Column` body shell and retains `GameToUIBusListener` for live game wiring (composite contract: [`components/ct-game-feature-screen-shell.md`](components/ct-game-feature-screen-shell.md)).
- **Back affordance:** `CtBackButton` chevron-left glyph followed by the muted label `Map` so the affordance reads `← Map`. The button's default behaviour calls `Navigator.maybePop()` and is a no-op when there is no prior route on the stack.
- **Icon + title:** Pixel-art technology icon `assets/icons/32/ui_icon_technology.png` rendered at 18 × 18 logical px between the back affordance and the title. The title literal is `Technology`, rendered in the dark-theme `titleMedium` slot (Cinzel display family per `AppThemes.editorialMonocle`).
- **Height + chrome:** Fixed `CtTopBar.height` (36 px), filled with `CtGradients.topBarGradient`, capped by a 1 px `EditorialMonoclePalette.accentDim` bottom border. Hard-coded colours are forbidden; all tokens resolve through `EditorialMonoclePalette`.
- **Trailing slot — Slots / Tree toggle:** A pair of pixel-art toggle chips occupies the `CtTopBar.trailing` slot in the order `Slots`, `Tree`. The selected chip paints a 1 px `EditorialMonoclePalette.accent` border with an accent-tinted background; the unselected chip paints a 1 px `EditorialMonoclePalette.border` outline with a transparent background. Tapping a chip swaps the body between the Slots panel (`TechnologyPanel`) and the Tree panel (`TechTreeWidget`) without unmounting the surrounding shell. Material `TabBar` / `Tab` / `ToggleButtons` / `ChoiceChip` are banned on this surface per `SPEC/ui/pixel-art-ui-catalog.md`.

### Body

- **Slots tab (default):** Scrollable `TechnologyPanel` containing the researched-tech grid and the four research slot cards per § Slot behaviour. Wrapped in a 16 dp padded `SingleChildScrollView` so long content scrolls within the body area below the top bar.
- **Tree tab:** Full-bleed `TechTreeWidget` (no inner padding) so the DAG visualization fills the available height.

Slots tab content: vertical list of slot rows (label, assigned tech + progress, Cancel / Choose tech). Choose-tech opens the dark editorial-monocle Choose-tech dialog (see § Choose-tech dialog) listing researchable techs only.

#### Slots tab — section ordering (normative)

The body of the Slots tab MUST render the following sections in this top-to-bottom order, matching the mockup body markup in [`mockups/GAME40001-technology-panel.html`](mockups/GAME40001-technology-panel.html) where `.researched-heading` + `.researched-grid` precede `.slots-heading` + `#slots-container`:

The Slots tab body MUST NOT render a dev-only panel header block. The mockup `.content` block opens directly with `.researched-heading`; there is no per-player title or slot-count line above it. Specifically, the body MUST NOT render the legacy `technologyPanel_title` (`"Technology - {playerName}"`) line nor the legacy `technologyPanel_researchSlotsCount` (`"Research slots: {slots}"`) line. The player identity and the `Technology` title are already carried by the `CtTopBar` chrome (§ Top bar). Refs #3510.

1. **Researched Techs** — `TechSectionHeading` heading (`technologyPanel_researchedTechsHeading`) followed by the read-only `ResearchedTechChip` `Wrap` grid (or the empty-state line when the player has no researched techs).
2. **Section divider** — a single `CtBrassDivider` separates the Researched Techs block from the Research Slots block below it.
3. **Research Slots** — `TechSectionHeading` heading (`technologyPanel_researchSlotsHeading`) followed by the four slot cards per § Slot behaviour.

The Slots tab body MUST NOT render a standalone "In progress" auxiliary block below the Research Slots section. In-progress techs keep occupying their slots via the persisted `Player.researchSlotAssignments` (§ Slot occupancy) and render exclusively inside their slot cards. Rendering a separate `CtSectionLabel` "In progress" list (the legacy `technologyPanel_inProgress` + `technologyPanel_progressLine` block) is a regression. Refs #3512.

#### Slots tab — canonical heading style (normative, Refs #3510)

The two canonical Slots-tab section headings (`Researched Techs`, `Research Slots`) render via `TechSectionHeading` (`app/lib/features/game/widgets/technology/technology_panel.dart`), matching the mockup `.researched-heading` / `.slots-heading` style in [`mockups/GAME40001-technology-panel.html`](mockups/GAME40001-technology-panel.html): the Cinzel display family (`editorialMonocleDisplayFontFamily`) at `13` logical px, weight `600`, `0.04em` letter spacing, `EditorialMonoclePalette.accent` colour, and the literal heading text. These headings do **not** use the small-caps upper-cased `CtSectionLabel` chrome used elsewhere in the app. Per § Source-of-truth precedence (issue #3510) the mockup is canonical for this purely visual heading detail, so the Technology Slots headings deliberately diverge from the cross-panel `CtSectionLabel` convention. Rendering these headings via `CtSectionLabel` (small-caps, `--muted`, brass underline) is a regression.

Reversing the ordering of (1) ↔ (3) — including via an intervening `CtBrassDivider` placement that visually swaps the two sections — is a regression. Refs #2864 S0/S6.

---

## Behavior

### Incoming (what shows this UI)

| Source | Condition | Result |
|--------|-----------|--------|
| Technology route | Player opens Technology → Slots tab | Research slots panel visible. |

### User actions → outcomes

| Control / gesture | When enabled | Emits / calls | Side effects |
|-------------------|--------------|---------------|--------------|
| Choose tech | Slot empty or re-assign | Opens Choose-tech dialog (`showChooseTechDialog`) | Modal lists researchable-only techs; no order mutation until assign. |
| Choose-tech row body (assignable area) | Choose-tech open; at least one choosable tech | `applyAssignTechToSlot` via `onSelect` callback | Assigns `ResearchOrder` to slot; closes Choose-tech; dispatches `onOrdersChanged`. |
| Choose-tech Details | Choose-tech open; per-row control | Opens nested `showTechDefinitionDetailDialog` | Mounts Tree-parity detail dialog (full effects, prerequisites when any, researched-by pennants); does **not** assign or close Choose-tech. |
| Choose-tech Close | Choose-tech open | `Navigator.pop` | Dismisses dialog; orders unchanged. |
| Cancel | Slot assigned | Emits empty-`techId` cancel signal `ResearchOrder` (after a forfeiture-warning `CtConfirmDialog` when progress `> 0`) | Persisted slot freed; progress forfeited on resolution per research-resolution. |
| Funding toggle | Slot assigned and editing enabled | Sets `ResearchOrder.funding` for that slot | Updates `Orders.researchOrdersByPlayerId` immediately; persists until changed or cancelled. |

---

## States and variants

| Variant | Trigger | Render difference |
|---------|---------|-------------------|
| Empty chooser | Choose-tech open; no researchable unassigned techs | Single muted line `"No techs available to research"`; footer Close only; no option rows or effect/Details chrome. |
| Choose-tech option row (default) | Choose-tech open; choosable tech with effect summary | Row shows category icon, display name, GP pennants, era/category/RP subtitle, **1–2 muted effect lines** (`buildTechEffectSummaryLines`), and per-row **Details** `CtActionTextButton`. Row body tap assigns; Details tap opens nested detail dialog. |
| Choose-tech option row (truncated effects) | Tech has more than two effect lines | Default row shows first two effect lines only; remainder available via Details. |
| Choose-tech detail nested dialog | Player taps Details on a row | Nested `CtDialogShell` with full effect list, prerequisites (when any), researched-by pennants; Choose-tech remains open underneath. |
| Assigned slot | `ResearchOrder` present | Shows tech id + progress. |

---

## Components

- Technology screen widgets, choose-tech dialog, [tech-tree-widget.md](tech-tree-widget.md).
- `buildTechEffectSummaryLines` (`app/lib/features/game/widgets/technology/tech_effect_summary.dart`) — shared pure helper for Tree and Choose-tech effect copy (Refs #4222).
- `showTechDefinitionDetailDialog` / `TechDefinitionDetailDialog` (`tech_definition_detail_dialog.dart`) — Tree-parity detail surface reused by Choose-tech Details (Refs #4222).
- `ChooseTechOptionRow` / `ChooseTechOptionLabels` (`technology_panel_choose_tech_dialog_rows.dart`) — Choose-tech option row with effect lines and Details control (Refs #4222).
- `TechSectionHeading` (`app/lib/features/game/widgets/technology/technology_panel.dart`) — mockup-faithful accent display-font heading for the two canonical Slots-tab sections (Refs #3510); see § Slots tab — canonical heading style.
- `SlotFundingToggleRow` (`app/lib/features/game/widgets/technology/technology_slot_funding_toggles.dart`) — compact five-button per-slot research-funding selector (Refs #3512). Pure-helper `applySetSlotFunding` (`technology_panel_orders.dart`) returns the updated `Orders` for the dispatch callback.

---

## Widgetbook

Folder: **Tech Tree** — stories for slots tab with fixture player research state.

- **Mid-game (half researched)** — desktop-width `TechnologyScreen` (Slots tab default) with half the catalog unlocked and one in-progress tech.
- **Mid-game slots (mobile)** — same fixture inside the shared `mobileViewport` frame (360 × 640 dp) per `SPEC/ui/mobile-adaptation.md` § 6 (Refs #2870 R22 / S9).
- **Slots — funding & turn preview** — desktop editable `TechnologyPanel` (non-null `onOrdersChanged`) seeded by `technologyFundingPreviewFixture` with three prerequisite-free tier-1 techs assigned to slots 0–2 at varied funding levels (Medium / High / Low) and committed progress, with ample treasury so no slot is debt-blocked. Exercises the per-slot funding toggles and the dual-segment (committed + anticipated) turn preview with the RP delta and gold row (Refs #3512).
- **Slots — funding & turn preview (mobile)** — same fixture inside the shared `mobileViewport` frame (360 × 640 dp) so the funding toggles and dual-segment preview can be reviewed at the mobile width per `SPEC/ui/mobile-adaptation.md` § 6 (Refs #3512).
- **Slots — sequential funding preview** — desktop editable `TechnologyPanel` seeded by `technologySequentialFundingPreviewFixture` with two slots at Medium funding and treasury `200` (max debt `0`) so slot 0 spends and slot 1 is sequential-blocked. Exercises the empire-wide **Research this turn** header and sequential debt-block copy (Refs #4335).
- **Slots — spy insight (one rival)** — desktop editable `TechnologyPanel` seeded by `technologySpyInsightPreviewFixture` with one qualifying rival court; slot **+N RP** includes +15% spy insight (Refs #4457).
- **Slots — spy insight (two rivals)** — same host with two qualifying rivals (stacked ×1.30) (Refs #4457).
- **Slots — funding None** — assigned slot at funding None so anticipated RP is 0 and the breakdown has no spy row (Refs #4457).
- **Slots — persisted in-progress (no fresh orders)** — editable `TechnologyPanel` seeded by `technologyPersistedSlotFixture`: three slots occupied by persisted `Player.researchSlotAssignments` (with accrued progress) and an **empty** `currentOrders`. Proves an in-progress tech renders inside its slot from the persisted baseline alone, with no standalone "In progress" list (Refs #3512).

---

## Purpose

- **Placement:** Within the Technology flow (e.g. “Slots” tab). Shows the current player’s researched techs, research progress, and **research slots** for assigning techs to research.
- **Assignment:** Each slot allows the user to assign one tech to research (or clear the slot). The list of techs offered when choosing must be **researchable only** (prerequisites and discovery rules satisfied).

## Researchable set (assignment list)

The techs **choosable** for a slot are exactly:

- **Researchable:** Same rule as the tech tree: all tech prerequisites in the player’s `techUnlocked`, and for discovery techs (e.g. “Explorer finds Sugar”) the player must have **revealed** the required resource(s) per [tech-tree-new-world.md](../game/tech-tree-new-world.md). Derived via `researchableTechIds(techUnlocked, hasDiscoveredResource: …)` with `hasDiscoveredResource` supplied from game state (e.g. `hasRevealedResourceForPlayer(game, player.id, r)`).
- **Not already assigned:** A tech already assigned to another slot is not offered in the list (no duplicate assignment).
- **Not yet unlocked:** Techs in `techUnlocked` are not offered.

The panel does **not** show locked techs in the assignment list. When there are no choosable techs, the UI shows the message “No techs available to research”.

## Slot behaviour

- **Slots:** The Slots tab always renders exactly four slot cards in slot-index order regardless of `player.researchSlots`. The active slot count remains `player.researchSlots` (default 3; 4 with University); the locked-slot rule below covers the fourth card when the player has not researched University.
- **Locked slot 4 (University):** When `player.researchSlots` is `null` or strictly less than `4`, the fourth slot card renders as a **locked placeholder**:
  - The card uses the same slot-card chrome and occupies the **same card width** as Slots 1–3 (it stretches to the full panel content width; only its opacity, header label, and body content differ). Refs #3510.
  - The card body is rendered at exactly `0.45` opacity (the mockup `.slot-card[style="opacity:.45"]` value).
  - The slot header label reads exactly `"Slot 4 (University)"` (no other content in the header).
  - In place of the assigned-tech body / progress / empty-state, the card body shows exactly one footnote line `"Requires University tech"` in `--muted` italic.
  - The card renders no Cancel and no Choose tech action button.
  - The card emits no `ResearchOrder` mutations.
- Each active slot card (indices `0..player.researchSlots - 1`) shows label (e.g. “Slot 1”), assigned tech (if any) with progress, and actions: Cancel (if assigned), Choose tech.
- **Slot action controls (compact, mockup-faithful):** The slot header actions use the compact text-button chrome from the mockup `.slot-actions` block (`SPEC/ui/mockups/GAME40001-technology-panel.html`), **not** the heavy `CtNinePatchButton` primary chrome:
  - **Choose tech** renders as a neutral `CtActionTextButton` (mockup `.slot-actions button`: `--surface-lite` → `--bg-deep` gradient, 1 px `--border`, `--accent-dim` → `--accent-bright` on hover, Cinzel display font).
  - **Cancel** renders as a destructive `CtDangerTextButton` (mockup `.cancel-slot`: transparent fill, 1 px `--danger` border, `--danger` label, idle opacity `0.7` lifting to `1.0` on hover).
  - The locked Slot 4 placeholder renders neither control (per § Slot behaviour > Locked slot 4).
  - **Mobile touch target:** When the viewport width is `< kTechnologySlotActionTouchTargetBreakpoint` (600 logical px, mirroring the in-game shell narrow breakpoint in `SPEC/ui/mobile-adaptation.md` § 4), each slot action control guarantees a tap target of at least `kMinTouchTargetSize` (44 dp) in both dimensions per mobile-adaptation § 1. At or above that width the controls render at their compact mockup density.
- **Slot funding controls (Refs #3512):** Each active slot card with an assigned tech renders a compact row of **five rectangular funding toggle controls** in the fixed order **None, Low, Medium, High, Maximum** (one per `ResearchFundingLevel` value), implemented by `SlotFundingToggleRow` (`app/lib/features/game/widgets/technology/technology_slot_funding_toggles.dart`). Each toggle carries a stable key `techFundingToggle_<slotIndex>_<level.name>` so widget tests can locate it without coupling to localized strings. The toggle matching the slot's current `ResearchOrder.funding` renders in the **selected** state (1 px `--accent` border, accent-tinted fill, `--accent-bright` label); the other four render **unselected** (1 px `--border` outline, transparent fill, `--muted` label). New assignments default to **Medium** (`applyAssignTechToSlot` seeds `ResearchFundingLevel.medium`), so a freshly assigned slot shows Medium selected. Tapping a toggle for level `L` dispatches the updated `Orders` (via `applySetSlotFunding`) so the slot's `ResearchOrder.funding` becomes `L` with its `techId` / `slotIndex` unchanged; selection persists until changed again or the slot is cancelled. The funding toggle row is rendered **only** when the slot has an assigned tech **and** editing is enabled (`onOrdersChanged != null`); empty slots, the locked Slot 4 placeholder, and read-only (`onOrdersChanged == null`) panels render no funding controls. Hard-coded colours are forbidden; all tokens resolve through `EditorialMonoclePalette`.
### Slot turn preview (Refs #3512, #4335)

When editing is enabled (`onOrdersChanged != null`), the Slots body renders a default **empire-wide funding header** (`ResearchTurnFundingHeader`, key `techResearchTurnFunding`) directly beneath the **Research Slots** section heading and above the slot cards. It shows **Research this turn: −£X · +Y RP** when at least one occupied slot will spend gold or apply RP on the next turn, or **Research this turn: no spend** when every seat is empty, funding is None, or no slot can afford its selected funding after the sequential walk.

Each active slot card with an assigned tech and editing enabled renders a per-slot **turn preview** beneath the funding toggles, implemented by `ResearchSlotTurnPreviewView` (`app/lib/features/game/widgets/technology/research_slot_turn_preview_view.dart`). Previews are computed deterministically by the pure helpers `computeResearchSlotsTurnPreview` and `computeResearchSlotTurnPreview` (`app/lib/features/game/widgets/technology/research_slot_preview.dart`), which mirror the research-phase resolver ([research-resolution.md](../program/research-resolution.md)) so the card and header show the same RP/gold effect the next End Turn will apply. The helpers reuse the single-source-of-truth funding rates (`fundingStats`), the industrial bonus (`effectiveResearchPointsForTechAllocation`), the spy-insight boost (`applySpyResearchBoostToPoints` after industrial, using a precomputed qualifying-rival count from `spyResearchBoostGpCountForTech`), and the debt floor (`researchMaxDebtForUnlocked`) — they never re-derive those rates. Preview uses **current** spy presence (a same-turn spy kill can make live RP slightly lower). The default slot card still shows one **+N RP** number (spy insight is included in that number; no second always-visible percentage).

**Sequential walk:** `computeResearchSlotsTurnPreview` evaluates occupied slots in **ascending slot-index order** (matching `research_resolver.dart`), threading residual treasury after each successful spend. Spy insight is applied **per slot after** the industrial bonus, then the treasury walk continues as today. Per-slot `anticipatedRpPerTurn`, `goldSpentThisTurn`, and debt-block state reflect that walk — not an independent full-treasury snapshot per card. When a later slot is blocked because earlier seats consumed gold, `sequentialBlocked == true` and the gold row / breakdown dialog use plain-language copy distinct from a slot that fails against the starting treasury alone.

- **Dual-segment progress bar:** A 12 dp bar (mirroring `CtProgressBar` chrome: `--surface` track, 1 px `--accent-dim` border) renders **committed** RP as segment A (`--accent`) followed by **anticipated** RP this turn as segment B (a subtler `--accent` tint at `0.4` alpha, animated on width only). Segment B is capped to the bar's remaining headroom so the combined fill never exceeds 100%. Segment B carries a stable key `techSlotAnticipatedSegment_<slotIndex>`.
- **RP row:** The monospace `progress/cost RP` label is followed, when anticipated RP `> 0`, by a green `+N RP` delta control (key `techSlotRpDelta_<slotIndex>`). The delta is **hidden** when funding is None or the spend is blocked. Tapping the delta opens the breakdown dialog.
- **Gold row:** A treasury-coin icon (`ui_icon_treasury_coin.png`) plus the per-turn gold cost with a signed delta (key `techSlotGoldRow_<slotIndex>`). When the slot spends, the per-turn cost shows as a negative treasury delta (`CtResourceCell` danger colour). When debt-blocked, the cost is shown greyed with no spend; sequential-blocked slots add a plain-language hint that earlier slots consumed the treasury. The gold row is omitted entirely for None funding.
- **Treasury-insufficient (debt-blocked) state:** When the selected funding's per-turn gold cost would push the slot's **residual** treasury below `-researchMaxDebtForUnlocked(techUnlocked)` (mirroring the resolver's `nextTreasury < -maxDebt` early-return), the slot applies 0 RP that turn: segment B is **not shown**, the green RP delta is **hidden**, and the gold row shows the per-turn cost greyed with no spend (plus sequential hint when applicable). The breakdown dialog explains the block and, for sequential blocks, the residual treasury before the slot.
- **Breakdown dialog:** Tapping the RP delta opens `ResearchFundingBreakdownDialog` (`CtDialogShell`, `maxWidth 360`, scrim `--dialog-scrim`) listing the base funding RP, the +20% industrial bonus row (only when it applies), a **Spy insight** row only when the qualifying-rival count is `> 0` and the slot will spend (plain-language court display names, +15% per court; never raw ids), the emphasised effective RP total (including spy insight when it applies), the treasury cost this turn, and an italic `--danger` debt-block note when the spend is blocked (sequential vs starting-treasury variants). Funding **None**, debt-blocked, sequential-blocked, and no-qualifying-rival seats omit the spy row. A single `Close` `CtNinePatchButton` dismisses it without mutating orders.

- **Choose tech:** Opens the dark editorial-monocle Choose-tech dialog (see § Choose-tech dialog) listing only the choosable techs (researchable, not in another slot). Selecting a tech assigns it to that slot and closes the dialog.
- **Cancel:** Frees the slot. Because slot occupancy is persisted (§ Slot occupancy), Cancel emits an **empty-`techId`** `ResearchOrder` cancel signal for the slot (not a mere order removal) so the resolver releases the persisted assignment; progress for that tech is forfeited on resolution per [research-resolution.md](../program/research-resolution.md). When the slot's tech has accrued progress (`Player.researchProgressByTechId[techId] > 0`), the UI first shows a `CtConfirmDialog` forfeiture warning (`technologyPanel_cancelWarningTitle` / `technologyPanel_cancelWarningMessage`); the cancel proceeds only when the player confirms. When there is no accrued progress, the slot is freed immediately with no warning dialog.
- **Goal slot:** Out of scope for this spec; only assignment slots are defined here.

### Slot occupancy (persisted) (Refs #3512)

Each slot card's assigned tech and funding are the **effective** occupancy for the turn: the durable `Player.researchSlotAssignments[slotIndex]` entry is the baseline, and this turn's `Orders.researchOrdersByPlayerId` override it as the UI mutation surface — a non-empty order assigns/updates the slot, an empty-`techId` order (the Cancel signal) frees it. This mirrors the resolver's reconciliation in [research-resolution.md](../program/research-resolution.md) § Slot occupancy persistence. Consequently an in-progress tech with a persisted assignment but **no** fresh order this turn still renders in its slot (with its accumulated progress and funding), so the panel never shows an empty slot for a tech that is still researching. Only catalog-known techs are surfaced; a stale persisted tech id (not in the catalog) renders the slot as empty. Changing funding on a slot that is occupied only by a persisted assignment (no fresh order) creates a fresh `ResearchOrder` carrying the persisted tech so the funding change is applied.

## Choose-tech dialog

The Choose-tech dialog is the dark editorial-monocle modal opened by the slot card "Choose tech" button. It is a `CtDialogShell`-based modal (no Material `AlertDialog`/`Dialog`/`showModalBottomSheet`/`ListTile` chrome) and follows the visual contract in `SPEC/ui/mockups/GAME40001-technology-panel.html` `.tech-dialog` / `.dialog-card`:

- **Frame:** `CtDialogShell` default 2 px `--accent-dim` border on all four sides; canonical panel gradient background; `maxWidth = 480` (catalog default).
- **Scrim (barrier):** The modal route `barrierColor` MUST resolve to `EditorialMonoclePalette.dialogScrim` (the `--dialog-scrim` token from `pixel-art-ui-catalog.md` § Dialog scrim). Hard-coded `Colors.black54` or hex literals are regressions.
- **Title row:** Single line `"Choose Tech — Slot N"` (where `N = slotIndex + 1`), rendered in the display font in `--accent`.
- **Option rows (when at least one choosable tech exists):** Vertical column where each option is a bordered row containing:
  - Tech category icon at 22 px (resolved via `techCategoryIconAssetPath`, omitted when null).
  - **Assignable body** (tappable `InkWell`): tech display name in body font / `--fg` / 600 weight (per mockup `.t-name`); **GP pennants (Refs #3862)** inline after the name; subtitle line in mono font / `--muted` carrying era, category, and cost in research points (`technologyPanel_pickSubtitle`); **1–2 plain-language effect lines** in muted body style (`10` px) sourced from the shared `buildTechEffectSummaryLines` helper (same strings as the Tree description dialog — regiment/ship unlocks, authored `tech_effect_summary` lines, then category fallback when empty). When a tech has more than two effect lines, the default row shows only the first two; remaining lines appear under **Details**.
  - **Details control (Refs #4222):** Per-row `CtActionTextButton` labelled `technologyPanel_chooseTechDetails` (`"Details"`). Activating Details opens a nested `CtDialogShell` with Tree-parity content (display name, era/category, RP cost, prerequisites when any, full effect list, researched-by GP pennants when any) **without** assigning the tech and **without** closing Choose-tech. Row-body tap (excluding Details) assigns via `applyAssignTechToSlot` and closes Choose-tech.
  - Prerequisites appear only in the Details dialog, not on the default row.
- **Empty state (no choosable techs):** Single italic muted line `"No techs available to research"` (existing `technologyPanel_noTechsAvailable`) replaces the option list. The Close button (below) is still rendered.
- **Footer:** A single full-width `CtNinePatchButton` labelled `"Close"` (existing `common_close`) dismisses the dialog without mutating orders.
- **Implementation pin:** `app/lib/features/game/widgets/technology/technology_panel_orders.dart` exposes `showChooseTechDialog(...)` (replacing the legacy `showChooseTechBottomSheet`). The dialog body widget is private to that file or co-located alongside it.

## Data

- **Player:** `Player.techUnlocked`, `Player.researchProgressByTechId`, `Player.researchSlots`, `Player.researchSlotAssignments` (persisted slot → `{techId, funding}` occupancy; the baseline source for each slot's effective assignment, § Slot occupancy).
- **Orders:** `Orders.researchOrdersByPlayerId[playerId]` — list of `ResearchOrder` (slotIndex, techId, funding). Assignment updates this; turn resolution applies it per [research-resolution.md](../program/research-resolution.md). An empty-`techId` `ResearchOrder` is the Cancel signal that frees a persisted slot.
- **Game:** Required for discovery rule: visibility/revealed resources via `hasRevealedResourceForPlayer(game, player.id, resourceId)`.

## Acceptance criteria

- **Given** the user is on the Technology panel (slots tab) and taps “Choose tech” for a slot, **when** the assignment list is shown, **then** the list contains only techs that are researchable for the current player (all tech prerequisites in `techUnlocked`, and for discovery techs the player has revealed the required resource(s)) and that are not already assigned to another slot.

- **Given** the user is on the Technology panel and opens “Choose tech” for a slot, **when** there are no techs that are both researchable and not already in another slot, **then** the UI shows the message “No techs available to research” and does not list any techs.

- **Given** the user has opened the “Choose tech” list for a slot and the list is filtered to researchable techs only, **when** the user selects a tech from the list, **then** that tech is assigned to the slot, the dialog closes, and the orders are updated so the slot’s `ResearchOrder` has that tech id.

- **Given** the user has assigned tech A to slot 1, **when** the user opens “Choose tech” for slot 2, **then** tech A does not appear in the list for slot 2 (no duplicate assignment).

- **Given** the Technology panel is shown with a game that has world state and visibility, **when** the assignment list is computed, **then** discovery techs (e.g. discovery_of_sugar) are included only if the player has revealed the corresponding resource(s), using the same rule as the tech tree (`hasRevealedResourceForPlayer`).

- **Given** the Slots tab is rendered for any player, **when** the slot list is computed, **then** the UI layer renders exactly four slot cards in slot-index order regardless of `player.researchSlots`.

- **Given** `player.researchSlots` is `null` or strictly less than `4`, **when** the fourth slot card is rendered, **then** the UI layer renders the card body at opacity `0.45`, sets the header label to exactly `"Slot 4 (University)"`, shows exactly the footnote line `"Requires University tech"` in place of any assigned-tech / progress / empty-state content, and renders no Cancel and no Choose tech button on that card.

- **Given** `player.researchSlots` is greater than or equal to `4`, **when** the fourth slot card is rendered, **then** the UI layer renders the card at full opacity (not the locked `0.45`), uses the standard slot label `"Slot 4"`, and renders Cancel (when assigned) and Choose tech buttons as on the other active slots.

- **Compact slot action controls (Refs #3510):** **Given** an active slot card with an assigned tech is rendered with editing enabled (`onOrdersChanged != null`), **when** the slot header actions build, **then** the UI layer renders the `Choose tech` action as a `CtActionTextButton` and the `Cancel` action as a `CtDangerTextButton`, and renders no `CtNinePatchButton` for the slot actions (the heavy nine-patch chrome is reserved for the Choose-tech dialog `Close` footer).

- **Mobile slot-action touch target (Refs #3510):** **Given** the Slots tab is rendered with editing enabled at a viewport width strictly less than `kTechnologySlotActionTouchTargetBreakpoint` (600 logical px), e.g. the `360 × 640 dp` mobile frame, **when** each rendered slot action control (`CtActionTextButton` / `CtDangerTextButton`) is measured, **then** the UI layer reports a rendered size of at least `kMinTouchTargetSize` (44 dp) in both width and height.

- **Desktop slot-action density (Refs #3510):** **Given** the Slots tab is rendered with editing enabled at a viewport width greater than or equal to `kTechnologySlotActionTouchTargetBreakpoint` (600 logical px), **when** a slot action control is measured, **then** the UI layer reports a rendered height strictly less than `kMinTouchTargetSize` (44 dp), preserving the compact mockup `.slot-actions button` density rather than padding the control to the mobile minimum.

- **Slot funding toggles present (Refs #3512):** **Given** an active slot card with an assigned tech is rendered with editing enabled (`onOrdersChanged != null`), **when** the slot body builds, **then** the UI layer renders exactly five funding toggle controls inside a `SlotFundingToggleRow`, in order labelled None, Low, Medium, High, Maximum, each carrying a stable key `techFundingToggle_<slotIndex>_<level.name>` for the five `ResearchFundingLevel` values.

- **Slot funding default Medium (Refs #3512):** **Given** a slot whose `ResearchOrder.funding` equals `ResearchFundingLevel.medium` (the default seeded on new assignment by `applyAssignTechToSlot`), **when** the funding toggle row renders, **then** the Medium toggle is rendered in the selected state (`--accent` border) and the None, Low, High, and Maximum toggles are rendered in the unselected state (`--border` outline).

- **Slot funding selection updates orders (Refs #3512):** **Given** an active slot at index `i` with an assigned tech `t` and editing enabled, **when** the player taps the funding toggle for level `L` (any `ResearchFundingLevel` other than the current one), **then** the UI layer dispatches `onOrdersChanged` with an `Orders` whose `researchOrdersByPlayerId[playerId]` entry at `slotIndex == i` has `funding == L`, `techId == t`, and `slotIndex == i` unchanged, and no other slot's `ResearchOrder` is mutated.

- **No funding toggles on read-only panel (Refs #3512):** **Given** an active slot card with an assigned tech is rendered with editing disabled (`onOrdersChanged == null`), **when** the slot body builds, **then** the UI layer renders no `SlotFundingToggleRow` and no funding toggle controls.

- **No funding toggles on empty slot (Refs #3512):** **Given** an active slot card with no assigned tech (no `ResearchOrder` for that slot) rendered with editing enabled, **when** the slot body builds, **then** the UI layer renders the empty-state line and no `SlotFundingToggleRow` (funding is meaningless without an assigned tech).

- **Turn-preview helper mirrors the resolver (Refs #3512):** **Given** a player with sufficient treasury and a tech assigned at funding level `L` (not None) and no qualifying spy-insight rivals, **when** `computeResearchSlotTurnPreview` runs, **then** `baseRpPerTurn` equals `fundingStats(L).points`, `anticipatedRpPerTurn` equals `effectiveResearchPointsForTechAllocation(player, tech, base)` (including the +20% floor bonus for military/naval techs when Industrial Funding of Research is unlocked), `goldCostPerTurn` equals `fundingStats(L).cost`, `goldSpentThisTurn` equals `goldCostPerTurn`, and `debtBlocked` is false.

- **Anticipated segment present when spending (Refs #3512):** **Given** an active editable slot at index `i` whose funding is not None and whose spend stays within the research debt floor, **when** the slot card renders, **then** the UI layer renders the anticipated segment-B fill (key `techSlotAnticipatedSegment_<i>`), the green RP delta control (key `techSlotRpDelta_<i>`), and the gold row (key `techSlotGoldRow_<i>`), and the combined committed + anticipated bar fraction does not exceed 1.0.

- **Debt-blocked slot preview (Refs #3512):** **Given** an active editable slot whose selected funding's per-turn gold cost would push `treasury` below `-researchMaxDebtForUnlocked(techUnlocked)`, **when** the slot card renders, **then** the UI layer renders no anticipated segment-B fill and no green RP delta control, `computeResearchSlotTurnPreview` reports `debtBlocked == true` with `anticipatedRpPerTurn == 0` and `goldSpentThisTurn == 0` while still exposing the non-zero `goldCostPerTurn` and `effectiveRpPerTurn`, and the gold row still renders (greyed, no spend).

- **None funding hides the gold row (Refs #3512):** **Given** an active editable slot whose funding is None, **when** the slot card renders, **then** the UI layer renders no green RP delta control and the gold row collapses to zero height (no per-turn cost shown).

- **RP delta opens the breakdown dialog (Refs #3512):** **Given** an active editable slot showing a non-zero anticipated RP delta, **when** the player taps the green `+N RP` delta control, **then** the UI layer mounts the `ResearchFundingBreakdownDialog` modal listing the base funding RP, the +20% industrial bonus row only when it applies, the Spy insight row only when it applies, the effective RP total, and the treasury cost this turn (plus a debt-block note when the spend is blocked).

- **Spy insight preview matches the resolver (Refs #4457):** **Given** a funded slot (funding ≥ Low, not debt-blocked) whose assigned tech is unlocked by at least one rival Great Power that currently has one of the human's Spies in their territory, **when** `computeResearchSlotTurnPreview` / Slots render, **then** `anticipatedRpPerTurn` and the green **+N RP** equal `applySpyResearchBoostToPoints` on the industrial-adjusted base, and the **Research this turn** header includes that RP.

- **Spy insight breakdown names courts (Refs #4457):** **Given** that state, **when** the player opens the RP breakdown, **then** a **Spy insight** row appears naming the qualifying court(s) in display names and stating +15% per court in player words (never raw ids).

- **Spy insight stacks for two rivals (Refs #4457):** **Given** two qualifying rivals who both unlocked the tech, **when** preview and breakdown render, **then** RP uses the stacked multiplier (×1.30) and both courts are named.

- **No spy row without insight or spend (Refs #4457):** **Given** funding **None**, no Spy in any rival GP, no qualifying rival has the tech unlocked, or the slot is debt-blocked / sequential-blocked, **when** the slot renders, **then** anticipated RP matches the non-spy preview (0 when blocked or None) and the breakdown has **no** spy row.

- **Next-turn dialog unchanged (Refs #4457):** **Given** `DLG60001` Next turn, **when** confirmation opens, **then** the dialog still does not list empty research seats or idle Spies (`UXD-001`, `UXD-002`).

- **Spy-insight Widgetbook / golden coverage (Refs #4457):** **Given** Widgetbook / goldens for slot preview and the breakdown dialog, **when** this ships, **then** use cases cover no-insight, one-rival insight, two-rival stack, and funding None.

- **Slot turn-preview visual golden coverage (Refs #3512):** **Given** an assigned, editable `ResearchSlotCard` (and the `ResearchFundingBreakdownDialog`) rendered against `AppThemes.editorialMonocle` at device pixel ratio `1.0`, **when** the funded-Medium, None-funding, debt-blocked, and breakdown-dialog states are captured via a keyed `RepaintBoundary`, **then** the UI layer produces stable `matchesGoldenFile` baselines under `app/test/goldens/research_slot_card_*.png` / `research_funding_breakdown_dialog.png` that fail on visual divergence from those states and pass against the committed baselines (`app/test/research_slot_card_goldens_test.dart`).

- **Persisted assignment renders in slot without a fresh order (Refs #3512):** **Given** `Player.researchSlotAssignments[i]` is `{techId: T, funding: F}` for a catalog-known tech `T` and `Orders.researchOrdersByPlayerId[playerId]` contains **no** order with `slotIndex == i`, **when** the Slots tab renders slot `i`, **then** the UI layer renders slot `i` as an assigned `ResearchSlotCard` showing tech `T`, its `Player.researchProgressByTechId[T]` progress, and funding `F` selected on the toggle row, and does **not** render the empty-state line for slot `i`.

- **Fresh order overrides persisted assignment (Refs #3512):** **Given** `Player.researchSlotAssignments[i]` is `{techId: T1, funding: F1}` and `Orders.researchOrdersByPlayerId[playerId]` contains an order at `slotIndex == i` with non-empty `techId == T2`, **when** the Slots tab renders slot `i`, **then** the UI layer renders slot `i` showing tech `T2` (the order overrides the persisted baseline).

- **Empty-techId order frees a persisted slot in the UI (Refs #3512):** **Given** `Player.researchSlotAssignments[i]` is `{techId: T, funding: F}` and `Orders.researchOrdersByPlayerId[playerId]` contains an order at `slotIndex == i` with empty `techId`, **when** the Slots tab renders slot `i`, **then** the UI layer renders slot `i` as an empty assignable slot (empty-state line; no tech `T`).

- **Stale persisted tech id renders empty (Refs #3512):** **Given** `Player.researchSlotAssignments[i]` carries a `techId` that is not present in the tech catalog and there is no fresh order for slot `i`, **when** the Slots tab renders slot `i`, **then** the UI layer renders slot `i` as empty (no assigned-tech body).

- **No standalone In-Progress block (Refs #3512):** **Given** `Player.researchProgressByTechId` is non-empty and the Slots tab is rendered for any player on any viewport, **when** the panel body widget tree is inspected, **then** the UI layer renders no `CtSectionLabel` carrying the localized `technologyPanel_inProgress` text and no `Text` carrying any `technologyPanel_progressLine` entry below the Research Slots section; in-progress techs appear only inside their occupied slot cards.

- **Cancel with progress warns before forfeiting (Refs #3512):** **Given** an active editable slot `i` whose effective tech `T` has accrued progress (`Player.researchProgressByTechId[T] > 0`), **when** the player taps the slot's Cancel control, **then** the UI layer mounts a `CtConfirmDialog` whose title is `technologyPanel_cancelWarningTitle` and whose message is `technologyPanel_cancelWarningMessage(displayName(T), progress)`, and dispatches **no** `onOrdersChanged` until the player confirms.

- **Cancel confirm frees slot via empty-techId order (Refs #3512):** **Given** the forfeiture-warning dialog is shown for slot `i`, **when** the player taps the confirm (`technologyPanel_cancelWarningConfirm`) button, **then** the UI layer dispatches `onOrdersChanged` with an `Orders` whose `researchOrdersByPlayerId[playerId]` contains a `ResearchOrder` at `slotIndex == i` with empty `techId` (the cancel signal that frees the persisted slot on resolution).

- **Cancel keep aborts (Refs #3512):** **Given** the forfeiture-warning dialog is shown for slot `i`, **when** the player taps the keep (`technologyPanel_cancelWarningKeep`) button or dismisses the barrier, **then** the UI layer dispatches no `onOrdersChanged` and the slot remains assigned to `T`.

- **Cancel without progress skips the warning (Refs #3512):** **Given** an active editable slot `i` whose effective tech `T` has no accrued progress (`Player.researchProgressByTechId[T]` missing or `0`), **when** the player taps the slot's Cancel control, **then** the UI layer dispatches `onOrdersChanged` immediately with an empty-`techId` cancel-signal `ResearchOrder` at `slotIndex == i` and mounts no `CtConfirmDialog`.

- **Slot occupancy visual golden coverage (Refs #3512):** **Given** the editable `TechnologyPanel` seeded by `technologyPersistedSlotFixture` (three slots occupied by persisted `Player.researchSlotAssignments` with accrued progress and an **empty** `currentOrders`) and the cancel-forfeiture `CtConfirmDialog` (`technologyPanel_cancelWarningTitle` / `technologyPanel_cancelWarningMessage`), each rendered against `AppThemes.editorialMonocle` at device pixel ratio `1.0`, **when** the persisted in-slot in-progress panel (at the `360 × 640 dp` mobile frame) and the forfeiture-warning dialog states are captured via a keyed `RepaintBoundary`, **then** the UI layer produces stable `matchesGoldenFile` baselines under `app/test/goldens/technology_slots_persisted_in_progress_mobile_360.png` and `app/test/goldens/research_cancel_forfeiture_dialog.png` that fail on visual divergence from those states and pass against the committed baselines (`app/test/technology_slot_occupancy_goldens_test.dart`).

- **Slots tab section ordering (Refs #2864 S0/S6):** **Given** the Slots tab is rendered for any player on any viewport, **when** the body widget tree is laid out, **then** the `TechSectionHeading` carrying the localized `technologyPanel_researchedTechsHeading` text appears at a strictly smaller vertical offset (smaller `Offset.dy`) than the `TechSectionHeading` carrying the localized `technologyPanel_researchSlotsHeading` text, matching the mockup body markup (`SPEC/ui/mockups/GAME40001-technology-panel.html`: `.researched-heading` precedes `.slots-heading`).

- **Mockup-faithful section heading style (Refs #3510):** **Given** the Slots tab is rendered for any player, **when** the two canonical section headings build, **then** the UI layer renders each of `technologyPanel_researchedTechsHeading` and `technologyPanel_researchSlotsHeading` inside a `TechSectionHeading` whose `Text` carries the literal (non-upper-cased) heading string, resolves its colour to `EditorialMonoclePalette.accent`, uses the `editorialMonocleDisplayFontFamily` (Cinzel) display family, and uses `FontWeight.w600`; the UI layer renders neither canonical heading via `CtSectionLabel` (no small-caps upper-cased `RESEARCHED TECHS` / `RESEARCH SLOTS` text for these two headings).

- **No dev-only panel header block (Refs #3510):** **Given** the Slots tab is rendered for any player on any viewport, **when** the panel body widget tree is inspected, **then** the UI layer renders no `Text` carrying the localized `technologyPanel_title` (`"Technology - {playerName}"`) string and no `Text` carrying the localized `technologyPanel_researchSlotsCount` (`"Research slots: {slots}"`) string, matching the mockup which opens directly with the `Researched Techs` heading.

- **Funding & turn-preview Widgetbook coverage (Refs #3512):** **Given** the editable `TechnologyPanel` is rendered for the `technologyFundingPreviewFixture` (three prerequisite-free tier-1 techs assigned to slots 0–2 at funding Medium / High / Low, committed progress `{600, 300, 0}` RP, treasury `8000` so no slot is debt-blocked) with a non-null `onOrdersChanged`, at both a desktop-width viewport and the `360 × 640 dp` mobile frame, **when** the Slots body builds, **then** for each of the three assigned slots the UI layer renders a `SlotFundingToggleRow` exposing all five `ResearchFundingLevel` toggles (keyed by `SlotFundingToggleRow.toggleKey`) and a dual-segment turn preview whose anticipated segment B (keyed by `ResearchSlotTurnPreviewView.anticipatedSegmentKey`) and RP delta (keyed by `ResearchSlotTurnPreviewView.rpDeltaKey`) are present.

- **Sequential multi-slot preview honesty (Refs #4335):** **Given** two or more funded research slots whose combined gold cost exceeds what sequential spending allows under the research debt floor (for example treasury `200`, max debt `0`, slots 0–1 both at Medium funding `150` gold each), **when** the player opens `GAME40001` Slots with editing enabled, **then** only slots that will actually spend show anticipated RP/spend, later blocked slots show `sequentialBlocked == true` with 0 RP and plain-language sequential debt-block copy on the gold row, and the `ResearchTurnFundingHeader` shows overall **−£X · +Y RP** matching the sequential walk (not the sum of independent full-treasury previews).

- **Overall funding header when ample treasury (Refs #4335):** **Given** ample treasury and three funded slots whose sequential walk succeeds for each, **when** Slots renders with editing enabled, **then** each slot's anticipated RP and gold match the sequential preview and the header totals equal the sum of those per-slot spends and RP.

- **Overall funding empty state (Refs #4335):** **Given** all seats empty or funding None, **when** Slots renders with editing enabled, **then** the `ResearchTurnFundingHeader` shows the no-spend empty state and no slot shows false debt-block noise.

- **Sequential breakdown dialog (Refs #4335):** **Given** a sequential-blocked slot whose effective RP would be non-zero if treasury allowed, **when** the player opens the RP breakdown from a slot that still shows the greyed gold row, **then** the dialog explains residual treasury after earlier slots in plain language (distinct from the starting-treasury debt-floor note).

- **Locked Slot 4 same width as active slots (Refs #3510):** **Given** `player.researchSlots` is `null` or strictly less than `4`, **when** the Slots tab is rendered, **then** the locked `LockedResearchSlotCard` fourth-slot card and each active `ResearchSlotCard` are laid out at the same width (within ±1 logical px) so the locked placeholder is not visually narrower or wider than Slots 1–3.

- **Mockup locked Slot 4 parity (Refs #3510):** **Given** the `SPEC/ui/mockups/GAME40001-technology-panel.html` `slots-container` is rendered, **when** the default / empty variant is active (`activeSlots < 4`), **then** it shows exactly four `.slot-card` elements — three active slots plus exactly one locked `Slot 4 (University)` placeholder — and **when** the `all` variant is active (`activeSlots === 4`), then it shows exactly four `.slot-card` elements (Slots 1–4 live) and no locked Slot 4 placeholder.

- **Slots-tab visual golden parity coverage (Refs #3510):** **Given** the `TechnologyPanel` (Slots body) is rendered for the deterministic debug fixture player against `AppThemes.editorialMonocle` at device pixel ratio `1.0`, at both a desktop-width viewport and the `360 × 640 dp` mobile frame (§ Defined viewports), **when** each viewport is captured via a keyed `RepaintBoundary`, **then** the UI layer produces stable `matchesGoldenFile` baselines (`app/test/goldens/technology_slots_panel_desktop.png`, `app/test/goldens/technology_slots_panel_mobile_360.png`) that fail on visual divergence from the mockup-aligned heading / slot-card / action-control style and pass against the committed baselines (`app/test/technology_slots_panel_parity_goldens_test.dart`).

- **Top bar present (dark chrome):** **Given** the Technology screen is mounted for the viewed player on any viewport, **when** the screen builds its chrome, **then** the UI layer renders a `CtTopBar` instance above the body whose `title` equals `"Technology"`, whose `backButtonLabel` equals `"Map"`, and whose leading `icon` is the pixel-art asset `assets/icons/32/ui_icon_technology.png` sized 18 × 18 logical px (no fallback to the legacy `CtScreenShell` parchment chrome).

- **Top bar Material ban (regression guard):** **Given** the Technology screen is mounted on any viewport, **when** the widget tree is inspected, **then** the technology surface contains no Material `TabBar`, `Tab`, `Divider`, or `AppBar` widgets (catalog ban per `SPEC/ui/pixel-art-ui-catalog.md`).

- **Top bar Slots/Tree toggle present:** **Given** the Technology screen is mounted, **when** the top bar trailing slot builds, **then** the UI layer renders exactly two pixel-art toggle chips inside the `CtTopBar.trailing` slot in the order `Slots`, `Tree`, each tappable, and each carrying a stable key (`TechnologyScreen.slotsToggleKey`, `TechnologyScreen.treeToggleKey`) so widget tests can locate them without coupling to localized strings.

- **Slots is the default tab:** **Given** the Technology screen is first mounted, **when** the body builds, **then** the UI layer renders a `TechnologyPanel` (Slots body) and renders no `TechTreeWidget` until the player taps the Tree toggle.

- **Tree toggle swaps the body:** **Given** the Technology screen is mounted with the Slots tab active, **when** the player taps the `Tree` toggle chip in the top bar trailing slot, **then** the UI layer unmounts the `TechnologyPanel` and renders `TechTreeWidget` in the body; tapping the `Slots` toggle chip again restores the `TechnologyPanel` and unmounts the `TechTreeWidget`.

- **Given** the user is on the Technology panel and taps "Choose tech" for slot index `N - 1` (`N` in `1..4`), **when** the modal is shown, **then** the UI layer mounts a `CtDialogShell` modal whose route `barrierColor` is exactly `EditorialMonoclePalette.dialogScrim`, and renders the title row `"Choose Tech — Slot N"`. The UI layer mounts no Material `AlertDialog`, `Dialog`, `showModalBottomSheet`, or `ListTile` chrome on this route.

- **Given** the Choose-tech dialog is shown for a slot and the choosable-tech list is empty (no techs both researchable for the player and not already assigned to another slot), **when** the dialog body is rendered, **then** the UI layer renders exactly the line `"No techs available to research"` and a single `"Close"` `CtNinePatchButton`, and renders no option rows.

- **Given** the Choose-tech dialog is shown for a slot and the choosable-tech list is non-empty, **when** the user taps the `"Close"` `CtNinePatchButton`, **then** the UI layer pops the dialog route, the player's `Orders.researchOrdersByPlayerId` are unchanged, and no `ResearchOrder` mutation is dispatched via `onOrdersChanged`.

- **Given** a researchable tech with authored effect lines and/or regiment/ship unlocks, **when** the Choose-tech dialog renders that tech's default row, **then** the UI layer renders 1–2 plain-language effect lines (muted `10` px body) below the era/category/RP subtitle, sourced from `buildTechEffectSummaryLines` (Tree parity).

- **Given** a tech whose full effect list has more than two lines, **when** the default Choose-tech row renders, **then** the UI layer renders only the first two effect lines on the row and exposes the remainder via the per-row **Details** control.

- **Given** a tech with only the category fallback effect, **when** the Choose-tech row renders, **then** the UI layer renders that fallback line on the default row (same rule as the Tree description dialog).

- **Given** the Choose-tech dialog is open, **when** the player activates **Details** on a row, **then** the UI layer mounts a nested detail dialog with full effects and prerequisites (when any) without assigning the tech and without closing Choose-tech.

- **Given** the Choose-tech dialog is open, **when** the player taps the row assignable body (not Details), **then** the slot receives that tech via `applyAssignTechToSlot`, Choose-tech closes, and `onOrdersChanged` dispatches the updated `Orders`.

## Integration

- **Source of truth:** [tech-tree.md](../game/tech-tree.md), [research-state.md](../game/research-state.md), [tech-tree-new-world.md](../game/tech-tree-new-world.md). Resolution: [research-resolution.md](../program/research-resolution.md).
- **Consistency:** Assignment list uses the same `researchableTechIds` and discovery callback as the tech tree widget and order suggestion logic.
