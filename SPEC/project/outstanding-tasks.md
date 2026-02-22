# Outstanding Project Tasks

**SPEC/project** — Comprehensive gap analysis documenting unimplemented, partially implemented, and undertested features. Tasks ordered by priority (P0 first) so implementers can quickly understand what needs to be done.

---

## Priority Key

| Priority | Meaning |
|----------|---------|
| **P0** | Critical blocker — blocks completion or causes incorrect gameplay |
| **P1** | High priority — significant feature gap，影响核心玩法 |
| **P2** | Medium priority — noticeable gap but not blocking |
| **P3** | Nice to have — can be deferred |

**Complexity Key**

| Complexity | Estimate |
|------------|----------|
| **Small** | 1–2 days |
| **Medium** | 3–5 days |
| **Large** | 1+ weeks |

---

## P0: Critical — Blocks Completion or Causes Incorrect Gameplay

No outstanding P0 tasks.

---

## P1: High Priority — Significant Feature Gap

### Task: Complete Siege Mechanics Implementation

**Gap:** Province model has `fortLevel` field and basic fort build in `orders_application.dart`. Core siege numbers are implemented; gates/sortie and on-wall vs behind-wall targeting remain.

| Missing Component | Spec Reference | Status |
|-------------------|----------------|--------|
| Wall damage reduction percentages | `siege-mechanics.md` | **Done** — 0/25/45/60% in combat_config, combat_resolver |
| Emplaced artillery resolution | `siege-mechanics.md` | **Done** — fortGunCount, wallHp in resolver |
| Gates and sortie logic | `siege-mechanics.md` | Spec clarified; deferred to future tactical expansion |
| Units on/behind wall behavior | `siege-mechanics.md` | Spec clarified; deferred to future tactical expansion |

**Referenced specs:**
- [SPEC/game/siege-mechanics.md](SPEC/game/siege-mechanics.md)
- [SPEC/game/combat.md](SPEC/game/combat.md) — Battle Mode section

**What needs to be done:**
1. ~~Define exact damage reduction percentages in spec~~ — **Done.** 0/25/45/60% in combat_config, combat_resolver.
2. ~~Implement wall HP and breach mechanics in `CombatResolver`~~ — **Done.** wallHpByFortLevel, fortGunCount in resolver.
3. ~~Implement emplaced artillery fire during siege (bonus to defender)~~ — **Done.** Emplaced artillery resolution in resolver.
4. Implement gate mechanics — units can sortie/retreat through gates (deferred to future tactical expansion)
5. Implement "units on wall" vs "units behind wall" targeting rules (deferred to future tactical expansion)
6. Update combat mode selection to use siege rules when `fortLevel >= 1` (as needed)

**Acceptance criteria:** Done when combat resolution uses fortLevel for damage reduction and wall HP; tests assert percentages and wall HP by level; gates/sortie and on-wall vs behind-wall behavior remain deferred per spec.

**Complexity:** Large

---

### Task: Complete Naval Missions and Interception

**Gap:** `NavalMissionOrder` exists with types (Patrol, Blockade, Beachhead, Defend). Interception and retreat are implemented; Beachhead landing/invasion enablement remains.

| Missing Component | Spec Reference | Status |
|-------------------|----------------|--------|
| Patrol interception (30% base) | `ships-and-naval.md` | **Done** — naval_combat_resolver.dart |
| Blockade interception (50% base) | `ships-and-naval.md` | **Done** — kNavalInterceptBaseBlockade |
| Superior/inferior force modifiers | `ships-and-naval.md` | **Done** — kNavalInterceptSuperiorBonus / InferiorPenalty |
| Beachhead landing logic | `ships-and-naval.md` | Deferred — landing site / invasion next turn |
| Retreat from naval combat | `ships-and-naval.md` | **Done** — base 0.6, speed, aggression in resolveSeaBattle |

**Referenced specs:**
- [SPEC/game/ships-and-naval.md](SPEC/game/ships-and-naval.md)
- [SPEC/program/naval-movement-resolution.md](SPEC/program/naval-movement-resolution.md)
- [SPEC/program/naval-combat-resolution.md](SPEC/program/naval-combat-resolution.md)

**What needs to be done:**
1. ~~Implement interception probability calculation with base values and modifiers~~ — **Done.** naval_combat_resolver (Patrol 30%, Blockade 50%, superior/inferior modifiers).
2. ~~Implement force comparison (superior/inferior detection)~~ — **Done.** kNavalInterceptSuperiorBonus / InferiorPenalty.
3. Implement Beachhead mission — fleet establishes landing site, enables invasion next turn (deferred)
4. ~~Implement naval retreat logic with speed advantage and aggression modifiers~~ — **Done.** resolveSeaBattle: base 0.6, speed, aggression.
5. ~~Wire naval missions into TurnResolver's Naval Interception & Combat phase~~ — **Done.** Naval phase uses resolver.

