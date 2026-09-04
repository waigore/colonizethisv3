# Diplomacy Panel

**Screen ID:** `GAME30001` — stable; do not reassign.
**SPEC/ui** — Full-page diplomacy screen. Implementation: `app/lib/features/game/screens/diplomacy/diplomacy_screen.dart`.
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

A **Great Power** or **Minor Nation** is **discovered** for the human player when its id appears in the canonical discovery set produced by `knownDiplomaticTargetFactionIds` (`packages/colonizethis_logic/lib/order_suggestion_api.dart`, normative rules in [order-suggestions.md](../program/order-suggestions.md) § Diplomatic orders (visibility)). For Great Powers and Minor Nations, a faction is discovered when **either** of the following holds:

1. A `DiplomacyRelation` exists between the human player and that faction.
2. The human player has **non-`unknown` tile visibility** (fogged or fully visible) in a province owned by that faction.

At game start same-region (GP–GP, GP–Minor) relations are initialized, so Great Powers and Minor Nations are discovered immediately.

### Tribes require first contact (Refs #3620)

A **Tribe** is **never** surfaced via sea-reachable colonial intel. A Tribe `T` appears in the Tribes section for the human GP `G` only after **first contact**, defined per `(G, T)` pair as **either** of:

1. A persisted `DiplomacyRelation` exists between `G` and `T`, **or**
2. `G` holds **non-`unknown` tile visibility** (fogged or fully visible) in at least one province owned by `T` (the canonical `discoveredTribeIdsForFirstContact` set).

This supersedes the colonial-intel discovery path documented for #3341/#2509: cross-region (GP–Tribe) relations are **not** initialized at game start, and **sea-reachability alone does not surface a Tribe row** even when a tribe colony is sea-reachable from the GP's Old World anchors at turn 0. First contact is per-GP (each GP discovers each Tribe independently) and irreversible (the persisted relation keeps the Tribe row visible even if visibility later decays to fogged/unknown).

As of #3620 the `knownDiplomaticTargetFactionIds` helper **itself** applies the first-contact gate (existing relation or non-`unknown` tile visibility) for **all** consumers — diplomacy panel, order suggestions, and AI declare-war targeting — so sea-reachable colonial intel alone no longer surfaces a Tribe in any diplomatic surface. Colonial intel still drives non-diplomatic prioritization (Explorer explore, AI military scoring) at those call sites.

