// Pins the **no-hysteresis phase-transition guard** clause from issue #2509
// at the `observerGoalPhaseFor` + `runDomainPlanners` boundary:
//
//   Issue #2509 § S10 Observer goal phases (Full AI):
//     Phase transition guard: Re-enter EXPAND only when
//     `oldWorldProvincesOwned` drops below 10 again. No hysteresis band at
//     quota+1 — a province loss immediately restores EXPAND so NW work
//     cannot mask OW regression.
//
//   SPEC/ai/ai-architecture.md § Observer goal phases (Full AI):
//     EXPAND -> `oldWorldProvincesOwned < kObserverConquestMinOwProvincesPerGp`
//     (10); COLONIAL -> OW quota met and `hasColonialAcquisitionTargets`.
//
// Sibling pins exercise the **value-range** of the phase function
// (`observer_goal_phase_test.dart` uses OW=8 for EXPAND, OW=10 for COLONIAL,
// OW=11 for DEVELOP) and the **EXPAND-vs-COLONIAL toggle** of the
// orchestrator (`domain_planner_orchestrator_expand_nw_overture_suppression_test.dart`
// runs OW=7 EXPAND vs OW=11 COLONIAL). Neither pins:
//
//   - the **OW=10 (at quota, COLONIAL) vs OW=9 (just below quota, EXPAND)**
//     boundary directly — a regression that introduced an off-by-one
//     comparison (`<=` instead of `<`, or a quota constant of 9 instead of
//     10) would silently slip past both sibling pins; OR
//   - the **statelessness** of `observerGoalPhaseFor` — a future tuning
//     slice that introduced a cached per-GP phase memoizer with hysteresis
//     (e.g. `_lastPhase[gp] = COLONIAL` retained on the next call even when
//     `ownOw` dropped to 9) would mask OW regressions and let NW work
//     continue while the GP loses OW provinces, directly threatening the
//     canonical seed-42 `--verify-conquest` per-GP +3 net OW gain gate at
//     turn 100.
//
// Coverage layers (all at turn 110 so COLONIAL-lite is **not** active —
// COLONIAL-lite requires turn >= `kObserverColonialLiteMinTurn` = 120):
//
//   - Phase function boundary: OW=10 -> COLONIAL, OW=9 -> EXPAND (same
//     fixture otherwise; pins the off-by-one + boundary case in isolation).
//   - Phase function statelessness: alternating snapshot calls between
//     OW=10 and OW=9 within the same test must produce the alternating
//     phases without any retained state between calls.
//   - Orchestrator boundary: `runDomainPlanners` at OW=10 surfaces the NW
//     tribe overture (COLONIAL allows it); at OW=9 drops it (EXPAND
//     suppresses NW colonial diplomacy). Same scenario shape — only the
//     OW province count flips.
//   - Determinism guard (must-have #7): per-phase outputs are identical
//     across repeated runs with the same inputs.

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'domain_planner_test_fake_api.dart';

const String _nationId = 'gp1';
const String _tribeId = 'tribe1';
const String _tribeNwProvince = 'newWorld|tribe1_nw0';

// One below quota (`isBelowObserverConquestQuota(9)` -> true). The "just below
// quota" boundary the no-hysteresis guard hinges on: a single province loss
// from 10 must immediately put the GP back in EXPAND.
const List<String> _gp1OwProvincesJustBelowQuota = <String>[
  'oldWorld|gp1_0',
  'oldWorld|gp1_1',
  'oldWorld|gp1_2',
  'oldWorld|gp1_3',
  'oldWorld|gp1_4',
  'oldWorld|gp1_5',
  'oldWorld|gp1_6',
  'oldWorld|gp1_7',
  'oldWorld|gp1_8',
];

// Exactly at the observer quota (`kObserverConquestMinOwProvincesPerGp` = 10).
// `isBelowObserverConquestQuota(10)` -> false, so the GP enters COLONIAL when
// `hasColonialAcquisitionTargets` is true. Distinct from the sibling
// `_gp1OwProvincesAtQuota` fixture (11 provinces) used by the EXPAND/COLONIAL
// pin so this file isolates the **at-quota boundary** rather than well above
// it.
const List<String> _gp1OwProvincesAtQuota = <String>[
  'oldWorld|gp1_0',
  'oldWorld|gp1_1',
  'oldWorld|gp1_2',
  'oldWorld|gp1_3',
  'oldWorld|gp1_4',
  'oldWorld|gp1_5',
  'oldWorld|gp1_6',
  'oldWorld|gp1_7',
  'oldWorld|gp1_8',
  'oldWorld|gp1_9',
];

