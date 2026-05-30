# Diplomacy Panel

**Screen ID:** `GAME30001` — stable; do not reassign.
**SPEC/ui** — Full-page diplomacy screen. Implementation: `app/lib/features/game/screens/diplomacy_screen.dart`.
**Widgetbook:** `Diplomacy Panel` → `app/lib/widgetbook/catalog.dart`. Source: [diplomacy.md](../game/diplomacy.md), [factions.md](../game/factions.md).

**Mockup:** [mockups/GAME30001-diplomacy-panel.html](mockups/GAME30001-diplomacy-panel.html)
---

## Widget contract

`DiplomacyScreen` presents discovered factions, relation summaries, and diplomatic action buttons. Orders accumulate in `currentOrders` until Next Turn; panel does not resolve orders locally.

---

## Trigger conditions

- **Toolbar:** Dove icon opens Diplomacy as a **full-page** screen (pushed route).
- **Single-player vs AI only.** No multiplayer-specific UI.

## Purpose

The player can view all **discovered** factions (Great Powers, Minor Nations, Tribes), see current diplomatic state with each, and take **diplomatic actions** per [diplomacy.md](../game/diplomacy.md).

---

## Discovered factions

A faction is **discovered** iff the player has a **diplomatic relation** with that faction (i.e. a `DiplomacyRelation` exists between player and faction). Relations are only possible when the faction is discovered. At game start: same-region (GP–GP, GP–Minor) relations are initialized; cross-region (GP–Tribe) are not, so Tribes appear when the player first gains a relation (e.g. after establishing consulate).

- **List contents:** All GPs (except the player), all Minors, and only Tribes that are discovered.
- **Grouping:** Sections by type — Great Powers, Minor Nations, Tribes.
- **Sort:** Great Powers by **military power** (desc), then by **number of provinces** (desc). Minors and Tribes: implementation-defined (e.g. by name or id).

---

## Top bar (dark editorial-monocle, all viewports)

The diplomacy screen renders its chrome through `CtGameFeatureScreenShell`'s opt-in `topBar` slot so the surrounding `Scaffold` + `SafeArea` + `Column` shell, `GameToUIBusListener`, and ordering of body widgets remain identical to the legacy chrome path. The legacy `CtScreenShell` parchment title bar is **not** used on this surface (R1–R3 of #2863 — full dark editorial-monocle alignment).

