# Diplomacy Panel

**SPEC/ui** — Full-page diplomacy screen. Source: SPEC/game/diplomacy.md, SPEC/game/factions.md.

---

## Purpose

The player can view all **discovered** factions (Great Powers, Minor Nations, Tribes), see current diplomatic state with each, and take **diplomatic actions** (declare war, offer peace, alliance, establish overture, grant aid, set subsidy) per SPEC/game/diplomacy.md.

---

## Access

- **Toolbar:** New icon (dove) in the in-game toolbar. Tapping opens the Diplomacy panel as a **full-page** screen (modal or pushed route).
- **Single-player vs AI only.** No multiplayer-specific UI.

---

## Discovered factions

A faction is **discovered** iff the player has a **diplomatic relation** with that faction (i.e. a `DiplomacyRelation` exists between player and faction). Relations are only possible when the faction is discovered. At game start: same-region (GP–GP, GP–Minor) relations are initialized; cross-region (GP–Tribe) are not, so Tribes appear when the player first gains a relation (e.g. after establishing consulate).

- **List contents:** All GPs (except the player), all Minors, and only Tribes that are discovered.
- **Grouping:** Sections by type — Great Powers, Minor Nations, Tribes.
- **Sort:** Great Powers by **military power** (desc), then by **number of provinces** (desc). Minors and Tribes: implementation-defined (e.g. by name or id).

---

## Per-faction row

- **Left:** Faction name (displayName or id), type badge (GP / Minor / Tribe), current **diplomatic state**: relation state (AT_PEACE / AT_WAR), **one-word relation state** (Hostile / Unfriendly / Cordial / Friendly) derived from the hidden relation score per [diplomacy.md](../game/diplomacy.md) § Player-facing relation display. The numeric relation score is **not** shown. For Minor/Tribe: overture stage (none, Trade Consulate, Embassy, NAP, Join Empire) if any. For **Great Powers:** the **power score** per [diplomacy.md](../game/diplomacy.md) § Great Power power score is shown; if the GP’s score is higher than the player’s, the score is shown in **red**, otherwise in **green**. **Economic diplomacy lines (receiver-centric):** If the player has an **active** outgoing `SubsidyState` to this row’s faction, show `Outgoing subsidy: £N/turn to {displayName}`. If the player has a **pending** Grant Aid order toward this row’s faction, show `Pending grant aid: £N (resolves end of turn)`. If the player has a **pending** Set Subsidy order toward this row’s faction, show `Pending subsidy: £N/turn (resolves end of turn)`. Omit each line when not applicable; multiple lines may appear.
- **Right:** **Available diplomatic actions** for the player toward that faction. Actions are those explicitly in SPEC/game/diplomacy.md and SPEC/program/orders.md: Declare War, Offer Peace, Alliance (GP only), Establish Overture (stage), Grant Aid, Set Subsidy. Only show actions that are **valid** per the diplomatic order validator (same rules as order submission).

Tapping anywhere on a faction row (or an explicit “Details” affordance in that row) opens a **Diplomacy Detail** view for that faction, scoped to the current player’s Great Power.

---

## Diplomacy Detail view (per faction)

When the user opens the detail view for a faction `B` while controlling Great Power `A`, the UI shows:

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
- **Parameter dialogs:** Actions that require parameters (Grant Aid amount, Set Subsidy amount, Establish Overture stage) open the parameter dialog first; after parameters are set, the confirmation dialog appears before the order is submitted. **Grant Aid / Set Subsidy:** stepper-only entry (no free numeric typing). Grant Aid: initial amount **£1000**, step **£1000**, only positive multiples of **£1000** up to treasury. Set Subsidy: initial amount **£1000**, step **£100**, only positive multiples of **£100** up to treasury. Dialog titles use **sentence case** (`Grant aid`, `Set subsidy`).
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

## Layout

- Full-page: list is scrollable; sections (GPs, Minors, Tribes) with headers.
- Actions shown to the right of each faction row (inline buttons or compact actions). No 1-to-1 sub-panel for now; multi-party treaties deferred.

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

- **Diplomacy Detail — open:** Given the Diplomacy panel is open and shows at least one faction row, when the user taps that row (or its Details affordance), then the UI opens a Diplomacy Detail view scoped to the current player’s Great Power and the tapped faction.
- **Diplomacy Detail — history contents:** Given the Diplomacy Detail view is open for Great Power `A` and faction `B`, when the UI renders the history panel, then it shows all and only those `DiplomaticEvent` entries from the Game’s diplomatic history whose `participants` include both `A` and `B`, ordered by newest first (highest `turn`, then highest `intraTurnIndex`).
- **Diplomacy Detail — year and turn:** Given a `DiplomaticEvent` in the history panel, when the UI renders its timestamp, then it shows a year label derived from the event’s `turn` using the game calendar mapping and includes the raw turn number in parentheses (e.g. `1505 (Turn 12)`).
- **Diplomacy Detail — unknown faction substitution:** Given a `DiplomaticEvent` in the history panel that involves a third faction `C` that is not discovered by the current player, when the UI renders that event, then the faction `C` is shown as `Unknown faction` while `A` and `B` (if discovered) are shown by their normal display names.
- **Diplomacy Detail — dossier subpanel:** Given the Diplomacy Detail view is open for Great Power `B` (and the current player controls Great Power `A`), when the UI renders the dossier subpanel, then it shows dossier sections for `B` per SPEC/ai/ai-dossier.md using only PlayerView-safe data and does not expose hidden agenda values directly.