Game _scenarioGame({required List<String> gp1OwProvinces}) {
  return Game(
    id: 'g-2509-phase-transition-no-hysteresis',
    worldState: WorldState(
      // turnNumber 110 keeps the fixture below the COLONIAL-lite floor of
      // `kObserverColonialLiteMinTurn` (120), so OW=9 lands in EXPAND not
      // COLONIAL-lite. This is the regime the no-hysteresis guard governs.
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 110),
      oldWorld: RegionData(
        provinces: [
          for (final id in gp1OwProvinces)
            Province(id: id, regionId: 'oldWorld', ownerId: _nationId),
        ],
      ),
      newWorld: const RegionData(
        provinces: [
          Province(
            id: _tribeNwProvince,
            regionId: 'newWorld',
            ownerId: _tribeId,
          ),
        ],
      ),
      // Non-empty Home Army avoids unrelated zero-regiment stalemate peace
      // suggestions firing into the diplomatic orders, matching the guard
      // shape used by sibling orchestrator pins.
      armies: [
        Army(
          id: homeArmyIdFor(_nationId),
          ownerId: _nationId,
          regionId: 'oldWorld',
          stationedProvinceId: gp1OwProvinces.first,
          regimentUnitIds: const ['u_gp1'],
          isHomeArmy: true,
        ),
      ],
    ),
    players: const [
      Player(
        id: _nationId,
        displayName: 'GP1',
        isHuman: false,
        leaderKey: 'henry',
      ),
    ],
    tribes: const [Tribe(id: _tribeId, displayName: 'T1')],
    minorNations: const [],
    // Peace + embassy is the precondition for `establishOverture(joinEmpire)`
    // to be a structurally valid candidate at the COLONIAL boundary. The
    // EXPAND boundary uses the same Game shape (only the OW count differs).
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: _nationId,
        factionId2: _tribeId,
        state: RelationState.atPeace,
        score: 60,
      ),
    ],
    overtureStates: const [
      OvertureState(
        gpId: _nationId,
        targetId: _tribeId,
        stage: OvertureStage.embassy,
      ),
    ],
  );
}

// Fake API provides one `establishOverture(tribe1, joinEmpire)` candidate.
// `runDomainPlanners` enforces the EXPAND `establishOverture` suppression
// vs COLONIAL emission contract at the boundary OW=9/10 exercised here.
const FakeOrderSuggestionAPIForDomainPlannerTests _nwTribeOvertureApi =
    FakeOrderSuggestionAPIForDomainPlannerTests(
  work: [],
  build: [],
  move: [],
  research: [],
  navalMove: [],
  navalMission: [],
  diplomatic: [
    DiplomaticOrder(
      type: DiplomaticOrderType.establishOverture,
      targetFactionId: _tribeId,
      overtureStage: OvertureStage.joinEmpire,
    ),
  ],
);

const EconomyPlan _economyPlan = EconomyPlan(
  productionAssignments: [],
  cargoPreference: CargoPreference.none,
);

// `henry` + `merchant` mirrors the sibling COLONIAL pins so a regression
// in those personality/agenda tables is not the cause of a phase-boundary
// failure here.
const AIConfig _aiConfig = AIConfig(
  leaderId: 'henry',
  personalityId: 'henry',
  hiddenAgendaId: 'merchant',
);

AIWorldSnapshot _expandJustBelowQuotaSnapshot() {
  return const AIWorldSnapshot(
    playerId: _nationId,
    threats: ThreatSummary(),
    opportunities: OpportunitySummary(),
    // 9 OW provinces: `isBelowObserverConquestQuota(9)` -> true. The "loss
    // from quota" snapshot the no-hysteresis guard targets.
    conquest: ConquestSummary(
      oldWorldProvincesOwned: 9,
      provincesToVictory: 22,
    ),
    colonial: ColonialSummary(
      invadableNewWorldProvinceIdsSorted: [_tribeNwProvince],
      adjacentNewWorldOwnerFactionIdsSorted: [_tribeId],
      preferredColonialTargetFactionIdsSorted: [_tribeId],
    ),
    economy: EconomySummary(ownProvinceCount: 9),
    relations: {
      _tribeId: DiplomacyRelation(
        factionId1: _nationId,
        factionId2: _tribeId,
        state: RelationState.atPeace,
        score: 60,
      ),
    },
  );
}

