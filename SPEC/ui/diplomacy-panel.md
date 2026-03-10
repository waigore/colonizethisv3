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

- **Left:** Faction name (displayName or id), type badge (GP / Minor / Tribe), current **diplomatic state**: relation state (AT_PEACE / AT_WAR), relation level (Hostile / Neutral / Friendly / Allied), relation score (0–100). For Minor/Tribe: overture stage (none, Trade Consulate, Embassy, NAP, Join Empire) if any.
- **Right:** **Available diplomatic actions** for the player toward that faction. Actions are those explicitly in SPEC/game/diplomacy.md and SPEC/program/orders.md: Declare War, Offer Peace, Alliance (GP only), Establish Overture (stage), Grant Aid, Set Subsidy. Only show actions that are **valid** per the diplomatic order validator (same rules as order submission).

---

## Actions

- **No parameters:** Submit the overture/order immediately (e.g. Declare War, Offer Peace, Alliance).
- **Parameters required:** Open a **dialog** to collect amount (Grant Aid, Set Subsidy) or overture stage (Establish Overture); on confirm, submit the order.
- Orders are submitted into the current turn’s order set; resolution happens on Next Turn. The panel does not resolve orders itself.

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
- Given a faction row, the panel shows current relation state and level and, for Minor/Tribe, overture stage; to the right it shows only valid diplomatic actions for that faction.
- Given the user taps an action that requires no parameters, the UI submits that diplomatic order for the current turn.
- Given the user taps an action that requires parameters (amount or overture stage), the UI shows a dialog; on confirm, the UI submits the order with the chosen parameters.