> **Deferred (tracked by #3620):** persisting GP↔Tribe first-contact relations for **AI** GPs during turn resolution (so AI relation records appear on visibility reveal without app-layer sync, AC-5) remains follow-up work on the same issue. Diplomatic **targeting** for AI GPs is already gated by the shared first-contact helper above.

**First-contact standing.** When a Tribe is discovered before a GP–Tribe relation exists, `syncGpTribeFirstContact` (`applyGpTribeFirstContactRelations` in logic) persists `AT_PEACE`, score `50`, Neutral on the same turn index, and enqueues the first-contact herald (`OVL80001`, [`tribe-first-contact-overlay.md`](tribe-first-contact-overlay.md)). Until sync runs, the panel still surfaces the same default standing for display (`RelationState.atPeace`, score `50`, `RelationLevel.neutral`).

- **List contents:** All GPs (except the player), all Minors, and only Tribes that are discovered (per the rules above).
- **Grouping:** Sections by type — Great Powers, Minor Nations, Tribes.
- **Sort:** Great Powers by **military power** (desc), then by **number of provinces** (desc). Minors and Tribes: implementation-defined (e.g. by name or id).

---

## Top bar (dark editorial-monocle, all viewports)

The diplomacy screen renders its chrome through `CtGameFeatureScreenShell`'s opt-in `topBar` slot so the surrounding `Scaffold` + `SafeArea` + `Column` shell, `GameToUIBusListener`, and ordering of body widgets remain identical to the legacy chrome path. The legacy `CtScreenShell` parchment title bar is **not** used on this surface (R1–R3 of #2863 — full dark editorial-monocle alignment). Composite contract: [`components/ct-game-feature-screen-shell.md`](components/ct-game-feature-screen-shell.md).

- **Component:** `CtTopBar` (`SPEC/ui/pixel-art-ui-catalog.md` § Pixel-art component catalog → `CtTopBar` entry), supplied through the `topBar` slot of `CtGameFeatureScreenShell`. The screen retains `GameToUIBusListener` for live game wiring (default `attachGameToUiListener: true`).
- **Title text:** literal `Diplomacy`. The display font (`Cinzel` / `Iowan Old Style`) and `--accent` text color resolve from the dark editorial-monocle theme `titleMedium` slot per `CtTopBar` defaults.
- **Back affordance:** `CtTopBar.backButtonLabel == 'Map'` so the chevron + muted label read together as `← Map`; `onBackPressed` is unset, deferring to `CtBackButton`'s default `Navigator.maybePop()` behavior (which produces the same shell-level pop semantics as the legacy `CtScreenShell` AppBar back button).
- **Leading icon:** the pixel-art diplomacy icon `assets/icons/32/ui_icon_diplomacy.png` rendered through `StrictAssetIcon` at 18 × 18 logical px, painted between the back affordance and the title (matching the production / technology screens' 18 px convention).
- **Height + chrome:** Fixed `CtTopBar.height` (36 px), filled with `CtGradients.topBarGradient` (matches `--surface-lite → --surface`), capped by a 1 px `EditorialMonoclePalette.accentDim` bottom border. Hard-coded colours are forbidden; all tokens resolve through `EditorialMonoclePalette`.
- **Stable widget key:** the top-bar widget carries `DiplomacyScreen.topBarKey` so widget and e2e tests can locate the dark chrome without coupling to localized strings.

The top bar applies to both wide and narrow viewports; mobile adaptation does not change the top-bar contract.

**Intelligence (trailing):** `CtActionTextButton` **Intelligence** in `GameFeatureScreenTopBar.trailing` opens `GAME30003` via `NavigateToRouteEvent(Routes.intelligence)` (same pattern as Production **Counsel** — not a parallel map shell). A compact numeric badge shows last-turn world + spy-report line count for the human (`LastTurnIntelligenceDigest.lineCountForObserver`). Badge `0` still shows the control. Spec: [intelligence-council.md](intelligence-council.md).

---

## Section headings

Faction rows are grouped into three sections in this order: **Great Powers**, **Minor Nations**, **Tribes**. Each section heading is **always rendered** (subject to the mode-bar filter — see § Mode bar (filter)), **even when the section has no rows**. This decouples heading visibility from discovery so the player always sees the three faction categories and understands that more factions may appear (notably Tribes, which are discovered during play). Each heading is rendered per [mockups/GAME30001-diplomacy-panel.html](mockups/GAME30001-diplomacy-panel.html) `.section-head`:

- Display font (`Cinzel` / `Iowan Old Style` per [pixel-art-ui-catalog.md](pixel-art-ui-catalog.md) § Editorial-monocle palette font stacks); `font-weight: 600`; small positive letter-spacing.
- Text color `--accent`.
- 2 px bottom border in `--accent-dim` spanning the heading container width.
- **First-heading top rhythm (Refs #3621):** every section heading carries a leading top gap (mockup `.section-head { margin-top: clamp(10px,2vh,16px) }`) **except** the first heading rendered in the list, which has **zero** top gap (mockup `.section-head:first-child { margin-top: 0 }`). "First" is the first section heading actually emitted under the active mode-bar filter (e.g. with `Great Powers only` the `Great Powers` heading is first; with `Minors only` the `Minor Nations` heading is first). The implementation exposes a `_DiplomacySectionHeader.isFirst` flag set from the panel so the top padding resolves to `0` for the first heading and `CtSpacing.l` for the rest.

The heading is otherwise an inert label (no tap target).

### Empty-section placeholder copy

When a visible section has no rows, the panel renders a single muted-italic placeholder line beneath the heading (matches the mockup `.empty` style — `--muted` colour, italic). The copy is:

| Section | Empty placeholder copy (l10n key) |
|---------|-----------------------------------|
| Great Powers | `No Great Powers discovered yet.` (`diplomacy_panel_noGreatPowers`) |
| Minor Nations | `No Minor Nations discovered yet.` (`diplomacy_panel_noMinorNations`) |
| Tribes | `No tribes contacted yet.` (`diplomacy_panel_noTribes`) |

In practice the Great Powers and Minor Nations sections are populated from game start (same-region relations are initialized), so their placeholders are edge-case fallbacks; the Tribes placeholder is the common case until first tribe contact. The previously documented single global empty message (`diplomacy_panel_noFactions`) is superseded by these per-section placeholders.

---

## Per-faction row

- **Row chrome (editorial-monocle dark theme):** Each faction row is a flat-bordered tile per [mockups/GAME30001-diplomacy-panel.html](mockups/GAME30001-diplomacy-panel.html) `.faction-row` — **vertical** `linear-gradient(180deg, --bg-deep, --surface)` background, 1 px `--border` outline, 4 px vertical gap between consecutive rows, minimum content height ~48 dp. On hover the outline transitions to `--accent-dim` (`transition:border-color .15s` in the mockup; in Flutter, a `MouseRegion` + `StatefulWidget` swap is acceptable — the **visible target** is the resolved border color). Touch devices that do not emit hover events render the row in its idle state. Nine-patch `CtPanel` chrome is **not** used for diplomacy rows because the mockup uses a sharp 1 px border, not the brass nine-patch frame.
- **Left:** Faction name (displayName or id), type badge (GP / Minor / Tribe), current **diplomatic state**: relation state (AT_PEACE / AT_WAR) rendered via the **relation state badge** (see § Relation state badge), **one-word relation state** (Hostile / Unfriendly / Cordial / Friendly) derived from the hidden relation score per [diplomacy.md](../game/diplomacy.md) § Player-facing relation display. The numeric relation score is **not** shown. For Minor/Tribe: overture stage (none, Trade Consulate, Embassy, NAP, Join Empire) if any. For **Great Powers:** a **relative power line** is shown below the header — a derived display only, not a new data field. See **Relative power line (Great Power rows only)** below.
- **Type badge colors (editorial-monocle dark theme):** The type badge uses mono font and the canonical [pixel-art-ui-catalog.md](pixel-art-ui-catalog.md) § Editorial-monocle palette tokens per [mockups/GAME30001-diplomacy-panel.html](mockups/GAME30001-diplomacy-panel.html) `.f-badge`. Great Power rows use `--accent-dim` background with `--bg-deep` foreground; Minor Nation rows use `--muted` background with `--bg-deep` foreground; Tribe rows are **outlined** — transparent background, `--muted` border and `--muted` foreground. No hardcoded Material chrome colors are permitted.
- **Outgoing economic diplomacy (list row only):** On the **same row**, below the relation line, when the human Great Power has **active or pending** economic diplomacy toward this faction (receiver-centric copy): **Active subsidy:** `Outgoing subsidy: {percent}% to {displayName}` when `Game.subsidyStates` has `payerId` = human GP and `targetId` = this row’s faction (percent model, 5–20 step 5 — Refs #3753 R3). **Pending grant:** `Pending grant aid: £N (resolves end of turn)` when current-turn orders include `grantAid` toward this faction. **Pending subsidy:** `Pending subsidy: {percent}% (resolves end of turn)` when current-turn orders include `setSubsidy` toward this faction (`amount` carries the subsidy percentage). Omit each line when not applicable. Do **not** duplicate this block on the Diplomacy Detail screen for current product (list row is the source of truth). Hover or long-press (`Tooltip`) on an active or pending subsidy percent line exposes `subsidyFillPriceConsequenceTooltip` (same buy/sell fill meaning as `DIPL20001` Effect, plus no per-turn gold charge; Refs #4546). Compact row text stays the percent line only.
  - **Styling (Refs #3621):** all three economic lines (active subsidy, pending grant, pending subsidy) render with the **mono** font stack (`monospace` family, `Courier` fallback), the `--accent-dim` foreground token, and **non-italic** weight, matching the mockup `.f-subsidy` treatment (`font-family: var(--font-mono); color: var(--accent-dim)`). The earlier italic `bodySmall` / `colorScheme.tertiary` styling for the pending lines is superseded — pending and active lines share one compact mono `--accent-dim` style so the block reads uniformly.
- **Right:** **Diplomatic action buttons** for the player toward that faction. The panel enumerates the full action matrix per faction type via `enumerateDiplomaticPanelActionsForTarget` (`packages/colonizethis_logic/lib/order_suggestion_api.dart`), probing each candidate with the same incremental diplomatic validator used for order submission. **Default row surface (Refs #4265):** only **validator-enabled** actions and any **pending** action (shown as **Cancel**) render on the row by default. Disabled actions that are not pending are **not** shown until the player expands **More actions** for that row. **More actions:** when at least one disabled non-pending action remains in the matrix, a per-row **More actions** control appears on the default cluster. Tapping it toggles local UI state (while the panel stays open) to reveal the remainder of the matrix; each hidden disabled action shows its validator `rejectionReason` **inline** beneath the button (mono, `--muted`, compact) in addition to the existing `Tooltip`, so touch users can read gates without long-press. When expanded, the control label reads **Fewer actions** and collapses the hidden cluster. When every applicable action is either enabled or pending, **no** More control is shown. Matrix per faction type:
  - **Great Power row:** Declare War, Offer Peace, Alliance **or** Break Alliance (mutually exclusive treaty slot — see § Alliance slot), Establish Overture stages (Consulate, Embassy, NAP, Join Empire as separate buttons), Establish Favored partner, Grant Aid, Set Subsidy, Boycott, Revoke Boycott.
  - **Minor Nation / Tribe row:** Declare War, Offer Peace, Establish Overture stages (Consulate, Embassy, NAP, Join Empire), Grant Aid, Set Subsidy.
  - **Enabled** when the probe accepts; **disabled** with rejection reason when it rejects (hidden under More by default). Pending orders still replace the matching button with a **Cancel** affordance on the default row per § Submitting an action.
  - **Boycott / Revoke Boycott (Great Power rows only; Refs #3753 R6 / R14 / S14):** the colony-trade embargo controls are enumerated only on **Great Power** rows (the boycott target is always another Great Power), never on Minor/Tribe rows. Their enabled state is validator-driven (`boycottSubValidator` / `revokeBoycottSubValidator`), so the buttons render disabled with rejection text when the precondition fails: **Boycott** is enabled only when the human Great Power **holds at least one colony** (`Game.colonyStates` with `colonyOfGpId == human`), the pair is at peace, and no boycott for the `(human, target)` pair already exists; **Revoke Boycott** is enabled only when an active boycott for the `(human, target)` pair exists. At most one of the two is ever enabled for the same target. A queued (pending) `boycott` or `revokeBoycott` order replaces its button with the shared **Cancel** affordance per § Submitting an action.

### Relative power line (Great Power rows only)

Replaces the previously displayed absolute **power score** per [diplomacy.md](../game/diplomacy.md) § Great Power power score with a labelled relative comparison to the human player. **Derived display only** — no new data field is required; both inputs are read from the existing `greatPowerPowerScore` source already consumed by the diplomacy panel rows.

- **Placement:** A dedicated line rendered **between the faction header row** (name + GP badge) and the relation row — **not** inside the header. The header carries only the faction name and the type badge. The same line is shared with the Diplomacy Detail screen ([diplomacy-detail-screen.md](diplomacy-detail-screen.md) § Current relation) via one widget so styling stays consistent across both surfaces.
- **Structure:** `Relative power: +22% · Superior` — a muted prefix, the signed percentage, a middle-dot (`·`, U+00B7) separator, and the tier word.
- **Formula:** `pct = round(((gpPowerScore - playerPowerScore) / max(playerPowerScore, 1)) * 100)`.
- **Percentage format:** `+N%` when `pct > 0`, `−N%` when `pct < 0`, `0%` when `pct == 0`. Use the unicode minus sign `−` (U+2212), not the ASCII hyphen-minus, to match the mockup. Rendered **semibold**.
- **Prefix:** localized **`Relative power:`** in `--muted`, normal weight, sized at or below the percentage.
- **Color:** The percentage **and** the tier word share one color — red (`--danger`) when the GP is stronger than the player (`pct > 0`); green (`--success`) when the GP is weaker or equal (`pct ≤ 0`, including `0%`). Preserves the red/green semantic from the prior absolute-score display. The prefix and separator stay `--muted`.
- **Tier word (always shown):**

  | `pct` range | Tier label |
  |-------------|------------|
  | `−10 … +10` | Roughly equal |
  | `+11 … +30` | Superior |
  | `≥ +31` | Vastly superior |
  | `−30 … −11` | Inferior |
  | `≤ −31` | Vastly inferior |

  Boundaries are inclusive on the side shown: `+10` → Roughly equal, `+11` → Superior; `+30` → Superior, `+31` → Vastly superior; `−10` → Roughly equal, `−11` → Inferior; `−30` → Inferior, `−31` → Vastly inferior; `0%` → Roughly equal (green). Extreme values when `playerPowerScore` is near zero (e.g. `+4900%`) map to Vastly superior with no cap. The tier is a **display-only** label and never feeds AI war-desire or any logic-package model.
- **Zero-player guard:** `max(playerPowerScore, 1)` so a player at score 0 still yields a finite percentage (no division-by-zero).
- **Wrap:** At narrow viewports (≤ 500 dp, down to the 320 dp minimum) the line wraps to additional lines; it is **never** truncated with `TextOverflow.ellipsis`.
- **Tooltip / accessibility:** The line carries a `Tooltip` (long-press / hover) explaining that the value compares the target GP's military power score (provinces, army strength, ships per [diplomacy.md](../game/diplomacy.md) § Great Power power score) to the human player's, plus a `semanticsLabel` combining the prefix, percentage, and tier for screen readers.

Tapping anywhere on a faction row (or an explicit “Details” affordance in that row) opens the **Diplomacy Detail** screen for that faction (GAME30002), scoped to the current player’s Great Power. See [Diplomacy Detail navigation](#diplomacy-detail-view-per-faction) below.

---

## Relation state badge

Each faction row renders the AT_PEACE / AT_WAR state as a small mono-font chip preceding the one-word relation label, per [mockups/GAME30001-diplomacy-panel.html](mockups/GAME30001-diplomacy-panel.html) `.f-relation .state`:

- **Label:** uppercase `WAR` when the relation is `atWar`, otherwise `PEACE`.
- **Chrome:** mono font, font-size 9 sp, padding 1 dp top/bottom × 5 dp left/right, square 1 dp corners (`border-radius: 1px`), 4 dp gap before the relation word.
- **War variant:** translucent warm-red overlay background derived from the canonical `--danger` token (the mockup uses `oklch(40% 0.06 20 / 0.4)`, which is the danger hue desaturated and alpha-tinted at 0.40); foreground text `--danger`.
- **Peace variant:** translucent cool-green overlay background derived from the canonical `--success` token (the mockup uses `oklch(40% 0.06 150 / 0.2)`, which is the success hue desaturated and alpha-tinted at 0.20); foreground text `--success`.
- **Forbidden:** raw `Colors.red`, `Colors.green`, or any Material chrome background. The badge resolves background and foreground from the editorial-monocle palette only.

### Formal alliance indicator (Refs #3625)

A **formal alliance** (treaty) between the human Great Power and another Great Power is a persisted state distinct from the informal relation score. It is recorded on `DiplomacyRelation.formalAlliance` (set when an `Alliance` order resolves — `allianceFormed` — and cleared on `allianceBroken`, e.g. a Call to Arms refusal) per [diplomacy.md](../game/diplomacy.md) § Alliances and [diplomacy-resolution.md](../program/diplomacy-resolution.md). Because the player-facing relation display only ever shows the one-word band label (`Hostile` / `Unfriendly` / `Cordial` / `Friendly`) and **never** the word "Allied", a high relation score alone must not read as a treaty. The panel therefore surfaces an explicit alliance badge so the player can distinguish a formal mutual-defence treaty from merely-Friendly relations.

- **Trigger:** rendered **only** when the row's `DiplomacyRelation.formalAlliance` is `true`. A row whose relation is in the informal `RelationLevel.allied` band (score 76–100) but with `formalAlliance == false` shows **no** alliance badge. Formal alliances are GP↔GP only, so the badge appears only on Great Power rows in current product.
- **Placement:** a compact mono chip rendered on the relation line, immediately after the WAR/PEACE relation state badge and before the one-word relation label, with a 4 dp gap on each side.
- **Label:** uppercase `ALLIANCE` (library-scope constant `kDiplomacyAllianceBadgeLabel` so widget tests pin a single source). The label is intentionally **not** the relation-band word, so it cannot be confused with the informal `Friendly` label.
- **Chrome:** mono font, font-size 9 sp, padding 1 dp top/bottom × 5 dp left/right, square 1 dp corners — matching the `WAR`/`PEACE` relation state badge chrome. Foreground text resolves to `--accent` (`EditorialMonoclePalette.accent`); background is a translucent accent overlay derived from the accent hue (`oklch(40% 0.06 85 / 0.30)`) so the gold treaty chip reads as distinct from both the translucent cool-green `PEACE` chip and the italic green `Friendly` word.
- **Forbidden:** raw Material chrome colors; reusing the relation-band word to imply a treaty; rendering the badge when `formalAlliance` is `false`.

#### Formal alliance indicator acceptance criteria (Refs #3625)

- **Alliance badge shown for a formal alliance:** Given a faction row whose `DiplomacyRelation.formalAlliance` is `true`, when the relation line renders, then exactly one alliance badge with label `kDiplomacyAllianceBadgeLabel` (`ALLIANCE`) is present on that row, its foreground text color resolves to `EditorialMonoclePalette.accent`, and it renders after the WAR/PEACE relation state badge.
- **Alliance badge absent without a formal alliance (negative):** Given a faction row whose relation score is in the informal `RelationLevel.allied` band (e.g. score `90`) but whose `DiplomacyRelation.formalAlliance` is `false`, when the relation line renders, then no alliance badge (`kDiplomacyAllianceBadgeLabel`) is present and the row still shows the one-word `Friendly` relation label.
- **Alliance badge is distinct from the relation word:** Given a formally-allied faction row, when the relation line renders, then the alliance badge text equals `ALLIANCE` and is a separate widget from the one-word relation label (`Friendly`), so the treaty indicator never reuses the informal relation band word.

### Relation meter (Refs #3753 R13)

The relation line renders a **10-step gradient meter** ([`RelationMeter`](components/relation-meter.md)) between the WAR/PEACE relation state badge (and the optional `ALLIANCE` badge) and the one-word ladder label. The meter is the player-facing representation of the hidden decimal relation score; the numeric score is never shown. See [`SPEC/ui/components/relation-meter.md`](components/relation-meter.md) for the bar layout, indicator, and OKLCH gradient.

The relation line is laid out as a `Wrap` (state badge → optional `ALLIANCE` badge → meter → label) with a `CtSpacing.s` run spacing, so on a narrow info column (e.g. a formal-alliance row at the 320 dp minimum viewport) the cluster flows onto a second run instead of overflowing; the label still ellipsizes within the column width.

### Relation word styling

The one-word relation label rendered after the meter is the 10-word ladder word for the score's meter step (`relationScoreToDisplayLabel`, e.g. `Hostile` / `Distrustful` / `Neutral` / `Devoted`), styled per the mockup [mockups/GAME30001-diplomacy-panel.html](mockups/GAME30001-diplomacy-panel.html) `.f-relation .word` (`font-style: italic`):

- **Weight / slant:** the relation word renders **italic** on the `bodySmall` text slot. The gap before the word is provided by the `Wrap` spacing; the optional overture clause (`· {stage}`) stays `--muted`, non-italic.
- **Per-step color:** the relation word color is resolved by `diplomacyRelationWordColor(score)`, which returns `relationMeterStepColor(relationScoreToMeterStep(score))` — the same red → green OKLCH ladder used by the meter indicator (Refs #3753 R13.3). Step 1 reuses the canonical `--danger` token and step 10 reuses `--success`, preserving the warm-red / cool-green semantic shared with the relation state badge; intermediate steps interpolate hue/chroma at the AA-tuned `L = 0.62` through the shared `oklchToColor` converter — not raw Material colors. The inline word and the meter indicator always read in the same hue.
- **Forbidden:** rendering the relation word in `--muted` (the prior plain `bodySmall` styling) or with any hardcoded Material color.

### Diplomatic standing chip cluster (Refs #3753 R12)

The single inline overture-stage clause (`· {stage}`) previously appended to the relation word on Minor/Tribe rows is **replaced** by a compact chip cluster rendered on its own run **under** the relation line (`DiplomacyStandingChipCluster`). The cluster lists every active diplomatic overture/treaty/economic state for the row's faction as small mono chips, reusing the relation-state / alliance-badge chrome tokens (no new palette tokens, no Material chrome). When a faction has **no** active standing chips the cluster renders nothing (zero layout footprint), so a fresh discovered faction at overture stage `none` is unchanged.

- **Overture / treaty chips (accent overlay, `--accent` text — alliance-badge chrome):** the cumulative overture milestones reached, derived from the row's `OvertureState.stage` (linear `none < tradeConsulate < embassy < nap < joinEmpire`): `Consulate` when `stage ≥ tradeConsulate`, `Embassy` when `stage ≥ embassy`, `NAP` when `stage ≥ nap`. The terminal-stage chip differs by faction kind: `Join Empire` for a **Minor** at `stage == joinEmpire`; `Colony` for a **Tribe** that is a colony of the human Great Power (`Game.colonyStates` with `colonyOfGpId == humanPlayerId`), regardless of the underlying stage. A Tribe colony therefore reads e.g. `Consulate · Embassy · NAP · Colony`.
- **Formal alliance:** GP↔GP formal alliances continue to use the existing `DiplomacyAllianceBadge` on the relation line (§ Formal alliance indicator); the cluster does **not** duplicate a formal-alliance chip.
- **Active subsidy:** the human Great Power's outgoing subsidy to this Minor/Tribe continues to render on its dedicated `Outgoing subsidy: N%` line (§ Per-faction row → Outgoing economic diplomacy); it is **not** also duplicated as a cluster chip.
- **Boycott chips (danger overlay, `--danger` text — relation-state WAR chrome):** rendered only on **Tribe** rows that are a colony.
  - For a Tribe that is a colony of the **human** Great Power, one `Boycott vs {GP}` chip per `Game.boycottStates` whose `gpId == humanPlayerId` (the boycotts the human has imposed through this colony), where `{GP}` is the boycotted target GP's display name.
  - For a Tribe that is a colony of **another** Great Power `X`, one `Boycotted by {GP}` chip when a `BoycottState` exists with `gpId == X` and `targetGpId == humanPlayerId` (the human is barred from trading with `X`'s colony), where `{GP}` is `X`'s display name.
- **Overseas holdings chip (success overlay, `--success` text — relation-state PEACE chrome):** shown only on Minor/Tribe rows when the human Great Power owns at least one purchased tile sourced from that faction's provinces. The chip reads `Overseas: N · S%` where `N` is the count of `PurchasedTileIndex` attributions with `owningGpId == humanPlayerId` and `sourceFactionId == factionId`, and `S` is the human's overseas tile-owner share rate for that faction rounded to the nearest integer percent — equal to the decimal relation score (per [world-market-first-right-of-refusal.md](../game/world-market-first-right-of-refusal.md) R8.2 tile-owner share `relationScore / 100`). When the count is zero the chip is omitted.
- **Chrome:** each chip uses mono font, font-size 9 sp, padding 1 dp top/bottom × 5 dp left/right, square 1 dp corners — matching the WAR/PEACE/ALLIANCE badge chrome. The cluster is a `Wrap` (`CtSpacing.s` spacing / `CtSpacing.xs` run spacing) so it flows onto additional runs on narrow info columns rather than overflowing.
- **Labels:** the overture/colony chip labels (`Consulate`, `Embassy`, `NAP`, `Join Empire`, `Colony`) and the boycott/overseas prefixes are library-scope constants, mirroring the non-localized `WAR` / `PEACE` / `ALLIANCE` badge-label convention.

#### Diplomatic standing chip cluster acceptance criteria (Refs #3753 R12)

- **Colony tribe surfaces Colony + Embassy chips:** Given a Tribe row whose faction has a `Game.colonyStates` entry with `colonyOfGpId` equal to the human Great Power and an `OvertureState.stage` of at least `embassy`, when the row renders, then the standing chip cluster contains exactly one `Colony` chip and one `Embassy` chip and does not contain a `Join Empire` chip.
- **Imposed boycott surfaces a vs chip:** Given a Tribe that is a colony of the human Great Power and a `Game.boycottStates` entry with `gpId` equal to the human Great Power and `targetGpId` equal to GP `X`, when the Tribe row renders, then the cluster contains a `Boycott vs {display name of X}` chip.
- **Foreign colony boycott surfaces a Boycotted by chip (Refs #3753 R12 / S17):** Given a Tribe that is a colony of Great Power `X` (not the human) and a `Game.boycottStates` entry with `gpId == X` and `targetGpId == humanPlayerId`, when the Tribe row renders, then the cluster contains a `Boycotted by {display name of X}` chip and no `Boycott vs` chip for that embargo. Pin: `app/test/diplomacy_standing_chips_test.dart` — `AC: foreign colony boycotting the human yields a "Boycotted by" chip`.
- **Overseas holdings chip reflects tile count and share:** Given a Minor row whose faction has two purchased tiles owned by the human Great Power and a decimal relation score of `80.0`, when the row renders, then the cluster contains an `Overseas: 2 · 80%` chip.
- **Empty standing renders no cluster (negative):** Given a discovered faction with overture stage `none`, no colony, no boycott, no subsidy, and no overseas holdings, when the row renders, then no `DiplomacyStandingChipCluster` chip widget is present and the relation line shows no `· {stage}` clause.
- **Colony Tribe row golden (Refs #3753 R12/R13):** Given the diplomacy panel renders a Tribe row whose faction is a colony of the human Great Power at `OvertureState.stage == embassy`, with an imposed `Boycott vs Castile`, and relation score `60.0`, when the row is captured to `goldens/diplomacy_panel_colony_tribe_row.png` under `AppThemes.editorialMonocle`, then the golden matches and the structural finders resolve a `Colony` chip, an `Embassy` chip, a `Boycott vs Castile` chip, and at least one `RelationMeter`.
- **Subsidized Minor row golden (Refs #3753 R3/R8/R12):** Given the diplomacy panel renders a Minor row (`Bavaria`) with an active 10% outgoing subsidy and two human-owned purchased tiles sourced from that Minor at relation score `80.0`, when the row is captured to `goldens/diplomacy_panel_subsidized_minor_row.png` under `AppThemes.editorialMonocle`, then the golden matches and the structural finders resolve the `Outgoing subsidy: 10% to Bavaria` line and an `Overseas: 2 · 80%` chip.
- **Standing-chips Widgetbook stories render (Refs #3753 R12):** Given the `Diplomatic Standing Chips` Widgetbook use cases (`Colony Tribe (treaty + Colony + Boycott vs)`, `Minor overseas holdings (Overseas chip)`, `Empty standing (no chips, zero footprint)`) are each mounted in a `WidgetTester` under `AppThemes.editorialMonocle`, when each builder pumps, then `WidgetTester.takeException()` returns `null`; the colony story shows `Colony`, `Embassy`, and `Boycott vs Castile` chips; the overseas story shows an `Overseas: 2 · 80%` chip; and the empty story renders no `Wrap` (zero layout footprint).

---

## Mode bar (filter)

A bottom filter bar lets the player narrow the visible faction list. The bar is anchored to the bottom of the diplomacy panel with a top divider; buttons use mono font with inactive label `--muted`, active/hover label `--accent`, and `--accent-dim` border on the active item per [mockups/GAME30001-diplomacy-panel.html](mockups/GAME30001-diplomacy-panel.html) `.mode-bar`.

### Mode-bar chip chrome (Refs #3621)

Each filter chip (`_DiplomacyModeButton`) renders the mockup `.mode-bar button` surface, not a bare label:

- **Background:** the compact action gradient (`--surface-lite → --bg-deep`, sourced from `CtGradients.actionButtonGradient`), matching mockup `.mode-bar button { background: linear-gradient(180deg, var(--surface-lite), var(--bg-deep)) }`.
- **Border:** a 1 px border present in **all** states — `--border` (`EditorialMonoclePalette.border`) when **inactive**, `--accent-dim` (`EditorialMonoclePalette.accentDim`) when **active** — mirroring the mockup idle `border:1px solid var(--border)` and active `border-color: var(--accent-dim)`. The previous implementation drew no border on the inactive chip; the inactive chip now always carries the `--border` outline.
- **Label:** mono font, `--muted` inactive / `--accent` active, unchanged.

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

All diplomatic actions are **submitted for end-of-turn resolution** — the panel does not resolve orders itself. Orders accumulate in the current turn's order set until Next Turn. **Exception (Refs #3811):** **Break Alliance** on a Great Power row applies **immediately** on confirm via `BreakAllianceImmediatelyEvent` (no pending order, no Cancel toggle).

### Alliance slot (Great Power rows only; Refs #3811)

- When `DiplomacyRelation.formalAlliance == true` at peace, the panel enumerates **Break Alliance** only (destructive styling) — never **Alliance**.
- When `formalAlliance == false` and no post-break bilateral cooldown is active, the panel enumerates **Alliance** only — never **Break Alliance**.
- When `formalAlliance == false` and a post-break bilateral cooldown is active for the pair on the current turn, the panel enumerates a single **Alliance** button in the **disabled** state with rejection text `On cooldown after breaking alliance — available next turn`.
- Informal high relation score / Friendly band alone does **not** swap the slot; only `formalAlliance` drives the treaty action.

### Submitting an action

- **Break Alliance confirm (Refs #4719):** **When** states the treaty ends immediately on confirm. Effect lines state standing hits with the former ally and other Great Powers (no −50/−10 numerals), that until next turn the player cannot offer **Alliance**, **overture**, **Favored Trading Partner**, **Grant Aid**, or **Set Subsidy** toward that court, that **Declare War** and **Offer Peace** remain available this turn, and that the lock clears next turn. Do not claim **Boycott** is blocked; omit raw `allianceBreakCooldowns` / `sinceTurn` field names. Implementation: `_breakAlliance` in `diplomacy_confirm_preview.dart`.
- **Boycott / Revoke Boycott confirm (Refs #4584):** **Boycott** Cost is `No treasury charge.` Effect lines (first-order, no scores, no −50/−10, no raw tribe ids) state that world-market deals between the target GP and the human’s current colony Tribes will not fill in either direction; that the target cannot purchase land, grant aid, or set subsidies toward those colonies; and that subsidies the target already pays those colonies are cancelled when this resolves. Name colony **display names** when there are at most three; otherwise `your colony tribes`. **Revoke Boycott** Cost is the same free line; Effect states the embargo ends so that court may again trade with, purchase land in, and grant aid or subsidies toward those colonies (does not claim cancelled subsidies are restored). Omit **When** (war auto-cancel is not listed). Implementation: `boycottConfirmPreviewLines` / `revokeBoycottConfirmPreviewLines`.
- **Confirm dialog:** Before a parameter-less diplomatic action is submitted, the UI shows a **confirmation dialog** with the action title and a **short structured body** (Refs #4181, #4409, #4586): labelled lines for **Cost** (when a treasury spend or explicit free applies), **Effect** (first-order pair-level outcome, plus **one Effect line per other court** a **Declare War** can pull in), and **When** (only for **Break Alliance**, which ends the treaty immediately on confirm). All other covered actions omit a timing line — end-of-turn Diplomacy phase resolution is the implied default. Copy is first-order only: no hidden relation scores, no point penalties (−50/−10), no province counts on Join Empire, and at most one £ figure when a real spend applies. **Establish Favored partner (Refs #4586):** Cost remains `No treasury charge.` Effect lines state that acceptance makes the pair Favored Trading Partners; that fills between the pair are preferred when they buy or sell the **same good at the same bid rank**; that **prices do not change**; and that this **does not beat First right of refusal**. Do not print the AI relation threshold. Implementation: `favoredTradingPartnerConfirmLines` via `buildDiplomacyConfirmPreviewLines`. Incoming answers use [`favored-trading-partner-dialogue-overlay.md`](favored-trading-partner-dialogue-overlay.md) (`OVL90001`). **Declare War third parties (Refs #4409):** for a Great Power target, one Effect line per other GP that holds a **persisted** formal alliance with the target, is at peace with them, and is **not already at war with the declaring GP** (phase-start snapshot; not same-turn draft `Alliance` orders), sorted by court display name — e.g. `Effect: France holds a formal alliance with Spain and may be called to defend. They may join the war against you or refuse.` For a Minor/Tribe target, one Effect line per other GP with an Embassy or purchased land there (same `gpHasEmbassyOrPurchasedLandInMinorTribe` check as the resolver; no already-at-war skip) — e.g. `Effect: France holds an Embassy or purchased land in Bavaria and may be asked to intervene.` Omit extra lines when nobody qualifies. Do not predict join/refuse. Implementation: `declareWarThirdPartyPreviewLines` appended from `buildDiplomacyConfirmPreviewMessage` in `colonizethis_diplomacy` (re-exported via `colonizethis_logic`), wired from `diplomacy_panel_order_actions.dart`. The same helper strings are reused on `DLG20001` / Military Counsel invade **Declare war?** sub-dialogs. **Grant Aid / Set Subsidy** do **not** use this second confirm: Cost / Effect live on `DIPL20001` and **Submit** commits the pending order (Refs #4415; see [grant-or-subsidy-dialog.md](grant-or-subsidy-dialog.md)).
- **Parameter dialogs:** **Establish Overture** opens the stage parameter dialog first; after the stage is set, the confirmation dialog appears before the order is submitted. **Grant Aid / Set Subsidy:** single dialog (`GrantOrSubsidyDialog`, see [grant-or-subsidy-dialog.md](grant-or-subsidy-dialog.md)) with **stepper-only** entry (no free numeric typing). Dialog titles use **sentence case** (`Grant aid`, `Set subsidy`). **Grant Aid:** step **£1000**, default **£1000**, positive multiples of **£1000** up to treasury; **Submit** only when valid, and **Submit** stages the pending order with no further confirm. **Set Subsidy:** percent step **5%**, default **5%**, range **5–20%** in **5**-point steps (treasury-independent; Refs #3753 R3 / S15); **Submit** only when valid, and **Submit** stages the pending order with no further confirm.
- **Pending state:** After an order is submitted, the corresponding action button for that (player, target, type) is shown with a **"Cancel" label** to indicate the action is pending. The button text changes from the action name to "Cancel" and tapping it **removes the pending order** (toggle off), returning the UI to the pre-submitted state.
- **Toggle logic:** Clicking an action button while the same order is already pending cancels it. The pending state is per `(humanPlayerId, targetFactionId, DiplomaticOrderType)`. If the pending order has parameters (amount, overtureStage), canceling removes the entire order; the user must re-enter parameters to submit again.

### Action button labels (pending state)

| Action | Default | Pending (Cancel) |
|--------|---------|-----------------|
| Declare War | "Declare War" | "Cancel" |
| Offer Peace | "Offer Peace" | "Cancel" |
| Alliance | "Alliance" | "Cancel" |
| Break Alliance | "Break Alliance" | *(immediate — no pending state)* |
| Establish Overture | "Consulate/Embassy/NAP/Join Empire" | "Cancel" |
| Grant Aid | "Grant Aid (£N)" | "Cancel" |
| Set Subsidy | "Set Subsidy (N%)" | "Cancel" |
| Establish Favored partner | "Establish Favored partner" | "Cancel" |

### Action button styling (editorial-monocle dark theme)

Per [mockups/GAME30001-diplomacy-panel.html](mockups/GAME30001-diplomacy-panel.html) `.f-actions button`, all diplomatic action buttons render against a small (compact) variant of the canonical `CtNinePatchButton` brass surface. **Declare War** and **Break Alliance** use the destructive variant per `.f-actions button.war-btn`:

- **Border and text color:** `--danger` (warm-red brass).
- **Background:** unchanged from the standard action button gradient (`--surface-lite` → `--bg-deep`); only the outline and label color shift.
- **Applies to:** `DiplomaticOrderType.declareWar` and `DiplomaticOrderType.breakAlliance`. The pending (Cancel) variant retains its own pending styling and is not the destructive variant.

#### Compact variant metrics (normative)

The diplomacy action button is a **compact** `CtNinePatchButton`: it is materially tighter than the 48 dp / 16 × 12 dp default chrome so the trailing cluster matches the mockup `.f-actions button { padding: 3px 7px }` density. The implementation exposes these as library-scope constants so widget tests can pin them deterministically:

| Metric | Constant | Value | Mockup source |
|--------|----------|-------|---------------|
| Button min height | `kDiplomacyActionButtonMinHeight` | **24 dp** | compact `.f-actions button` |
| Button inner padding | `kDiplomacyActionButtonPadding` | **7 dp horizontal × 3 dp vertical** | `.f-actions button { padding: 3px 7px }` |
| Label font size | `kDiplomacyActionButtonFontSize` | **10 sp** | `.f-actions button { font-size: 8px }` |

**Label typography (Refs #3621).** The action-button label resolves to the editorial-monocle **display** font stack (`editorialMonocleDisplayFontFamily` = `Cinzel`) at the compact `kDiplomacyActionButtonFontSize` (**10 sp**, normative; the mockup density target is `.f-actions button { font-size: 8px; font-family: var(--font-display) }`). The label is seeded from the M3 `bodySmall` slot so weight and colour still flow from `AppThemes.editorialMonocle` (per #2914 S7), but its `fontFamily` and `fontSize` are overridden to this pinned compact display value — it is **not** the unmodified ~12 dp `bodySmall` slot. The smaller display label packs more buttons per trailing-cluster run so the wide cluster extends horizontally. The pending **Cancel** and disabled (rejection-tooltip) states keep their existing semantics on the compact surface.

**Shrink-wrap sizing (Refs #3621).** The diplomacy action button is built with `CtNinePatchButton(shrinkWrap: true)` so the surface sizes to its label width (plus padding) rather than expanding to fill the run width. This is required for the wide-cluster left-to-right flow: the default `CtNinePatchButton` centers its content with a `Center` that grows to the maximum width handed down by the parent, so inside the trailing cluster `Wrap` each button would otherwise occupy the full available run width and the cluster would degrade to one button per run (a vertical column). With shrink-wrap each compact display-font button sizes to its label, so several buttons pack onto each run and the cluster flows horizontally across the available faction-row width, wrapping only at true overflow. `shrinkWrap` defaults to `false` for every other `CtNinePatchButton` call site, preserving their expanding layout.

Orders are submitted into the current turn's order set; resolution happens on Next Turn.

---

## Layout / wireframe

- Full-page: list is scrollable; sections (GPs, Minors, Tribes) with headers.
- Actions shown to the right of each faction row (inline buttons or compact actions). **Current product:** pairwise diplomacy only (human Great Power toward each discovered faction). **Out of scope:** multi-party treaty or coalition UI beyond what pairwise orders already support; not a deferred placeholder—such flows are undefined until specified in GDD/TDD.

---

## Responsive layout

The faction-row body adapts to a single normative breakpoint per [mockups/GAME30001-diplomacy-panel.html](mockups/GAME30001-diplomacy-panel.html) `@media (max-width: 500px)`. The cross-cutting narrative is owned by [mobile-adaptation.md](mobile-adaptation.md) § 4; this section codifies the diplomacy-row specifics.

- **Breakpoint:** viewport width **≤ 500 dp** (Flutter dp; matches the mockup CSS `max-width: 500px` cutoff and the **`≤ 500 dp`** column in mobile-adaptation.md § 4).
- **Wide variant (viewport width `> 500 dp`):** the faction-row body lays out the info column and the action-button cluster **side by side** in a `Row`, with the action cluster anchored to the trailing edge. Matches mockup `.faction-row { display:flex; align-items:flex-start }` plus `.f-actions { justify-content:flex-end }`. The info column sits in an `Expanded` and the trailing cluster sits in a `Flexible` `Align(alignment: Alignment.topRight, …)` so the cluster is bounded **only by the available faction-row width** — there is **no fixed `dp` cap** (the former `kDiplomacyActionClusterMaxWidth` 180 dp cap and its `ConstrainedBox` are removed, Refs #3621). The action `Wrap` uses `WrapAlignment.end` with `kDiplomacyActionWrapSpacing` (**4 dp**, mockup `gap: 4px`) so the compact buttons extend **left-to-right** across the available width and wrap onto a new run **only** once the remaining row width cannot fit the next button (matching the mockup `.f-actions` with its `max-width: 180px` removed). The cluster never stretches into a single premature vertical column.
- **Narrow variant (viewport width `≤ 500 dp`):** the faction-row body stacks the action-button cluster **below** the info column, and the action cluster is **left-aligned**. Matches mockup `.faction-row { flex-wrap:wrap }` plus `.f-actions { max-width:none; justify-content:flex-start }`. The action `Wrap` uses `WrapAlignment.start` (no `maxWidth` cap) at this breakpoint.
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
| Diplomatic action button | Enabled per validator probe | Confirm for parameter-less actions; `DIPL20001` Submit for Grant Aid / Set Subsidy; overture parameter dialog then confirm → adds/cancels draft diplomatic order | Pending shows **Cancel** on the default row; disabled non-pending actions sit under **More actions** with inline refusal copy when expanded. |
| Row Details | Always | Opens detail route | See diplomacy-detail spec. |

---

## States and variants

| Variant | Trigger | Render difference |
|---------|---------|-------------------|
| Default | Panel open | Scrollable faction list; each row shows enabled actions + pending **Cancel** only. |
| More expanded | Player taps **More actions** on a row | That row also shows disabled matrix entries with inline refusal reasons. |
| Pending action | Order in `currentOrders` | Matching action on the default row shows **Cancel**. |

---

## Components

- `DiplomacyScreen`, faction row widgets, `GrantOrSubsidyDialog` — [grant-or-subsidy-dialog.md](grant-or-subsidy-dialog.md).

---

## Widgetbook

At least one story that shows the Diplomacy panel using a **real game** (e.g. from init-game or debug init). Ensures the panel works with actual Game/PlayerView data and diplomacy state.

In addition, a **mobile viewport** use case must render the panel inside the shared [mobileViewport](../program/app-ui-wiring.md) frame (360 × 640 dp `MediaQuery` size from `app/lib/widgetbook/catalog.dart`) so the `≤ 500 dp` narrow row variant from [§ Responsive layout](#responsive-layout) is reviewable without window resizing. This satisfies the "any other screen with responsive variants" clause from [mobile-adaptation.md](mobile-adaptation.md) § 6 (Widgetbook verification) for the diplomacy surface listed under [`Refs #2870`](https://github.com/waigore/colonizethisv3/issues/2870) R22.

Finally, an **empty-state** use case named `No factions discovered (empty state)` must render the panel against a `Game` whose human player has no diplomacy relations with any other faction (no other Great Power, Minor Nation, or Tribe). Because section headings are now always rendered (§ Section headings), the story exposes all three headings (`Great Powers`, `Minor Nations`, `Tribes`) and their per-section empty placeholders — including the canonical `No tribes contacted yet.` (`diplomacy_panel_noTribes`) copy — under the editorial-monocle dark chrome inherited from the Widgetbook host theme (`AppThemes.editorialMonocle`), so reviewers can validate the empty-state layout without scripting a custom save. The fixture is a stable widget catalog asset — not a runtime debug toggle — so its layout cannot regress silently when `buildDiplomacyRows` is changed.

In addition, a **Diplomatic Standing Chips** folder isolates the `DiplomacyStandingChipCluster` (§ Diplomatic standing chip cluster, Refs #3753 R12) so reviewers can inspect the treaty / colony / boycott / overseas chip chrome and run-wrapping without scripting a save. It carries three use cases: `Colony Tribe (treaty + Colony + Boycott vs)` (cumulative `Consulate · Embassy · NAP · Colony` treaty chips plus a `Boycott vs {GP}` chip and an `Overseas: N · S%` chip), `Minor overseas holdings (Overseas chip)`, and `Empty standing (no chips, zero footprint)` (the negative case that renders nothing).

A **Declare War confirm — named formal ally** use case renders `CtConfirmDialog` with `buildDiplomacyConfirmPreviewMessage` for a Spain target whose persisted formal ally is France, proving the third-party Effect line (Refs #4409).

A **Break Alliance confirm — rest-of-turn lock** use case renders `CtConfirmDialog` with `buildDiplomacyConfirmPreviewMessage` for a Spain target, proving the same-turn lock Effect lines (Refs #4719).

**Boycott confirm — two named colonies** and **Revoke Boycott confirm — two named colonies** render the same `CtConfirmDialog` host with two human colony display names (Aztec and Inca) so the full embargo Effect lines are reviewable (Refs #4584).

---

## Acceptance criteria

- **Top bar present (dark chrome):** **Given** the Diplomacy screen is mounted for the human player on any viewport, **when** the screen builds its chrome, **then** the UI layer renders a `CtTopBar` instance above the body whose `title` equals `"Diplomacy"`, whose `backButtonLabel` equals `"Map"`, and whose leading `icon` is the pixel-art asset `assets/icons/32/ui_icon_diplomacy.png` sized 18 × 18 logical px (no fallback to the legacy `CtScreenShell` parchment chrome).
- **Top bar gradient + accent border:** **Given** the Diplomacy screen is mounted on any viewport, **when** the `CtTopBar` surface paints, **then** the surface's `BoxDecoration` resolves its gradient to `CtGradients.topBarGradient` and its bottom border colour resolves to `EditorialMonoclePalette.accentDim` with width `1` px.
- **Top bar Material ban (regression guard):** **Given** the Diplomacy screen is mounted on any viewport, **when** the widget tree is inspected, **then** the diplomacy surface contains no `CtScreenShell` widget (the legacy parchment title-bar path is gone) and no Material `AppBar` widget.
- **Top bar stable key:** **Given** the Diplomacy screen is mounted on any viewport, **when** the screen builds, **then** the `CtTopBar` carries the stable key `DiplomacyScreen.topBarKey` so widget tests can locate the dark chrome without coupling to localized strings.
- **Top bar back affordance:** **Given** the Diplomacy screen is pushed over a prior route, **when** the user taps the `CtBackButton` inside the `CtTopBar`, **then** `Navigator.maybePop()` runs and the prior route regains focus (same shell-level pop semantics as the legacy chrome).
- Given the user is in-game and taps the dove icon in the toolbar, the UI opens the Diplomacy panel as a full-page screen.
- Given the Diplomacy panel is open, it lists only discovered factions, grouped as Great Powers, Minor Nations, Tribes; GPs sorted by military power then province count.
- Given a faction row, the panel shows current relation state (Peace/War) and the **one-word relation state** (Hostile, Unfriendly, Cordial, Friendly) derived from the hidden score per SPEC/game/diplomacy.md § Player-facing relation display; it does **not** show the numeric relation score. For Minor/Tribe it shows overture stage. For Great Powers it shows the **relative power line** (see § Relative power line) below the header instead of the absolute score. To the right it shows the **ready shortlist** of diplomatic actions (enabled + pending **Cancel**) with the remainder behind **More actions** when applicable (§ Per-faction row).
- Given a Great Power row where `gpPowerScore = 110` and `playerPowerScore = 100`, when the row is rendered, then the relative-power line reads `Relative power: +10% · Roughly equal` (localized) and the percentage and tier word both resolve to `--danger` (red) per § Relative power line.
- Given a Great Power row where `gpPowerScore = 78` and `playerPowerScore = 100`, when the row is rendered, then the relative-power line reads `Relative power: −22% · Inferior` (using the U+2212 minus sign) and the percentage and tier word both resolve to `--success` (green) per § Relative power line.
- Given a Great Power row where `pct = 0`, when the row is rendered, then the relative-power line reads `Relative power: 0% · Roughly equal`, the `Relative power:` prefix resolves to `--muted`, and `0%` plus `Roughly equal` resolve to `--success` (green).
- Given a Minor Nation or Tribe row, when the row is rendered, then no relative-power line is shown (the comparison is Great-Power only).
- Given the relative-power line on either the panel row or the detail screen, when the player invokes its tooltip / long-press affordance, then the UI layer shows explanatory copy describing the comparison to the human player's military power score.
- Given a viewport width of 320 dp and a long faction name, when the relative-power line renders, then the line wraps to additional lines and no segment uses `TextOverflow.ellipsis`.
- Given a Great Power row where `playerPowerScore = 0`, when the row is rendered, then the percentage computation uses `max(playerPowerScore, 1)` so no division-by-zero error occurs and a finite percentage value is shown.
- Given the `powerComparisonTier` helper, when it is evaluated at the boundary integers, then `+10 → Roughly equal`, `+11 → Superior`, `+30 → Superior`, `+31 → Vastly superior`, `−10 → Roughly equal`, `−11 → Inferior`, `−30 → Inferior`, and `−31 → Vastly inferior`.
- Given the user taps an action button other than **Grant Aid** or **Set Subsidy**, the UI shows a **confirmation dialog** with the action name and target faction. Tapping "Confirm" in the dialog submits the diplomatic order; tapping "Cancel" dismisses without submitting.
- Given the user taps **Grant Aid** or **Set Subsidy**, when they choose a valid amount on `DIPL20001` and tap **Submit**, then the UI layer stages the pending order with no `ConfirmDialogEvent` (Cost / Effect are already on `DIPL20001`; Refs #4415).
- Given the user taps **Establish Overture**, the UI shows the **parameter dialog** first; after the stage is set, the **confirmation dialog** appears; on "Confirm" the order is submitted; on "Cancel" it is dismissed.
- **Consulate confirm unlocks (Refs #4682):** Given `GAME30001` **Consulate** confirm toward a Minor Nation or Tribe, when the dialog renders, then Effect states that acceptance lets the player Explore and Prospect on that court's land and that bids on that court's sales are served before courts with no Consulate (after First right of refusal), and the body contains no hidden relation scores.
- **Consulate confirm GP target (Refs #4682):** Given the same confirm toward a Great Power, when the dialog renders, then Effect does not claim Explore, Prospect, or Purchase land on that court's provinces.
- **Embassy confirm unlocks (Refs #4682):** Given `GAME30001` **Embassy** confirm toward a Minor Nation or Tribe, when the dialog renders, then Effect names Grant Aid, Set Subsidy, and Purchase land toward that court and that another Great Power declaring war on them may ask the player to intervene.
- **NAP confirm unlocks (Refs #4682):** Given `GAME30001` **NAP** confirm, when the dialog renders, then Effect states that acceptance lets the player later offer Join Empire and that the pact does not by itself block Declare War; Cost remains no treasury charge.
- **Consulate confirm golden (Refs #4682):** Given `CtConfirmDialog` titled `Consulate` toward Bavaria (Minor) under `AppThemes.editorialMonocle`, when `app/test/diplomacy_confirm_preview_goldens_test.dart` captures the keyed `RepaintBoundary`, then the UI layer matches `app/test/goldens/diplomacy_confirm_consulate.png` and the body includes Explore/Prospect and First-right Effect lines.
- **Embassy confirm golden (Refs #4682):** Given `CtConfirmDialog` titled `Embassy` toward Bavaria (Minor) under `AppThemes.editorialMonocle`, when `app/test/diplomacy_confirm_preview_goldens_test.dart` captures the keyed `RepaintBoundary`, then the UI layer matches `app/test/goldens/diplomacy_confirm_embassy.png` and the body includes Grant Aid, Set Subsidy, Purchase land, and intervention Effect lines.
- **NAP confirm golden (Refs #4682):** Given `CtConfirmDialog` titled `NAP` toward Bavaria (Minor) under `AppThemes.editorialMonocle`, when `app/test/diplomacy_confirm_preview_goldens_test.dart` captures the keyed `RepaintBoundary`, then the UI layer matches `app/test/goldens/diplomacy_confirm_nap.png` and the body includes Join Empire path and Declare War non-block Effect lines.
- **Declare War names a formal ally (Refs #4409):** Given Spain and France hold a persisted formal alliance and are at peace, and France is not at war with the human, when the human opens **Declare War** confirm on Spain from `GAME30001`, then the body includes an Effect line that names France as a formal ally who may be called to defend, and does not claim France will join.
- **Declare War omits informal Allied (Refs #4409):** Given France’s relation with Spain is in the informal Allied band but `formalAlliance == false`, when the same confirm opens, then the UI layer does not name France as a defender.
- **Declare War omits already-at-war ally (Refs #4409):** Given France holds a persisted formal alliance with Spain and is at peace with Spain, but France is already at war with the human, when the human opens **Declare War** confirm on Spain, then the UI layer does not name France as a defender.
- **Declare War one line per court (Refs #4409):** Given Spain holds persisted formal alliances with both France and England, both at peace with Spain and not at war with the human, when the human opens **Declare War** confirm on Spain, then the body includes one Effect line naming France and one Effect line naming England, ordered by display name.
- **Declare War intervention line (Refs #4409):** Given France holds an Embassy or purchased land in Bavaria and the human confirms **Declare War** on Bavaria, then the body names France as a court that may be asked to intervene.
- **Declare War omits empty third-party scare line (Refs #4409):** Given no other GP qualifies, when Declare War confirm opens, then the extra third-party Effect line is absent and the existing pair Effect lines still render.
- **Declare War confirm has no scores (Refs #4409):** Given any of the above confirms, when the body is inspected, then it contains no relation score numerals, no `−50` / `−10` penalty figures, and no raw `formalAlliance` / pending-type ids.
- **Declare War named-ally goldens (Refs #4409):** Given `CtConfirmDialog` is mounted under `AppThemes.editorialMonocle` with `buildDiplomacyConfirmPreviewMessage` for Spain whose persisted formal ally is France, when `app/test/diplomacy_declare_war_third_party_goldens_test.dart` captures the keyed `RepaintBoundary`, then the UI layer matches `app/test/goldens/diplomacy_confirm_declare_war_named_ally.png`. Given Spain also holds a persisted formal alliance with England, then the capture matches `app/test/goldens/diplomacy_confirm_declare_war_two_allies.png` with one Effect line naming England before France.
- **Establish Favored partner confirm golden (Refs #4586):** Given `CtConfirmDialog` titled `Establish Favored partner` is mounted under `AppThemes.editorialMonocle` with `buildDiplomacyConfirmPreviewMessage` for `DiplomaticOrderType.establishFtp` toward Spain, when `app/test/diplomacy_confirm_preview_goldens_test.dart` captures the keyed `RepaintBoundary`, then the UI layer matches `app/test/goldens/diplomacy_confirm_establish_favored_partner.png` and the body includes no-treasury Cost plus same-rank / prices / First-right Effect lines.
- **Break Alliance confirm names rest-of-turn lock (Refs #4719):** Given the human Great Power holds a formal alliance with Spain at peace, when **Break Alliance** confirm opens on `GAME30001`, then the body states that until next turn the player cannot offer Alliance, overture, Favored Trading Partner, Grant Aid, or Set Subsidy toward Spain. Pin: `packages/colonizethis_diplomacy/test/diplomacy/diplomacy_confirm_preview_cases.dart`.
- **Break Alliance confirm war/peace remain (Refs #4719):** Given that same confirm, when the body is read, then it states that Declare War and Offer Peace remain available this turn and that the lock clears next turn.
- **Break Alliance confirm omits scores and field names (Refs #4719):** Given that same confirm, when the body is inspected, then **When** still says the treaty ends immediately, standing-hit lines remain without −50 / −10 numerals, and the body contains no raw `allianceBreakCooldowns`, `sinceTurn`, or `formalAlliance` field names.
- **Break Alliance confirm does not claim Boycott locked (Refs #4719, negative):** Given that same confirm, when the body is inspected, then it does not claim Boycott is blocked.
- **Break Alliance confirm goldens (Refs #4719):** Given `CtConfirmDialog` titled `Break Alliance` toward Spain under `AppThemes.editorialMonocle`, when `app/test/diplomacy_confirm_break_alliance_goldens_test.dart` captures the keyed `RepaintBoundary` at 360 dp and at 320 dp, then the UI layer matches `app/test/goldens/diplomacy_confirm_break_alliance.png` and `app/test/goldens/diplomacy_confirm_break_alliance_320dp.png`, the lock Effect lines wrap without ellipsis that drops the lock, and the body does not mention Boycott.
- **Break Alliance confirm Widgetbook (Refs #4719):** Given the Diplomacy Panel Widgetbook use case `Break Alliance confirm — rest-of-turn lock` is mounted under `AppThemes.editorialMonocle`, when the builder pumps, then `CtConfirmDialog` shows the lock Effect lines toward Spain and does not mention Boycott. Pin: `app/test/widgetbook_diplomacy_break_alliance_confirm_test.dart`.
- Given the user has **already submitted** a diplomatic order for a (player, target, order type) combination, when the panel renders the action button for that order type toward that target, the button label shows **"Cancel"** and the action is **not shown** again in the suggested actions list for that faction.
- Given the user has a pending diplomatic order toward a target faction, when the user taps the **"Cancel" button** for that pending order, the UI removes that order from the current turn's order set (toggle off) and the action reappears as a suggested action for that faction.
- Given the user opens the Grant Aid parameter dialog, when they use only the stepper controls, then the amount changes in steps of **£1000**, starts at **£1000**, and cannot go below **£1000** or above **treasury**.
- Given the user opens the Set Subsidy parameter dialog, when they use only the stepper controls, then the percent changes in steps of **5%**, starts at **5%**, and cannot go below **5%** or above **20%** (Refs #3753 R3 / S15).
- Given the human player has an active subsidy in `Game.subsidyStates` paying the row’s faction, when the Diplomacy list row renders, then it shows that ongoing **percent** on the row via `diplomacy_panel_outgoingSubsidy` (e.g. `Outgoing subsidy: 10% to Free City`) — not a £/turn amount (Refs #3753 R3 / S15).
- **Pending subsidy percent copy (Refs #3753 S15):** Given the human player has queued `setSubsidy` toward the row’s faction in the current turn’s orders with `amount = 15`, when the list row renders, then it shows `Pending subsidy: 15% (resolves end of turn)` on the economic line, the `Set Subsidy (15%)` action button is absent, and tapping **Cancel** emits `RemoveDiplomaticOrderRequestedEvent` for that pending order.
- **Subsidy buy/sell tooltip (Refs #4546):** Given a row with an active or pending subsidy percent `P` toward `{displayName}`, when the player inspects that compact line (hover / long-press `Tooltip`), then the tooltip is `subsidyFillPriceConsequenceTooltip` for `P` and `{displayName}` (pays P% more buying / receives P% less selling on fills with that court; no per-turn gold charge) and the compact percent line itself is unchanged. Test: `app/test/diplomacy_panel_orders_subsidy_test.dart`.
- **Set Subsidy opens percent dialog (Refs #3753 S15):** Given a Minor Nation row with an enabled `Set Subsidy` action (Embassy held), when the user taps **Set Subsidy**, then the UI layer emits `OpenDialogEvent(grantOrSubsidyDialogId, { targetFactionId, isSubsidy: true })` and does not append a diplomatic order until the dialog submits.
- **Grant Aid opens amount dialog (Refs #3753 R2):** Given a Minor Nation row with an enabled `Grant Aid` action (Embassy held), when the user taps **Grant Aid**, then the UI layer emits `OpenDialogEvent(grantOrSubsidyDialogId, { targetFactionId, isSubsidy: false })` and does not append a diplomatic order until the dialog submits.
- **Pending grant aid copy (Refs #3753 R2):** Given the human player has queued `grantAid` toward the row’s faction in the current turn’s orders with `amount = 2000`, when the list row renders, then it shows `Pending grant aid: £2000 (resolves end of turn)` on the economic line, the `Grant Aid` action button is absent, and tapping **Cancel** emits `RemoveDiplomaticOrderRequestedEvent` for that pending order.
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
- **Mode-bar chip gradient + idle border (Refs #3621):** Given the diplomacy panel is open with default state, when an **inactive** mode-bar chip's surface is inspected, then its `BoxDecoration` gradient equals `CtGradients.actionButtonGradient` (`--surface-lite → --bg-deep`) and its border is a 1 px side whose colour resolves to `EditorialMonoclePalette.border` (no longer a borderless label).
- **Mode-bar chip active border (Refs #3621):** Given the diplomacy panel is open with default state, when the **active** ("All") mode-bar chip's surface is inspected, then its `BoxDecoration` gradient equals `CtGradients.actionButtonGradient` and its border is a 1 px side whose colour resolves to `EditorialMonoclePalette.accentDim`.
- **Economic lines mono `--accent-dim` (Refs #3621):** Given a faction row with an outgoing active subsidy, a pending grant, or a pending subsidy, when each economic line renders, then its `TextStyle.fontFamily` is `monospace`, its `TextStyle.color` resolves to `EditorialMonoclePalette.accentDim`, and its `TextStyle.fontStyle` is **not** italic (mockup `.f-subsidy`).
- **Section heading first-child top rhythm (Refs #3621):** Given the diplomacy panel is open under any mode-bar filter, when the **first** rendered `_DiplomacySectionHeader` is inspected, then its outer top padding equals `0`; and when any **subsequent** section heading is inspected, then its outer top padding equals `CtSpacing.l` (mockup `.section-head:first-child { margin-top: 0 }`).
- **Relation meter present (Refs #3753 R13):** Given a faction row with a diplomatic relation, when the relation line renders, then exactly one `RelationMeter` is present between the WAR/PEACE badge and the one-word ladder label, and the meter's keyed active segment matches `relationScoreToMeterStep(score)`.
- **Relation word italic (Refs #3621):** Given a faction row whose relation renders a one-word relation label, when the relation row `Text.rich` is inspected, then the `TextSpan` carrying the relation word has `TextStyle.fontStyle == FontStyle.italic` while the muted separator/overture spans are not italic (mockup `.f-relation .word { font-style: italic }`).
- **Relation word step color — Hostile (Refs #3753 R13.3):** Given a faction row whose relation score is in step 1 (`[0, 10)`), when the relation word renders, then its `TextStyle.color` resolves to `EditorialMonoclePalette.danger` and `diplomacyRelationWordColor(score)` returns that same color.
- **Relation word step color — Devoted (Refs #3753 R13.3):** Given a faction row whose relation score is in step 10 (`[90, 100]`), when the relation word renders, then its `TextStyle.color` resolves to `EditorialMonoclePalette.success`.
- **Relation word step color — gradient interior (Refs #3753 R13.3):** Given a faction row whose relation score falls in an interior step `s` (2 … 9), when the relation word renders, then its `TextStyle.color` resolves to `relationMeterStepColor(s)`, the OKLCH ladder color for that step, and matches the meter indicator hue.
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

- **Wide action cluster is bounded by available row width, not a fixed cap (Refs #3621):** Given the Diplomacy panel is open at a viewport width strictly greater than `kDiplomacyRowNarrowMaxWidth` (500 dp) and a faction row has at least one action button, when the row body renders, then the info column is an `Expanded` and the trailing action cluster is a `Flexible` whose child is an `Align(alignment: Alignment.topRight, …)` wrapping the action `Wrap` (so the cluster is bounded only by the available faction-row width with **no** `ConstrainedBox` capping its `maxWidth` to a fixed dp value), and the enclosed action `Wrap` uses `WrapAlignment.end` with `spacing` and `runSpacing` equal to `kDiplomacyActionWrapSpacing` (4 dp), so the buttons flow left-to-right on the trailing edge.

- **Compact action buttons shrink-wrap to their label (Refs #3621):** Given the Diplomacy panel renders any action button, when that `CtNinePatchButton` is laid out inside the trailing cluster `Wrap`, then the button is constructed with `shrinkWrap: true` so its surface sizes to its label width (plus `kDiplomacyActionButtonPadding`) instead of expanding to fill the run width. Without shrink-wrap each button would expand to the full available run width and the cluster would degrade to one button per run (a vertical column).

- **Action button label uses the compact display font (Refs #3621):** Given the Diplomacy panel renders any action button on any viewport, when that button's label `Text` style is inspected, then its `fontFamily` resolves to `editorialMonocleDisplayFontFamily` (`Cinzel`) and its `fontSize` equals `kDiplomacyActionButtonFontSize` (10 sp), so the label uses the editorial-monocle display stack at the pinned compact size rather than the unmodified ~12 dp M3 `bodySmall` slot (mockup `.f-actions button { font-size: 8px; font-family: var(--font-display) }`).

- **Wide action cluster fills runs left-to-right, wrapping only at width exhaustion (rendered geometry, Refs #3621):** Given the Diplomacy panel is open at a viewport width strictly greater than `kDiplomacyRowNarrowMaxWidth` and a Great Power row renders its full action matrix (at least four action buttons), when the rendered global bounds of those action buttons are inspected and grouped into runs (sets of buttons sharing a top y-offset within `0.5 dp`), then (a) the buttons do **not** all share a single x-offset (the cluster is not a single vertical column), and (b) for every run **except** the last, the run holds at least two buttons and the first button of the **next** run could **not** have fit in that run's remaining trailing width (run width − used width < next button width + `kDiplomacyActionWrapSpacing`), so each run is filled left-to-right and the cluster wraps **only** when the available row width is exhausted — never a premature wrap.

- **Wide action cluster collapses to a single run when width allows (rendered geometry, Refs #3621):** Given the Diplomacy panel is open at a viewport wide enough that the full Great Power action matrix fits within the available faction-row width on one run, when the rendered global bounds of those action buttons are inspected, then **all** action buttons share a single run-top (one horizontal run within `0.5 dp`), confirming the cluster extends horizontally rather than stacking once it is no longer width-constrained.

- **Compact action button chrome (Refs #3621):** Given the Diplomacy panel is open and a faction row renders any action button, when that button's `CtNinePatchButton` is inspected, then its `minHeight` equals `kDiplomacyActionButtonMinHeight` (24 dp) and its `padding` equals `kDiplomacyActionButtonPadding` (7 dp horizontal × 3 dp vertical), distinguishing the compact diplomacy variant from the 48 dp / 16 × 12 dp default panel button chrome.

- **Compact button chrome constants are normative (Refs #3621):** Given the diplomacy panel implementation, when the action-cluster constants are read, then `kDiplomacyActionWrapSpacing == 4.0`, `kDiplomacyActionButtonMinHeight == 24.0`, and `kDiplomacyActionButtonFontSize == 10.0` so widget tests pin the compact contract from a single source. The former fixed-width cap constant `kDiplomacyActionClusterMaxWidth` is removed (the wide cluster is bounded by the available row width, not a fixed dp value).

- **Mobile-viewport Widgetbook story renders narrow rows:** Given the Diplomacy Panel `Mobile viewport — narrow rows (≤ 500 dp)` Widgetbook use case is mounted in a `WidgetTester`, when the builder pumps inside the shared 360 × 640 dp `mobileViewport` frame, then `WidgetTester.takeException()` returns `null` and at least one faction-row body keyed `${kDiplomacyRowBodyKeyPrefix}<factionId>` is a `Column` (the `≤ 500 dp` narrow variant per § Responsive layout), demonstrating the responsive contract is reviewable from Widgetbook without resizing the host window (Refs #2870 R22 / S9).

- **Always-visible section headings:** Given the diplomacy panel is open with the mode-bar filter set to `all`, when the panel renders, then a `_DiplomacySectionHeader` is present for each of `Great Powers`, `Minor Nations`, and `Tribes` regardless of whether those sections have any rows. Refs #3341.
- **Empty Tribes placeholder copy:** Given the diplomacy panel is open and no tribe has been contacted (the Tribes section has no rows), when the panel renders, then the `Tribes` heading is present and exactly one widget shows the copy `No tribes contacted yet.` (`diplomacy_panel_noTribes`) beneath it, and no tribe faction-row body keyed `${kDiplomacyRowBodyKeyPrefix}<factionId>` is in the tree. Refs #3341.
- **Empty-state Widgetbook story renders headings + tribe placeholder:** Given the Diplomacy Panel `No factions discovered (empty state)` Widgetbook use case is mounted in a `WidgetTester` under `AppThemes.editorialMonocle`, when the builder pumps the fixture `Game` whose human player has no other discovered factions and no diplomacy relations, then `WidgetTester.takeException()` returns `null`, `buildDiplomacyRows` returns an empty list, the three section headings (`Great Powers`, `Minor Nations`, `Tribes`) are each present, `find.text('No tribes contacted yet.')` resolves to exactly one widget (the localized `diplomacy_panel_noTribes` copy), and no faction-row body keyed `${kDiplomacyRowBodyKeyPrefix}<factionId>` is in the tree. Refs #2863 S7 / #3341.

- **Discovery via tile visibility (no prior relation):** Given the human player has non-`unknown` tile visibility in a province owned by a Tribe `T` and **no** `DiplomacyRelation` with `T`, when `buildDiplomacyRows` runs, then the returned rows include exactly one row whose `factionId == T` and `kind == FactionKind.tribe`, and that row's `relation` is non-null with `state == RelationState.atPeace`, `score == 50`, and `level == RelationLevel.neutral`. Refs #3341.

- **Discovery does not depend solely on relation table (consulate fix):** Given a Tribe `T` is discovered for the human player by **tile visibility** (per § Tribes require first contact) and `T` has no game-setup `DiplomacyRelation` with the player, when the Diplomacy panel renders, then the Tribe row for `T` is present under the `Tribes` section (the previously documented "tribes appear only after establishing a consulate" behavior no longer governs discovery). Refs #3341.

- **No spurious discovery (negative):** Given the human player has no `DiplomacyRelation`, no non-`unknown` tile visibility into any other faction's province, and no sea-reachable Tribe province, when `buildDiplomacyRows` runs, then it returns an empty list (no synthesized rows are added for undiscovered factions). Refs #3341.

- **AC-1 (#3620) — turn-0 sea-reachable Tribe is not surfaced:** Given a new game at turn 0 where the human GP has **no** non-`unknown` tiles in any Tribe-owned province and **no** persisted `DiplomacyRelation` with that Tribe, **and** that Tribe owns a New-World province that is sea-reachable from the GP's Old-World anchor provinces/units, when `buildDiplomacyRows` runs, then the returned rows contain **no** row whose `kind == FactionKind.tribe`, and `knownDiplomaticTargetFactionIds` does **not** include the tribe id (the first-contact gate is applied by the shared helper, not only by the panel). Refs #3620.

- **AC-6 (#3620) — no sea-reachable diplomatic targeting:** Given a Tribe `T` is sea-reachable from the GP's anchors but the GP holds zero non-`unknown` tiles in any province `T` owns and no persisted GP↔`T` relation, when `knownDiplomaticTargetFactionIds` runs, then `T` is **not** in the returned set and `suggestDiplomaticOrders` (including `Declare War`) emits no order targeting `T`. Refs #3620.

- **AC-7 (#3620) — contact survives fog decay:** Given the human GP has a persisted GP↔Tribe `DiplomacyRelation` with Tribe `T` and currently holds **no** non-`unknown` tile visibility in any province owned by `T` (visibility decayed to fogged/unknown), when `buildDiplomacyRows` runs, then the returned rows include exactly one row whose `factionId == T` and `kind == FactionKind.tribe`, carrying the persisted relation. Refs #3620.

- **Overture buttons on default row (AC-6, Refs #4265):** Given a Minor or Tribe row at overture stage `none` and no pending diplomatic orders, when the panel renders the default action cluster, then only the validator-enabled next overture stage (typically `Consulate`) appears on the default row; later locked stages are absent until **More actions** is expanded, where they appear disabled with inline rejection text.

- **GP overture + FTP default shortlist (AC-7 / Refs #4265):** Given a Great Power row at peace with no overture, when the default action cluster renders, then the validator-enabled next overture stage (typically `Consulate`) and other enabled treaty/economic actions appear on the default row; disabled stages (`Embassy`, `NAP`, `Join Empire`, `Establish Favored partner`, `Offer Peace`, etc.) are absent until **More actions** is expanded.

- **Boycott button present and gated by colony ownership (Refs #3753 S14):** Given a Great Power row at peace with the target Great Power and the human Great Power holds **no** colony (`Game.colonyStates` has no entry with `colonyOfGpId == human`) and no existing boycott for the pair, when `enumerateDiplomaticPanelActionsForTarget` runs for that target, then the returned actions include exactly one `DiplomaticOrderType.boycott` action and it is **disabled** with a non-empty rejection reason. Refs #3753.

- **Boycott button enabled when a colony is held (Refs #3753 S14):** Given a Great Power row at peace with the target Great Power, the human Great Power holds at least one colony (`Game.colonyStates` with `colonyOfGpId == human`), and no boycott for the `(human, target)` pair exists, when `enumerateDiplomaticPanelActionsForTarget` runs for that target, then the returned `DiplomaticOrderType.boycott` action is **enabled**. Refs #3753.

- **Revoke Boycott enabled only with an active boycott (Refs #3753 S14):** Given a Great Power row and an active `Game.boycottStates` entry with `gpId == human` and `targetGpId == target`, when `enumerateDiplomaticPanelActionsForTarget` runs for that target, then the returned `DiplomaticOrderType.revokeBoycott` action is **enabled** and the `DiplomaticOrderType.boycott` action is **disabled** (a boycott already exists); given no such boycott entry, the `revokeBoycott` action is **disabled** with a non-empty rejection reason. Refs #3753.

- **Boycott controls are Great-Power-only (negative, Refs #3753 S14):** Given a Minor Nation or Tribe row, when `diplomaticPanelActionCandidates` runs for that target, then the returned candidates include **no** `DiplomaticOrderType.boycott` and **no** `DiplomaticOrderType.revokeBoycott` order. Refs #3753.

- **S14 widget: Boycott disabled without colony (Refs #3753):** Given a Great Power row at peace and the human Great Power holds no colony, when `DiplomacyPanel` renders, then a `CtNinePatchButton` labelled `Boycott` is present and `enabled == false`. Pin: `app/test/diplomacy_panel_orders_test.dart` — `Boycott disabled when human holds no colony`.

- **Boycott confirm full embargo copy (Refs #4584):** Given `GAME30001` **Boycott** confirm toward a named Great Power while the human holds at least one colony Tribe, when the dialog renders, then **Effect** states that world-market deals between that court and the human’s colony tribes will not fill, that the court cannot purchase land, grant aid, or set subsidies toward those colonies, and that subsidies they already pay those colonies are cancelled when this resolves. Pin: `packages/colonizethis_diplomacy/test/diplomacy/diplomacy_confirm_preview_cases.dart`, `app/test/diplomacy_panel_confirm_preview_test.dart`.
- **Boycott confirm first-order and names (Refs #4584):** Given that confirm, when copy is inspected, then **Cost** still says there is no treasury charge, hidden relation scores and −50/−10 are absent, and colony names are display names (no raw tribe ids).
- **Revoke Boycott confirm restores court work copy (Refs #4584):** Given `GAME30001` **Revoke Boycott** confirm for an active pair boycott, when the dialog renders, then **Effect** states that the embargo ends so that court may again trade with, purchase land in, and grant aid or subsidies toward the human’s colony tribes.
- **Boycott confirm covers the current colony set (Refs #4584):** Given the human holds two colony Tribes, when **Boycott** confirm renders, then the copy names both (or `your colony tribes` when more than three), never a single tribe pinned at order time.
- **Boycott confirm Widgetbook and goldens (Refs #4584):** Given the Diplomacy Panel Widgetbook use cases `Boycott confirm — two named colonies` and `Revoke Boycott confirm — two named colonies` are mounted under `AppThemes.editorialMonocle`, when the host goldens in `app/test/diplomacy_confirm_preview_goldens_test.dart` capture each `CtConfirmDialog`, then the captured `RepaintBoundary` matches `app/test/goldens/diplomacy_confirm_boycott.png` and `app/test/goldens/diplomacy_confirm_revoke_boycott.png` via `matchesGoldenFile`, Cost still says there is no treasury charge, and Boycott Effect names world-market fill block, blocked purchase land / grant aid / set subsidy, and subsidy cancel.
- **S14 widget: Boycott confirm emits order (Refs #3753):** Given a Great Power row at peace, the human Great Power holds a colony, and no active boycott exists for the `(human, target)` pair, when the user taps **Boycott** and confirms, then the UI layer emits `AppendDiplomaticOrderRequestedEvent` with `order.type == boycott` and `order.targetFactionId == target`. Pin: `app/test/diplomacy_panel_orders_test.dart` — `colony holder shows Boycott enabled on GP row`.

- **S14 widget: Revoke Boycott confirm emits order (Refs #3753):** Given a Great Power row and an active `BoycottState` with `gpId == human` and `targetGpId == target`, when the user taps **Revoke Boycott** and confirms, then the UI layer emits `AppendDiplomaticOrderRequestedEvent` with `order.type == revokeBoycott`. Pin: `app/test/diplomacy_panel_orders_test.dart` — `active boycott shows Revoke Boycott enabled on GP row`.

- **S14 widget: pending boycott Cancel (Refs #3753):** Given a queued `boycott` order toward a Great Power target, when the list row renders, then the `Boycott` button is absent, a **Cancel** affordance is shown, and tapping it emits `RemoveDiplomaticOrderRequestedEvent` for that pending order. Pin: `app/test/diplomacy_panel_orders_test.dart` — `pending boycott shows Cancel and removes on tap`.

- **S14 widget: pending revokeBoycott Cancel (Refs #3753):** Given a queued `revokeBoycott` order and an active boycott for the pair, when the list row renders, then the `Revoke Boycott` button is absent, a **Cancel** affordance is shown, and tapping it emits `RemoveDiplomaticOrderRequestedEvent` for that pending order. Pin: `app/test/diplomacy_panel_orders_test.dart` — `pending revokeBoycott shows Cancel and removes on tap`.

- **S14 widget: Minor row omits boycott controls (negative, Refs #3753):** Given a Minor Nation row, when `DiplomacyPanel` renders, then neither `Boycott` nor `Revoke Boycott` action labels appear in the row subtree. Pin: `app/test/diplomacy_panel_orders_test.dart` — `Minor row omits Boycott controls`.

- **S15/R2 widget pins (Refs #3753):** Given the economic-dialog and pending-order fixtures in `app/test/diplomacy_panel_orders_test.dart`, when each named test runs under `AppThemes.editorialMonocle`, then the panel order UI pins for pending/active subsidy percent copy, `OpenDialogEvent(grantOrSubsidyDialogId, …)` on Grant Aid / Set Subsidy taps, and pending grant-aid Cancel all pass without exception (tests: `pending setSubsidy shows percent line and Cancel`, `active subsidy shows outgoing percent line`, `Grant Aid emits grantOrSubsidy dialog`, `Set Subsidy emits grantOrSubsidy dialog`, `pending grantAid shows amount line and Cancel`).

- **Ready shortlist + More control (Refs #4265):** Given a Great Power at peace with several disabled matrix entries and at least one enabled action, when the row renders at default, then only enabled actions (and any pending **Cancel**) appear as action buttons and a **More actions** control is present when hidden entries remain.
- **More expanded inline reasons (Refs #4265):** Given the player expands **More actions**, when the expanded cluster renders, then each previously hidden disabled action shows its validator rejection reason inline beneath the button (not tooltip-only as the sole path).
- **Pending Cancel on default row (Refs #4265):** Given a pending diplomatic order for that faction, when the row renders default, then that action appears as **Cancel** without requiring More.
- **Narrow viewport shortlist (Refs #4265):** Given viewport width `≤ kDiplomacyRowNarrowMaxWidth` (500 dp) and an unexpanded row, when actions wrap, then the default cluster is the ready shortlist (not the full ~12-button matrix).
- **No More when nothing hidden (Refs #4265, negative):** Given no disabled non-pending remainder for a row, when the row renders, then no **More actions** control is shown.
- **Disabled actions discoverable under More (AC-10, Refs #4265):** Given any faction row where Declare War, Offer Peace, Alliance, or economic actions fail validation, when the player expands **More actions**, then those actions appear as disabled `CtNinePatchButton` widgets with non-empty inline rejection copy (not omitted from the tree).

- **Widget golden coverage for visual ACs (AC-14):** Given the diplomacy panel and the first-contact herald are mounted under `AppThemes.editorialMonocle` with deterministic fixtures, when the host golden tests in `app/test/diplomacy_panel_goldens_test.dart` render the empty-state panel (AC-1), a Great Power row at peace with overture/`Establish FTP` controls (AC-7), a discovered Tribe row with overture controls (AC-6), the disabled-not-hidden control state (AC-10), and the `TribeFirstContactOverlay` (`OVL80001`) herald (AC-4), then each captured `RepaintBoundary` matches its committed baseline in `app/test/goldens/` via `matchesGoldenFile` and the structural finders for the asserted controls resolve to a non-empty set. Refs #3341.

- **Wide-viewport GP-row golden proves left-to-right action flow (Refs #3621):** Given the diplomacy panel is mounted under `AppThemes.editorialMonocle` with the deterministic Great-Power-at-peace fixture inside a host whose panel width is strictly greater than `kDiplomacyRowNarrowMaxWidth` (500 dp — e.g. an 800 dp surface), when the host golden test in `app/test/diplomacy_panel_goldens_test.dart` renders the Great Power row, then the captured `RepaintBoundary` matches its committed baseline `app/test/goldens/diplomacy_panel_gp_row_wide.png` via `matchesGoldenFile`, the GP row body is a `Row` (the wide variant per § Responsive layout, not the narrow `Column`), and the rendered geometry of the action buttons places at least two buttons on a shared top y-offset run — the trailing compact cluster (bounded by the available row width, no fixed dp cap) flows left-to-right and packs several buttons per run rather than stacking as a single vertical column. The pre-existing AC-7 GP-row golden renders the narrow (≤ 500 dp) variant; this golden adds the missing wide-variant proof for the headline action-flow fix.

- **Relative-power line tier + wrap golden coverage (AC-15, Refs #3622):** Given the shared `RelativePowerLine` widget is mounted under `AppThemes.editorialMonocle` with the app localization delegates, when the golden tests in `app/test/diplomacy_relative_power_goldens_test.dart` render one representative `pct` per `powerComparisonTier` bucket — `−40` (Vastly inferior), `−20` (Inferior), `0` (Roughly equal), `+20` (Superior), `+40` (Vastly superior) — and a width-constrained host that forces the line to wrap, then each captured `RepaintBoundary` matches its committed baseline `app/test/goldens/diplomacy_relative_power_<tier>.png` / `diplomacy_relative_power_narrow_wrap.png` via `matchesGoldenFile`, the asserted tier word resolves via `find.textContaining(..., findRichText: true)`, and the wrapped line's `Text.overflow` is never `TextOverflow.ellipsis`. This adds the per-tier and narrow-viewport visual-regression baselines that the line's color/copy and § Relative power line wrap rule require.
