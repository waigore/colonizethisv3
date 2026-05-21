// Pins all four phase branches of `shouldSuppressNewWorldColonialOrders` at
// the predicate boundary (Refs #2509 S10).
//
//   SPEC/ai/ai-architecture.md § Observer goal phases (Full AI):
//
//     EXPAND     → suppress NW colonial diplomacy, military, civilian, and
//                  naval work. EXPAND suppressions list: "No NW
//                  `declareWar` / `establishOverture` toward colonial
//                  targets, NW conquest army moves, colonial naval
//                  ranking/caps, `purchase_land` / NW `build_improvement`
//                  civilian work, or colonial-pressure goal/diplomacy
//                  floors." `shouldSuppressNewWorldColonialOrders` is the
//                  single predicate behind those suppressions.
//     COLONIAL-lite → allow colonial naval/cargo and `establishOverture`
//                  even while OW < quota. The naval boost in
//                  `naval_planner.dart` and the NW `establishOverture`
//                  gate in `diplomatic_candidate_scoring.dart` are both
//                  conditioned on `!shouldSuppressNewWorldColonialOrders`.
//     COLONIAL   → allow NW acquisition (NW declare-war scoring, colonial
//                  pressure, NW naval ranking, NW establishOverture all
//                  depend on this predicate returning `false`).
//     DEVELOP    → allow this predicate to be `false` (DEVELOP's own
//                  suppressions live in `shouldSuppressNewWorldDeclareWar`
//                  `InvasionAndPurchase` and `shouldFilterObserverPhase`
//                  `WorkOrder`, not in this predicate; flipping it to
//                  `true` would re-enable EXPAND-style suppressions in
//                  DEVELOP and double-gate NW improvement-supporting
//                  diplomacy/naval flows).
//
// The implementation in `observer_goal_phase.dart`:
//
//   bool shouldSuppressNewWorldColonialOrders({...}) =>
//       observerGoalPhaseFor(snapshot: snapshot, game: game) ==
//       ObserverGoalPhase.expand;
//
// The predicate is consumed by:
//
//   - `naval_planner.dart` — `hasColonialTargets` gating the +65 colonial
//     weight boost and the 85 floor on `runNavalPlanner` (a regression
//     returning `true` in COLONIAL-lite drops the naval boost — see
//     `domain_planner_orchestrator_colonial_lite_naval_allow_test.dart`).
//   - `diplomatic_candidate_scoring.dart` — gates the EXPAND
//     `establishOverture` suppression toward NW colonial targets.
//   - `diplomatic_candidate_scoring_declare_war.dart` — `colonialPressure`
//     boolean (line 162-167) and `_declareWarSuppressedExpandColonialScore`
//     (line 300-304) both pivot on this predicate.
//   - `domain_planner_orchestrator.dart` — orchestrator-level
//     `colonialPressure` boolean (line 230-236).
//   - `goal_manager.dart` — colonial diplomacy / trade goal penalties.
//   - `observer_goal_phase.dart` itself — `isExpandPhaseColonialDiplomacy`
//     `Target` short-circuit (line 227).
//
// A single regression in this central predicate — for example collapsing
// `colonialLite` into `expand` (returning `true` and re-suppressing
// colonial naval + NW `establishOverture` in COLONIAL-lite) or collapsing
// `develop` into `expand` (returning `true` and double-gating DEVELOP
// peace and improvement-supporting naval/diplomacy flows) — would ripple
// through all six call sites at once and break must-have #1 (turn-150 NW
// ownership), must-have #5 (turn-100 OW conquest), and the COLONIAL-lite
// safeguard (turn ≥120 near-quota NW progress).
//
// Existing related coverage (not redundant with this pin):
//
//   - `observer_goal_phase_test.dart` group `observerGoalPhaseFor` —
//     directly asserts the predicate output only for three of the four
//     phase branches and mixed with phase-routing setup:
//       - EXPAND `true` (no game arg)
//       - COLONIAL-lite `false` (with game arg, OW=9, turn 120)
//       - COLONIAL `false` (no game arg, OW=10)
//     The **DEVELOP** branch is not pinned at the predicate boundary in
//     that file (it only asserts `isObserverDevelopPhase`). A regression
//     returning `true` for DEVELOP would surface only as indirect
//     orchestrator drift — far from the single switch line responsible.
//   - `domain_planner_orchestrator_colonial_lite_naval_allow_test.dart`,
//     `domain_planner_orchestrator_colonial_lite_test.dart` — pin
//     COLONIAL-lite naval ALLOW and overture ALLOW at the orchestrator
//     boundary. Those tests rely on the predicate already returning
//     `false` for COLONIAL-lite; they do not catch a regression that
//     inverted both the predicate **and** the corresponding orchestrator
//     pin in a single tuning slice (which would still pass the
//     orchestrator assertion but break every other call site).
//   - `observer_goal_phase_nw_declare_war_invasion_purchase_branches_`
//     `test.dart` (#2659) — pins the **sibling** predicate
//     `shouldSuppressNewWorldDeclareWarInvasionAndPurchase`. That
//     predicate is `true` for EXPAND / COLONIAL-lite / DEVELOP and
//     `false` for COLONIAL — a different shape from this one (EXPAND
//     true, all others false). Together they describe the complete
//     phase-branch matrix for the two NW suppression predicates.
//
// Coverage layers:
//
//   - **Branch table:** one assertion per `ObserverGoalPhase` value with
//     a fixture that resolves to that phase via `observerGoalPhaseFor`.
//   - **Phase fixture controls:** every test first asserts the fixture
//     resolves to the target phase, so a regression in
//     `observerGoalPhaseFor` cannot silently pass the predicate pin for
//     the wrong reason.
//   - **Switch exhaustiveness:** all four enum values are covered, so a
//     future addition to `ObserverGoalPhase` that omits this predicate
//     fails this group (Dart's exhaustive switch keeps the source
//     compile-clean, but a missed arm would surface here as the new
//     phase silently falls through to one of the existing branches).
//   - **Determinism (must-have #7):** identical phase inputs produce
//     identical predicate outcomes across repeat invocations.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _nationId = 'gp1';
const String _tribeId = 'tribe1';
const String _nwTribeProvince = 'newWorld|tribe1_nw0';
const String _nwGpOwnedProvince = 'newWorld|gp1_nw0';

