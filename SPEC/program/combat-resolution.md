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

### 3. Deployment Limit (per side)

Before running the per-engagement resolver, cap each side’s participating regiments to the deployment limit per [military-generals.md](../game/military-generals.md): **base 10** (or **12** if the faction has Nationalism tech) **+1 per general medal**. Only the capped subset participates in strength and casualty computation; excess units do not take or deal damage in that engagement. Defender general medals are not yet modelled (treated as 0).

### 4. Per-Engagement Resolver

**Input:** One attacker side (capped unit list), current defender side (capped unit list), province snapshot, ruleset config, optional RNG seed.

Steps:

1. Aggregate strength per side per game/combat.md § Rules (Strength).
2. For Minor Nation / Tribe defenders, apply effective military level per [factions.md](../game/factions.md).
3. Apply siege modifiers if fort present per [siege-mechanics.md](../game/siege-mechanics.md).
4. Apply terrain, difficulty, general, and feeding modifiers per game/combat.md § Rules (Modifiers). **General morale aura** (bonus scaling with general medals) is deferred until general/medal state is modelled.
5. Compute winner and casualties. Pure function; no side effects.

**Output:** EngagementResult.

**Deferred:** General medals are not yet read from game state (conflict detection passes 0); initiative still uses cavalry share. When general/medal state exists, populate `AttackingSide.generalMedals` in conflict detection and apply general morale aura in step 4.

### 5. Resolution Chain

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

### 6. Probabilistic Resolver (Simulation Only)

Separate resolver for simulation and Monte Carlo analysis; **not** used in the main game loop.

- Up to 5 rounds per engagement.
- Hit probability: `P_a = E_a / (E_a + E_d)`, clamped to [0.15, 0.85].
- Expected casualties: `λ = k × P` (k = 1.0), sampled from Poisson(λ), capped by remaining units.
- Casualty selection: strength-weighted (weight ∝ 1 / (strength + 0.1)).
- Deterministic given same seed.

## Integration

- **Phase:** Combat phase, after Movement.
- **Upstream:** Movement phase (unit positions), ruleset config (tactical stats, modifiers).
- **Downstream:** Province ownership updates, unit removal; connectivity and extraction recompute next turn.

## Constraints

- Resolver is a pure function: same inputs (including seed) → same output.
- No global RNG access; callers provide explicit seed when randomness is needed.
- Province battles are independent; processing order is deterministic (province id).
- Results applied in a single pass after full chain resolution per BattleContext.