AIWorldSnapshot _colonialAtQuotaSnapshot() {
  return const AIWorldSnapshot(
    playerId: _nationId,
    threats: ThreatSummary(),
    opportunities: OpportunitySummary(),
    // 10 OW provinces: `isBelowObserverConquestQuota(10)` -> false. The
    // "at quota" snapshot at the EXPAND -> COLONIAL boundary.
    conquest: ConquestSummary(
      oldWorldProvincesOwned: 10,
      provincesToVictory: 21,
    ),
    colonial: ColonialSummary(
      newWorldProvincesOwned: 0,
      invadableNewWorldProvinceIdsSorted: [_tribeNwProvince],
      adjacentNewWorldOwnerFactionIdsSorted: [_tribeId],
      preferredColonialTargetFactionIdsSorted: [_tribeId],
    ),
    economy: EconomySummary(ownProvinceCount: 10),
    relations: {
      _tribeId: DiplomacyRelation(
        factionId1: _nationId,
        factionId2: _tribeId,
        state: RelationState.atPeace,
        score: 60,
      ),
    },
  );
}

List<String> _overtureTargets(Orders orders) => <String>[
  for (final order
      in orders.diplomaticOrdersByPlayerId[_nationId] ?? const [])
    if (order.type == DiplomaticOrderType.establishOverture)
      order.targetFactionId,
];

