# Diplomacy Panel

**Screen ID:** `GAME30001` — stable; do not reassign.
**SPEC/ui** — Full-page diplomacy screen. Implementation: `app/lib/features/game/screens/diplomacy_screen.dart`.
**Widgetbook:** `Diplomacy Panel` → `app/lib/widgetbook/catalog.dart`. Source: [diplomacy.md](../game/diplomacy.md), [factions.md](../game/factions.md).

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

## Per-faction row

- **Left:** Faction name (displayName or id), type badge (GP / Minor / Tribe), current **diplomatic state**: relation state (AT_PEACE / AT_WAR), **one-word relation state** (Hostile / Unfriendly / Cordial / Friendly) derived from the hidden relation score per [diplomacy.md](../game/diplomacy.md) § Player-facing relation display. The numeric relation score is **not** shown. For Minor/Tribe: overture stage (none, Trade Consulate, Embassy, NAP, Join Empire) if any. For **Great Powers:** the **power score** per [diplomacy.md](../game/diplomacy.md) § Great Power power score is shown; if the GP’s score is higher than the player’s, the score is shown in **red**, otherwise in **green**.
- **Outgoing economic diplomacy (list row only):** On the **same row**, below the relation line, when the human Great Power has **active or pending** economic diplomacy toward this faction (receiver-centric copy): **Active subsidy:** `Outgoing subsidy: £N/turn to {displayName}` when `Game.subsidyStates` has `payerId` = human GP and `targetId` = this row’s faction. **Pending grant:** `Pending grant aid: £N (resolves end of turn)` when current-turn orders include `grantAid` toward this faction. **Pending subsidy:** `Pending subsidy: £N/turn (resolves end of turn)` when current-turn orders include `setSubsidy` toward this faction. Omit each line when not applicable. Do **not** duplicate this block on the Diplomacy Detail screen for current product (list row is the source of truth).
- **Right:** **Available diplomatic actions** for the player toward that faction. Actions are those explicitly in SPEC/game/diplomacy.md and SPEC/program/orders.md: Declare War, Offer Peace, Alliance (GP only), Establish Overture (stage), **Grant Aid**, **Set Subsidy** as **separate** buttons when each is valid. Grant Aid requires Embassy; Set Subsidy requires Consulate or Embassy — hide or omit a button when its preconditions are not met. Only show actions that are **valid** per the diplomatic order validator (same rules as order submission). Any counterparty that is a valid target for aid/subsidy per game rules (Great Power, Minor, or Tribe) uses the same button rules.

Tapping anywhere on a faction row (or an explicit “Details” affordance in that row) opens a **Diplomacy Detail** view for that faction, scoped to the current player’s Great Power.

---

## Diplomacy Detail view (per faction)

Widget contract, layout, navigation, and acceptance criteria: **[diplomacy-detail-screen.md](diplomacy-detail-screen.md)**. When the user opens the detail view for a faction `B` while controlling Great Power `A`, the UI shows:

- **Header:** Faction name and type (GP / Minor / Tribe), and the same current relation summary as the row (relation state, one-word relation).
- **History panel:** A vertical list of **diplomatic history events** involving `A` and `B`, newest first. Each entry renders:
  - A **year label** derived from the event’s `turn` using the game calendar mapping (e.g. `1505 (Turn 12)`).
  - A human-readable sentence describing the event (e.g. `We declared war on Spain.`, `We established an Embassy with Bavaria.`, `Our subsidies to Bavaria were cancelled when war began.`).
  - If an event involves a faction that is not yet discovered by the current player (no relation, outside visibility rules), that faction’s name is shown as `Unknown faction` in the text.
- **Dossier subpanel (Great Powers only):** When `B` is a Great Power, a secondary panel or tab within the detail view shows the **AI dossier** for `B` from the perspective of `A`, per [SPEC/ai/ai-dossier.md](../ai/ai-dossier.md). The dossier uses only PlayerView-safe data.

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

Orders are submitted into the current turn's order set; resolution happens on Next Turn.

---

## Layout / wireframe

- Full-page: list is scrollable; sections (GPs, Minors, Tribes) with headers.
- Actions shown to the right of each faction row (inline buttons or compact actions). **Current product:** pairwise diplomacy only (human Great Power toward each discovered faction). **Out of scope:** multi-party treaty or coalition UI beyond what pairwise orders already support; not a deferred placeholder—such flows are undefined until specified in GDD/TDD.

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

