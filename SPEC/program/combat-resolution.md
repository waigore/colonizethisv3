# Combat Resolution

## Responsibility

Conflict detection, auto-resolve pipeline, and application of combat outcomes to world state during the Combat phase.

## Data Model

**BattleContext:** Province id, defender side (faction id + unit ids), list of attacking sides (each: faction id + unit ids + optional general id), battle type (field / siege), province terrain and fort level snapshot.

**EngagementResult:** Winner side (attacker / defender / stalemate / mutual annihilation), casualty unit ids per side.

## Algorithm / Flow

### 1. Conflict Detection

**Input:** World state after the Movement phase (unit locations updated).

For each province with units from multiple factions:

1. Group units by faction.
2. Determine defender and attacker sides per game/combat.md § Rules (Attacker / Defender).
3. If ≥ 1 attacker and a defender exist, create a BattleContext.

**Output:** List of BattleContexts, ordered deterministically by province id.

### 2. Initiative Ordering

Per BattleContext, compute initiative per attacking side per game/combat.md § Rules (Initiative). Sort descending; tie-break by faction id.

### 3. General assignment (per BattleContext)

Before resolving a BattleContext, assign generals per [military-generals.md](../game/military-generals.md): for each attacking side, assign one uncommitted general at random (or none if the faction has no uncommitted general); for the defender, assign one uncommitted general at random (or none, in which case defender general medals = 0). Populate each side’s `generalMedals` from the assigned general’s medals. When the **entire** BattleContext resolution (full multi-attacker chain) completes, **free** all generals assigned to that battle so they may be assigned again in a subsequent BattleContext the same turn.

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

**Implementation note:** Conflict detection currently does not perform general assignment; when implemented, run the assignment step (§3) before resolution and pass resulting generalMedals into the resolver. Record which general commanded each side so medal gain can be applied to the winning general per military-generals.md. DEF/9 in strength/casualties and unit health scaling are deferred. Difficulty is not wired from game config into the resolver.

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
   - **Fort downgrade (when implemented):** When the fort-downgrade condition is defined and implemented (per [siege-mechanics.md](../game/siege-mechanics.md) and issue #25), apply it in this same pass: if the condition holds for the battle province (e.g. all emplaced guns destroyed), set `province.fortLevel = (current - 1).clamp(0, 3)` when building the updated province list for that BattleContext.

**Where ownership and fort level are applied:** The same application step that updates province ownership and unit lists is the single place that must also apply fort level change when the condition holds. In the main game loop this is the logic inside `resolveBattleContext` that builds the updated region (provinces and units). The quick-battle path (`applyQuickBattleResultToGame`) applies outcomes in a separate code path; when fort downgrade is implemented, that path must apply the same fort-level update so both resolution paths keep the TDD as source of truth. See issue #24 for implementation.

### 7. Probabilistic Resolver (Simulation Only)

Separate resolver for simulation and Monte Carlo analysis; **not** used in the main game loop.

- Up to 5 rounds per engagement.
- Hit probability: `P_a = E_a / (E_a + E_d)`, clamped to [0.15, 0.85].
- Expected casualties: `λ = k × P` (k = 1.0), sampled from Poisson(λ), capped by remaining units.
- Casualty selection: strength-weighted (weight ∝ 1 / (strength + 0.1)).
- Deterministic given same seed.

## Integration

- **Phase:** Combat phase, after Movement.
- **Upstream:** Movement phase (unit positions), ruleset config (tactical stats, modifiers). Leader bonus application: [leader-bonuses.md](../game/leader-bonuses.md).
- **Downstream:** Province ownership updates, unit removal; connectivity and extraction recompute next turn.

## Constraints

- Resolver is a pure function: same inputs (including seed) → same output.
- No global RNG access; callers provide explicit seed when randomness is needed.
- Province battles are independent; processing order is deterministic (province id).
- Results applied in a single pass after full chain resolution per BattleContext.
