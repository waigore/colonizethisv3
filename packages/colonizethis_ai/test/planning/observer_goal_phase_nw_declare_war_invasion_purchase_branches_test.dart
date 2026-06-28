// Pins all four phase branches of
// `shouldSuppressNewWorldDeclareWarInvasionAndPurchase` at the predicate
// boundary (Refs #2509 S10).
//
//   SPEC/ai/ai-architecture.md § Observer goal phases (Full AI):
//
//     EXPAND     → suppress NW colonial diplomacy/military/civilian/cargo
//                  (NW declareWar, invasion army moves, and purchase_land are
//                  a strict subset of that suppression list).
//     COLONIAL-lite → suppress only NW `declareWar`, invasion army moves,
//                  and `purchase_land`; allow colonial naval / overture.
//     COLONIAL   → allow NW acquisition (NW declareWar, invasion, and
//                  purchase_land are the canonical NW acquisition routes;
//                  must-have #2 and the COLONIAL declare-war / overture
//                  rule depend on this).
//     DEVELOP    → suppress all new declareWar and NW acquisition (the
//                  improvement-first imperative cannot tolerate new NW
//                  conquest pulling Builders off the 70% gate path).
//
// The implementation in `observer_goal_phase.dart`:
//
//   bool shouldSuppressNewWorldDeclareWarInvasionAndPurchase({...}) {
//     switch (observerGoalPhaseFor(snapshot: snapshot, game: game)) {
//       case ObserverGoalPhase.expand:
//       case ObserverGoalPhase.colonialLite:
//       case ObserverGoalPhase.develop:
//         return true;
//       case ObserverGoalPhase.colonial:
//         return false;
//     }
//   }
//
// The predicate is consumed by:
//
//   - `conquest_planner.dart` (three call sites at lines 164, 259, 459) to
//     filter NW provinces out of the invadable army-move destination set
//     in every non-COLONIAL phase.
//   - `diplomatic_candidate_scoring_declare_war.dart` to zero NW
//     declare-war scores in every non-COLONIAL phase.
//
// A single regression in this central switch — for example collapsing
// `colonialLite` into `colonial` (returning `false` and re-enabling NW
// declare-war + invasion before the OW quota is met) or collapsing
// `colonial` into the suppress arm (returning `true` and blocking the
// only AC-sanctioned NW conquest path at quota) — would ripple through
// all four call sites at once and break must-have #1 (turn-150 NW
// ownership) **and** must-have #5 (turn-100 OW conquest).
//
// Existing related coverage (not redundant with this pin):
//
//   - `observer_goal_phase_test.dart` group `observerGoalPhaseFor` —
//     pins only the **COLONIAL-lite** branch of this function (turn 120,
//     OW=9, tribe-owned NW). The other three phase branches (EXPAND,
//     COLONIAL, DEVELOP) are exercised only **indirectly** through
//     orchestrator integration tests:
//       - EXPAND: `domain_planner_orchestrator_expand_nw_declare_war_`
//         `suppression_test.dart`
//       - COLONIAL: `domain_planner_orchestrator_colonial_tribe_declare_`
//         `war_test.dart`
//       - DEVELOP: `domain_planner_orchestrator_develop_declare_war_`
//         `suppression_test.dart`
//     A future tuning slice that left every orchestrator branch intact
//     but inverted one arm of this predicate's switch (e.g. swapping
//     `colonial` and `colonialLite`) could pass every orchestrator pin
//     while breaking the **other** call sites in `conquest_planner.dart`
//     (NW invadable filtering) and `diplomatic_candidate_scoring_declare`
//     `_war.dart` (NW declare-war scoring) that share this predicate.
//   - `observer_goal_phase_colonial_lite_preconditions_test.dart` —
//     pins the COLONIAL-lite **entry preconditions** (turn boundary,
//     OW boundary, global-NW-ownership). Does not pin the predicate
//     output per phase.
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