void main() {
  group('observerGoalPhaseFor OW-boundary transition', () {
    test('OW=10 lands in COLONIAL (at-quota boundary)', () {
      final game = _scenarioGame(gp1OwProvinces: _gp1OwProvincesAtQuota);
      final snapshot = _colonialAtQuotaSnapshot();
      expect(
        observerGoalPhaseFor(snapshot: snapshot, game: game),
        ObserverGoalPhase.colonial,
        reason:
            'OW=10 is exactly at quota (`isBelowObserverConquestQuota(10)` '
            'is false). With colonial acquisition targets visible the GP '
            'must enter COLONIAL. A regression that flipped the boundary '
            'to `<=` (or set the constant to 11) would put OW=10 back in '
            'EXPAND and starve NW acquisition from turn 100 onward.',
      );
    });

    test('OW=9 falls back to EXPAND (just-below-quota boundary)', () {
      final game = _scenarioGame(
        gp1OwProvinces: _gp1OwProvincesJustBelowQuota,
      );
      final snapshot = _expandJustBelowQuotaSnapshot();
      expect(
        observerGoalPhaseFor(snapshot: snapshot, game: game),
        ObserverGoalPhase.expand,
        reason:
            'OW=9 is one below quota and turn=110 < '
            'kObserverColonialLiteMinTurn=120, so COLONIAL-lite is not '
            'eligible. Issue #2509 phase-transition guard requires the '
            'GP to re-enter EXPAND immediately on the OW loss (no '
            'hysteresis band at quota+1) so a single OW regression cannot '
            'be masked by lingering colonial work.',
      );
    });

    test('alternating OW=10 and OW=9 calls produce alternating phases', () {
      // Pins `observerGoalPhaseFor` statelessness: the same function called
      // back-to-back with snapshots that swap OW=10 and OW=9 must produce
      // the corresponding phases on every call. A regression that cached
      // the previous phase per GP (or used hysteresis to retain COLONIAL
      // on the first OW=9 call after OW=10) would break this loop.
      final gameAtQuota = _scenarioGame(
        gp1OwProvinces: _gp1OwProvincesAtQuota,
      );
      final gameJustBelowQuota = _scenarioGame(
        gp1OwProvinces: _gp1OwProvincesJustBelowQuota,
      );
      final atQuotaSnapshot = _colonialAtQuotaSnapshot();
      final justBelowQuotaSnapshot = _expandJustBelowQuotaSnapshot();
      final phases = <ObserverGoalPhase>[];
      for (var i = 0; i < 3; i++) {
        phases.add(
          observerGoalPhaseFor(snapshot: atQuotaSnapshot, game: gameAtQuota),
        );
        phases.add(
          observerGoalPhaseFor(
            snapshot: justBelowQuotaSnapshot,
            game: gameJustBelowQuota,
          ),
        );
      }
      expect(
        phases,
        const <ObserverGoalPhase>[
          ObserverGoalPhase.colonial,
          ObserverGoalPhase.expand,
          ObserverGoalPhase.colonial,
          ObserverGoalPhase.expand,
          ObserverGoalPhase.colonial,
          ObserverGoalPhase.expand,
        ],
        reason:
            '`observerGoalPhaseFor` must be a pure function of its '
            'snapshot + game inputs. A cached previous-phase memoizer '
            'with hysteresis would surface as a non-alternating phase '
            'sequence here (for example two consecutive COLONIAL entries '
            'after a province loss).',
      );
    });
  });

  group('runDomainPlanners OW-boundary phase transition', () {
    test(
      'OW=10 (COLONIAL) surfaces NW tribe overture',
      () {
        final game = _scenarioGame(
          gp1OwProvinces: _gp1OwProvincesAtQuota,
        );
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, _nationId);
        final snapshot = _colonialAtQuotaSnapshot();

        expect(
          observerGoalPhaseFor(snapshot: snapshot, game: game),
          ObserverGoalPhase.colonial,
          reason:
              'Sanity: the at-quota fixture must land in COLONIAL so the '
              'orchestrator pin below exercises the COLONIAL allow path. '
              'A failure here means the phase boundary itself drifted, '
              'and the orchestrator assertion would be measuring the '
              'wrong contract.',
        );

        final orders = runDomainPlanners(
          game: game,
          topology: topology,
          nationId: _nationId,
          view: view,
          snapshot: snapshot,
          config: _aiConfig,
          primaryGoal: StrategicGoal.conquer,
          seeds: AISeedBundle.fromTurnSeed(2509330),
          suggestionAPI: _nwTribeOvertureApi,
          economyPlan: _economyPlan,
        );

        expect(
          _overtureTargets(orders),
          contains(_tribeId),
          reason:
              'At quota (OW=10) the GP is in COLONIAL: SPEC § COLONIAL '
              'phase acquisition priority allows Join Empire (and the '
              'establishOverture candidate the fake API supplies). Over-'
              'suppression here would strip Join Empire from the NW '
              'acquisition routes and stall turn-150 NW ownership.',
        );
      },
    );

    test(
      'OW=9 (post-loss EXPAND) drops the same NW tribe overture',
      () {
        final game = _scenarioGame(
          gp1OwProvinces: _gp1OwProvincesJustBelowQuota,
        );
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, _nationId);
        final snapshot = _expandJustBelowQuotaSnapshot();

        expect(
          observerGoalPhaseFor(snapshot: snapshot, game: game),
          ObserverGoalPhase.expand,
          reason:
              'Sanity: dropping a single province from quota (10 -> 9) '
              'must put the GP in EXPAND immediately (no hysteresis band '
              'at quota+1). A failure here means the phase guard drifted '
              'and the orchestrator suppression below would be '
              'spuriously verified against the wrong phase.',
        );

        final orders = runDomainPlanners(
          game: game,
          topology: topology,
          nationId: _nationId,
          view: view,
          snapshot: snapshot,
          config: _aiConfig,
          primaryGoal: StrategicGoal.expand,
          seeds: AISeedBundle.fromTurnSeed(2509331),
          suggestionAPI: _nwTribeOvertureApi,
          economyPlan: _economyPlan,
        );

        expect(
          _overtureTargets(orders),
          isNot(contains(_tribeId)),
          reason:
              'Issue #2509 § Phase transition guard: a province loss '
              'from quota immediately restores EXPAND so NW work cannot '
              'mask OW regression. The orchestrator must therefore drop '
              'the same NW tribe overture candidate it surfaced at OW=10. '
              'A regression that retained the COLONIAL phase (hysteresis) '
              'would let NW work continue and threaten the canonical '
              'seed-42 `--verify-conquest` per-GP +3 net OW gain gate.',
        );
      },
    );

    test(
      'identical OW=9 inputs produce identical EXPAND orders across runs',
      () {
        // Determinism guard (must-have #7) at the boundary fixture used by
        // the no-hysteresis pin above: a flaky filter that intermittently
        // retained the previous-phase output would not necessarily fail
        // the alternating-phase pin but would surface here as a diverging
        // diplomatic-order fingerprint between two identical runs.
        final game = _scenarioGame(
          gp1OwProvinces: _gp1OwProvincesJustBelowQuota,
        );
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, _nationId);
        final snapshot = _expandJustBelowQuotaSnapshot();

        Orders runOnce(int turnSeed) => runDomainPlanners(
          game: game,
          topology: topology,
          nationId: _nationId,
          view: view,
          snapshot: snapshot,
          config: _aiConfig,
          primaryGoal: StrategicGoal.expand,
          seeds: AISeedBundle.fromTurnSeed(turnSeed),
          suggestionAPI: _nwTribeOvertureApi,
          economyPlan: _economyPlan,
        );

        final firstRun = runOnce(2509332);
        final secondRun = runOnce(2509332);

        List<String> diplomaticFingerprint(Orders orders) => <String>[
          for (final o
              in orders.diplomaticOrdersByPlayerId[_nationId] ?? const [])
            '${o.type}|${o.targetFactionId}|${o.overtureStage}',
        ];

        expect(
          diplomaticFingerprint(secondRun),
          diplomaticFingerprint(firstRun),
          reason:
              'Determinism (must-have #7): the just-below-quota fixture '
              'must surface identical diplomatic orders across repeated '
              'runs. A divergence here indicates a non-deterministic '
              'phase-boundary path that a single-run pin would miss.',
        );
      },
    );
  });
}
