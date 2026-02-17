# Combat Resolution

**SPEC/program** — Conflict detection and auto-resolve pipeline. Reference: [combat.md](../game/combat.md), [military-units.md](../game/military-units.md), [siege-mechanics.md](../game/siege-mechanics.md), [turn-resolution-phases.md](turn-resolution-phases.md), [movement.md](movement.md).

---

## Battle Model

Combat is orchestrated around a **battle context per province**.

- **BattleContext:** province id, defender side (owner faction id + unit ids), list of **attacking sides** (one per attacking army: faction id + unit ids + optional general id), battle type (field or siege), snapshot of province terrain and fort level.
- Within a BattleContext, the defender may fight multiple attacking sides in sequence (multi‑attacker chain; see [combat.md](../game/combat.md)).

---

## Conflict Detection

**Input:** WorldState after the movement phase (unit locations updated; movement orders applied).

**Logic:** For each province that has at least one unit:

1. Group units by faction id.
2. Determine **defender**: province owner if any; otherwise the faction that did **not** move in this turn (tie‑break by lowest faction id if both moved). Defender side = defender faction id + all of its units in the province.
3. Determine **attackers:** for each Great Power that moved units into the province this turn (based on MoveOrders), construct an attacking side = faction id + just the units that moved in (or that are assigned to its army).
4. If there is at least one attacking side and a defender side, create one BattleContext for the province containing defender + list of attackers.

**Output:** A list of BattleContexts, one per contested province. Global ordering between provinces can be by province id; ordering of attackers **within** a BattleContext is handled by initiative (below).

---

## Initiative and Ordering

For each attacking side in a BattleContext, compute an **army initiative score**:

- Inputs: unit composition (e.g. cavalry share), attached general medals, difficulty modifiers.
- Implementation: weighted sum defined in colonizethis_data (see [combat.md](../game/combat.md)).

Within a BattleContext:

1. Sort attacking sides by initiative (descending); break ties by faction id for determinism.
2. Use this ordered list to drive the **resolution chain** (defender vs highest‑initiative attacker first, then winner vs next attacker, etc.).

---

## Combat Resolver (Per Engagement)

**Input:** One engagement between a single attacking side and the current defender side: attacker faction id + unit ids (with type and medals), defender faction id + unit ids, province snapshot (fort level, terrain), game config (tactical stats per regiment type, terrain/fort/difficulty modifiers from colonizethis_data), and optional RNG/seed.

**Steps:**

1. **Aggregate strength:** For each side, compute effective strength from **tactical stats** (FPN, FPM) per unit type and **medals** (multiplier 1.0–1.4) per [military-units.md](../game/military-units.md). Blend ranged (FPN) and melee (FPM) per formula. If defender is Minor Nation or Tribe, use **minor military parity**: defender stats are interpreted at the faction’s `effectiveMilitaryLevel` (see [factions.md](../game/factions.md)).
2. **Siege modifiers:** If province has fort (level 1–3), apply wall protection and emplaced artillery contribution per [siege-mechanics.md](../game/siege-mechanics.md).
3. **Apply modifiers:** Apply terrain and difficulty modifiers to attacker and/or defender strength per [combat.md](../game/combat.md).
4. **Run formula:** Compute winner and casualties per side (how many units removed, or which units). Deterministic given inputs (including RNG seed, if any).
5. **Output:** Engagement result: winner side (attacker, defender, mutual annihilation, or stalemate) plus casualty unit ids for both sides.

The resolver itself does **not** flip provinces or advance the attacker chain; it is a pure function used by the BattleContext orchestrator.

---

## Resolution Chain and Application

For each BattleContext:

1. Keep local, mutable views of defender units and each attacking side’s units.
2. Iterate over attacking sides in initiative order:
   - Run the **per‑engagement resolver** between current defender and current attacker.
   - Apply casualties to the local views only.
   - Interpret the result per [combat.md](../game/combat.md) *Battle Outcomes*:
     - **Attacker victory:** defender units empty, attacker retains survivors.
     - **Defender victory:** attacker units empty, defender retains survivors.
     - **Stalemate:** both sides keep survivors; province owner unchanged.
     - **Mutual annihilation:** both sides empty.
   - If mutual annihilation occurs and there are **further attackers** left in this BattleContext:
     - Compute `recoverCount = ceil(initialDefenderUnitCount * 0.2)`.
     - Recreate a small defending garrison of `recoverCount` units using the province owner’s current regiment templates (at their effective military level); this represents rapid local reconstitution before the next attacker arrives.
3. Stop when there are no attackers left or no defender units remain.
4. After the chain completes, apply results to WorldState in a single pass:
   - Remove all units marked as casualties across all engagements.
   - If the **final defender** has no units and the province previously had an owner, flip `province.ownerId` to the surviving attacking faction (if any) per [combat.md](../game/combat.md) *Province Flip*.

Battles in different provinces are independent; TurnResolver may process BattleContexts in any deterministic order (e.g. by province id).

---

## Minor Military Parity

When the defender is a Minor Nation or Tribe, the **parity step** (see [factions.md](../game/factions.md)) must have run earlier in the **Combat phase**. The combat resolver and BattleContext orchestrator read the faction’s stored `effectiveMilitaryLevel` and treat defender stats, regiment templates, and any recovered garrison units as being at that level. Owner: colonizethis_logic; parity computation and storage in colonizethis_models / colonizethis_logic.

---

## Probabilistic Engagement (Simulation)

A separate **probabilistic** resolver is used by `sim_combat` and `sim_combat_montecarlo` for simulation and analysis. The main game uses the **deterministic** resolver above; `resolveBattleContext` is unchanged.

The probabilistic resolver:

- **Rounds:** Up to 5 rounds per engagement.
- **Hit probabilities:** P(attacker hits) = E_a / (E_a + E_d), P(defender hits) = E_d / (E_a + E_d), clamped to [0.15, 0.85].
- **Expected casualties:** λ_defender = k × P_a, λ_attacker = k × P_d (k = 1.0).
- **Sampling:** Actual casualties per round sampled from Poisson(λ), capped by remaining units.
- **Casualty selection:** Strength-weighted; stronger units less likely to be chosen (weight ∝ 1 / (strength + 0.1)).
- **Determinism:** Same seed and inputs produce identical outcome.

---

## Determinism and RNG

The combat resolver must be **deterministic given its inputs**:

- If no randomness is used, the formula is pure: same attacker/defender inputs → same outcome.
- If randomness is desired (e.g. later phases), callers provide an explicit RNG/seed; the resolver must not access global RNG state. Given the same seed and inputs, results must be reproducible (needed for `sim_combat` and replays).

---

## Owner

colonizethis_logic owns conflict detection, combat resolver, and application of results within the Combat phase.