- **Component:** `CtTopBar` (`SPEC/ui/pixel-art-ui-catalog.md` § Pixel-art component catalog → `CtTopBar` entry), supplied through the `topBar` slot of `CtGameFeatureScreenShell`. The screen retains `GameToUIBusListener` for live game wiring (default `attachGameToUiListener: true`).
- **Title text:** literal `Diplomacy`. The display font (`Cinzel` / `Iowan Old Style`) and `--accent` text color resolve from the dark editorial-monocle theme `titleMedium` slot per `CtTopBar` defaults.
- **Back affordance:** `CtTopBar.backButtonLabel == 'Map'` so the chevron + muted label read together as `← Map`; `onBackPressed` is unset, deferring to `CtBackButton`'s default `Navigator.maybePop()` behavior (which produces the same shell-level pop semantics as the legacy `CtScreenShell` AppBar back button).
- **Leading icon:** the pixel-art diplomacy icon `assets/icons/32/ui_icon_diplomacy.png` rendered through `StrictAssetIcon` at 18 × 18 logical px, painted between the back affordance and the title (matching the production / technology screens' 18 px convention).
- **Height + chrome:** Fixed `CtTopBar.height` (36 px), filled with `CtGradients.topBarGradient` (matches `--surface-lite → --surface`), capped by a 1 px `EditorialMonoclePalette.accentDim` bottom border. Hard-coded colours are forbidden; all tokens resolve through `EditorialMonoclePalette`.
- **Stable widget key:** the top-bar widget carries `DiplomacyScreen.topBarKey` so widget and e2e tests can locate the dark chrome without coupling to localized strings.

The top bar applies to both wide and narrow viewports; mobile adaptation does not change the top-bar contract.

---

## Section headings

Faction rows are grouped into three sections in this order: **Great Powers**, **Minor Nations**, **Tribes**. Each non-empty section is preceded by a heading rendered per [mockups/GAME30001-diplomacy-panel.html](mockups/GAME30001-diplomacy-panel.html) `.section-head`:

- Display font (`Cinzel` / `Iowan Old Style` per [pixel-art-ui-catalog.md](pixel-art-ui-catalog.md) § Editorial-monocle palette font stacks); `font-weight: 600`; small positive letter-spacing.
- Text color `--accent`.
- 2 px bottom border in `--accent-dim` spanning the heading container width.

The heading is otherwise an inert label (no tap target).

---

## Per-faction row

- **Row chrome (editorial-monocle dark theme):** Each faction row is a flat-bordered tile per [mockups/GAME30001-diplomacy-panel.html](mockups/GAME30001-diplomacy-panel.html) `.faction-row` — **vertical** `linear-gradient(180deg, --bg-deep, --surface)` background, 1 px `--border` outline, 4 px vertical gap between consecutive rows, minimum content height ~48 dp. On hover the outline transitions to `--accent-dim` (`transition:border-color .15s` in the mockup; in Flutter, a `MouseRegion` + `StatefulWidget` swap is acceptable — the **visible target** is the resolved border color). Touch devices that do not emit hover events render the row in its idle state. Nine-patch `CtPanel` chrome is **not** used for diplomacy rows because the mockup uses a sharp 1 px border, not the brass nine-patch frame.
- **Left:** Faction name (displayName or id), type badge (GP / Minor / Tribe), current **diplomatic state**: relation state (AT_PEACE / AT_WAR) rendered via the **relation state badge** (see § Relation state badge), **one-word relation state** (Hostile / Unfriendly / Cordial / Friendly) derived from the hidden relation score per [diplomacy.md](../game/diplomacy.md) § Player-facing relation display. The numeric relation score is **not** shown. For Minor/Tribe: overture stage (none, Trade Consulate, Embassy, NAP, Join Empire) if any. For **Great Powers:** a **power comparison percentage** is shown — a derived display only, not a new data field. See **Power comparison percentage (Great Power rows only)** below.
- **Type badge colors (editorial-monocle dark theme):** The type badge uses mono font and the canonical [pixel-art-ui-catalog.md](pixel-art-ui-catalog.md) § Editorial-monocle palette tokens per [mockups/GAME30001-diplomacy-panel.html](mockups/GAME30001-diplomacy-panel.html) `.f-badge`. Great Power rows use `--accent-dim` background with `--bg-deep` foreground; Minor Nation rows use `--muted` background with `--bg-deep` foreground; Tribe rows are **outlined** — transparent background, `--muted` border and `--muted` foreground. No hardcoded Material chrome colors are permitted.
- **Outgoing economic diplomacy (list row only):** On the **same row**, below the relation line, when the human Great Power has **active or pending** economic diplomacy toward this faction (receiver-centric copy): **Active subsidy:** `Outgoing subsidy: £N/turn to {displayName}` when `Game.subsidyStates` has `payerId` = human GP and `targetId` = this row’s faction. **Pending grant:** `Pending grant aid: £N (resolves end of turn)` when current-turn orders include `grantAid` toward this faction. **Pending subsidy:** `Pending subsidy: £N/turn (resolves end of turn)` when current-turn orders include `setSubsidy` toward this faction. Omit each line when not applicable. Do **not** duplicate this block on the Diplomacy Detail screen for current product (list row is the source of truth).
- **Right:** **Available diplomatic actions** for the player toward that faction. Actions are those explicitly in SPEC/game/diplomacy.md and SPEC/program/orders.md: Declare War, Offer Peace, Alliance (GP only), Establish Overture (stage), **Grant Aid**, **Set Subsidy** as **separate** buttons when each is valid. Grant Aid requires Embassy; Set Subsidy requires Consulate or Embassy — hide or omit a button when its preconditions are not met. Only show actions that are **valid** per the diplomatic order validator (same rules as order submission). Any counterparty that is a valid target for aid/subsidy per game rules (Great Power, Minor, or Tribe) uses the same button rules.

### Power comparison percentage (Great Power rows only)

Replaces the previously displayed absolute **power score** per [diplomacy.md](../game/diplomacy.md) § Great Power power score with a relative comparison to the human player. **Derived display only** — no new data field is required; both inputs are read from the existing `greatPowerPowerScore` source already consumed by the diplomacy panel rows.

- **Formula:** `pct = round(((gpPowerScore - playerPowerScore) / max(playerPowerScore, 1)) * 100)`.
- **Format:** `+N%` when `pct > 0`, `−N%` when `pct < 0`, `0%` when `pct == 0`. Use the unicode minus sign `−` (U+2212), not the ASCII hyphen-minus, to match the mockup.
- **Color:** Red (`--danger`) when the GP is stronger than the player (`pct > 0`); green (`--success`) when the GP is weaker (`pct ≤ 0`). Preserves the red/green semantic from the prior absolute-score display.
- **Zero-player guard:** `max(playerPowerScore, 1)` so a player at score 0 still yields a finite percentage (no division-by-zero).

Tapping anywhere on a faction row (or an explicit “Details” affordance in that row) opens the **Diplomacy Detail** screen for that faction (GAME30002), scoped to the current player’s Great Power. See [Diplomacy Detail navigation](#diplomacy-detail-view-per-faction) below.

---

## Relation state badge

Each faction row renders the AT_PEACE / AT_WAR state as a small mono-font chip preceding the one-word relation label, per [mockups/GAME30001-diplomacy-panel.html](mockups/GAME30001-diplomacy-panel.html) `.f-relation .state`:

- **Label:** uppercase `WAR` when the relation is `atWar`, otherwise `PEACE`.
- **Chrome:** mono font, font-size 9 sp, padding 1 dp top/bottom × 5 dp left/right, square 1 dp corners (`border-radius: 1px`), 4 dp gap before the relation word.
- **War variant:** translucent warm-red overlay background derived from the canonical `--danger` token (the mockup uses `oklch(40% 0.06 20 / 0.4)`, which is the danger hue desaturated and alpha-tinted at 0.40); foreground text `--danger`.
- **Peace variant:** translucent cool-green overlay background derived from the canonical `--success` token (the mockup uses `oklch(40% 0.06 150 / 0.2)`, which is the success hue desaturated and alpha-tinted at 0.20); foreground text `--success`.
- **Forbidden:** raw `Colors.red`, `Colors.green`, or any Material chrome background. The badge resolves background and foreground from the editorial-monocle palette only.

---

## Mode bar (filter)

A bottom filter bar lets the player narrow the visible faction list. The bar is anchored to the bottom of the diplomacy panel with a top divider; buttons use mono font with inactive label `--muted`, active/hover label `--accent`, and `--accent-dim` border on the active item per [mockups/GAME30001-diplomacy-panel.html](mockups/GAME30001-diplomacy-panel.html) `.mode-bar`.

| Mode | Label | Visible sections |
|------|-------|------------------|
| `all` (default) | "All" | Great Powers, Minor Nations, Tribes |
| `gp` | "Great Powers only" | Great Powers only |
| `minors` | "Minors only" | Minor Nations **and** Tribes (no Great Powers) |

Notes:

- The "Minors only" mode includes **both** Minor Nations **and** Tribes, matching mockup `setMode('minors')`. The word "Minors" is used loosely as shorthand for "non-Great-Power factions"; the panel still groups them into separate "Minor Nations" and "Tribes" sections when both are present.
- Filter state is local UI state in `_DiplomacyPanelState`; it does not persist across panel close/reopen.
- The mode bar is independent of the `discovered factions` rule — switching modes never reveals undiscovered factions.
- **Minimum viewport (`kMinViewportWidth` = 320 dp):** the three filter chips are laid out in a centred `Wrap` (8 dp spacing / run spacing) so the cluster flows onto a second run when the combined intrinsic width (~458 dp) exceeds the panel body width (~296 dp after horizontal padding). At wider widths all three chips remain on a single centred run, matching the mockup `.mode-bar` cluster. See [mobile-adaptation.md](mobile-adaptation.md) § 7.

---

## Diplomacy Detail view (per faction)

Navigation contract: the detail view (**GAME30002**) is a **full-page route**, not an in-panel overlay. Tapping a faction row emits `NavigateToRouteEvent(Routes.diplomacyDetail, …)` with `factionId`, `factionDisplayName`, `kind`, and `relation` payload per [`app-event-bus.md`](../program/app-event-bus.md); the shell pushes `DiplomacyDetailScreen` over the diplomacy panel. The detail-overlay HTML block inside the GAME30001 mockup ([mockups/GAME30001-diplomacy-panel.html](mockups/GAME30001-diplomacy-panel.html)) is **illustrative** of the detail content layout and is **not** implemented as an in-panel overlay. The canonical visual layout for the full-page detail screen is [mockups/GAME30002-diplomacy-detail-screen.html](mockups/GAME30002-diplomacy-detail-screen.html).

Widget contract, layout, navigation, and acceptance criteria: **[diplomacy-detail-screen.md](diplomacy-detail-screen.md)**. When the user opens the detail view for a faction `B` while controlling Great Power `A`, the UI shows:

- **Header:** Faction name and type (GP / Minor / Tribe), and the same current relation summary as the row (relation state, one-word relation).
- **History panel:** A vertical list of **diplomatic history events** involving `A` and `B`, newest first. Each entry renders:
  - A **year label** derived from the event’s `turn` using the game calendar mapping (e.g. `1505 (Turn 12)`).
  - A human-readable sentence describing the event (e.g. `We declared war on Spain.`, `We established an Embassy with Bavaria.`, `Our subsidies to Bavaria were cancelled when war began.`).
  - If an event involves a faction that is not yet discovered by the current player (no relation, outside visibility rules), that faction’s name is shown as `Unknown faction` in the text.
- **Dossier subpanel (Great Powers only):** When `B` is a Great Power, a secondary panel or tab within the detail view shows the **AI dossier** for `B` from the perspective of `A`, per [SPEC/ai/ai-dossier.md](../ai/ai-dossier.md). The dossier uses only PlayerView-safe data. The dossier subpanel is **in scope** for visual restyling against [mockups/GAME30002-diplomacy-detail-screen.html](mockups/GAME30002-diplomacy-detail-screen.html) `.dossier` chrome (mono `Turn N` label + sentence rows, `--accent-dim` left border) — the restyle does not change dossier data sources, evidence mechanics, or PlayerView-safety contracts.

Events are read from the flat diplomatic history list on `Game`, filtered to those whose `participants` include both `A` and `B`, and ordered by `(turn desc, intraTurnIndex desc)`.

---

## Actions

All diplomatic actions are **submitted for end-of-turn resolution** — the panel does not resolve orders itself. Orders accumulate in the current turn's order set until Next Turn.

### Submitting an action

- **Confirm dialog:** Before any action is submitted, the UI shows a **confirmation dialog** with the action name and target faction. The dialog has "Confirm" and "Cancel" buttons. Tapping "Confirm" submits the order; tapping "Cancel" dismisses without submitting.
- **Parameter dialogs:** Actions that require parameters (Grant Aid amount, Set Subsidy amount, Establish Overture stage) open the parameter dialog first; after parameters are set, the confirmation dialog appears before the order is submitted. **Grant Aid / Set Subsidy:** single dialog (`GrantOrSubsidyDialog`, see [grant-or-subsidy-dialog.md](grant-or-subsidy-dialog.md)) with **stepper-only** entry (no free numeric typing). Dialog titles use **sentence case** (`Grant aid`, `Set subsidy`). **Grant Aid:** step **£1000**, default **£1000**, positive multiples of **£1000** up to treasury; **Submit** only when valid. **Set Subsidy:** step **£100**, default **£1000**, positive multiples of **£100** up to treasury; **Submit** only when valid.
- **Pending state:** After an order is submitted, the corresponding action button for that (player, target, type) is shown with a **"Cancel" label** to indicate the action is pending. The button text changes from the action name to "Cancel" and tapping it **removes the pending order** (toggle off), returning the UI to the pre-submitted state.
- **Toggle logic:** Clicking an action button while the same order is already pending cancels it. The pending state is per `(humanPlayerId, targetFactionId, DiplomaticOrderType)`. If the pending order has parameters (amount, overtureStage), canceling removes the entire order; the user must re-enter parameters to submit again.

### Action button labels (pending state)

| Action | Default | Pending (Cancel) |
|--------|---------|-----------------|
| Declare War | "Declare War" | "Cancel" |
| Offer Peace | "Offer Peace" | "Cancel" |
| Alliance | "Alliance" | "Cancel" |
| Establish Overture | "Consulate/Embassy/NAP/Join Empire" | "Cancel" |
| Grant Aid | "Grant Aid (£N)" | "Cancel" |
| Set Subsidy | "Set Subsidy (£N)" | "Cancel" |

### Action button styling (editorial-monocle dark theme)

Per [mockups/GAME30001-diplomacy-panel.html](mockups/GAME30001-diplomacy-panel.html) `.f-actions button`, all diplomatic action buttons render against a small (compact) variant of the canonical `CtNinePatchButton` brass surface. The **Declare War** button is the only action button with a destructive variant per `.f-actions button.war-btn`:

- **Border and text color:** `--danger` (warm-red brass).
- **Background:** unchanged from the standard action button gradient (`--surface-lite` → `--bg-deep`); only the outline and label color shift.
- **Applies to:** `DiplomaticOrderType.declareWar` only. The pending (Cancel) variant retains its own pending styling and is not the war variant.

Orders are submitted into the current turn's order set; resolution happens on Next Turn.

---

## Layout / wireframe

- Full-page: list is scrollable; sections (GPs, Minors, Tribes) with headers.
- Actions shown to the right of each faction row (inline buttons or compact actions). **Current product:** pairwise diplomacy only (human Great Power toward each discovered faction). **Out of scope:** multi-party treaty or coalition UI beyond what pairwise orders already support; not a deferred placeholder—such flows are undefined until specified in GDD/TDD.

---

## Responsive layout

The faction-row body adapts to a single normative breakpoint per [mockups/GAME30001-diplomacy-panel.html](mockups/GAME30001-diplomacy-panel.html) `@media (max-width: 500px)`. The cross-cutting narrative is owned by [mobile-adaptation.md](mobile-adaptation.md) § 4; this section codifies the diplomacy-row specifics.

- **Breakpoint:** viewport width **≤ 500 dp** (Flutter dp; matches the mockup CSS `max-width: 500px` cutoff and the **`≤ 500 dp`** column in mobile-adaptation.md § 4).
- **Wide variant (viewport width `> 500 dp`):** the faction-row body lays out the info column and the action-button cluster **side by side** in a `Row`, with the action cluster anchored to the trailing edge. Matches mockup `.faction-row { display:flex; align-items:flex-start }` plus `.f-actions { justify-content:flex-end }`.
- **Narrow variant (viewport width `≤ 500 dp`):** the faction-row body stacks the action-button cluster **below** the info column, and the action cluster is **left-aligned**. Matches mockup `.faction-row { flex-wrap:wrap }` plus `.f-actions { max-width:none; justify-content:flex-start }`.
- The breakpoint constant exposed by the implementation (`kDiplomacyRowNarrowMaxWidth = 500.0`) is normative so widget tests can pin the boundary deterministically.
- **Out of scope:** the panel-level mode bar, section headings, and per-row chrome (gradient, 1 dp border) are **not** re-laid-out at the narrow breakpoint — only the row's info-vs-actions arrangement changes.

---

## Behavior

### Incoming (what shows this UI)

| Source | Condition | Result |
|--------|-----------|--------|
| Toolbar dove | In-game | `DiplomacyScreen` pushed full-page. |
| Faction row tap | Any discovered faction | Navigates to detail per [diplomacy-detail-screen.md](diplomacy-detail-screen.md) (out of scope for GAME30001 row). |

### User actions → outcomes

| Control / gesture | When enabled | Emits / calls | Side effects |
|-------------------|--------------|---------------|--------------|
| Diplomatic action button | Valid per validator | Confirm (+ parameter dialogs) → adds/cancels draft diplomatic order | Pending shows **Cancel** label. |
| Row Details | Always | Opens detail route | See diplomacy-detail spec. |

---

## States and variants

| Variant | Trigger | Render difference |
|---------|---------|-------------------|
| Default | Panel open | Scrollable faction list with inline actions. |
| Pending action | Order in `currentOrders` | Action button label **Cancel**. |

---

## Components

- `DiplomacyScreen`, faction row widgets, `GrantOrSubsidyDialog` — [grant-or-subsidy-dialog.md](grant-or-subsidy-dialog.md).

---

## Widgetbook

At least one story that shows the Diplomacy panel using a **real game** (e.g. from init-game or debug init). Ensures the panel works with actual Game/PlayerView data and diplomacy state.

In addition, a **mobile viewport** use case must render the panel inside the shared [mobileViewport](../program/app-ui-wiring.md) frame (360 × 640 dp `MediaQuery` size from `app/lib/widgetbook/catalog.dart`) so the `≤ 500 dp` narrow row variant from [§ Responsive layout](#responsive-layout) is reviewable without window resizing. This satisfies the "any other screen with responsive variants" clause from [mobile-adaptation.md](mobile-adaptation.md) § 6 (Widgetbook verification) for the diplomacy surface listed under [`Refs #2870`](https://github.com/waigore/colonizethisv3/issues/2870) R22.

Finally, an **empty-state** use case named `No factions discovered (empty state)` must render the panel against a `Game` whose human player has no diplomacy relations with any other faction (no other Great Power, Minor Nation, or Tribe). The story exposes the `diplomacy_panel_noFactions` copy under the editorial-monocle dark chrome inherited from the Widgetbook host theme (`AppThemes.editorialMonocle`), so reviewers can validate the empty-state layout without scripting a custom save. The fixture is a stable widget catalog asset — not a runtime debug toggle — so its layout cannot regress silently when `buildDiplomacyRows` is changed.

---

## Acceptance criteria

- **Top bar present (dark chrome):** **Given** the Diplomacy screen is mounted for the human player on any viewport, **when** the screen builds its chrome, **then** the UI layer renders a `CtTopBar` instance above the body whose `title` equals `"Diplomacy"`, whose `backButtonLabel` equals `"Map"`, and whose leading `icon` is the pixel-art asset `assets/icons/32/ui_icon_diplomacy.png` sized 18 × 18 logical px (no fallback to the legacy `CtScreenShell` parchment chrome).
- **Top bar gradient + accent border:** **Given** the Diplomacy screen is mounted on any viewport, **when** the `CtTopBar` surface paints, **then** the surface's `BoxDecoration` resolves its gradient to `CtGradients.topBarGradient` and its bottom border colour resolves to `EditorialMonoclePalette.accentDim` with width `1` px.
- **Top bar Material ban (regression guard):** **Given** the Diplomacy screen is mounted on any viewport, **when** the widget tree is inspected, **then** the diplomacy surface contains no `CtScreenShell` widget (the legacy parchment title-bar path is gone) and no Material `AppBar` widget.
- **Top bar stable key:** **Given** the Diplomacy screen is mounted on any viewport, **when** the screen builds, **then** the `CtTopBar` carries the stable key `DiplomacyScreen.topBarKey` so widget tests can locate the dark chrome without coupling to localized strings.
- **Top bar back affordance:** **Given** the Diplomacy screen is pushed over a prior route, **when** the user taps the `CtBackButton` inside the `CtTopBar`, **then** `Navigator.maybePop()` runs and the prior route regains focus (same shell-level pop semantics as the legacy chrome).
- Given the user is in-game and taps the dove icon in the toolbar, the UI opens the Diplomacy panel as a full-page screen.
- Given the Diplomacy panel is open, it lists only discovered factions, grouped as Great Powers, Minor Nations, Tribes; GPs sorted by military power then province count.
- Given a faction row, the panel shows current relation state (Peace/War) and the **one-word relation state** (Hostile, Unfriendly, Cordial, Friendly) derived from the hidden score per SPEC/game/diplomacy.md § Player-facing relation display; it does **not** show the numeric relation score. For Minor/Tribe it shows overture stage. For Great Powers it shows the **power comparison percentage** (see § Power comparison percentage) instead of the absolute score: `+N%` rendered in `--danger` (red) when the GP is stronger than the human player, `0%` or `−N%` rendered in `--success` (green) when the GP is at or below the human player's score. To the right it shows only valid diplomatic actions for that faction.
- Given a Great Power row where `gpPowerScore = 110` and `playerPowerScore = 100`, when the row is rendered, then the power-comparison text is `+10%` and the text color resolves to `--danger` (red) per § Power comparison percentage.
- Given a Great Power row where `gpPowerScore = 78` and `playerPowerScore = 100`, when the row is rendered, then the power-comparison text is `−22%` (using the U+2212 minus sign) and the text color resolves to `--success` (green) per § Power comparison percentage.
- Given a Great Power row where `playerPowerScore = 0`, when the row is rendered, then the percentage computation uses `max(playerPowerScore, 1)` so no division-by-zero error occurs and a finite percentage value is shown.
- Given the user taps an action button, the UI shows a **confirmation dialog** with the action name and target faction. Tapping "Confirm" in the dialog submits the diplomatic order; tapping "Cancel" dismisses without submitting.
- Given the user has **already submitted** a diplomatic order for a (player, target, order type) combination, when the panel renders the action button for that order type toward that target, the button label shows **"Cancel"** and the action is **not shown** again in the suggested actions list for that faction.
- Given the user has a pending diplomatic order toward a target faction, when the user taps the **"Cancel" button** for that pending order, the UI removes that order from the current turn's order set (toggle off) and the action reappears as a suggested action for that faction.
- Given the user taps an action that requires parameters (amount or overture stage), the UI shows the **parameter dialog** first; after parameters are set, the **confirmation dialog** appears; on "Confirm" the order is submitted; on "Cancel" it is dismissed.
- Given the user opens the Grant Aid parameter dialog, when they use only the stepper controls, then the amount changes in steps of **£1000**, starts at **£1000**, and cannot go below **£1000** or above **treasury**.
- Given the user opens the Set Subsidy parameter dialog, when they use only the stepper controls, then the amount changes in steps of **£100**, starts at **£1000**, and cannot go below **£100** or above **treasury**.
- Given the human player has an active subsidy in `Game.subsidyStates` paying the row’s faction, when the Diplomacy list row renders, then it shows that ongoing **£/turn** amount on the row (outgoing from the player).
- Given the human player has queued `grantAid` toward the row’s faction in the current turn’s orders, when the list row renders, then it shows a **pending grant** line with that amount until the order is removed or the turn resolves.
- Given the human player has an embassy toward a Minor Nation or Tribe and trade-agreement commodity capacity applies per [diplomacy-resolution.md](../program/diplomacy-resolution.md) (`tradeSlotsForGp`: **0** without embassy, **3** with embassy baseline, **6** with embassy when the human GP has **`trade_fairs`** unlocked), when the UI surfaces trade or economic copy that depends on that capacity, then the UI layer reflects **per-agreement commodity-slot** semantics (not a binary 0/1 “trade on/off” model).
- Given the diplomacy panel is open with at least one non-empty faction group, when a section heading widget is rendered for that group, then the heading text color resolves to `--accent` per the editorial-monocle palette in [pixel-art-ui-catalog.md](pixel-art-ui-catalog.md), and its container exposes a 2 px bottom border in `--accent-dim`.
- Given the diplomacy panel is open and at least one Great Power row is rendered, when the GP type badge is inspected, then its background resolves to `--accent-dim` and its foreground resolves to `--bg-deep` from the editorial-monocle palette (no Material primary or `Colors.blue` chrome).
- Given the diplomacy panel is open and at least one Minor Nation row is rendered, when the Minor type badge is inspected, then its background resolves to `--muted` and its foreground resolves to `--bg-deep` from the editorial-monocle palette (no Material grey chrome).
- Given the diplomacy panel is open and at least one Tribe row is rendered, when the Tribe type badge is inspected, then it renders as an outlined chip: transparent background, 1 px `--muted` border, foreground text color `--muted` (no Material orange chrome).
- Given the diplomacy panel is open and a faction row is rendered, when the row chrome is inspected, then it paints a vertical `linear-gradient(180deg, --bg-deep, --surface)` background and a 1 dp solid border in `--border`; the row does **not** wrap a `CtPanel` (nine-patch) frame, matching `.faction-row` in [mockups/GAME30001-diplomacy-panel.html](mockups/GAME30001-diplomacy-panel.html).
- Given the diplomacy panel is open and at least one faction row is rendered, when the row's relation state chip is inspected for a row whose `DiplomacyRelation.atWar` is `true`, then the chip label is the uppercase string `WAR`, the foreground text color resolves to `--danger`, and the chip background is a translucent warm-red overlay derived from the `--danger` hue (mockup token `oklch(40% 0.06 20 / 0.4)`).
- Given the diplomacy panel is open and at least one faction row is rendered, when the row's relation state chip is inspected for a row whose `DiplomacyRelation.atWar` is `false`, then the chip label is the uppercase string `PEACE`, the foreground text color resolves to `--success`, and the chip background is a translucent cool-green overlay derived from the `--success` hue (mockup token `oklch(40% 0.06 150 / 0.2)`).
- Given the diplomacy panel is open and a faction row has a valid `Declare War` action button, when the action button is inspected, then its label text color resolves to `--danger` and its outer outline resolves to `--danger` per [mockups/GAME30001-diplomacy-panel.html](mockups/GAME30001-diplomacy-panel.html) `.f-actions button.war-btn`. The non-war action buttons (`Offer Peace`, `Alliance`, `Establish Overture`, `Grant Aid`, `Set Subsidy`) keep the standard `--accent-dim` label.
- Given the diplomacy panel is open with default state, when the bottom mode bar is inspected, then the "All" filter button is active (text in `--accent`, `--accent-dim` border) and the other two ("Great Powers only", "Minors only") render as inactive (text in `--muted`, no accent border).
- Given the user taps "Great Powers only" in the mode bar, when the list re-renders, then only Great Power rows are visible — no Minor Nation or Tribe rows are present in the rendered widget tree.
- Given the user taps "Minors only" in the mode bar, when the list re-renders, then both Minor Nation and Tribe rows are visible (using their normal section headings) and no Great Power rows are present in the rendered widget tree.

- **Diplomacy Detail — open via full-page route:** Given the Diplomacy panel is open and shows at least one faction row, when the user taps that row (or its Details affordance), then the UI layer emits `NavigateToRouteEvent(Routes.diplomacyDetail, { game, humanPlayerId, factionId, factionDisplayName, kind, relation })` so the shell pushes `DiplomacyDetailScreen` as a full-page route (never an in-panel overlay).
- **Diplomacy Detail — history contents:** Given the Diplomacy Detail view is open for Great Power `A` and faction `B`, when the UI renders the history panel, then it shows all and only those `DiplomaticEvent` entries from the Game’s diplomatic history whose `participants` include both `A` and `B`, ordered by newest first (highest `turn`, then highest `intraTurnIndex`).
- **Diplomacy Detail — year and turn:** Given a `DiplomaticEvent` in the history panel, when the UI renders its timestamp, then it shows a year label derived from the event’s `turn` using the game calendar mapping and includes the raw turn number in parentheses (e.g. `1505 (Turn 12)`).
- **Diplomacy Detail — unknown faction substitution:** Given a `DiplomaticEvent` in the history panel that involves a third faction `C` that is not discovered by the current player, when the UI renders that event, then the faction `C` is shown as `Unknown faction` while `A` and `B` (if discovered) are shown by their normal display names.
- **Diplomacy Detail — dossier subpanel:** Given the Diplomacy Detail view is open for Great Power `B` (and the current player controls Great Power `A`), when the UI renders the dossier subpanel, then it shows dossier sections for `B` per SPEC/ai/ai-dossier.md using only PlayerView-safe data and does not expose hidden agenda values directly.

- **Faction row wide layout:** Given the Diplomacy panel is open at a viewport width strictly greater than `kDiplomacyRowNarrowMaxWidth` (500 dp), when a faction row renders, then the row body uses a `Row` whose first child is an `Expanded` containing the info column and whose trailing sibling is the action-button `Wrap`, matching `.faction-row { display:flex; align-items:flex-start }` from [mockups/GAME30001-diplomacy-panel.html](mockups/GAME30001-diplomacy-panel.html).
- **Faction row narrow wrap:** Given the Diplomacy panel is open at a viewport width `≤ kDiplomacyRowNarrowMaxWidth` (500 dp), when a faction row renders, then the row body uses a `Column` whose first child is the info column and whose second child is the action-button `Wrap` aligned to the leading (left) edge, matching the mockup `@media (max-width: 500px)` rule `.faction-row { flex-wrap:wrap }` + `.f-actions { justify-content:flex-start }`.
- **Faction row narrow does not right-align actions:** Given the Diplomacy panel is open at viewport width `≤ kDiplomacyRowNarrowMaxWidth`, when a faction row renders, then no `Expanded(child: info)` + sibling action cluster `Row` arrangement is present in the row body (so the action buttons never render trailing-edge anchored under the narrow rule).

- **Mobile-viewport Widgetbook story renders narrow rows:** Given the Diplomacy Panel `Mobile viewport — narrow rows (≤ 500 dp)` Widgetbook use case is mounted in a `WidgetTester`, when the builder pumps inside the shared 360 × 640 dp `mobileViewport` frame, then `WidgetTester.takeException()` returns `null` and at least one faction-row body keyed `${kDiplomacyRowBodyKeyPrefix}<factionId>` is a `Column` (the `≤ 500 dp` narrow variant per § Responsive layout), demonstrating the responsive contract is reviewable from Widgetbook without resizing the host window (Refs #2870 R22 / S9).

- **Empty-state Widgetbook story renders no-factions copy:** Given the Diplomacy Panel `No factions discovered (empty state)` Widgetbook use case is mounted in a `WidgetTester` under `AppThemes.editorialMonocle`, when the builder pumps the fixture `Game` whose human player has no other discovered factions and no diplomacy relations, then `WidgetTester.takeException()` returns `null`, `buildDiplomacyRows` returns an empty list, `find.text('No other factions discovered yet.')` resolves to exactly one widget (the localized `diplomacy_panel_noFactions` copy), and no `_DiplomacySectionHeader` widget is in the tree (so the panel does not paint a `Great Powers` / `Minor Nations` / `Tribes` heading when no factions are discovered). Refs #2863 S7.
