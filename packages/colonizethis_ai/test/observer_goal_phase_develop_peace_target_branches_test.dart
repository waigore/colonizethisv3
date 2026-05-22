// Pins the DEVELOP-phase peace-targeting branches of
// `developPhaseGpPeaceTargets` from issue #2509 S10 at the function-unit
// boundary (Refs #2509).
//
//   SPEC/ai/ai-architecture.md § Observer goal phases (Full AI), DEVELOP:
//     "`offerPeace` toward all GP wars unless defending a province with
//     an active improvement worker"
//
// This file is the DEVELOP analog of
// `observer_goal_phase_expand_peace_blocker_branches_test.dart` (EXPAND
// peace blocker pin via PR #2662) and
// `observer_goal_phase_colonial_peace_blocker_branches_test.dart`
// (COLONIAL peace blocker pin via PR #2661). The DEVELOP helper is
// simpler than its EXPAND/COLONIAL siblings -- it has no blocker
// preservation rule and no minor-first short-circuit -- but the existing
// function-unit pin in `observer_goal_phase_test.dart` group
// `developPhaseGpPeaceTargets` only contains **one** happy-path test
// ('lists all at-war GPs in develop phase'). That single test asserts
// the canonical two-GPs-plus-one-minor case `['gp2', 'gp3']` (already
// sorted input, single phase entry) but does not exercise the
// not-in-DEVELOP early return, empty-`atWarWith` branch,
// non-GP-only-`atWarWith` filter result, single-GP path, multi-GP
// unsorted-input ordering, or determinism contract.
//
// Sibling coverage that this file complements (but does not duplicate):
//
//   - `observer_goal_phase_test.dart` group `developPhaseGpPeaceTargets`
//     pins the single happy-path multi-GP-with-minor case (`['gp2',
//     'gp3']`). It does not exercise the other branch arms.
//   - `observer_goal_phase_test.dart` group
//     `collectStalledGreatPowerPeaceTargets phase gating` test 'develop
//     phase uses develop peace only, not expand ratchet' asserts that
//     the orchestrator wrapper defers to this helper in DEVELOP, but
//     uses a single canonical develop-phase fixture and does not pin
//     the helper's branch table.
//   - `domain_planner_orchestrator_develop_two_gp_peace_test.dart` pins
//     the canonical 2-GP-at-war peace contract at the orchestrator
//     boundary. Its file header explicitly notes that the predicate
//     itself is pinned at the function level by the
//     `developPhaseGpPeaceTargets` group above -- this file finishes
//     that function-level pin so the orchestrator pin can rely on a
//     fully-branched helper contract.
//
// What's not currently pinned (this file's coverage):
//
//   1. **Not-in-DEVELOP early return:** the helper must return `const []`
//      when the phase is EXPAND or COLONIAL. EXPAND and COLONIAL each
//      have their own peace-target helpers (`expandPhaseGpPeaceTargets`,
//      `colonialPhaseGpPeaceTargets`) with **different** rules
//      (minor-first / blocker preservation), so a regression that
//      dropped the phase guard would silently apply the DEVELOP
//      "peace-all-GPs" rule to EXPAND below-quota wars (collapsing the
//      OW conquest push) or to COLONIAL wars (collapsing the blocker
//      preservation rule).
//   2. **Empty `atWarWith`:** DEVELOP with no live wars must return
//      empty (loop body never runs; the sort on an empty list is a
//      no-op). A regression that returned the at-peace GP roster would
//      generate spurious `offerPeace` orders.
//   3. **`atWarWith` contains only minors / tribes:** the inline
//      `game.playerById(factionId) != null` filter must drop every
//      non-GP faction. DEVELOP is GP-vs-GP peace only -- minors and
//      tribes are pursued through other diplomacy paths.
//   4. **Single GP at war:** the helper does **not** require two or
//      more GPs (unlike EXPAND / COLONIAL). One GP at war returns a
//      one-element list immediately. A regression that copied the
//      EXPAND `gpWars.length <= 1` guard would leave the lone GP front
//      open and starve improvement-first DEVELOP civilian work.
//   5. **Multi-GP unsorted-input ordering:** the trailing `..sort()`
//      must return the GP fronts in ascending `factionId` order
//      regardless of `snapshot.threats.atWarWith` order. Must-have #7
//      (determinism) at the function-unit level.
//   6. **Mixed GP + non-GP `atWarWith`:** non-GP factions must be
//      filtered out **before** the sort, leaving only GP ids in
//      ascending order.
//   7. **Determinism:** repeating the call with identical inputs must
//      yield an identical list (Must-have #7).
//
// Coverage layers:
//   - **Function unit (`developPhaseGpPeaceTargets`):** not-in-DEVELOP
//     (EXPAND fixture) / not-in-DEVELOP (COLONIAL fixture) /
//     empty-atWarWith / non-GP-only-atWarWith / single-GP-at-war /
//     three-GPs-unsorted-input / mixed-GP-and-non-GP-atWarWith /
//     determinism branch table.
//
// Pin strategy: small synthetic fixtures targeted at one branch each.
// The happy path is covered by the existing canonical test; this file
// fills in the remaining branch arms so future S10 tuning cannot
// silently regress them.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gp1 = 'gp1';
const String _gp2 = 'gp2';
const String _gp3 = 'gp3';
const String _gp4 = 'gp4';
const String _tribe1 = 'tribe1';
const String _minor1 = 'minor1';

