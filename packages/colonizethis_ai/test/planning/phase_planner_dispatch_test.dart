// Unit tests for the phase planner dispatcher in
// `packages/colonizethis_ai/lib/src/planning/phase_planner_dispatch.dart`
// (Refs #2509 S5 foundation / S6 phase-planner-architecture sub-spec).
//
// Spec contract (issue #2509 § Design § Single-goal replacement;
// SPEC/ai/phase-planner-architecture.md § Orchestrator dispatch):
//
//   "Each phase dispatches to a self-contained planner module that makes
//    one primary decision per domain. No scores are aggregated across
//    phases."
//
// The dispatcher is the missing wiring between `observerGoalPhaseFor`
// and the four per-phase planner modules. It does not emit orders --
// the orchestrator translates `PhasePlanOutcome` into the legacy
// `runDiplomacyPlanner` / `runConquestArmyMovePlanner` / economy call
// chain in a later S5 slice. These tests pin:
//
//   1. Phase routing: `runPhasePlanners` returns each
//      `ObserverGoalPhase` value when the snapshot matches the
//      condition table (EXPAND below quota; COLONIAL-lite at quota=9
//      and turn>=120 with non-GP NW ownership; COLONIAL at quota with
//      colonial targets; DEVELOP at quota with no colonial targets).
//   2. EXPAND outcome composition: EXPAND-phase fields populate while
//      COLONIAL-lite / COLONIAL / DEVELOP fields stay at default. The
//      declare-war target picked by `planExpandDeclareWar` flows into
//      `planExpandMilitary` so the two plans target the same faction.
//   3. COLONIAL-lite outcome composition: both EXPAND fields and
//      COLONIAL-lite fields populate (OW push continues during the
//      safeguard); full-COLONIAL and DEVELOP slots stay default.
//   4. COLONIAL outcome composition: COLONIAL slots populate; EXPAND
//      / COLONIAL-lite / DEVELOP slots stay default. When acquisition
//      resolves to `declareWar`, the target factionId flows into both
//      `planColonialMilitary` and `planColonialNaval`. When
//      acquisition is `null` (no method reachable), the military /
//      naval pair fall back to their at-war arms with no declared
//      target.
//   5. DEVELOP outcome composition: only DEVELOP fields populate.
//   6. Determinism: identical inputs produce field-equal outcomes
//      (Must-have #7).
//
// Fixture style mirrors the existing per-planner tests
// (`expand_phase_planner_test.dart`, `colonial_phase_planner_test.dart`,
// `develop_phase_planner_test.dart`): minimal `Game` scaffolds tuned
// per scenario, no live AI invocation, no orchestrator wiring. The
// dispatcher is a thin composition layer so the assertions focus on
// the routing matrix rather than re-pinning each planner's internal
// branches.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/develop_phase_planner.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gp1 = 'gp1';
const String _gp2 = 'gp2';
const String _gp3 = 'gp3';
const String _tribe1 = 'tribe1';
const String _minor1 = 'minor1';

const String _owProvGp1 = 'oldWorld|gp1_a';
const String _owProvMinor = 'oldWorld|m1_a';
const String _nwProvTribe = 'newWorld|tribe1_a';

/// Convenience for tests that need to know which regiment-build catalog
/// cost gates trip; mirrors the planner's internal helper.
int _cheapestRegimentBuildCost() {
  var min = 999999999;
  for (final econ in RegimentEconomyCatalog.byId.values) {
    if (econ.buildTreasuryCost < min) {
      min = econ.buildTreasuryCost;
    }
  }
  return min;
}

/// Home Army with [regimentCount] dummy regiment ids; matches the walk
/// in `regimentCountForPlayer`.
Army _homeArmyWithRegiments(String ownerId, int regimentCount) {
  return Army(
    id: 'home_army:$ownerId',
    ownerId: ownerId,
    regionId: kOldWorldRegionId,
    stationedProvinceId: _owProvGp1,
    isHomeArmy: true,
    regimentUnitIds: <String>[
      for (var i = 0; i < regimentCount; i++) 'reg_${ownerId}_$i',
    ],
  );
}