**Acceptance criteria:** Done when interception (base + modifiers) and retreat are exercised in tests; Beachhead landing/invasion enablement remains deferred per spec.

**Complexity:** Medium

---

### Task: Verify and Complete Worker/Population Model

**Status:** Food consumption and starvation verified and tested (economy_consumption_test, economy_logic_test). Luxury and training deferred per spec.

**Gap:** Worker model exists (`WorkerPool`). Food and starvation implemented; luxury and training deferred.

| Component | Spec Reference | Status |
|-----------|----------------|--------|
| Worker tiers (Peasant/Journeyman/Master) | `workers-and-population.md` | **Done** — model and consumption |
| Food consumption | `workers-and-population.md` | **Done** — 1/2 food per tier, tested |
| Luxury consumption | `workers-and-population.md` | Deferred |
| Starvation (worker death) | `workers-and-population.md` | **Done** — order peasants first, tested |
| Training (tier upgrade) | `workers-and-population.md` | Deferred (CLARIFICATION NEEDED) |

**Referenced specs:**
- [SPEC/game/workers-and-population.md](SPEC/game/workers-and-population.md)

**What needs to be done:**
1. Verify food consumption in `economy_consumption.dart` matches spec (1 grain+meat per tier)
2. Verify luxury consumption for trained workers (sugar, cigars, furs)
3. Verify starvation removes workers when food cannot be met
4. Implement worker training (fabric + paper + cash → next tier)

**Acceptance criteria:** Done when economy_consumption_test (and related tests) assert food per tier, starvation order, and luxury/training behavior per workers-and-population.md; training implementation or deferral documented.

**Complexity:** Medium

---

## P2: Medium Priority — Noticeable Gap

### Task: Complete Quick Battle UI Integration

**Gap:** `QuickBattleResolver` and models exist, but player interaction (tactical mode) is not integrated into the app:

| Component | Spec Reference | Status |
|-----------|----------------|--------|
| Lane/line battlefield layout | `quick-battle.md` | Model exists |
| Cohesion (morale) system | `quick-battle.md` | Implemented |
| Command Point actions | `quick-battle.md` | Not in UI |
| Terrain modifiers per lane | `quick-battle.md` | Not wired to combat |
| Player input for actions | `quick-battle.md` | Not implemented |

**Referenced specs:**
- [SPEC/game/quick-battle.md](SPEC/game/quick-battle.md)
- [SPEC/program/quick-battle-resolution.md](SPEC/program/quick-battle-resolution.md)

**What needs to be done:**
1. Integrate QuickBattle screen into app (Flutter + Flame)
2. Implement lane selection and CP spending UI
3. Wire terrain modifiers from province to lane
4. Connect resolver output to combat casualty pipeline

**Acceptance criteria:** Done when player can enter tactical mode from combat, select lanes and spend CP, and resolver output affects casualties; terrain modifiers wired per quick-battle.md.

**Complexity:** Large (UI integration)

---

### Task: Complete Diplomacy Full Actions

**Gap:** `DiplomacyResolver` exists but many diplomatic actions are incomplete:

| Missing Action | Spec Reference | Status |
|----------------|----------------|--------|
| Join Empire (GP absorbing GP) | `diplomacy.md` | Not implemented |
| Alliance with mutual defense | `diplomacy.md` | Partial |
| Subsidies (trade) | `diplomacy.md` | **Done** — SetSubsidy in resolver; GP→GP transfer, GP→Minor relation +3 |
| Foreign aid grants | `diplomacy.md` | **Done** — GrantAid in resolver |
| Intervention (protecting Minor) | `diplomacy.md` | Resolver helpers exist; wire into combat flow for full flow |

**Referenced specs:**
- [SPEC/game/diplomacy.md](SPEC/game/diplomacy.md)
- [SPEC/program/diplomacy-resolution.md](SPEC/program/diplomacy-resolution.md)

**What needs to be done:**
1. Implement Join Empire — removes target GP, transfers provinces
2. Implement Alliance — mutual defense clause triggers on ally attack
3. ~~Implement Subsidies~~ — **Done.** SetSubsidy in diplomacy_resolver; consulate/embassy required; GP→GP treasury transfer, GP→Minor/Tribe relation +3.
4. ~~Implement Foreign Aid~~ — **Done.** GrantAid in diplomacy_resolver.
5. Wire Intervention — needsInterventionChoice/applyInterventionChoice exist; call from combat/turn flow when Minor with Embassy is attacked

