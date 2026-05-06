# Combat Resolution

## Responsibility

Conflict detection, auto-resolve pipeline, and application of combat outcomes to world state during the Combat phase.

## Data Model

**BattleContext:** Province id, defender side (faction id + unit ids), list of attacking sides (each: faction id + unit ids + **army id** + optional general id bound in pre-Combat), battle type (field / siege), province terrain and fort level snapshot. Province ids in BattleContext and in all conflict-detection inputs (unit locations, move-order destinations) are always the **prefixed** form `regionId|localId` per [../game/world-model-identity.md](../game/world-model-identity.md); conflict detection and resolution MUST NOT use bare local province ids. Land armies: [../game/military-armies.md](../game/military-armies.md).

**EngagementResult:** Winner side (attacker / defender / stalemate / mutual annihilation), casualty unit ids per side.

## Algorithm / Flow

### 1. Conflict Detection

**Input:** World state after the Movement phase (unit locations updated).

For each province with units from multiple factions:

1. Group units by faction.
2. Determine defender and attacker sides per game/combat.md § Rules (Attacker / Defender).
3. If ≥ 1 attacker and a defender exist, create a BattleContext.

**Output:** List of BattleContexts, ordered deterministically by province id (the prefixed `regionId|localId` form).

### 2. Initiative Ordering

Per BattleContext, compute initiative per attacking side per game/combat.md § Rules (Initiative). Sort descending. For exact ties, use one deterministic RNG tie-break for the whole BattleContext (seeded from combat seed + context identity), not lexical faction id.

### 3. Pre-Combat general binding and ledger

**Pre-Combat step (once per Combat phase, before §1 conflict detection or immediately before first battle — same ordering as turn-resolution orchestration):** Bind generals to **armies** per [military-generals.md](../game/military-generals.md): each **attacking army** that will appear in any `BattleContext` this phase receives at most one general from its faction’s pool; each **defending army** in a contested province receives defender binding when the pool allows. Persist bindings on `BattleContext` attacking sides (`generalId`, `generalMedals`) and defender side medals from the **primary defending army** rule in [military-armies.md](../game/military-armies.md). If binding cannot assign a general, set `generalMedals` from leader fallback mapping (same as below) and null `generalId` for that side.

**Combat phase ledger (turn-wide attack cap):** The Combat phase maintains a mutable **ledger** (not a global singleton), created at the start of the phase. For each faction id, the ledger records which general ids are **already bound to an attacking army** this phase. Pre-Combat binding **consumes** generals for attacking armies subject to: no general id may be bound to two **attacking** armies in the same phase. **Completed battle** steps append attacking `generalId` to the ledger when non-null (for parity with prior replay tests) **or** ledger is fully established at pre-Combat — TDD chooses one approach; Quick Battle and auto-resolve must match. Defender binding does **not** consume attacking ledger slots. **Any** faction id present as `General.ownerId` uses the same rules (not only Great Powers).

**Binding RNG:** Pre-Combat binding for auto-resolve and Quick Battle uses the same deterministic seed recipe: `hash(globalGameSeed, turnNumber, "preCombatGenerals")` extended with per-army tie-breaks as needed (program-level `Object.hash` or equivalent).

**Quick Battle:** `buildQuickBattleInput` must use the same pre-Combat bindings + ledger + fallback rules as auto-resolve. **Primary attacker** for Quick Battle initiative and attacker medal inputs is the **first** entry in `BattleContext.attackers` (same as `QuickBattleInput.attackerFactionId`). Defender medal inputs use the defender binding from the same pre-Combat pass.

If a side has no assignable general (empty pool after exclusions), derive fallback `generalMedals` from leader combat multiplier (`leader-bonuses.md`) using this mapping:

- multiplier `>= 1.25` => 4 medals
- multiplier `>= 1.20` => 3 medals
- multiplier `>= 1.15` => 2 medals
- multiplier `>= 1.10` => 1 medal
- else => 0 medals

In multi-attacker chains, when the winner of engagement _n_ becomes defender in engagement _n+1_, reuse that winner side's assigned/fallback `generalMedals` for the carried defender role.

When an engagement is won by a side with an assigned general record, increment that general's medals by exactly `+1` (cap at 4) and persist to game state immediately so later engagements in the same BattleContext observe updated medals. Medal gain is per engagement win, not per BattleContext aggregate.

When the **entire** Combat phase ends, **release** all general–army bindings for the next turn. If the implementation records attacking `generalId` on the ledger per **completed** battle instead of only at pre-Combat, **after** each completed land battle append each attacking side’s `generalId` (when non-null) for that attacker’s `factionId` consistent with [military-generals.md](../game/military-generals.md).

### 4. Deployment Limit (per side)

Before running the per-engagement resolver, cap each side’s participating regiments to the deployment limit per [military-generals.md](../game/military-generals.md): **base 10** (or **12** if the faction has Nationalism tech) **+1 per general medal**. Only the capped subset participates in strength and casualty computation; excess units do not take or deal damage in that engagement. Defender general medals come from the defender’s assigned general (or 0 if no general assigned).