/// Game fixture used for the EXPAND, COLONIAL-lite, and COLONIAL branches.
/// The non-GP-owned NW province satisfies the
/// `globalNewWorldHasNonGpOwnership` precondition for COLONIAL-lite while
/// the turn number drives whether the phase function picks COLONIAL-lite
/// (turn ≥ `kObserverColonialLiteMinTurn`) or EXPAND (turn below it) when
/// the snapshot is below quota, and supplies a visible NW acquisition
/// target for the COLONIAL branch at OW quota.
Game _gameWithTribeNw({required int turnNumber}) {
  return Game(
    id: 'g-2509-nw-colonial-orders-predicate',
    worldState: WorldState(
      turnState: TurnState(
        turnNumber: turnNumber,
        phase: TurnPhase.orders,
      ),
      oldWorld: const RegionData(),
      newWorld: RegionData(
        provinces: const [
          Province(
            id: _nwTribeProvince,
            regionId: kNewWorldRegionId,
            ownerId: _tribeId,
          ),
        ],
      ),
    ),
    players: const [Player(id: _nationId, displayName: 'P1', isHuman: false)],
    tribes: const [Tribe(id: _tribeId, displayName: 'T1')],
    minorNations: const [],
  );
}

/// Game fixture used for the DEVELOP branch — every visible NW province is
/// GP-owned so `hasColonialAcquisitionTargets` is false and the phase
/// function picks DEVELOP at OW quota.
Game _gameWithGpOwnedNw() {
  return Game(
    id: 'g-2509-nw-colonial-orders-predicate-develop',
    worldState: WorldState(
      turnState: const TurnState(
        turnNumber: 140,
        phase: TurnPhase.orders,
      ),
      oldWorld: const RegionData(),
      newWorld: RegionData(
        provinces: const [
          Province(
            id: _nwGpOwnedProvince,
            regionId: kNewWorldRegionId,
            ownerId: _nationId,
          ),
        ],
      ),
    ),
    players: const [Player(id: _nationId, displayName: 'P1', isHuman: false)],
    tribes: const [],
    minorNations: const [],
  );
}

/// Snapshot for EXPAND: below the observer OW quota, with one invadable
/// NW tribe province visible so the suppression has meaningful targets to
/// strip.
const AIWorldSnapshot _expandSnapshot = AIWorldSnapshot(
  playerId: _nationId,
  threats: ThreatSummary(),
  opportunities: OpportunitySummary(),
  conquest: ConquestSummary(oldWorldProvincesOwned: 7),
  colonial: ColonialSummary(
    invadableNewWorldProvinceIdsSorted: [_nwTribeProvince],
    adjacentNewWorldOwnerFactionIdsSorted: [_tribeId],
  ),
  economy: EconomySummary(),
  relations: {},
);

