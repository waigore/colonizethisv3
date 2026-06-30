// Table-driven matrix consolidation of the observer-phase NW-suppression
// `(snapshot, game) -> bool` predicate pins (Refs #3749 branch-pin
// consolidation, continuation of the EXPAND predicate matrix in
// `expand_phase_planner_peace_predicate_game_matrix_test.dart`).
//
// This single file replaces two former per-predicate `*_branches_test.dart`
// suites that each pinned one observer-phase NW-suppression `bool` predicate
// from `observer_goal_phase.dart` with one `test(...)` per `ObserverGoalPhase`
// branch:
//
//   - `observer_goal_phase_nw_colonial_orders_branches_test.dart`
//     (`shouldSuppressNewWorldColonialOrders`)
//   - `observer_goal_phase_nw_declare_war_invasion_purchase_branches_test.dart`
//     (`shouldSuppressNewWorldDeclareWarInvasionAndPurchase`)
//
// Both predicates share the exact signature
// `({required AIWorldSnapshot snapshot, required Game game}) -> bool` and the
// same four phase fixtures (EXPAND, COLONIAL-lite, COLONIAL, DEVELOP), so each
// former phase-branch test becomes one matrix row that (1) re-asserts the
// shared phase fixture resolves to its target `ObserverGoalPhase` via
// `observerGoalPhaseFor` (the per-suite "phase fixture control" guard) and
// (2) asserts the predicate's expected boolean with the same verbatim
// regression `reason`. Coverage is preserved 1:1 — every former assertion has a
// corresponding assertion here — while the duplicated per-file fixtures and
// scaffolding collapse into one shared fixture set and one table-driven runner.
// The two former determinism guards (repeated-call stability across all four
// phases) are kept verbatim in a dedicated group below.
//
// The two predicates describe complementary phase-branch matrices:
//   - `shouldSuppressNewWorldColonialOrders`: EXPAND true; COLONIAL-lite,
//     COLONIAL, DEVELOP false.
//   - `shouldSuppressNewWorldDeclareWarInvasionAndPurchase`: EXPAND,
//     COLONIAL-lite, DEVELOP true; COLONIAL false.
//
// SPEC/ai/ai-architecture.md § Observer goal phases (Full AI) — the EXPAND /
// COLONIAL-lite / COLONIAL / DEVELOP NW colonial-order and
// NW declare-war/invasion/purchase suppression rows (Refs #2509 S10).

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
    id: 'g-2509-nw-suppression-predicate-matrix',
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
    id: 'g-2509-nw-suppression-predicate-matrix-develop',
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

/// One observer phase fixture: a `(snapshot, game)` pair whose
/// `observerGoalPhaseFor` resolves to [expectedPhase]. The game is built per
/// row so each `test` gets an independent instance (matching the source
/// suites, which constructed a fresh `Game` inside every test).
class _PhaseFixture {
  const _PhaseFixture({
    required this.label,
    required this.snapshot,
    required this.gameBuilder,
    required this.expectedPhase,
  });

  final String label;
  final AIWorldSnapshot snapshot;
  final Game Function() gameBuilder;
  final ObserverGoalPhase expectedPhase;
}

final _PhaseFixture _expandFixture = _PhaseFixture(
  label: 'EXPAND',
  snapshot: _expandSnapshot,
  gameBuilder: () => _gameWithTribeNw(turnNumber: 50),
  expectedPhase: ObserverGoalPhase.expand,
);
final _PhaseFixture _colonialLiteFixture = _PhaseFixture(
  label: 'COLONIAL-lite',
  snapshot: _colonialLiteSnapshot,
  gameBuilder: () => _gameWithTribeNw(turnNumber: kObserverColonialLiteMinTurn),
  expectedPhase: ObserverGoalPhase.colonialLite,
);
final _PhaseFixture _colonialFixture = _PhaseFixture(
  label: 'COLONIAL',
  snapshot: _colonialSnapshot,
  gameBuilder: () => _gameWithTribeNw(turnNumber: 110),
  expectedPhase: ObserverGoalPhase.colonial,
);
final _PhaseFixture _developFixture = _PhaseFixture(
  label: 'DEVELOP',
  snapshot: _developSnapshot,
  gameBuilder: _gameWithGpOwnedNw,
  expectedPhase: ObserverGoalPhase.develop,
);

typedef _PredicateFn = bool Function({
  required AIWorldSnapshot snapshot,
  required Game game,
});

/// One byte-equivalent branch row transcribed from a source `*_branches_test`.
/// [expected] is the predicate's verbatim per-phase outcome and [reason] is
/// the verbatim regression rationale from the source test.
class _Case {
  const _Case({
    required this.fixture,
    required this.expected,
    required this.reason,
  });

  final _PhaseFixture fixture;
  final bool expected;
  final String reason;
}

