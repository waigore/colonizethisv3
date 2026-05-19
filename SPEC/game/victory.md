# Victory

**SPEC/game** — Victory conditions and resolution. Reference: GDD 01. Current scope: military victory only.

---

## Current scope: Military Victory Only

- **Condition:** A Great Power controls **31 or more Old World provinces**. Control means the province’s owner is that Great Power (i.e. the province’s `ownerId` equals the GP’s player id).
- **Province identity:** Ownership and counting of provinces for the victory check use the same province identity and lookup rules as the rest of the game: prefixed province id (`regionId|localId`) and region-scoped lookup. See [world-model-identity.md](world-model-identity.md). The **Old World** region identity (e.g. `oldWorld`) is defined in [world-model.md](world-model.md) (§ Regions).
- **Eligibility:** Only Great Powers are eligible. Minor Nations and Tribes do not win.
- **Tie-breaking:** If two or more GPs each control ≥31 OW provinces in the same turn, the winner is the one with the lexicographically smallest player id (deterministic).

---

## Calendar campaign end (no military victory)

When the campaign reaches the **calendar cap** (`Game.calendarCampaignHalted == true`) per [turn-time-mapping.md](turn-time-mapping.md) § Campaign calendar cap, **`Game.victory` remains null**; the session is finished for turn-advance purposes but there is no military `VictoryState`. Calendar halt is **not** a victory type and does not set `Game.victory`. Campaigns with `Game.infiniteMode == true` skip the calendar halt and end only via military victory (or player exit).

- **Declared winner (observers / summaries):** Among Great Powers in `Game.players`, the winner is the player id with the **strictly highest** `greatPowerPowerScore` (see [diplomacy.md](diplomacy.md) § Great Power power score). If two or more GPs tie for the highest score, or there are no eligible scorers, the declared winner is **no-one** (represented as a null/absent winner id in summary JSON).
- **UI:** The app must not allow further full-turn resolution when `calendarCampaignHalted` is true (same blocking category as military victory for “Next turn”); presentation of a non-military campaign-complete screen is deferred to UI spec.

---

## Victory Check

- **When:** At the **end of each turn**, after all phases (Orders through Build/Work) have run, during the **End-of-turn** phase.
- **Logic:** Count Old World provinces by owner; if any GP has count ≥ 31, set the game’s victory state (winner player id, victory type military, turn number). If victory is already set, leave it unchanged (no re-check).
- **State:** `Game.victory` holds `VictoryState` (winnerPlayerId, type, turnNumber). When non-null, the game is finished.
- **Implementation:** See [turn-resolution-phase-details.md](../program/turn-resolution-phase-details.md) § End-of-turn (step (1)).

---

## Acceptance criteria

- **Check timing:** Victory is evaluated once per turn during the End-of-turn phase, after all other phases (Orders through Build/Work) have run; see [turn-resolution-phase-details.md](../program/turn-resolution-phase-details.md) § End-of-turn.
- **Condition:** A Great Power wins (military victory) when it controls ≥31 Old World provinces; control is province `ownerId` equals that GP’s player id; province identity and counting use prefixed id and region-scoped lookup per [world-model-identity.md](world-model-identity.md). **current product:** The 31-province threshold is **fixed** (not ruleset-configurable). This may be made configurable in a future phase.
- **Idempotence:** If `Game.victory` is already set, the check does not overwrite it (no re-evaluation).
- **Tie-breaking:** When two or more GPs each have ≥31 OW provinces in the same turn, the winner is the one with the lexicographically smallest player id.
- **UI:** When `Game.victory != null`, the app shows the victory screen and does not allow further orders or turn advancement.

---

## Victory Screen (UI)

- When `Game.victory != null`, the app shows a **victory screen** (overlay or dedicated view).
- **Content:** Winner’s display name, victory type label (e.g. “Military victory”), turn number. Option to **return to main menu** or **view final state** (continue viewing the map without further turns).
- No further orders or turn advancement once victory is set.

---

## Out of scope

Alternative victory types (Economic, Scientific, Peaceful, Score) are not implemented. They may be added in a later phase per GDD.