**Acceptance criteria:** Done when Join Empire and Alliance (mutual defense) are implemented and tested; Intervention wired from combat/turn flow when Minor with Embassy is attacked; Subsidies and GrantAid remain verified.

**Complexity:** Medium

---

## P3: Nice to Have — Deferred

No outstanding P3 tasks.

---

## Test Coverage Summary

### colonizethis_logic: Key modules and test files

| Module | File | Priority | Note |
|--------|------|----------|------|
| Consumption | `economy/economy_consumption.dart` | P0 | economy_consumption_test.dart |
| Extraction | `economy/economy_extraction.dart` | P0 | economy_extraction_test.dart |
| Production | `economy/economy_production.dart` | P0 | economy_production_test.dart |
| Riches to Treasury | `economy/economy_riches_to_treasury.dart` | P0 | economy_riches_to_treasury_test.dart |
| Research Resolver | `turn/research_resolver.dart` | P0 | Covered by research_phase_test.dart |
| Province Lookup | `world/province_lookup.dart` | P0 | province_lookup_test.dart exists |
| Simple AI Heuristics | `ai/simple_ai_heuristics.dart` | P0 | simple_ai_heuristics_test.dart exists |
| Constants | `constants.dart` | P0 | constants_test.dart exists |

### Coverage Status

- **Total lib files:** 42
- **Test files:** 46 (including characterization tests)
- **Files without dedicated tests:** Run `tool/test_coverage.py` for current count. The table above lists key modules and their corresponding test files.

Target: **90% coverage** per project rules. Current gap is primarily in economy and other modules not yet covered by dedicated tests.

---

---

## Completed (Verified)

Tasks below have been verified against the codebase and are implemented. Date: 2026-02.

| Task | Verification |
|------|--------------|
| Fix Research Funding Values | research_resolver.dart: 50/150/400/1000 gold, 100/300/800/2500 RP; research_phase_test asserts. |
| Add Desert Terrain | TerrainType.desert, diamonds on desert, terrain_region_rules, combat_config, specs updated. |
| Mineral Prospecting Gate | playerProspectedTiles, prospect work order, extraction gates; tests in resource_extractor_test, orders_application_test, order_visibility_test. |
| Ship Reveal Mechanic | turn_resolver: fleet enter sea zone → coastal tiles revealed for owner. |
| Add Tests for Core Logic | province_lookup_test, simple_ai_heuristics_test, constants_test, research_phase_test exist. |
| Add Tests for Economy Modules | economy_consumption/extraction/production/riches_to_treasury_test + research_phase_test cover research resolver. |
| Minor Nation Military Parity | applyMinorMilitaryParity at start of _runCombatPhase; minor_military_parity_test. |
| Capital Choice Phase | capital_choice_test: isProvinceSeaBound, setCapital with auto-port. |
| Complete Trade/Transport Raids Integration | applyTradeInterception in sea_transport.dart; wired in turn_resolver; sea_transport_test. |
| Siege (core numbers) | fortDamageReduction 0/25/45/60%, wallHpByFortLevel, fortGunCount in combat_config and combat_resolver. |
| Verify Fog Decay | Tests in turn_resolver_test; Explorer/Spy prevents decay; resolver uses case-insensitive type and localIdFrom. |
| Add Victory Screen | Victory overlay in ctdev when game.victory != null; return to menu and view final state. |
| Complete Capital and Connectivity | capital_choice: shortest path port→capital, road on path; connectivity_resolver: port rule (seaboard vs road), sea-path BFS S–S; turn_resolver: capital reassignment after combat (setCapitalForReassignment); tests in capital_choice_test, connectivity_resolver_test. |
| Civilian Units Spec — Verification and Test Coverage | order_engine_test: purchase_land validation (embassy, war, treasury, resource, mineral prospected). orders_application_test: purchase_land apply, build_road/build_fort materials, upgrade_town completion, steal_tech/counter_spy scenarios. player_view_test: Spy invisible to other player. resource_extractor_test: townDevelopmentLevel cap. order_visibility: purchase_land/steal_tech/counter_spy visibility. |

---

## References

- [SPEC/game/](SPEC/game/) — Game design documents (GDD)
- [SPEC/program/](SPEC/program/) — Technical design documents (TDD)
- [colonizethis_logic/lib/src/](packages/colonizethis_logic/lib/src/) — Implementation
- [colonizethis_logic/test/](packages/colonizethis_logic/test/) — Tests
- [tool/test_coverage.py](tool/test_coverage.py) — Coverage script