### 5. Per-Engagement Resolver

**Input:** One attacker side (capped unit list, generalMedals set per §3), current defender side (capped unit list, defender generalMedals set per §3), province snapshot, ruleset config, optional RNG seed.

Steps:

1. Aggregate strength per side per game/combat.md § Rules (Strength).
2. For Minor Nation defenders, apply effective military level per [factions.md](../game/factions.md); for Tribe defenders, effective military level is always 1 (no parity).
3. Apply siege modifiers if fort present per [siege-mechanics.md](../game/siege-mechanics.md).
4. Apply terrain, difficulty, general, and feeding modifiers per game/combat.md § Rules (Modifiers). Apply **leader bonus** per [leader-bonuses.md](../game/leader-bonuses.md): multiplier from each side's GP leaderKey (attackerLeaderMultiplier, defenderLeaderMultiplier). Apply **general morale aura** per [military-generals.md](../game/military-generals.md): 5% strength bonus per general medal, max 20%. **Difficulty** is not yet passed into the resolver; when game/config provides difficulty, apply it in this step. **Strength aggregation** (step 1): currently (FPN + FPM) × medalMult per unit only; DEF/9 and damaged-unit health scaling are deferred per GDD.
5. Compute winner and casualties. Pure function; no side effects.

**Output:** EngagementResult.

**Implementation note:** Conflict detection supplies **army id** per attacking side; **generalMedals** and `generalId` come from **pre-Combat binding** (§3) unless TDD merges binding into conflict detection in one pass. Record which general commanded each side so medal gain can be applied to the winning general per military-generals.md and this spec's per-engagement medal progression rule. DEF/9 in strength/casualties and unit health scaling are deferred. Difficulty is not wired from game config into the resolver.

### 6. Resolution Chain

Per BattleContext:

1. Maintain mutable views of defender and attacker unit lists.
2. Iterate attackers in initiative order:
   - Run per-engagement resolver.
   - Apply casualties to local views.
   - Interpret outcome per game/combat.md § Rules (Outcomes).
   - On mutual annihilation with remaining attackers: recover garrison per game/combat.md — regiment **count** from Recovery % (§ Configurable Values) and regiment **type** from § Garrison recovery type (most-advanced infantry at defender effective era `E`, deterministic tie-break, `peasant_levies` fallback). Logic: `garrisonRecoveryRegimentTypeForEra` in `packages/colonizethis_data/.../combat_config.dart`; applied when `resolveBattleContext` spawns `recover_*` units.
3. After chain completes, apply to world state in a single pass:
   - Remove casualty units.
   - Flip province ownership if defender eliminated per game/combat.md § Rules (Province Flip).
   - **Clear purchased land on conquest:** When a province changes hands (ownerId updated due to attacker victory), remove any entries in `purchasedTilesByTileKey` whose tile keys belong to that province (tile’s province id matches the conquered province id). This models the rule “if the aggressor conquers the province, any purchased land will revert to the new province owner”: after conquest, extraction/connectivity treat the province as owned entirely by the new owner, and no GP retains special purchased-land rights in that province.
   - **Civilian ownership-change legality relocation pass:** After ownership and purchased-land updates are applied, run a legality pass for civilian units in the changed province only. For each civilian in that province, evaluate standing legality using the same tile-occupancy rule used for civilian movement/work (`civilianMayOccupyLandTileKey` in program implementation terms). If a civilian is illegal under that rule, relocate it to its owner capital tile and normalize state (`status = idle`, clear `currentWork`, clear assignment tracking). If the owner capital tile cannot be resolved for a civilian that must relocate, fail with a hard error.
   - **Fort downgrade (auto-resolve path):** Not yet tied to “all emplaced guns destroyed” — auto-resolve uses aggregate emplaced strength without per-gun HP. When a future spec defines an aggregate proxy for fort downgrade, apply `province.fortLevel = (current - 1).clamp(0, 3)` in this pass when that condition holds.

**Quick Battle path — fort downgrade:** Per [siege-mechanics.md](../game/siege-mechanics.md) and [quick-battle-resolution.md](quick-battle-resolution.md), when combat is resolved via Quick Battle and **all virtual emplaced guns** are destroyed in that battle, `applyQuickBattleResultToGame` (or equivalent) **must** set `province.fortLevel = max(0, current - 1)` for that province **even if** the defender holds the province or the outcome is mutual exhaustion. This is independent of the auto-resolve application step above until auto-resolve gains a matching rule.

**Where ownership and regiment fort snapshot apply:** Regiment casualties and province ownership updates use the existing chain. Fort level changes from Quick Battle emplaced destruction apply in the Quick Battle result application path only (until auto-resolve is aligned).

### 7. Probabilistic Resolver (Simulation Only)