void _runPredicate(String label, _PredicateFn fn, List<_Case> cases) {
  group(label, () {
    for (final c in cases) {
      test('${c.fixture.label} -> ${c.expected}', () {
        final game = c.fixture.gameBuilder();
        expect(
          observerGoalPhaseFor(snapshot: c.fixture.snapshot, game: game),
          c.fixture.expectedPhase,
          reason:
              'Fixture must place GP in ${c.fixture.label} so that arm of the '
              'predicate is exercised, not a neighbouring phase fall-through '
              '(per-suite phase fixture control guard).',
        );
        expect(
          fn(snapshot: c.fixture.snapshot, game: game),
          c.expected ? isTrue : isFalse,
          reason: c.reason,
        );
      });
    }
  });
}

void main() {
  // --- shouldSuppressNewWorldColonialOrders: EXPAND true, others false. ---
  _runPredicate(
    'shouldSuppressNewWorldColonialOrders phase branches (truth table)',
    shouldSuppressNewWorldColonialOrders,
    <_Case>[
      _Case(
        fixture: _expandFixture,
        expected: true,
        reason:
            'EXPAND must suppress NW colonial diplomacy / military / '
            'civilian / naval work per SPEC § Observer goal phases (Full '
            'AI) EXPAND suppressions list. This predicate is the single '
            'gate behind those suppressions in naval_planner, '
            'diplomatic_candidate_scoring{,_declare_war}, '
            'domain_planner_orchestrator, and goal_manager.',
      ),
      _Case(
        fixture: _colonialLiteFixture,
        expected: false,
        reason:
            'COLONIAL-lite must allow colonial naval/cargo and NW '
            '`establishOverture` per SPEC § COLONIAL-lite allow set. The '
            'predicate must return `false` so naval_planner picks up the '
            'colonial weight boost and diplomatic_candidate_scoring '
            'stops suppressing NW establishOverture for the near-quota '
            'GP at turn ≥120.',
      ),
      _Case(
        fixture: _colonialFixture,
        expected: false,
        reason:
            'COLONIAL is the NW acquisition phase; the predicate must '
            'return `false` so NW declare-war, establishOverture, '
            'colonial pressure, and naval ranking remain reachable for '
            'the turn-150 NW ownership gate (must-have #1).',
      ),
      _Case(
        fixture: _developFixture,
        expected: false,
        reason:
            'DEVELOP must NOT suppress at this predicate. DEVELOP\'s own '
            'suppressions live in `shouldSuppressNewWorldDeclareWar`'
            '`InvasionAndPurchase` (true for DEVELOP) and '
            '`shouldFilterObserverPhaseWorkOrder` (filters NW '
            'purchase_land in DEVELOP). Flipping this predicate to '
            '`true` for DEVELOP would re-enable EXPAND-style colonial '
            'naval / overture suppressions and double-gate DEVELOP NW '
            'maintenance flows.',
      ),
    ],
  );

  // --- shouldSuppressNewWorldDeclareWarInvasionAndPurchase: EXPAND / ---
  // --- COLONIAL-lite / DEVELOP true, COLONIAL false. ---
  _runPredicate(
    'shouldSuppressNewWorldDeclareWarInvasionAndPurchase phase branches '
    '(truth table)',
    shouldSuppressNewWorldDeclareWarInvasionAndPurchase,
    <_Case>[
      _Case(
        fixture: _expandFixture,
        expected: true,
        reason:
            'EXPAND must suppress NW declareWar / invasion / purchase_land '
            'so below-quota GPs do not trade OW conquest pressure for NW '
            'work (SPEC § Observer goal phases (Full AI) EXPAND row).',
      ),
      _Case(
        fixture: _colonialLiteFixture,
        expected: true,
        reason:
            'COLONIAL-lite must suppress NW declareWar / invasion / '
            'purchase_land per the SPEC § COLONIAL-lite suppress list '
            '("NW declareWar, invasion army moves, and purchase_land '
            'only"). A regression returning `false` here would re-enable '
            'NW conquest before the OW quota is met and regress the '
            'turn-100 conquest gate.',
      ),
      _Case(
        fixture: _colonialFixture,
        expected: false,
        reason:
            'COLONIAL is the only phase where NW acquisition is the '
            'imperative; the predicate must return `false` so the NW '
            'declare-war, invasion army move, and Merchant purchase_land '
            'paths remain reachable for the turn-150 NW ownership gate.',
      ),
      _Case(
        fixture: _developFixture,
        expected: true,
        reason:
            'DEVELOP must suppress new NW declareWar / invasion / '
            'purchase_land per SPEC § DEVELOP rule 2 ("Suppress: new '
            'declareWar, NW acquisition orders ..."). A regression '
            'returning `false` here would re-open NW conquest in DEVELOP '
            'and pull Builders off the improvement-first path.',
      ),
    ],
  );

  // Determinism guards (must-have #7) retained verbatim from the source
  // suites: each predicate is pure with respect to (snapshot, game), so
  // repeated invocations across all four phases must agree with the
  // expected per-phase outcome. These are the only assertions that are not a
  // single `(snapshot, game) -> bool` matrix row.
  group('shouldSuppressNewWorldColonialOrders determinism', () {
    test('identical phase inputs produce identical predicate outcome', () {
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

  group('shouldSuppressNewWorldDeclareWarInvasionAndPurchase determinism', () {
    test('identical phase inputs produce identical predicate outcome', () {
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
