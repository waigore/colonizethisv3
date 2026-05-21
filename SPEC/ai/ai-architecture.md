# AI Architecture (Phase 6)

**SPEC/ai** — Hybrid AI stack for current product. Source: GDD 10b.

---

## Overview
Characterful, deterministic AI using only observable game state. Difficulty affects starting resources and ruleset modifiers, not AI logic.

## Rules

### Design Principles
- Each leader feels distinct via personality (see [ai-personalities.md](ai-personalities.md)).
- Deterministic: same game state and seeds → same decisions.
- PlayerView-only: AI never reads hidden tiles or enemy data.
- Difficulty via params only: same algorithm at all difficulty levels.

### Hybrid Stack

| Layer | System | Purpose |
|-------|--------|---------|
| Goal management | Behavior trees | Long-term strategy (expand, defend, trade, conquer, tech, diplomacy) |
| Strategic | Utility AI | Domain decisions: economy, military, diplomacy, research |
| Tactical | Shallow search / heuristics | Quick Battle actions; local move/attack |

Behavior trees pick top-level goals; utility AI scores and selects concrete objectives; tactical layer produces combat and movement orders.

**Goal selection implementation:** Goal selection may be implemented as **weighted choice** over strategic goals (expand, defend, trade, conquer, tech, diplomacy) using personality weights, agenda modifiers, and situational snapshot. This satisfies the "behavior tree" requirement when interpreted as hierarchical goal selection. Strict behavior-tree node structure (sequences, selectors) is optional and may be used where designer-editable trees are desired. **Weighted choice is the current implemented approach**; strict behavior-tree structure is deferred to future phases when designer-editable AI trees are required (e.g. for mod support or external AI editors).

### Turn Pipeline (per AI Great Power)
1. **Perception** — Derive observable snapshot: threats, opportunities, economy, relations. All from PlayerView; no hidden data.
2. **Goal selection** — Choose strategy (e.g. weighted choice over goals) using personality weights and hidden agenda modifiers.
3. **Domain planning** — Economy, military, diplomacy, research planners score candidates via personality and agenda weights; each emits candidate orders. The **economy planner** also produces **production assignments** (worker allocation to recipes) and a **cargo preference** for naval/build; see [economy-planner.md](economy-planner.md).
4. **Execution** — Combine, cap, and validate orders; emit dialogue/mood events. Strategic AI may emit **optional** agenda-flavoured dialogue and a matching base PortraitMoodEvent for each AI leader on a deterministic cadence derived from the dialogue seed (see [dialogue-and-mood.md](dialogue-and-mood.md) § When to emit for `kDialogueTurnsBetweenComments` and cadence rules).
5. **Tactical** — Quick Battle: CP-based actions per lane, deterministic given state and seed.