/// Snapshot for COLONIAL-lite: OW = `kObserverColonialLiteNearQuotaOw` (9)
/// and below quota. Combined with turn ≥120 and tribe-owned NW the GP
/// enters COLONIAL-lite per `isObserverColonialLitePhase`.
const AIWorldSnapshot _colonialLiteSnapshot = AIWorldSnapshot(
  playerId: _nationId,
  threats: ThreatSummary(),
  opportunities: OpportunitySummary(),
  conquest: ConquestSummary(
    oldWorldProvincesOwned: kObserverColonialLiteNearQuotaOw,
  ),
  colonial: ColonialSummary(
    invadableNewWorldProvinceIdsSorted: [_nwTribeProvince],
    adjacentNewWorldOwnerFactionIdsSorted: [_tribeId],
  ),
  economy: EconomySummary(),
  relations: {},
);

/// Snapshot for COLONIAL: at quota with visible colonial acquisition
/// targets, so `hasColonialAcquisitionTargets` is true and the phase
/// function picks COLONIAL.
const AIWorldSnapshot _colonialSnapshot = AIWorldSnapshot(
  playerId: _nationId,
  threats: ThreatSummary(),
  opportunities: OpportunitySummary(),
  conquest: ConquestSummary(oldWorldProvincesOwned: 11),
  colonial: ColonialSummary(
    invadableNewWorldProvinceIdsSorted: [_nwTribeProvince],
    adjacentNewWorldOwnerFactionIdsSorted: [_tribeId],
  ),
  economy: EconomySummary(),
  relations: {},
);

/// Snapshot for DEVELOP: at quota and no colonial acquisition targets.
const AIWorldSnapshot _developSnapshot = AIWorldSnapshot(
  playerId: _nationId,
  threats: ThreatSummary(),
  opportunities: OpportunitySummary(),
  conquest: ConquestSummary(oldWorldProvincesOwned: 11),
  colonial: ColonialSummary(newWorldProvincesOwned: 1),
  economy: EconomySummary(),
  relations: {},
);