/// Game scaffold for the EXPAND-phase route.
///
/// Active player [_gp1] holds [_owProvGp1] in OW and [regimentCount]
/// regiments. Minor [_minor1] owns the invadable OW province
/// [_owProvMinor] so the EXPAND priority-1 minor arm fires (and the
/// military-fallback arm has a candidate). NW left empty so
/// `observerGoalPhaseFor` cannot route to COLONIAL-lite or COLONIAL.
Game _expandGame({
  int turnNumber = 50,
  int regimentCount = 6,
  int ownTreasury = 9999,
  List<Province> newWorldProvinces = const [],
}) {
  return Game(
    id: 'g-2509-phase-planner-dispatch-expand-t$turnNumber',
    worldState: WorldState(
      turnState: TurnState(turnNumber: turnNumber, phase: TurnPhase.orders),
      oldWorld: const RegionData(
        provinces: [
          Province(id: _owProvGp1, regionId: kOldWorldRegionId, ownerId: _gp1),
          Province(
            id: _owProvMinor,
            regionId: kOldWorldRegionId,
            ownerId: _minor1,
          ),
        ],
      ),
      newWorld: RegionData(provinces: newWorldProvinces),
      armies: [_homeArmyWithRegiments(_gp1, regimentCount)],
    ),
    players: [
      Player(
        id: _gp1,
        displayName: 'GP1',
        isHuman: false,
        treasury: ownTreasury,
      ),
      const Player(id: _gp2, displayName: 'GP2', isHuman: false),
    ],
    minorNations: const [MinorNation(id: _minor1, displayName: 'Minor1')],
    tribes: const [Tribe(id: _tribe1, displayName: 'Tribe1')],
  );
}

/// Snapshot for EXPAND posture: OW below quota, OW invadable populated.
AIWorldSnapshot _expandSnapshot({
  int oldWorldProvincesOwned = 8,
  List<String> atWarWith = const <String>[],
  List<String> adjacentOwners = const <String>[_minor1],
}) {
  return AIWorldSnapshot(
    playerId: _gp1,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
      provincesToVictory: kObserverConquestMinOwProvincesPerGp * 3,
      invadableProvinceIdsSorted: const [_owProvMinor],
      adjacentOwnerFactionIdsSorted: adjacentOwners,
    ),
    colonial: const ColonialSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}

/// Game scaffold for the COLONIAL-lite route: turn >= 120, OW = 9, and
/// a NW province visibly owned by a tribe (so
/// `globalNewWorldHasNonGpOwnership` returns true).
Game _colonialLiteGame() {
  return _expandGame(
    turnNumber: kObserverColonialLiteMinTurn + 5,
    newWorldProvinces: const [
      Province(id: _nwProvTribe, regionId: kNewWorldRegionId, ownerId: _tribe1),
    ],
  );
}

/// Snapshot for COLONIAL-lite posture: OW = 9, NW summary populated
/// so `planColonialLiteOvertures` and `planColonialLiteNaval` have
/// candidates.
AIWorldSnapshot _colonialLiteSnapshot() {
  return const AIWorldSnapshot(
    playerId: _gp1,
    threats: ThreatSummary(),
    opportunities: OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: kObserverColonialLiteNearQuotaOw,
      provincesToVictory: kObserverConquestMinOwProvincesPerGp * 3,
      invadableProvinceIdsSorted: [_owProvMinor],
      adjacentOwnerFactionIdsSorted: [_minor1],
    ),
    colonial: ColonialSummary(
      invadableNewWorldProvinceIdsSorted: [_nwProvTribe],
      adjacentNewWorldOwnerFactionIdsSorted: [_tribe1],
      preferredColonialTargetFactionIdsSorted: [_tribe1],
    ),
    economy: EconomySummary(),
    relations: {},
  );
}