**Full AI civilian work observability (Refs #2082):** When domain planners emit civilian `WorkOrder` choices from `suggestWorkOrders`, the `ai` package logger emits **`Level.info`** lines (prefix `ai:`) — one per emitted order: tag **`civilian_work_assigned`** with `nationId`, `unitId`, `unitType`, `target`, `targetTileKey`; and one per idle civilian with no new work: tag **`civilian_work_idle`** with `nationId`, `unitId`, `unitType`, `reason` (e.g. `no_suggestions`). No summary-only line replaces per-unit lines.

### Tactical Behavior Rules
- Prefer occupying good terrain (hill, town, woods) with high-value units.
- Avoid exposing fragile units in swamp unless numerically overwhelming.
- Use Volley Fire / Defend when outmatched or holding key lanes (especially center).
- Use Maneuver / Fall Back to rotate damaged units or shift strength to threatened flanks.
- Use Assault / Charge when enemy lane is disrupted and terrain is favorable.

### Strategic Behavior Preferences
AI uses the order suggestion API and applies:
- **Movement:** Prefer contested or enemy territory (at war); avoid factions at peace.
  - **Filter:** All AI paths (simple heuristics and full-AI domain planner) must drop move orders whose destination is owned by a faction at peace with the mover (or by a Minor with no war). No move into at-peace or minor-without-war territory.
  - **Prefer enemy:** When choosing among valid move candidates, score moves into enemy (at-war) territory higher than moves into unowned or own territory; weighted selection then prefers enemy/contested. Default bonus +20 to score when destination owner is at war with the mover.
  - **Army parity with human rules:** AI `ArmyMoveOrder` generation uses the same legality as human move assignment: any player-owned destination province is valid across regions (no adjacency requirement), while non-owned destinations require normal adjacency/war validation.
- **Build/work:** Prefer cheaper orders improving owned, visible provinces.
- **Research:** Prefer lower-era, cheaper techs unlocking core capabilities.
- **Diplomacy (Full AI):**
  - Compute a per-pair `warDesireScore` (0..100) for GP↔target where target can be GP, Minor, or Tribe.
  - Use the same composite power basis as diplomacy power score (military + province + naval) for strength ratio.
  - Compute improve-relations desire as `100 - warDesireScore`.
  - Keep relation gate for war declarations.
  - Apply per GP-target pair cooldowns for war-declare and improve-relations retries.
  - While at war, recompute war desire each turn to decide continue-war vs offer-peace bias and adjust desired territory objective.
- **Province identity:** Movement targets, build provinces, and visibility use the **prefixed** form `regionId|localId` per [world-model-identity.md](../game/world-model-identity.md).

Seeded randomness selects among acceptable candidates; personality weights bias selection.

### Seeding
Per-turn seed: `turnSeed[P, T] = hash(globalGameSeed, aiSeed[P], T)`. Sub-seeds: perception, goals, economy, military, diplomacy, research, tactical, dialogue, agenda. Same save + seeds → same orders and events.

## Interactions
- [economy-planner.md](economy-planner.md) — worker allocation (production), cargo preference
- [ai-personalities.md](ai-personalities.md) — per-leader weights
- [hidden-agendas.md](hidden-agendas.md) — agenda modifiers
- [dialogue-and-mood.md](dialogue-and-mood.md) — event emission
- [world-model-identity.md](../game/world-model-identity.md) — province identity (prefixed id) in AI context
- Program: [ai-planner.md](../program/ai-planner.md) — control rules, order merge
- Program: [ai-systems-impl.md](../program/ai-systems-impl.md) — module boundaries, APIs

### Victory-aware military planning (Full AI)

Military victory requires a Great Power to control **≥31 Old World provinces** per [victory.md](../game/victory.md). Full AI must plan toward that threshold, not only declare war without follow-up invasion.

**Perception (`ConquestSummary` on `AIWorldSnapshot`):** From `PlayerView` only: `oldWorldProvincesOwned`, `provincesToVictory` (= max(0, 31 − owned)), `invadableProvinceIdsSorted` (adjacent enemy/minor/tribe Old World provinces reachable from owned territory or army positions), `adjacentOwnerFactionIdsSorted` (factions owning topologically adjacent Old World provinces, stable sort), `preferredConquestTargetFactionIdsSorted` (weak neighbors, current war targets, and adjacent owners, stable sort). Topology walks use **`combinedTopology`** node/edge ids (`regionId|localId` per [map-topology.md](../game/map-topology.md)); perception helpers match anchors and edge ends on both prefixed and local ids so invadable/adjacent lists are non-empty when borders exist.

**Goal selection:** Deterministic bonuses to `conquer` and military `expand` from `provincesToVictory` and non-empty `invadableProvinceIds` (weights in `colonizethis_data` `ai_victory_config.dart`). When `provincesToVictory > 20`, `conquer` score is floored at **`kMinimumConquerScoreWhenFarFromVictory`** so agenda penalties modulate intensity but cannot idle GPs far from the 31-province threshold. Declare-war scoring relaxes the relation cap for **minor/tribe** targets to **`kDeclareWarMinorMaxRelationWhenFarFromVictory`** under the same condition so peacemaker agendas still prosecute Old World minor conquest.

**Domain planner order (Full AI military):** After civilian move planning, **diplomacy (declare-war pass)** runs before invasion army moves so merged orders can include same-turn `declareWar` + `ArmyMoveOrder` (human parity per [app-ui-wiring.md](../program/app-ui-wiring.md)). Sequence: declare-war diplomacy → **conquest army-move pass** (suggestions against orders that already contain declare war) → relocation/at-war army-move pass → naval → diplomacy (non–declare-war pass; no duplicate declare war to the same target) → research. Staged progress id `aiStageD` covers the military block (declare war, conquest invasion, army relocation). The declare-war pass calls **`suggestDeclareWarOrders`** (not `suggestDiplomaticOrders`) so trade-focused leaders are not blocked from war by per-target `establishOverture` winning the primary suggestion pass ([order-suggestions.md](../program/order-suggestions.md)).

**Field army prep:** Before the declare-war pass, when `conquer` is active or `provincesToVictory` exceeds the build-pace threshold, Full AI may call `applyArmySplit` on the planning `Game` so regiments leave the **Home Army** (which cannot march) into a **field army** at the capital. The mutated `Game` is what order suggestion and turn validation use for that turn (same pattern as human split-then-move).

**Conquest army-move pass:** Uses `suggestArmyMoveOrders` with draft orders including any declare war chosen this turn; diplomacy filtering treats pending same-turn `declareWar` toward the destination owner as sufficient for invasion (logic `filterArmyMoveOrdersByDiplomacy` with `draftOrders`). Prefer destinations owned by the declare-war target, then other at-war owners, then provinces in `invadableProvinceIdsSorted`.

**Diplomacy targeting:** Forced **offerPeace** toward the sole at-war Great Power when this GP is below `kObserverConquestMinOwProvincesPerGp` and that enemy leads by at least `kUnwinnableSoleGpMinProvinceDeficit` OW provinces while holdings are at or below default observer start size **or** the Old World frontier is GP-only invadable, **or** leads by **1** OW province when holdings are **8–9** without a GP-only invadable frontier (pivot to minors), when OW holdings are at or below `kFewOldWorldProvincesDefendThreshold` and any OW minor remains (peace all GP wars), or when below the observer quota and at or below `kStalledOldWorldProvinceThreshold` even if minors were eliminated from the map (late-game survival peace), when at war with **two or more** Great Powers (non-blocker fronts; resolver accepts one-sided `offerPeace` per [diplomacy-resolution.md](../program/diplomacy-resolution.md)), when holdings are **8–9** OW and still below the observer quota (`nearQuotaHoldPeaceTargets`: peace non-invadable-blocker GP fronts when multi-front; sole GP enemy when not the invadable frontier blocker on a GP-only frontier), toward a mutual **8–9** OW plateau peer (`belowQuotaPeerGpPeaceTargets` / `isMutualBelowQuotaPlateauPeer`) even on a GP-only invadable frontier (observer seed-42 gp5/gp6 stalemate), when this GP already meets the observer quota and a below-quota Great Power at war does not own this GP's invadable OW frontier (exit futile bullying wars; observer seed-42 gp4/gp3), declare-war on a below-quota adjacent GP is suppressed (score 0) when the attacker already meets the observer quota and is not yet at war with that target, when the target has **zero regiments** and is not yet at war with the attacker (defenseless-victim anti-dogpile), when the target is below quota and already at war with one Great Power through turn `kDeclareWarEarlyAntiDogpileMaxTurn`, or at any turn when the attacker already meets the observer quota (one concurrent GP attacker per below-quota victim; observer seed-42 gp3/gp4 chronic front), or through that turn when the attacker leads the below-quota target in OW holdings (anti-dogpile; observer seed-42 gp3/gp4), except toward the invadable OW frontier blocker, when stalled with **zero regiments** and any Great Power war remains (peace all GP fronts before elimination), when both sides of a sole GP war are mutual-plateau peers on the late-stalled "8-9 plateau" (both OW counts at or above `kMutualExhaustedGpStalemateMinOw`, both still below the observer quota, `isStalledOldWorldExpansion`, and `|ownOw - enemyOw| <= 1`) **and** both are exhausted in regiments (≤ `kMutualExhaustedGpRegimentMax`) **and** treasury (≤ `kMutualExhaustedGpTreasuryMax`) — `mutualExhaustedBelowQuotaGpStalematePeaceTargets` peaces the blocker even on a GP-only invadable frontier so both sides rebuild before re-engaging (observer seed-42 gp3/gp4 3-regiment 0-treasury stalemate), or when this GP holds at least `kObserverConquestConsolidateMinOwProvinces` and leads the sole enemy by `kConsolidateGainsSoleGpProvinceLead` or more (lock observer gains before a counter-offensive). Declare-war scoring adds `kDeclareWarBelowObserverQuotaMinorBonus` toward adjacent invadable OW minors while below the observer quota. Mutual `offerPeace` reciprocals include the frontier blocker when the offer is from these forced paths. Declare-war scoring adds a bonus toward weak-neighbor **Great Powers** when war desire is high (`ai_victory_config.dart`) and `provincesToVictory <= kSuppressGpDeclareWarMinProvincesToVictory` (endgame only). When `provincesToVictory > 20`, declare-war candidates also receive the full `conquerScoreBonusForProvincesToVictory` (not the quarter-scale used when nearer victory). Targets in `adjacentOwnerFactionIdsSorted` receive `kDeclareWarAdjacentOwnerBonus` (and an extra bonus for low-`warLikelihood` personalities) so trade-focused leaders declare on **reachable** minors instead of distant factions. When far from victory and `adjacentOwnerFactionIdsSorted` is non-empty, declare-war toward any other faction is suppressed. While `provincesToVictory > kSuppressGpDeclareWarMinProvincesToVictory`, declare-war on **any adjacent Great Power** is suppressed (score 0) so every GP secures Old World holdings from minors/tribes before GP-vs-GP redistribution (observer per-GP conquest gate). After that threshold, weak adjacent GPs may be targeted with `kDeclareWarGpMaxRelationWhenFarFromVictory`. GPs at or below `kStalledOldWorldProvinceThreshold` OW holdings receive `kDeclareWarStalledExpansionMinorBonus` on adjacent minors and a higher declare-war pass weight; GPs with **≥10** OW holdings receive `kDeclareWarSatedExpansionMinorPenalty` so early expanders do not monopolize minor conquest. Declare-war on a minor/tribe is suppressed when that faction owns **no** province in `invadableProvinceIdsSorted` (avoids wars on minors whose adjacent land was already taken). Targets that still own invadable provinces receive `kDeclareWarMinorWithInvadableProvinceBonus`. Goal selection caps trade weight when far from victory and adds extra defend weight when at war with few Old World holdings. Build selection adds a regiment weight bonus when `provincesToVictory` exceeds the configured pace threshold and the primary goal is military.

### Colonial expansion (Full AI)

New World province acquisition is a **supporting strategy** for the Old World military victory path (31 provinces per [victory.md](../game/victory.md)). Full AI pursues colonies and overseas extraction to fuel OW conquest; NW goals must **not** weaken OW victory-aware floors in `ai_victory_config.dart`.

**Perception (`ColonialSummary` on `AIWorldSnapshot`):** From `PlayerView` only: `newWorldProvincesOwned`, `invadableNewWorldProvinceIdsSorted` (non-owned `newWorld|` provinces reachable from GP-owned anchors through owned provinces and **sea zones**, including warp S–S links on **`combinedTopology`** — not direct P–P adjacency only), `adjacentNewWorldOwnerFactionIdsSorted` (owners of invadable NW provinces), `preferredColonialTargetFactionIdsSorted` (war targets, weak neighbors, adjacent NW owners — stable sort). Anchors include owned provinces and army locations.

**Goal selection:** When `invadableNewWorldProvinceIdsSorted` is non-empty, deterministic bonuses to `expand` and `conquer` (`kColonialExpandBonusWhenInvadableNw`, `kColonialConquerBonusWhenInvadableNw`) without reducing `kMinimumConquerScoreWhenFarFromVictory` or other OW conquest floors. When `newWorldProvincesOwned` is below `kColonialFewNwProvincesThreshold` **and** acquisition targets remain, add `kColonialConquerBonusWhenFewNwProvinces` to `conquer`. While sea-reachable unowned NW provinces or adjacent tribe/minor owners remain (`hasColonialAcquisitionTargets`), apply colonial pressure floors (`kMinimumColonialExpandScoreWhenPressure`, `kMinimumColonialConquerScoreWhenPressure`, diplomacy/trade penalties) even after the GP owns `kColonialFewNwProvincesThreshold` or more NW provinces — late-game clearing of the last tribes must not drop NW pursuit.

**Diplomacy:** Declare-war scoring adds `kDeclareWarColonialInvadableOwnerBonus` toward tribe/minor factions owning a sea-reachable invadable NW province, plus `kDeclareWarColonialAdjacentTribeBonus` when listed in `adjacentNewWorldOwnerFactionIdsSorted`. Those targets are **not** suppressed by the OW-only non-adjacent declare-war guard when far from victory. Colonial pressure penalties on OW minors are **off** while the GP is below the observer OW conquest quota. When OW holdings are at or below `kStalledOldWorldProvinceThreshold` **and** `invadableProvinceIdsSorted` is non-empty, `kDeclareWarStalledOwMinorPriorityBonus` favours adjacent OW minors and `kDeclareWarStalledExpansionTribePenalty` discourages tribe wars that do not own a sea-reachable NW province for this GP (turn-100 observer gate). While any OW minor remains and `turnNumber <= kDeclareWarEarlyExpansionMaxTurn`, `kDeclareWarEarlyExpansionMinorBonus` / `kDeclareWarEarlyExpansionTribePenalty` apply the same preference in the early expansion window before minors are eliminated. `establishOverture` toward `preferredColonialTargetFactionIdsSorted` receives `kEstablishOvertureColonialTribeBonus`. Weight tuning only — no hard skip that removes all tribe declare-war candidates for intervention risk.

**Military:** Conquest army-move pass scores destinations in `invadableNewWorldProvinceIdsSorted` with `kConquestArmyMoveNwInvadableBonus` in addition to OW invadable bonuses.

**Economy / civilian:** Full AI Builder work selection prefers `build_improvement` on unimproved resource tiles (higher score when `improvementLevel` is 0 and the tile has a resource; extra weight for `newWorld|` tiles and again when the province is GP-owned) before lexicographic fallback among other work targets. Merchant units prefer `purchase_land` in `newWorld|` tribe/minor provinces via scored selection. Civilian work runs when colonial invadable or adjacent NW owners exist even if economy weight is below the default threshold (`kColonialCivilianWorkThresholdCap`). Build-order pass uses `kColonialBuildOrderThresholdWhenOwnedNw` when the GP owns any NW provinces, and `kColonialBuildOrderThresholdWhenOwnedNwUnderPressure` when owned NW provinces remain **and** acquisition targets are still visible.

**Economy (cargo):** `runEconomyPlanner` boosts effective economy weight for `cargoPreference` when colonial targets exist (`kColonialCargoPreferenceEconomyBoost`; extra when the GP owns zero NW provinces).

**Naval:** `runNavalPlanner` adds `kColonialNavalWeightBonus` to naval domain weight when colonial invasion/colonization targets are visible, with floor `kColonialNavalMinWeightWhenPressure`, favouring fleets that enable overseas access. Naval move/mission ranking and multi-move caps apply whenever acquisition targets remain, not only while `newWorldProvincesOwned` is below `kColonialFewNwProvincesThreshold`.

**Observer gates (nightly):** Seed **42**, turn **150**: all `newWorld|` provinces GP-owned; **≥70%** of extractable GP resource tiles improved (level ≥ 1). See [run_observer_game-tool.md](../program/run_observer_game-tool.md). Turn **100** OW per-GP conquest gate unchanged.

### Observer goal phases (Full AI)

Deterministic phases from `PlayerView` → `AIWorldSnapshot` (`observer_goal_phase.dart`; Refs #2509 S10):

| Phase | When | Imperative |
|-------|------|------------|
| **EXPAND** | `oldWorldProvincesOwned < kObserverConquestMinOwProvincesPerGp` (10) | OW conquest first |
| **COLONIAL** | OW quota met and `hasColonialAcquisitionTargets` | NW acquisition |
| **DEVELOP** | OW quota met and no visible colonial targets | Improve extractable tiles |

**EXPAND suppressions:** No NW `declareWar` / `establishOverture` toward colonial targets, NW conquest army moves, colonial naval ranking/caps, `purchase_land` / NW `build_improvement` civilian work, or colonial-pressure goal/diplomacy floors. OW declare-war, OW army moves, OW improvements, economy, and research remain allowed.

**EXPAND:** `offerPeace` toward at-war Great Powers that do not own the primary invadable Old World frontier blocker when fighting two or more GPs. While uninvaded OW minors remain, also peace below-quota GP peers within three provinces (pivot off mutual-plateau distraction wars). On GP-only frontiers with no minor pivot, the weaker mutual-plateau peer may `declareWar` on the stronger peer.

**COLONIAL-lite** (turn ≥`kObserverColonialLiteMinTurn`, OW ≥`kObserverColonialLiteNearQuotaOw` and below quota, global `newWorld|` not all GP-owned): allows `establishOverture`, colonial naval/cargo; suppresses NW `declareWar`, invasion army moves, and `purchase_land` only.

**COLONIAL:** `offerPeace` toward at-war Great Powers that do not own the primary colonial NW frontier blocker when fighting two or more GPs; tribe/minor colonial wars continue until objectives clear.

**DEVELOP:** Suppresses all new `declareWar` and NW acquisition; forces civilian work selection with improvement-first threshold (`kDevelopCivilianWorkThresholdCap`); `offerPeace` toward all at-war Great Powers.

**Peace collection (S10):** `collectStalledGreatPowerPeaceTargets` applies phase peace targets first. Legacy `colonial_pressure` OW-expansion ratchet helpers run only in **EXPAND** and **COLONIAL-lite**; **COLONIAL** uses phase peace plus tribe-distraction peace and survival helpers; **DEVELOP** uses phase peace plus survival helpers only.

### Implementation (turn pipeline)
AI order generation runs so that orders are available for the **Orders** phase of turn resolution. Merge (human + AI) and application order are defined in [turn-resolution-phases.md](../program/turn-resolution-phases.md) (phase 1 Orders) and [turn-resolution-phase-details.md](../program/turn-resolution-phase-details.md) § Orders. Control rules and merge semantics: [ai-planner.md](../program/ai-planner.md); module boundaries and APIs: [ai-systems-impl.md](../program/ai-systems-impl.md).

## Acceptance criteria
- **Determinism:** Same game state and seeds produce the same AI decisions and orders; per-turn seed and sub-seeds as in § Seeding.
- **PlayerView-only:** AI reads only observable state; no hidden tiles or enemy-only data.
- **Turn pipeline:** AI emits orders that are merged with human orders in the Orders phase; phase sequence and application order per [turn-resolution-phases.md](../program/turn-resolution-phases.md), [turn-resolution-phase-details.md](../program/turn-resolution-phase-details.md).
- **Goal selection and domains:** Behavior tree or weighted goal selection drives strategy; utility AI (economy, military, diplomacy, research) scores candidates; personality and hidden agendas bias selection per § Rules.
- **Province identity:** Movement targets, build provinces, and visibility use prefixed form `regionId|localId` per [world-model-identity.md](../game/world-model-identity.md).
- **Movement (filter and prefer):** Move orders are filtered by diplomacy (no move to at-peace or minor-without-war). Among valid moves, selection prefers moves into enemy/contested territory via configurable score bonus.
- **Army movement parity:** AI-generated `ArmyMoveOrder` uses the same destination legality as human orders, including cross-region moves to any AI-owned province in prefixed province-id form.
- **Difficulty:** Difficulty affects starting parameters and ruleset modifiers only, not AI logic or personality.
- **Victory-aware conquest (Full AI):** Given the AI agent selects `declareWar` on faction T and valid army-move candidates into T’s provinces exist in `PlayerView`, when domain planning completes for that turn, then merged orders include both `declareWar` toward T and at least one `ArmyMoveOrder` into T’s territory (deterministic for fixed seed). Given a GP owns fewer than 20 Old World provinces, when goal scores are evaluated, then `conquer` or expand-with-hostile-opportunity receives a deterministic bonus from `provincesToVictory` (trace fields `provincesToVictory`, `invadableCount` on AI trace export).