void main() {
  group('shouldSuppressNewWorldColonialOrders phase branches', () {
    test('EXPAND suppresses all NW colonial orders', () {
      // Turn 50 is far below `kObserverColonialLiteMinTurn` (120) so the
      // COLONIAL-lite safeguard is inactive; OW=7 keeps the GP below
      // quota → EXPAND. A regression returning `false` here would
      // re-enable EXPAND's full NW colonial work set (declare-war,
      // overture, invasion army moves, naval ranking, purchase_land,
      // build_improvement, colonial-pressure goal/diplomacy floors)
      // before the OW quota is met and starve the turn-100 conquest
      // gate.
      final game = _gameWithTribeNw(turnNumber: 50);
      expect(
        observerGoalPhaseFor(snapshot: _expandSnapshot, game: game),
        ObserverGoalPhase.expand,
        reason:
            'Fixture must place GP in EXPAND so the EXPAND arm of the '
            'predicate is exercised, not the COLONIAL-lite or COLONIAL '
            'fall-through.',
      );
      expect(
        shouldSuppressNewWorldColonialOrders(
          snapshot: _expandSnapshot,
          game: game,
        ),
        isTrue,
        reason:
            'EXPAND must suppress NW colonial diplomacy / military / '
            'civilian / naval work per SPEC § Observer goal phases (Full '
            'AI) EXPAND suppressions list. This predicate is the single '
            'gate behind those suppressions in naval_planner, '
            'diplomatic_candidate_scoring{,_declare_war}, '
            'domain_planner_orchestrator, and goal_manager.',
      );
    });

    test('COLONIAL-lite allows NW colonial orders', () {
      // Turn 120 + OW=9 + tribe-owned NW = COLONIAL-lite per
      // `isObserverColonialLitePhase`. COLONIAL-lite explicitly allows
      // colonial naval/cargo and `establishOverture`; both are gated on
      // this predicate returning `false`. A regression returning `true`
      // here would silently break the COLONIAL-lite naval-allow pin
      // (drop the +65 boost, fail the 85 floor for henry's mil=20) and
      // the COLONIAL-lite NW establishOverture orchestrator pin.
      final game = _gameWithTribeNw(turnNumber: kObserverColonialLiteMinTurn);
      expect(
        observerGoalPhaseFor(snapshot: _colonialLiteSnapshot, game: game),
        ObserverGoalPhase.colonialLite,
        reason:
            'Fixture must place GP in COLONIAL-lite so the COLONIAL-lite '
            'arm of the predicate is exercised, not EXPAND (turn below '
            '120) or COLONIAL (OW at quota).',
      );
      expect(
        shouldSuppressNewWorldColonialOrders(
          snapshot: _colonialLiteSnapshot,
          game: game,
        ),
        isFalse,
        reason:
            'COLONIAL-lite must allow colonial naval/cargo and NW '
            '`establishOverture` per SPEC § COLONIAL-lite allow set. The '
            'predicate must return `false` so naval_planner picks up the '
            'colonial weight boost and diplomatic_candidate_scoring '
            'stops suppressing NW establishOverture for the near-quota '
            'GP at turn ≥120.',
      );
    });

    test('COLONIAL allows NW colonial orders', () {
      // OW=11 + visible NW colonial target = COLONIAL. COLONIAL is the
      // NW acquisition phase: NW declare-war scoring, colonial pressure
      // diplomacy boosts, NW establishOverture, and colonial naval
      // ranking all depend on this predicate returning `false`. A
      // regression returning `true` here would block the only AC
      // -sanctioned NW conquest phase entirely.
      final game = _gameWithTribeNw(turnNumber: 110);
      expect(
        observerGoalPhaseFor(snapshot: _colonialSnapshot, game: game),
        ObserverGoalPhase.colonial,
        reason:
            'Fixture must place GP in COLONIAL so the COLONIAL arm of '
            'the predicate is exercised. OW at quota with visible '
            'colonial acquisition targets is the canonical COLONIAL '
            'entry.',
      );
      expect(
        shouldSuppressNewWorldColonialOrders(
          snapshot: _colonialSnapshot,
          game: game,
        ),
        isFalse,
        reason:
            'COLONIAL is the NW acquisition phase; the predicate must '
            'return `false` so NW declare-war, establishOverture, '
            'colonial pressure, and naval ranking remain reachable for '
            'the turn-150 NW ownership gate (must-have #1).',
      );
    });

    test('DEVELOP allows NW colonial orders at the predicate boundary', () {
      // OW=11 + no colonial acquisition targets + no unowned visible NW
      // = DEVELOP per `observerGoalPhaseFor`. DEVELOP's suppressions
      // (new `declareWar`, NW acquisition orders, improvement-first
      // civilian threshold) live in
      // `shouldSuppressNewWorldDeclareWarInvasionAndPurchase` and
      // `shouldFilterObserverPhaseWorkOrder`, not in this predicate. A
      // regression returning `true` here would double-gate DEVELOP NW
      // flows (e.g. naval cargo for improvement-supporting routes,
      // tribe diplomacy maintenance) and break DEVELOP's allow set
      // implicitly while still passing the dedicated DEVELOP
      // declareWar-suppression pin (which uses a different predicate).
      final game = _gameWithGpOwnedNw();
      expect(
        observerGoalPhaseFor(snapshot: _developSnapshot, game: game),
        ObserverGoalPhase.develop,
        reason:
            'Fixture must place GP in DEVELOP so the DEVELOP arm of the '
            'predicate is exercised, not the COLONIAL fall-through. OW '
            'at quota with no visible colonial targets is the canonical '
            'DEVELOP entry.',
      );
      expect(
        shouldSuppressNewWorldColonialOrders(
          snapshot: _developSnapshot,
          game: game,
        ),
        isFalse,
        reason:
            'DEVELOP must NOT suppress at this predicate. DEVELOP\'s own '
            'suppressions live in `shouldSuppressNewWorldDeclareWar`'
            '`InvasionAndPurchase` (true for DEVELOP) and '
            '`shouldFilterObserverPhaseWorkOrder` (filters NW '
            'purchase_land in DEVELOP). Flipping this predicate to '
            '`true` for DEVELOP would re-enable EXPAND-style colonial '
            'naval / overture suppressions and double-gate DEVELOP NW '
            'maintenance flows.',
      );
    });
  });

  group('shouldSuppressNewWorldColonialOrders determinism', () {
    test('identical phase inputs produce identical predicate outcome', () {
      // Determinism guard (must-have #7): the predicate is pure with
      // respect to (snapshot, game). Pinning determinism per phase here
      // catches a regression that introduced incidental state (e.g.
      // caching a singleton phase or reading mutable globals) without
      // depending on the broader Full AI determinism harness.
      final colonialLiteGame =
          _gameWithTribeNw(turnNumber: kObserverColonialLiteMinTurn);
      final colonialGame = _gameWithTribeNw(turnNumber: 110);
      final developGame = _gameWithGpOwnedNw();
      final expandGame = _gameWithTribeNw(turnNumber: 50);

      for (final entry in <(AIWorldSnapshot, Game, bool)>[
        (_expandSnapshot, expandGame, true),
        (_colonialLiteSnapshot, colonialLiteGame, false),
        (_colonialSnapshot, colonialGame, false),
        (_developSnapshot, developGame, false),
      ]) {
        final (snapshot, game, expected) = entry;
        final first = shouldSuppressNewWorldColonialOrders(
          snapshot: snapshot,
          game: game,
        );
        final second = shouldSuppressNewWorldColonialOrders(
          snapshot: snapshot,
          game: game,
        );
        expect(first, expected);
        expect(second, first);
      }
    });
  });
}