Separate resolver for simulation and Monte Carlo analysis; **not** used in the main game loop.

- Up to 5 rounds per engagement.
- Hit probability: `P_a = E_a / (E_a + E_d)`, clamped to [0.15, 0.85].
- Expected casualties: `λ = k × P` (k = 1.0), sampled from Poisson(λ), capped by remaining units.
- Casualty selection: strength-weighted (weight ∝ 1 / (strength + 0.1)).
- Deterministic given same seed.

## Observability

Structured **land** combat logs (`combat …` tokens after the `logic` prefix) are specified in [logging/turn-resolution.md](logging/turn-resolution.md) § Land combat: conflict detection, `battle_start`, per-engagement (debug, auto-resolve), and `battle_apply`. Global logger emission does not change resolver return values or determinism of game state.

## Integration

- **Phase:** Combat phase, after Movement.
- **Upstream:** Movement phase (unit positions), ruleset config (tactical stats, modifiers). Leader bonus application: [leader-bonuses.md](../game/leader-bonuses.md).
- **Downstream:** Province ownership updates, unit removal; connectivity and extraction recompute next turn.

## Constraints

- Per `BattleContext`, given the same `Game` snapshot, `BattleContext`, feeding coverage map, pre-Combat binding RNG seed (§3), and **ledger state** (whether established at pre-Combat or updated per battle per TDD), resolution is deterministic; the turn-wide attack cap is enforced via general–**army** binding rules in [military-generals.md](../game/military-generals.md).
- Resolver is a pure function: same inputs (including seed) → same **returned** `Game` / world state. Emitting logs via the global Dart `logger` is allowed for observability and is not part of the functional output.
- No global RNG access; callers provide explicit seed when randomness is needed.
- Province battles are independent; processing order is deterministic (prefixed province id `regionId|localId`).
- Results applied in a single pass after full chain resolution per BattleContext.

## Acceptance criteria (program)

- Given pre-Combat binding runs and a faction has general cap **G** with **G** distinct generals, when **G** distinct **attacking armies** of that faction enter land combat this phase, then each of those armies receives a **different** bound `generalId` when RNG selects from the pool, and no `generalId` is bound to two attacking armies in the same phase.

- Given a battle flips province ownership for province **P** and there is at least one civilian unit currently in **P** owned by a faction that cannot legally occupy its standing tile under civilian tile-occupancy legality, when the combat result is applied, then the system relocates each such civilian to that unit owner’s capital tile and normalizes that civilian state to `idle` with `currentWork`, `originTileKey`, and `assignedTileKey` cleared.

- Given the same ownership-flip context and a civilian in changed province **P** remains legal on its current tile under civilian tile-occupancy legality, when combat result application runs the ownership-change legality pass, then the system keeps that civilian on its current tile and does not relocate it solely because ownership changed.

- Given a battle flips ownership for province **P** and a civilian in **P** must relocate under legality rules but the owner capital tile cannot be resolved, when combat result application executes the legality relocation pass, then the system throws a hard error and does not silently drop or leave that civilian in an illegal state.

- Given one general **G1** for faction **F** and **G1** is already bound to an attacking army this Combat phase, when pre-Combat binding runs for **another** attacking army of **F** and no other general is free, then that army’s attacking side receives **fallback** leader-derived medals and no assigned attacking `generalId`.

- Given general **D** was bound to a defending army that fought earlier in the same Combat phase, when pre-Combat binding runs for a later defender (or the same faction defends again under pool rules), then **D** may be eligible again per [military-generals.md](../game/military-generals.md) (defender binding does not use the attacking ledger).

- Given identical `Game` (including `globalGameSeed`), turn number, and the same set of `BattleContext`s, when the system runs **pre-Combat binding** for auto-resolve and for Quick Battle input build, then both use the same binding RNG recipe and produce the same bound general ids and medal counts for attacker (per attacking army) and defender.

- Given `buildQuickBattleInput` is called with a defender faction that has an assigned general with **M** medals (0 ≤ M ≤ 4) under §3 rules  
  When the built `QuickBattleInput` is read  
  Then `defenderGeneralMedals` equals **M** (or fallback count when no defender general is assigned).

- Given `BattleContext.attackers` has a first entry for faction **A** with **M** attacker medals under §3 for that battle  
  When `buildQuickBattleInput` runs for that context  
  Then `attackerGeneralMedals` equals **M** for that primary attacker (first list entry), not a sum of `AttackingSide.generalMedals` from conflict detection alone.

- Given an engagement ends in mutual annihilation, at least one attacker remains later in the multi-attacker chain, and the defending faction’s effective military era is **E** (per game/factions.md and resolver inputs)  
  When `resolveBattleContext` applies garrison recovery  
  Then every spawned recovered regiment’s `type` equals `garrisonRecoveryRegimentTypeForEra(E)` from `combat_config.dart` (same value as game/combat.md § Garrison recovery type).
