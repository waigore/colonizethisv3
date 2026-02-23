# Victory

**SPEC/game** — Victory conditions and resolution. Reference: GDD 01. Current scope: military victory only.

---

## Current scope: Military Victory Only

- **Condition:** A Great Power controls **31 or more Old World provinces**. Control means the province’s owner is that Great Power (i.e. the province’s `ownerId` equals the GP’s player id).
- **Eligibility:** Only Great Powers are eligible. Minor Nations and Tribes do not win.
- **Tie-breaking:** If two or more GPs each control ≥31 OW provinces in the same turn, the winner is the one with the lexicographically smallest player id (deterministic).

---

## Victory Check

- **When:** At the **end of each turn**, after all phases (Orders through Build/Work) have run, during the **End-of-turn** phase.
- **Logic:** Count Old World provinces by owner; if any GP has count ≥ 31, set the game’s victory state (winner player id, victory type military, turn number). If victory is already set, leave it unchanged (no re-check).
- **State:** `Game.victory` holds `VictoryState` (winnerPlayerId, type, turnNumber). When non-null, the game is finished.

---

## Victory Screen (UI)

- When `Game.victory != null`, the app shows a **victory screen** (overlay or dedicated view).
- **Content:** Winner’s display name, victory type label (e.g. “Military victory”), turn number. Option to **return to main menu** or **view final state** (continue viewing the map without further turns).
- No further orders or turn advancement once victory is set.

---

## Out of scope

Alternative victory types (Economic, Scientific, Peaceful, Score) are not implemented. They may be added in a later phase per GDD.