/// Game fixture used for the COLONIAL-lite and EXPAND branches. The
/// non-GP-owned NW province satisfies the
/// `globalNewWorldHasNonGpOwnership` precondition for COLONIAL-lite while
/// the turn number drives whether the phase function picks COLONIAL-lite
/// (turn ≥ `kObserverColonialLiteMinTurn`) or EXPAND (turn below it).
Game _gameWithTribeNw({required int turnNumber}) {
  return Game(
    id: 'g-2509-nw-suppress-predicate',
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
    id: 'g-2509-nw-suppress-predicate-develop',
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
  group('shouldSuppressNewWorldDeclareWarInvasionAndPurchase phase branches',
      () {
    test('EXPAND suppresses NW declareWar / invasion / purchase_land', () {
      // Turn 50 is far below `kObserverColonialLiteMinTurn` (120) so the
      // COLONIAL-lite safeguard is inactive; OW=7 keeps the GP below quota
      // → EXPAND. Pinned here so a regression that returned `false` for
      // EXPAND would re-open NW declare-war + invasion + `purchase_land`
      // below the OW quota and starve the turn-100 conquest gate.
      final game = _gameWithTribeNw(turnNumber: 50);
      expect(
        observerGoalPhaseFor(snapshot: _expandSnapshot, game: game),
        ObserverGoalPhase.expand,
        reason:
            'Fixture must place GP in EXPAND so the EXPAND arm of the '
            'predicate switch is exercised, not the COLONIAL-lite or '
            'COLONIAL fall-through.',
      );
      expect(
        shouldSuppressNewWorldDeclareWarInvasionAndPurchase(
          snapshot: _expandSnapshot,
          game: game,
        ),
        isTrue,
        reason:
            'EXPAND must suppress NW declareWar / invasion / purchase_land '
            'so below-quota GPs do not trade OW conquest pressure for NW '
            'work (SPEC § Observer goal phases (Full AI) EXPAND row).',
      );
    });

    test(
      'COLONIAL-lite suppresses NW declareWar / invasion / purchase_land',
      () {
        // Turn 120 + OW=9 + tribe-owned NW = COLONIAL-lite per
        // `isObserverColonialLitePhase`. The COLONIAL-lite SPEC clause
        // explicitly suppresses these three NW order families while still
        // allowing colonial naval / overture (which this predicate does
        // not gate).
        final game = _gameWithTribeNw(turnNumber: kObserverColonialLiteMinTurn);
        expect(
          observerGoalPhaseFor(snapshot: _colonialLiteSnapshot, game: game),
          ObserverGoalPhase.colonialLite,
          reason:
              'Fixture must place GP in COLONIAL-lite so the COLONIAL-lite '
              'arm of the predicate switch is exercised, not EXPAND (turn '
              'below 120) or COLONIAL (OW at quota).',
        );
        expect(
          shouldSuppressNewWorldDeclareWarInvasionAndPurchase(
            snapshot: _colonialLiteSnapshot,
            game: game,
          ),
          isTrue,
          reason:
              'COLONIAL-lite must suppress NW declareWar / invasion / '
              'purchase_land per the SPEC § COLONIAL-lite suppress list '
              '("NW declareWar, invasion army moves, and purchase_land '
              'only"). A regression returning `false` here would re-enable '
              'NW conquest before the OW quota is met and regress the '
              'turn-100 conquest gate.',
        );
      },
    );

    test('COLONIAL allows NW declareWar / invasion / purchase_land', () {
      // OW=11 + visible NW colonial target = COLONIAL. This is the **only**
      // phase where NW declare-war + invasion + purchase_land are
      // SPEC-sanctioned (acquisition priority: Join Empire →
      // purchase_land → declareWar + invasion). A regression that
      // returned `true` here would silently block must-have #2
      // (purchase_land path) and the COLONIAL declareWar AC.
      final game = _gameWithTribeNw(turnNumber: 110);
      expect(
        observerGoalPhaseFor(snapshot: _colonialSnapshot, game: game),
        ObserverGoalPhase.colonial,
        reason:
            'Fixture must place GP in COLONIAL so the COLONIAL arm of the '
            'predicate switch is exercised. OW at quota + visible colonial '
            'acquisition targets is the canonical COLONIAL entry.',
      );
      expect(
        shouldSuppressNewWorldDeclareWarInvasionAndPurchase(
          snapshot: _colonialSnapshot,
          game: game,
        ),
        isFalse,
        reason:
            'COLONIAL is the only phase where NW acquisition is the '
            'imperative; the predicate must return `false` so the NW '
            'declare-war, invasion army move, and Merchant purchase_land '
            'paths remain reachable for the turn-150 NW ownership gate.',
      );
    });

    test('DEVELOP suppresses NW declareWar / invasion / purchase_land', () {
      // OW=11 + no colonial acquisition targets + no unowned visible NW =
      // DEVELOP per `observerGoalPhaseFor`. DEVELOP's imperative is
      // improvement-first development; new NW acquisition wars would
      // starve the 70% extractable improvement gate at turn 150.
      final game = _gameWithGpOwnedNw();
      expect(
        observerGoalPhaseFor(snapshot: _developSnapshot, game: game),
        ObserverGoalPhase.develop,
        reason:
            'Fixture must place GP in DEVELOP so the DEVELOP arm of the '
            'predicate switch is exercised, not the COLONIAL fall-through. '
            'OW at quota with no visible colonial targets is the canonical '
            'DEVELOP entry.',
      );
      expect(
        shouldSuppressNewWorldDeclareWarInvasionAndPurchase(
          snapshot: _developSnapshot,
          game: game,
        ),
        isTrue,
        reason:
            'DEVELOP must suppress new NW declareWar / invasion / '
            'purchase_land per SPEC § DEVELOP rule 2 ("Suppress: new '
            'declareWar, NW acquisition orders ..."). A regression '
            'returning `false` here would re-open NW conquest in DEVELOP '
            'and pull Builders off the improvement-first path.',
      );
    });
  });

  group('shouldSuppressNewWorldDeclareWarInvasionAndPurchase determinism', () {
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
        (_colonialLiteSnapshot, colonialLiteGame, true),
        (_colonialSnapshot, colonialGame, false),
        (_developSnapshot, developGame, true),
      ]) {
        final (snapshot, game, expected) = entry;
        final first = shouldSuppressNewWorldDeclareWarInvasionAndPurchase(
          snapshot: snapshot,
          game: game,
        );
        final second = shouldSuppressNewWorldDeclareWarInvasionAndPurchase(
          snapshot: snapshot,
          game: game,
        );
        expect(first, expected);
        expect(second, first);
      }
    });
  });
}
