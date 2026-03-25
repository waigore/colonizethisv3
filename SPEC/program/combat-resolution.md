# Combat Resolution

## Responsibility

Conflict detection, auto-resolve pipeline, and application of combat outcomes to world state during the Combat phase.

## Data Model

**BattleContext:** Province id, defender side (faction id + unit ids), list of attacking sides (each: faction id + unit ids + optional general id), battle type (field / siege), province terrain and fort level snapshot. Province ids in BattleContext and in all conflict-detection inputs (unit locations, move-order destinations) are always the **prefixed** form `regionId|localId` per [../game/world-model-identity.md](../game/world-model-identity.md); conflict detection and resolution MUST NOT use bare local province ids.

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

### 3. General assignment (per BattleContext)

Before resolving a BattleContext, assign generals per [military-generals.md](../game/military-generals.md): for each attacking side, assign one uncommitted general at random (or none if the faction has no uncommitted general); for the defender, assign one uncommitted general at random (or none if unavailable). Populate each side’s `generalMedals` from the assigned general’s medals.

If a side has no uncommitted general, derive fallback `generalMedals` from leader combat multiplier (`leader-bonuses.md`) using this mapping:

- multiplier `>= 1.25` => 4 medals
- multiplier `>= 1.20` => 3 medals
- multiplier `>= 1.15` => 2 medals
- multiplier `>= 1.10` => 1 medal
- else => 0 medals

In multi-attacker chains, when the winner of engagement _n_ becomes defender in engagement _n+1_, reuse that winner side's assigned/fallback `generalMedals` for the carried defender role.

When an engagement is won by a side with an assigned general record, increment that general's medals by exactly `+1` (cap at 4) and persist to game state immediately so later engagements in the same BattleContext observe updated medals. Medal gain is per engagement win, not per BattleContext aggregate.

When the **entire** BattleContext resolution (full multi-attacker chain) completes, **free** all generals assigned to that battle so they may be assigned again in a subsequent BattleContext the same turn.

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

**Implementation note:** Conflict detection currently does not perform general assignment; when implemented, run the assignment step (§3) before resolution and pass resulting generalMedals into the resolver. Record which general commanded each side so medal gain can be applied to the winning general per military-generals.md and this spec's per-engagement medal progression rule. DEF/9 in strength/casualties and unit health scaling are deferred. Difficulty is not wired from game config into the resolver.

### 6. Resolution Chain

Per BattleContext:

1. Maintain mutable views of defender and attacker unit lists.
2. Iterate attackers in initiative order:
   - Run per-engagement resolver.
   - Apply casualties to local views.
   - Interpret outcome per game/combat.md § Rules (Outcomes).
   - On mutual annihilation with remaining attackers: recover garrison per game/combat.md § Configurable Values (Recovery %).
3. After chain completes, apply to world state in a single pass:
   - Remove casualty units.
   - Flip province ownership if defender eliminated per game/combat.md § Rules (Province Flip).
   - **Clear purchased land on conquest:** When a province changes hands (ownerId updated due to attacker victory), remove any entries in `purchasedTilesByTileKey` whose tile keys belong to that province (tile’s province id matches the conquered province id). This models the rule “if the aggressor conquers the province, any purchased land will revert to the new province owner”: after conquest, extraction/connectivity treat the province as owned entirely by the new owner, and no GP retains special purchased-land rights in that province.
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

Structured **land** combat logs (`logic: combat …`) are specified in [ctdev-logging.md](ctdev-logging.md) § Land combat: conflict detection, `battle_start`, per-engagement (debug, auto-resolve), and `battle_apply`. Global logger emission does not change resolver return values or determinism of game state.

## Integration

- **Phase:** Combat phase, after Movement.
- **Upstream:** Movement phase (unit positions), ruleset config (tactical stats, modifiers). Leader bonus application: [leader-bonuses.md](../game/leader-bonuses.md).
- **Downstream:** Province ownership updates, unit removal; connectivity and extraction recompute next turn.

## Constraints

- Resolver is a pure function: same inputs (including seed) → same **returned** `Game` / world state. Emitting logs via the global Dart `logger` is allowed for observability and is not part of the functional output.
- No global RNG access; callers provide explicit seed when randomness is needed.
- Province battles are independent; processing order is deterministic (prefixed province id `regionId|localId`).
- Results applied in a single pass after full chain resolution per BattleContext.