/// Game scaffold for the COLONIAL route: OW at quota (10), NW
/// invadable populated.
Game _colonialGame({int regimentCount = 6, int ownTreasury = 9999}) {
  return Game(
    id: 'g-2509-phase-planner-dispatch-colonial',
    worldState: WorldState(
      turnState: const TurnState(turnNumber: 130, phase: TurnPhase.orders),
      oldWorld: const RegionData(
        provinces: [
          Province(id: _owProvGp1, regionId: kOldWorldRegionId, ownerId: _gp1),
        ],
      ),
      newWorld: const RegionData(
        provinces: [
          Province(
            id: _nwProvTribe,
            regionId: kNewWorldRegionId,
            ownerId: _tribe1,
          ),
        ],
      ),
      armies: [_homeArmyWithRegiments(_gp1, regimentCount)],
    ),
    players: [
      Player(
        id: _gp1,
        displayName: 'GP1',
        isHuman: false,
        treasury: ownTreasury,
      ),
      const Player(id: _gp2, displayName: 'GP2', isHuman: false),
    ],
    tribes: const [Tribe(id: _tribe1, displayName: 'Tribe1')],
  );
}

/// Snapshot for COLONIAL posture: OW = 10 (at quota), NW invadable
/// + at-war tribe so `planColonialMilitary` / `planColonialNaval`
/// have non-default candidates and `planColonialAcquisition` declareWar
/// arm is the priority pick (no overture / merchant -> joinEmpire and
/// purchase_land both null). Treasury set on the economy summary
/// (not the player) because `planColonialAcquisition`'s declareWar arm
/// reads `snapshot.economy.treasury` for the cheapest-regiment cost
/// gate, not the player record.
AIWorldSnapshot _colonialSnapshot({
  List<String> atWarWith = const <String>[_tribe1],
  int treasury = 9999,
}) {
  return AIWorldSnapshot(
    playerId: _gp1,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: const ConquestSummary(
      oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
      provincesToVictory: kObserverConquestMinOwProvincesPerGp * 3,
    ),
    colonial: const ColonialSummary(
      invadableNewWorldProvinceIdsSorted: [_nwProvTribe],
    ),
    economy: EconomySummary(treasury: treasury),
    relations: const {},
  );
}

/// Game scaffold for the DEVELOP route: OW at quota, no NW colonial
/// targets visible.
Game _developGame() {
  return Game(
    id: 'g-2509-phase-planner-dispatch-develop',
    worldState: WorldState(
      turnState: const TurnState(turnNumber: 140, phase: TurnPhase.orders),
      oldWorld: const RegionData(
        provinces: [
          Province(id: _owProvGp1, regionId: kOldWorldRegionId, ownerId: _gp1),
        ],
      ),
      // All NW provinces fully GP-owned so COLONIAL-lite preconditions
      // fail and DEVELOP wins the routing (own OW = 10, no invadable
      // NW visible, no NW outside GPs).
      newWorld: const RegionData(
        provinces: [
          Province(
            id: 'newWorld|gp2_owned',
            regionId: kNewWorldRegionId,
            ownerId: _gp2,
          ),
        ],
      ),
    ),
    players: const [
      Player(id: _gp1, displayName: 'GP1', isHuman: false),
      Player(id: _gp2, displayName: 'GP2', isHuman: false),
    ],
  );
}

/// Snapshot for DEVELOP posture: OW at quota, no colonial acquisition
/// targets in the colonial summary, one at-war GP so
/// `planDevelopPeace` returns a non-empty list (the contract pin needs
/// observable content, not just an empty list).
AIWorldSnapshot _developSnapshot() {
  return const AIWorldSnapshot(
    playerId: _gp1,
    threats: ThreatSummary(atWarWith: [_gp3]),
    opportunities: OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
      provincesToVictory: kObserverConquestMinOwProvincesPerGp * 3,
    ),
    colonial: ColonialSummary(),
    economy: EconomySummary(),
    relations: {},
  );
}