---

## Acceptance criteria

- Given the user is in-game and taps the dove icon in the toolbar, the UI opens the Diplomacy panel as a full-page screen.
- Given the Diplomacy panel is open, it lists only discovered factions, grouped as Great Powers, Minor Nations, Tribes; GPs sorted by military power then province count.
- Given a faction row, the panel shows current relation state (Peace/War) and the **one-word relation state** (Hostile, Unfriendly, Cordial, Friendly) derived from the hidden score per SPEC/game/diplomacy.md § Player-facing relation display; it does **not** show the numeric relation score. For Minor/Tribe it shows overture stage. For Great Powers it shows the **power score** (SPEC/game/diplomacy.md § Great Power power score) in **red** when the GP’s score is higher than the player’s, otherwise in **green**. To the right it shows only valid diplomatic actions for that faction.
- Given the user taps an action button, the UI shows a **confirmation dialog** with the action name and target faction. Tapping "Confirm" in the dialog submits the diplomatic order; tapping "Cancel" dismisses without submitting.
- Given the user has **already submitted** a diplomatic order for a (player, target, order type) combination, when the panel renders the action button for that order type toward that target, the button label shows **"Cancel"** and the action is **not shown** again in the suggested actions list for that faction.
- Given the user has a pending diplomatic order toward a target faction, when the user taps the **"Cancel" button** for that pending order, the UI removes that order from the current turn's order set (toggle off) and the action reappears as a suggested action for that faction.
- Given the user taps an action that requires parameters (amount or overture stage), the UI shows the **parameter dialog** first; after parameters are set, the **confirmation dialog** appears; on "Confirm" the order is submitted; on "Cancel" it is dismissed.
- Given the user opens the Grant Aid parameter dialog, when they use only the stepper controls, then the amount changes in steps of **£1000**, starts at **£1000**, and cannot go below **£1000** or above **treasury**.
- Given the user opens the Set Subsidy parameter dialog, when they use only the stepper controls, then the amount changes in steps of **£100**, starts at **£1000**, and cannot go below **£100** or above **treasury**.
- Given the human player has an active subsidy in `Game.subsidyStates` paying the row’s faction, when the Diplomacy list row renders, then it shows that ongoing **£/turn** amount on the row (outgoing from the player).
- Given the human player has queued `grantAid` toward the row’s faction in the current turn’s orders, when the list row renders, then it shows a **pending grant** line with that amount until the order is removed or the turn resolves.
- Given the human player has an embassy toward a Minor Nation or Tribe and trade-agreement commodity capacity applies per [diplomacy-resolution.md](../program/diplomacy-resolution.md) (`tradeSlotsForGp`: **0** without embassy, **3** with embassy baseline, **6** with embassy when the human GP has **`trade_fairs`** unlocked), when the UI surfaces trade or economic copy that depends on that capacity, then the UI layer reflects **per-agreement commodity-slot** semantics (not a binary 0/1 “trade on/off” model).

- **Diplomacy Detail — open:** Given the Diplomacy panel is open and shows at least one faction row, when the user taps that row (or its Details affordance), then the UI opens a Diplomacy Detail view scoped to the current player’s Great Power and the tapped faction.
- **Diplomacy Detail — history contents:** Given the Diplomacy Detail view is open for Great Power `A` and faction `B`, when the UI renders the history panel, then it shows all and only those `DiplomaticEvent` entries from the Game’s diplomatic history whose `participants` include both `A` and `B`, ordered by newest first (highest `turn`, then highest `intraTurnIndex`).
- **Diplomacy Detail — year and turn:** Given a `DiplomaticEvent` in the history panel, when the UI renders its timestamp, then it shows a year label derived from the event’s `turn` using the game calendar mapping and includes the raw turn number in parentheses (e.g. `1505 (Turn 12)`).
- **Diplomacy Detail — unknown faction substitution:** Given a `DiplomaticEvent` in the history panel that involves a third faction `C` that is not discovered by the current player, when the UI renders that event, then the faction `C` is shown as `Unknown faction` while `A` and `B` (if discovered) are shown by their normal display names.
- **Diplomacy Detail — dossier subpanel:** Given the Diplomacy Detail view is open for Great Power `B` (and the current player controls Great Power `A`), when the UI renders the dossier subpanel, then it shows dossier sections for `B` per SPEC/ai/ai-dossier.md using only PlayerView-safe data and does not expose hidden agenda values directly.