/// Game scaffold with a configurable turn number and roster.
///
/// Defaults to a 4-GP roster (no minors / tribes mounted) so tests can
/// freely add `atWarWith` entries that resolve to GP players for the
/// inline `game.playerById(factionId) != null` filter. Tests that need
/// minor / tribe filtering supply their own minor / tribe lists.
Game _developGame({
  required int turnNumber,
  List<Player> players = const [
    Player(id: _gp1, displayName: 'GP1', isHuman: false),
    Player(id: _gp2, displayName: 'GP2', isHuman: false),
    Player(id: _gp3, displayName: 'GP3', isHuman: false),
    Player(id: _gp4, displayName: 'GP4', isHuman: false),
  ],
  List<Tribe> tribes = const [],
  List<MinorNation> minorNations = const [],
}) {
  return Game(
    id: 'g-2509-develop-peace-target-branches-t$turnNumber',
    worldState: WorldState(
      turnState: TurnState(
        turnNumber: turnNumber,
        phase: TurnPhase.orders,
      ),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: players,
    tribes: tribes,
    minorNations: minorNations,
  );
}

/// Snapshot fixing the GP **at** the OW quota (10) with an empty
/// colonial summary -- no invadable NW, no adjacent NW owners -- so
/// `observerGoalPhaseFor` returns DEVELOP and
/// `developPhaseGpPeaceTargets` is the helper under test.
AIWorldSnapshot _developSnapshot({
  required List<String> atWarWith,
  int oldWorldProvincesOwned = kObserverConquestMinOwProvincesPerGp,
  String playerId = _gp1,
}) {
  return AIWorldSnapshot(
    playerId: playerId,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
    ),
    colonial: const ColonialSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}

void main() {
  group('developPhaseGpPeaceTargets guard branches', () {
    test('not in DEVELOP phase (EXPAND fixture) -> empty', () {
      // Below OW quota -> EXPAND. EXPAND has its own peace-target
      // helper (`expandPhaseGpPeaceTargets`) with a different rule
      // (minor-first + blocker preservation), so the DEVELOP helper
      // must abstain here. A regression that dropped the phase guard
      // would silently flatten "peace all GPs" onto EXPAND fronts and
      // collapse the SPEC EXPAND minor-first / blocker preservation
      // contract.
      final game = _developGame(turnNumber: 50);
      const snapshot = AIWorldSnapshot(
        playerId: _gp1,
        threats: ThreatSummary(atWarWith: [_gp2, _gp3]),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(oldWorldProvincesOwned: 8),
        colonial: ColonialSummary(),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        observerGoalPhaseFor(snapshot: snapshot, game: game),
        ObserverGoalPhase.expand,
        reason:
            'Fixture must place GP in EXPAND so the DEVELOP helper\'s '
            'early return is the only branch under test.',
      );
      expect(
        developPhaseGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Outside DEVELOP the helper must return the empty list '
            'immediately -- EXPAND has its own peace-target helper '
            'with a minor-first / blocker preservation rule that '
            '`developPhaseGpPeaceTargets` must not pre-empt.',
      );
    });

    test('not in DEVELOP phase (COLONIAL fixture) -> empty', () {
      // OW at quota plus visible invadable NW -> COLONIAL. COLONIAL
      // preserves the colonial-blocker GP front via
      // `colonialPhaseGpPeaceTargets`. A regression that dropped the
      // phase guard would peace every at-war GP in COLONIAL and
      // collapse the blocker preservation rule.
      final game = _developGame(turnNumber: 110);
      const snapshot = AIWorldSnapshot(
        playerId: _gp1,
        threats: ThreatSummary(atWarWith: [_gp2, _gp3]),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
        ),
        colonial: ColonialSummary(
          invadableNewWorldProvinceIdsSorted: ['newWorld|p1'],
        ),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        observerGoalPhaseFor(snapshot: snapshot, game: game),
        ObserverGoalPhase.colonial,
        reason:
            'Fixture must place GP in COLONIAL so the DEVELOP helper\'s '
            'early return is the only branch under test.',
      );
      expect(
        developPhaseGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Outside DEVELOP the helper must return the empty list '
            'immediately -- COLONIAL has its own peace-target helper '
            'with a blocker preservation rule that '
            '`developPhaseGpPeaceTargets` must not pre-empt.',
      );
    });

    test('DEVELOP with empty atWarWith -> empty', () {
      // DEVELOP phase entry confirmed below; the loop body never runs
      // and the sort on an empty list is a no-op. A regression that
      // returned the at-peace GP roster would generate spurious
      // `offerPeace` orders toward neutral powers.
      final game = _developGame(turnNumber: 140);
      final snapshot = _developSnapshot(atWarWith: const []);
      expect(
        observerGoalPhaseFor(snapshot: snapshot, game: game),
        ObserverGoalPhase.develop,
        reason: 'Fixture must place GP in DEVELOP.',
      );
      expect(
        developPhaseGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Empty `atWarWith` means there are no live war fronts; '
            'the helper must return empty without iterating the GP '
            'roster.',
      );
    });

    test('DEVELOP with only minors/tribes in atWarWith -> empty', () {
      // The inline `game.playerById(factionId) != null` filter must
      // drop every non-GP faction. DEVELOP is GP-vs-GP peace only --
      // minor / tribe wars are pursued through other diplomacy paths
      // (war pursuit, embassy chain, purchase_land). A regression
      // that returned tribe / minor ids here would emit `offerPeace`
      // toward non-GP factions and break downstream order
      // validation.
      final game = _developGame(
        turnNumber: 140,
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = _developSnapshot(
        atWarWith: const [_tribe1, _minor1],
      );
      expect(
        observerGoalPhaseFor(snapshot: snapshot, game: game),
        ObserverGoalPhase.develop,
        reason: 'Fixture must place GP in DEVELOP.',
      );
      expect(
        developPhaseGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Non-GP factions (tribes / minors) are filtered out of '
            'the peace-target list by `game.playerById` returning '
            'null for non-player ids. With only non-GP wars present, '
            'the helper must return empty.',
      );
    });

    test('DEVELOP with single GP at war -> [that GP]', () {
      // Unlike EXPAND / COLONIAL, DEVELOP has **no** `gpWars.length
      // <= 1` guard -- a single GP front must be peaced too. A
      // regression that copied the EXPAND / COLONIAL length guard
      // would leave a lone GP war open and starve the
      // improvement-first DEVELOP civilian work (turn-150
      // `--verify-colonial-expansion` 70% extractable-tile
      // improvement gate).
      final game = _developGame(turnNumber: 140);
      final snapshot = _developSnapshot(atWarWith: const [_gp2]);
      expect(
        observerGoalPhaseFor(snapshot: snapshot, game: game),
        ObserverGoalPhase.develop,
        reason: 'Fixture must place GP in DEVELOP.',
      );
      expect(
        developPhaseGpPeaceTargets(game: game, snapshot: snapshot),
        const [_gp2],
        reason:
            'DEVELOP peace rule covers every at-war GP, including a '
            'single GP front. The helper must return a one-element '
            'list, not empty.',
      );
    });

    test(
      'DEVELOP with three GPs at war (unsorted input) -> ascending sorted',
      () {
        // Pins the `..sort()` contract: the helper must return GP
        // fronts in stable ascending `factionId` order so downstream
        // order generation is deterministic for a fixed seed
        // (Must-have #7). Input order shuffled to gp3 / gp4 / gp2 so
        // a regression that dropped the sort (or replaced it with
        // input-order preservation) would surface here.
        final game = _developGame(turnNumber: 140);
        final snapshot = _developSnapshot(
          atWarWith: const [_gp3, _gp4, _gp2],
        );
        expect(
          observerGoalPhaseFor(snapshot: snapshot, game: game),
          ObserverGoalPhase.develop,
          reason: 'Fixture must place GP in DEVELOP.',
        );
        expect(
          developPhaseGpPeaceTargets(game: game, snapshot: snapshot),
          const [_gp2, _gp3, _gp4],
          reason:
              'All at-war GPs returned in ascending `factionId` order '
              'regardless of `snapshot.threats.atWarWith` order '
              '(Refs #2509 must-have #7 determinism).',
        );
      },
    );

    test(
      'DEVELOP with mixed GP + non-GP atWarWith -> only GPs, sorted',
      () {
        // Defensive pin: the filter and the sort must compose so that
        // tribe / minor ids in `atWarWith` are dropped **before** the
        // sort runs. The shuffled input order (gp3, tribe1, gp2,
        // minor1) exercises both the filter (drops tribe1, minor1)
        // and the sort (gp3, gp2 -> gp2, gp3) in one fixture. A
        // regression that sorted first and filtered after would
        // still pass; a regression that left non-GP ids in the
        // output list would break downstream `offerPeace` validation.
        final game = _developGame(
          turnNumber: 140,
          tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
          minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
        );
        final snapshot = _developSnapshot(
          atWarWith: const [_gp3, _tribe1, _gp2, _minor1],
        );
        expect(
          observerGoalPhaseFor(snapshot: snapshot, game: game),
          ObserverGoalPhase.develop,
          reason: 'Fixture must place GP in DEVELOP.',
        );
        expect(
          developPhaseGpPeaceTargets(game: game, snapshot: snapshot),
          const [_gp2, _gp3],
          reason:
              'Non-GP factions in `atWarWith` are filtered out before '
              'the sort, leaving the GP fronts in ascending '
              '`factionId` order.',
        );
      },
    );

    test(
      'determinism: identical inputs produce identical peace target list',
      () {
        // Must-have #7 (determinism) at the function-unit level,
        // mirroring the determinism pins in
        // `observer_goal_phase_expand_peace_blocker_branches_test.dart`
        // and `observer_goal_phase_colonial_peace_blocker_branches_test.dart`.
        // The mixed-input fixture exercises both the filter and the
        // sort, so repeating the call must yield the same list.
        final game = _developGame(
          turnNumber: 140,
          tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
          minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
        );
        final snapshot = _developSnapshot(
          atWarWith: const [_gp3, _tribe1, _gp2, _minor1],
        );
        final first = developPhaseGpPeaceTargets(
          game: game,
          snapshot: snapshot,
        );
        final second = developPhaseGpPeaceTargets(
          game: game,
          snapshot: snapshot,
        );
        expect(second, first);
      },
    );
  });
}