void main() {
  // Sanity-pin the regiment-cost helper so a regression in
  // `RegimentEconomyCatalog.byId` that bumped every cost above the
  // EXPAND fixture's default treasury (9999) would surface here rather
  // than silently failing later assertions about `planExpandDeclareWar`
  // not returning `null` from the treasury gate.
  setUpAll(() {
    final cheapest = _cheapestRegimentBuildCost();
    expect(cheapest, lessThanOrEqualTo(9999), reason: 'Treasury gate fixture');
  });

  group('runPhasePlanners phase routing', () {
    test('EXPAND when OW below quota', () {
      final outcome = runPhasePlanners(
        game: _expandGame(),
        snapshot: _expandSnapshot(),
      );
      expect(outcome.phase, ObserverGoalPhase.expand);
    });

    test('COLONIAL-lite when turn>=120, OW=9, NW non-GP-owned visible', () {
      final outcome = runPhasePlanners(
        game: _colonialLiteGame(),
        snapshot: _colonialLiteSnapshot(),
      );
      expect(outcome.phase, ObserverGoalPhase.colonialLite);
    });

    test('COLONIAL when OW at quota with colonial acquisition targets', () {
      final outcome = runPhasePlanners(
        game: _colonialGame(),
        snapshot: _colonialSnapshot(),
      );
      expect(outcome.phase, ObserverGoalPhase.colonial);
    });

    test('DEVELOP when OW at quota and no colonial acquisition targets', () {
      final outcome = runPhasePlanners(
        game: _developGame(),
        snapshot: _developSnapshot(),
      );
      expect(outcome.phase, ObserverGoalPhase.develop);
    });
  });

  group('EXPAND outcome composition', () {
    test('EXPAND populates EXPAND slots only; other slots stay default', () {
      final game = _expandGame();
      final snapshot = _expandSnapshot();
      final outcome = runPhasePlanners(game: game, snapshot: snapshot);

      // EXPAND fields paired with the per-planner outputs the
      // dispatcher composes. The declare-war target flows into
      // `planExpandMilitary`, so the two plans target the same
      // faction.
      expect(outcome.expandDeclareWarTargetFactionId, _minor1);
      expect(
        outcome.expandPeaceTargetFactionIdsSorted,
        planExpandPeace(game: game, snapshot: snapshot),
      );
      expect(
        outcome.expandEconomyPlan,
        planExpandEconomy(game: game, snapshot: snapshot),
      );
      expect(
        outcome.expandMilitaryPlan,
        planExpandMilitary(
          game: game,
          snapshot: snapshot,
          declaredWarTargetFactionId: _minor1,
        ),
      );

      // Non-EXPAND slots structurally default.
      expect(outcome.colonialLiteOverturesSorted, isEmpty);
      expect(outcome.colonialLiteNavalPlan, ColonialLiteNavalPlan.defaultPlan);
      expect(outcome.colonialAcquisitionTarget, isNull);
      expect(outcome.colonialPeaceTargetFactionIdsSorted, isEmpty);
      expect(outcome.colonialMilitaryPlan, ColonialMilitaryPlan.defaultPlan);
      expect(outcome.colonialNavalPlan, ColonialNavalPlan.defaultPlan);
      expect(outcome.colonialCivilianWorkOrders, isEmpty);
      expect(outcome.developPeaceTargetFactionIdsSorted, isEmpty);
      expect(outcome.developCivilianWorkOrders, isEmpty);
    });
  });

  group('COLONIAL-lite outcome composition', () {
    test('COLONIAL-lite populates EXPAND + COLONIAL-lite slots', () {
      final game = _colonialLiteGame();
      final snapshot = _colonialLiteSnapshot();
      final outcome = runPhasePlanners(game: game, snapshot: snapshot);

      // EXPAND continues to run during the safeguard ("Begin NW
      // overture/naval penetration without weakening OW push").
      expect(
        outcome.expandDeclareWarTargetFactionId,
        planExpandDeclareWar(game: game, snapshot: snapshot),
      );
      expect(
        outcome.expandMilitaryPlan,
        planExpandMilitary(
          game: game,
          snapshot: snapshot,
          declaredWarTargetFactionId: outcome.expandDeclareWarTargetFactionId,
        ),
      );

      // COLONIAL-lite directives surface.
      expect(
        outcome.colonialLiteOverturesSorted,
        planColonialLiteOvertures(game: game, snapshot: snapshot),
      );
      expect(
        outcome.colonialLiteNavalPlan,
        planColonialLiteNaval(game: game, snapshot: snapshot),
      );

      // Full-COLONIAL and DEVELOP slots stay default — COLONIAL-lite
      // is structurally an EXPAND safeguard, NOT a full-COLONIAL
      // run.
      expect(outcome.colonialAcquisitionTarget, isNull);
      expect(outcome.colonialPeaceTargetFactionIdsSorted, isEmpty);
      expect(outcome.colonialMilitaryPlan, ColonialMilitaryPlan.defaultPlan);
      expect(outcome.colonialNavalPlan, ColonialNavalPlan.defaultPlan);
      expect(outcome.colonialCivilianWorkOrders, isEmpty);
      expect(outcome.developPeaceTargetFactionIdsSorted, isEmpty);
      expect(outcome.developCivilianWorkOrders, isEmpty);
    });
  });

  group('COLONIAL outcome composition', () {
    test('declareWar acquisition pairs target factionId into military / naval',
        () {
      // The fixture has an at-war tribe owning the NW invadable
      // province. `planColonialAcquisition` resolves to
      // `(tribe1, declareWar)` and the dispatcher forwards that
      // factionId into both `planColonialMilitary` and
      // `planColonialNaval` -- the at-war fallback arm fires for both
      // sibling plans with `_tribe1` listed as the priority owner.
      final game = _colonialGame();
      final snapshot = _colonialSnapshot();
      final outcome = runPhasePlanners(game: game, snapshot: snapshot);

      expect(outcome.phase, ObserverGoalPhase.colonial);

      // Acquisition arm: declareWar over the tribe (Join Empire and
      // purchase_land arms have no overture / merchant).
      expect(
        outcome.colonialAcquisitionTarget,
        const ColonialAcquisitionTarget(
          targetFactionId: _tribe1,
          method: AcquisitionMethod.declareWar,
        ),
      );

      // Military / naval invasion-transport restricted to the
      // declared target.
      expect(
        outcome.colonialMilitaryPlan,
        planColonialMilitary(
          game: game,
          snapshot: snapshot,
          colonialDeclaredWarTargetFactionId: _tribe1,
        ),
      );
      expect(
        outcome.colonialNavalPlan,
        planColonialNaval(
          game: game,
          snapshot: snapshot,
          colonialDeclaredWarTargetFactionId: _tribe1,
        ),
      );

      // Peace + civilian still flow.
      expect(
        outcome.colonialPeaceTargetFactionIdsSorted,
        planColonialPeace(game: game, snapshot: snapshot),
      );
      expect(
        outcome.colonialCivilianWorkOrders,
        planColonialCivilian(game: game, snapshot: snapshot),
      );

      // EXPAND / COLONIAL-lite / DEVELOP slots stay default.
      expect(outcome.expandDeclareWarTargetFactionId, isNull);
      expect(outcome.expandPeaceTargetFactionIdsSorted, isEmpty);
      expect(outcome.expandEconomyPlan, ExpandEconomyPlan.defaultPlan);
      expect(outcome.expandMilitaryPlan, ExpandMilitaryPlan.defaultPlan);
      expect(outcome.colonialLiteOverturesSorted, isEmpty);
      expect(outcome.colonialLiteNavalPlan, ColonialLiteNavalPlan.defaultPlan);
      expect(outcome.developPeaceTargetFactionIdsSorted, isEmpty);
      expect(outcome.developCivilianWorkOrders, isEmpty);
    });

    test('null acquisition leaves military / naval to at-war fallback arm',
        () {
      // Zero regiments + no Join Empire / purchase_land path means
      // `planColonialAcquisition` returns null; the dispatcher must
      // therefore pass `null` as `colonialDeclaredWarTargetFactionId`
      // and the at-war fallback arms fire identically to a direct
      // call.
      final game = _colonialGame(regimentCount: 0);
      // Still at-war with the tribe so the at-war fallback arm
      // populates the priority owner roster (tribe1) for both
      // military and naval.
      final snapshot = _colonialSnapshot();
      final outcome = runPhasePlanners(game: game, snapshot: snapshot);

      expect(outcome.phase, ObserverGoalPhase.colonial);
      expect(
        outcome.colonialAcquisitionTarget,
        isNull,
        reason:
            'Zero regiments + no overture / merchant => null '
            'acquisition target.',
      );
      expect(
        outcome.colonialMilitaryPlan,
        planColonialMilitary(game: game, snapshot: snapshot),
        reason:
            'Dispatcher forwards null colonialDeclaredWarTargetFactionId '
            'so the planner picks via the at-war fallback arm.',
      );
      expect(
        outcome.colonialNavalPlan,
        planColonialNaval(game: game, snapshot: snapshot),
        reason:
            'Naval pairs with military on the same '
            'colonialDeclaredWarTargetFactionId argument.',
      );
    });
  });

  group('DEVELOP outcome composition', () {
    test('DEVELOP populates DEVELOP slots only', () {
      final game = _developGame();
      final snapshot = _developSnapshot();
      final outcome = runPhasePlanners(game: game, snapshot: snapshot);

      expect(outcome.phase, ObserverGoalPhase.develop);
      expect(
        outcome.developPeaceTargetFactionIdsSorted,
        planDevelopPeace(game: game, snapshot: snapshot),
      );
      expect(
        outcome.developCivilianWorkOrders,
        planDevelopCivilian(game: game, snapshot: snapshot),
      );

      // EXPAND / COLONIAL slots stay default.
      expect(outcome.expandDeclareWarTargetFactionId, isNull);
      expect(outcome.expandPeaceTargetFactionIdsSorted, isEmpty);
      expect(outcome.expandEconomyPlan, ExpandEconomyPlan.defaultPlan);
      expect(outcome.expandMilitaryPlan, ExpandMilitaryPlan.defaultPlan);
      expect(outcome.colonialLiteOverturesSorted, isEmpty);
      expect(outcome.colonialLiteNavalPlan, ColonialLiteNavalPlan.defaultPlan);
      expect(outcome.colonialAcquisitionTarget, isNull);
      expect(outcome.colonialPeaceTargetFactionIdsSorted, isEmpty);
      expect(outcome.colonialMilitaryPlan, ColonialMilitaryPlan.defaultPlan);
      expect(outcome.colonialNavalPlan, ColonialNavalPlan.defaultPlan);
      expect(outcome.colonialCivilianWorkOrders, isEmpty);
    });
  });

  group('determinism (Must-have #7)', () {
    test('EXPAND outcome equal across repeated calls', () {
      final game = _expandGame();
      final snapshot = _expandSnapshot();
      final a = runPhasePlanners(game: game, snapshot: snapshot);
      final b = runPhasePlanners(game: game, snapshot: snapshot);
      expect(b.phase, a.phase);
      expect(
        b.expandDeclareWarTargetFactionId,
        a.expandDeclareWarTargetFactionId,
      );
      expect(b.expandPeaceTargetFactionIdsSorted, a.expandPeaceTargetFactionIdsSorted);
      expect(b.expandEconomyPlan, a.expandEconomyPlan);
      expect(b.expandMilitaryPlan, a.expandMilitaryPlan);
    });

    test('COLONIAL outcome equal across repeated calls', () {
      final game = _colonialGame();
      final snapshot = _colonialSnapshot();
      final a = runPhasePlanners(game: game, snapshot: snapshot);
      final b = runPhasePlanners(game: game, snapshot: snapshot);
      expect(b.phase, a.phase);
      expect(b.colonialAcquisitionTarget, a.colonialAcquisitionTarget);
      expect(b.colonialPeaceTargetFactionIdsSorted, a.colonialPeaceTargetFactionIdsSorted);
      expect(b.colonialMilitaryPlan, a.colonialMilitaryPlan);
      expect(b.colonialNavalPlan, a.colonialNavalPlan);
      expect(b.colonialCivilianWorkOrders, a.colonialCivilianWorkOrders);
    });
  });
}
