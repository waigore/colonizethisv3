// Pins the COLONIAL-phase peace-targeting branches of `primaryColonialGpBlocker`
// and `colonialPhaseGpPeaceTargets` from issue #2509 S10 at the function-unit
// boundary (Refs #2509).
//
//   SPEC/ai/ai-architecture.md § Observer goal phases (Full AI), COLONIAL:
//     "offerPeace toward at-war Great Powers that do not own the primary
//     colonial NW frontier blocker when fighting two or more GPs".
//
// Sibling coverage that this file complements (but does not duplicate):
//
//   - `observer_goal_phase_test.dart` group `colonialPhaseGpPeaceTargets` —
//     pins the single canonical happy-path 2-GP-at-war case (gp2 blocker,
//     gp3 non-blocker → `['gp3']`). Does not exercise the
//     `primaryColonialGpBlocker` contract itself, the empty / single-GP
//     `gpWars` guards, the "blocker is null" branch (no GP owns any
//     invadable NW), the "blocker is not in `gpWars`" branch, the 3+ GP
//     at-war ordering, or the non-COLONIAL-phase early return.
//   - `domain_planner_orchestrator_colonial_two_gp_peace_test.dart` — pins
//     the same canonical 2-GP happy path at the orchestrator output. The
//     fixture explicitly asserts `primaryColonialGpBlocker == gp2` only as
//     a sanity check on its own setup; it does not exercise the other
//     blocker branches.
//
// What's not currently pinned (this file's coverage):
//
//   1. **`primaryColonialGpBlocker` contract:** empty invadable NW → null;
//      all invadable NW owned by non-GP factions (tribes / minors /
//      unowned) → null; single GP owning all invadable NW → that GP;
//      plurality wins among multiple GP owners; mixed GP + non-GP
//      ownership counts only GP-owned invadable provinces. A regression
//      that resolved the blocker to a tribe owner, a non-plurality GP, or
//      `null` when a clear plurality GP exists would silently invert the
//      `colonialPhaseGpPeaceTargets` preservation set.
//   2. **`colonialPhaseGpPeaceTargets` guard branches:** not in COLONIAL →
//      empty (EXPAND fall-through has its own peace-target helper);
//      `gpWars` empty / `gpWars.length <= 1` → empty (single-front war
//      keeps the front open for the SPEC two-or-more-GPs trigger); blocker
//      null → empty (no GP-owned invadable NW means the preservation rule
//      cannot identify a front to keep); blocker not in `gpWars` → empty
//      (the blocker is not actually a live war front).
//   3. **`colonialPhaseGpPeaceTargets` 3+ GP ordering:** 3 GPs at war with
//      one blocker → the other two non-blocker GP factions returned in
//      stable ascending `factionId` order (deterministic for fixed seed
//      per Must-have #7).
//
// Coverage layers:
//   - **Function unit (`primaryColonialGpBlocker`):** empty invadable /
//     all-tribe / single-GP / plurality / mixed / unowned-NW boundary
//     table.
//   - **Function unit (`colonialPhaseGpPeaceTargets`):** not-in-COLONIAL /
//     empty-gpWars / single-gpWar / null-blocker / blocker-not-in-gpWars /
//     3-GP-ordering branch table.
//
// Pin strategy: small synthetic fixtures targeted at one branch each. The
// happy path is covered by the existing canonical test; this file fills
// in the remaining branch arms so future S10 tuning cannot silently
// regress them.

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
const String _tribe2 = 'tribe2';
const String _minor1 = 'minor1';

/// Game with NW provinces enumerated by `(id, ownerId)` pairs.
Game _gameWithNwProvinces({
  required int turnNumber,
  required List<Province> nwProvinces,
  List<Player> players = const [
    Player(id: _gp1, displayName: 'GP1', isHuman: false),
    Player(id: _gp2, displayName: 'GP2', isHuman: false),
    Player(id: _gp3, displayName: 'GP3', isHuman: false),
    Player(id: _gp4, displayName: 'GP4', isHuman: false),
  ],
  List<Tribe> tribes = const [
    Tribe(id: _tribe1, displayName: 'T1'),
    Tribe(id: _tribe2, displayName: 'T2'),
  ],
  List<MinorNation> minorNations = const [
    MinorNation(id: _minor1, displayName: 'M1'),
  ],
}) {
  return Game(
    id: 'g-2509-colonial-peace-blocker-branches-t$turnNumber',
    worldState: WorldState(
      turnState: TurnState(turnNumber: turnNumber, phase: TurnPhase.orders),
      oldWorld: const RegionData(),
      newWorld: RegionData(provinces: nwProvinces),
    ),
    players: players,
    tribes: tribes,
    minorNations: minorNations,
  );
}

/// Snapshot fixing the GP at the OW quota (10) with COLONIAL acquisition
/// targets visible — keeps `observerGoalPhaseFor` on COLONIAL so the
/// peace-target helper runs.
AIWorldSnapshot _colonialSnapshot({
  required List<String> atWarWith,
  required List<String> invadableNw,
  List<String> adjacentNw = const [],
  String playerId = _gp1,
}) {
  return AIWorldSnapshot(
    playerId: playerId,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: const ConquestSummary(
      oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
      provincesToVictory: 21,
    ),
    colonial: ColonialSummary(
      invadableNewWorldProvinceIdsSorted: invadableNw,
      adjacentNewWorldOwnerFactionIdsSorted: adjacentNw.isEmpty
          ? (invadableNw.isEmpty ? const [_tribe1] : const [])
          : adjacentNw,
    ),
    economy: const EconomySummary(),
    relations: const {},
  );
}

void main() {
  group('primaryColonialGpBlocker contract', () {
    test('empty invadable NW → null', () {
      final game = _gameWithNwProvinces(turnNumber: 110, nwProvinces: const []);
      final snapshot = _colonialSnapshot(
        atWarWith: const [_gp2, _gp3],
        invadableNw: const [],
      );
      expect(
        primaryColonialGpBlocker(game: game, snapshot: snapshot),
        isNull,
        reason:
            'No invadable NW provinces means no GP can be the colonial '
            'frontier blocker — the loop body never runs and the function '
            'returns null. A regression that returned an arbitrary at-war GP '
            'as blocker would silently preserve that front when '
            '`colonialPhaseGpPeaceTargets` should peace everyone.',
      );
    });

    test('all invadable NW owned by tribes/minors → null', () {
      final game = _gameWithNwProvinces(
        turnNumber: 110,
        nwProvinces: const [
          Province(id: 'newWorld|t1_a', regionId: 'newWorld', ownerId: _tribe1),
          Province(id: 'newWorld|t2_a', regionId: 'newWorld', ownerId: _tribe2),
          Province(id: 'newWorld|m1_a', regionId: 'newWorld', ownerId: _minor1),
        ],
      );
      final snapshot = _colonialSnapshot(
        atWarWith: const [_gp2, _gp3],
        invadableNw: const ['newWorld|t1_a', 'newWorld|t2_a', 'newWorld|m1_a'],
      );
      expect(
        primaryColonialGpBlocker(game: game, snapshot: snapshot),
        isNull,
        reason:
            'Tribes and minor nations are not Great Powers '
            '(`game.playerById` returns null for them) so they are skipped '
            'by the blocker scan. A regression that counted non-GP owners '
            'would falsely identify a tribe as the colonial blocker and '
            'invert the peace preservation set.',
      );
    });

    test('all invadable NW unowned (null owner) → null', () {
      final game = _gameWithNwProvinces(
        turnNumber: 110,
        nwProvinces: const [
          Province(id: 'newWorld|u_a', regionId: 'newWorld'),
          Province(id: 'newWorld|u_b', regionId: 'newWorld'),
        ],
      );
      final snapshot = _colonialSnapshot(
        atWarWith: const [_gp2, _gp3],
        invadableNw: const ['newWorld|u_a', 'newWorld|u_b'],
      );
      expect(
        primaryColonialGpBlocker(game: game, snapshot: snapshot),
        isNull,
        reason:
            'Unowned NW provinces have null ownerId in the province-owner '
            'map and are skipped by the blocker scan (mirrors the '
            '`getProvinceOwnerMap` contract). A regression that picked the '
            'first iterated province\'s owner unconditionally would crash '
            'or return an empty-string owner here.',
      );
    });

    test('single GP owning all invadable NW → that GP', () {
      final game = _gameWithNwProvinces(
        turnNumber: 110,
        nwProvinces: const [
          Province(id: 'newWorld|gp2_a', regionId: 'newWorld', ownerId: _gp2),
          Province(id: 'newWorld|gp2_b', regionId: 'newWorld', ownerId: _gp2),
        ],
      );
      final snapshot = _colonialSnapshot(
        atWarWith: const [_gp2, _gp3],
        invadableNw: const ['newWorld|gp2_a', 'newWorld|gp2_b'],
      );
      expect(
        primaryColonialGpBlocker(game: game, snapshot: snapshot),
        _gp2,
        reason:
            'When exactly one GP owns every invadable NW province, that GP '
            'is unambiguously the colonial blocker.',
      );
    });

    test('plurality wins among multiple GP owners (2 vs 1)', () {
      final game = _gameWithNwProvinces(
        turnNumber: 110,
        nwProvinces: const [
          Province(id: 'newWorld|gp2_a', regionId: 'newWorld', ownerId: _gp2),
          Province(id: 'newWorld|gp2_b', regionId: 'newWorld', ownerId: _gp2),
          Province(id: 'newWorld|gp3_a', regionId: 'newWorld', ownerId: _gp3),
        ],
      );
      final snapshot = _colonialSnapshot(
        atWarWith: const [_gp2, _gp3],
        invadableNw: const [
          'newWorld|gp2_a',
          'newWorld|gp2_b',
          'newWorld|gp3_a',
        ],
      );
      expect(
        primaryColonialGpBlocker(game: game, snapshot: snapshot),
        _gp2,
        reason:
            'The GP with the largest count of owned invadable NW provinces '
            'is the colonial blocker (strict `>` over running max). A '
            'regression that picked the last encountered GP, the highest '
            'factionId, or any non-plurality owner would shift the '
            'preservation set off the correct frontier.',
      );
    });

    test('mixed GP + tribe ownership: only GP counts contribute', () {
      // gp3 owns one invadable NW; tribe1 owns two. The plurality scan
      // skips tribe-owned provinces entirely, so gp3 is the blocker even
      // though it does not own the most invadable NW overall.
      final game = _gameWithNwProvinces(
        turnNumber: 110,
        nwProvinces: const [
          Province(id: 'newWorld|t1_a', regionId: 'newWorld', ownerId: _tribe1),
          Province(id: 'newWorld|t1_b', regionId: 'newWorld', ownerId: _tribe1),
          Province(id: 'newWorld|gp3_a', regionId: 'newWorld', ownerId: _gp3),
        ],
      );
      final snapshot = _colonialSnapshot(
        atWarWith: const [_gp2, _gp3],
        invadableNw: const ['newWorld|gp3_a', 'newWorld|t1_a', 'newWorld|t1_b'],
      );
      expect(
        primaryColonialGpBlocker(game: game, snapshot: snapshot),
        _gp3,
        reason:
            'Tribes do not register as GPs in the blocker scan, so a '
            'tribe-owned majority cannot shadow a single-province GP owner. '
            'A regression that counted tribe-owned invadable NW would '
            'falsely return null (since the inner `provinceOwner[pid] == '
            'owner` check would compare tribe owners) and silently disable '
            'colonial blocker preservation.',
      );
    });

    test('determinism: identical inputs produce identical blocker', () {
      // Must-have #7 (determinism) at the function-unit level.
      final game = _gameWithNwProvinces(
        turnNumber: 110,
        nwProvinces: const [
          Province(id: 'newWorld|gp2_a', regionId: 'newWorld', ownerId: _gp2),
          Province(id: 'newWorld|gp2_b', regionId: 'newWorld', ownerId: _gp2),
          Province(id: 'newWorld|gp3_a', regionId: 'newWorld', ownerId: _gp3),
        ],
      );
      final snapshot = _colonialSnapshot(
        atWarWith: const [_gp2, _gp3],
        invadableNw: const [
          'newWorld|gp2_a',
          'newWorld|gp2_b',
          'newWorld|gp3_a',
        ],
      );
      final first = primaryColonialGpBlocker(game: game, snapshot: snapshot);
      final second = primaryColonialGpBlocker(game: game, snapshot: snapshot);
      expect(second, first);
    });
  });

  group('colonialPhaseGpPeaceTargets guard branches', () {
    test('not in COLONIAL phase → empty (EXPAND fixture)', () {
      // OW = 7, well below quota → EXPAND.
      final game = _gameWithNwProvinces(
        turnNumber: 50,
        nwProvinces: const [
          Province(id: 'newWorld|gp2_a', regionId: 'newWorld', ownerId: _gp2),
        ],
      );
      const snapshot = AIWorldSnapshot(
        playerId: _gp1,
        threats: ThreatSummary(atWarWith: [_gp2, _gp3]),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(oldWorldProvincesOwned: 7),
        colonial: ColonialSummary(
          invadableNewWorldProvinceIdsSorted: ['newWorld|gp2_a'],
          adjacentNewWorldOwnerFactionIdsSorted: [_gp2],
        ),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        observerGoalPhaseFor(snapshot: snapshot, game: game),
        ObserverGoalPhase.expand,
        reason:
            'Fixture must place the GP in EXPAND so the COLONIAL peace '
            'helper\'s early return is the only branch under test.',
      );
      expect(
        colonialPhaseGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Outside COLONIAL the helper must return the empty list '
            'immediately — EXPAND and DEVELOP have their own peace-target '
            'helpers and their own SPEC rules.',
      );
    });

    test('empty gpWars → empty', () {
      // COLONIAL phase, but `atWarWith` empty.
      final game = _gameWithNwProvinces(
        turnNumber: 110,
        nwProvinces: const [
          Province(id: 'newWorld|gp2_a', regionId: 'newWorld', ownerId: _gp2),
        ],
      );
      final snapshot = _colonialSnapshot(
        atWarWith: const [],
        invadableNw: const ['newWorld|gp2_a'],
      );
      expect(
        observerGoalPhaseFor(snapshot: snapshot, game: game),
        ObserverGoalPhase.colonial,
        reason: 'Fixture must place GP in COLONIAL.',
      );
      expect(
        colonialPhaseGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Empty `gpWars` short-circuits the `length <= 1` guard. A '
            'regression that always returned the empty `gpWars` list would '
            'still pass this test, but a regression that crashed on empty '
            'input or returned an arbitrary stub would not.',
      );
    });

    test('single GP at war → empty (length <= 1 guard)', () {
      // SPEC: "when fighting two or more GPs". A one-GP war must keep the
      // front open for the regular war-pursuit path, not silently peace
      // it via the blocker-preservation rule.
      final game = _gameWithNwProvinces(
        turnNumber: 110,
        nwProvinces: const [
          Province(id: 'newWorld|gp2_a', regionId: 'newWorld', ownerId: _gp2),
        ],
      );
      final snapshot = _colonialSnapshot(
        atWarWith: const [_gp2],
        invadableNw: const ['newWorld|gp2_a'],
      );
      expect(
        observerGoalPhaseFor(snapshot: snapshot, game: game),
        ObserverGoalPhase.colonial,
      );
      expect(
        colonialPhaseGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'A single-GP war is below the SPEC two-or-more-GPs trigger. The '
            'blocker-preservation rule must not engage here; the lone front '
            'is kept open by returning the empty peace-target list.',
      );
    });

    test(
      'single GP at war which is the blocker → still empty (length guard)',
      () {
        // Confirms the order of guard checks: `gpWars.length <= 1` runs
        // before the blocker computation, so a single-GP war never reaches
        // the blocker-membership branch.
        final game = _gameWithNwProvinces(
          turnNumber: 110,
          nwProvinces: const [
            Province(id: 'newWorld|gp2_a', regionId: 'newWorld', ownerId: _gp2),
          ],
        );
        final snapshot = _colonialSnapshot(
          atWarWith: const [_gp2],
          invadableNw: const ['newWorld|gp2_a'],
        );
        expect(
          primaryColonialGpBlocker(game: game, snapshot: snapshot),
          _gp2,
          reason:
              'Sanity check: the blocker resolves to the only at-war GP. '
              'Despite that, the helper must still return empty due to the '
              '`gpWars.length <= 1` guard.',
        );
        expect(
          colonialPhaseGpPeaceTargets(game: game, snapshot: snapshot),
          isEmpty,
        );
      },
    );

    test('two GPs at war but no GP-owned blocker → empty', () {
      // 2 GPs at war, but all invadable NW are tribe-owned, so
      // `primaryColonialGpBlocker` is null. With no identifiable
      // colonial frontier blocker the preservation rule has no front to
      // keep, so the helper must return empty (rather than picking an
      // arbitrary non-blocker GP).
      final game = _gameWithNwProvinces(
        turnNumber: 110,
        nwProvinces: const [
          Province(id: 'newWorld|t1_a', regionId: 'newWorld', ownerId: _tribe1),
        ],
      );
      final snapshot = _colonialSnapshot(
        atWarWith: const [_gp2, _gp3],
        invadableNw: const ['newWorld|t1_a'],
        adjacentNw: const [_tribe1],
      );
      expect(
        observerGoalPhaseFor(snapshot: snapshot, game: game),
        ObserverGoalPhase.colonial,
      );
      expect(
        primaryColonialGpBlocker(game: game, snapshot: snapshot),
        isNull,
        reason:
            'Sanity check: only a tribe owns invadable NW, so no GP '
            'qualifies as the colonial blocker.',
      );
      expect(
        colonialPhaseGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Without a GP blocker the rule has no front to preserve. A '
            'regression that returned all `gpWars` as peace targets would '
            'silently peace both GPs and remove any pressure on rival '
            'colonial powers when the only acquisition target is tribal.',
      );
    });

    test('blocker exists but is not among gpWars → empty', () {
      // gp4 owns the invadable NW (blocker = gp4) but the GP is at war
      // with gp2 and gp3 only. The `!gpWars.contains(blocker)` guard
      // returns empty: there is no live blocker front to preserve, so
      // peacing the other GPs would still leave the colonial frontier
      // untouched and the rule abstains.
      final game = _gameWithNwProvinces(
        turnNumber: 110,
        nwProvinces: const [
          Province(id: 'newWorld|gp4_a', regionId: 'newWorld', ownerId: _gp4),
        ],
      );
      final snapshot = _colonialSnapshot(
        atWarWith: const [_gp2, _gp3],
        invadableNw: const ['newWorld|gp4_a'],
        adjacentNw: const [_gp4],
      );
      expect(
        observerGoalPhaseFor(snapshot: snapshot, game: game),
        ObserverGoalPhase.colonial,
      );
      expect(
        primaryColonialGpBlocker(game: game, snapshot: snapshot),
        _gp4,
        reason:
            'Sanity check: the only GP owning an invadable NW province is '
            'gp4, so it is the colonial blocker.',
      );
      expect(
        colonialPhaseGpPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'When the blocker is not actually at war with the planning GP, '
            'no peace is suggested by this helper — the SPEC rule '
            'preserves "Great Powers that do not own the primary colonial '
            'NW frontier blocker" only when that blocker is itself an '
            'active war front.',
      );
    });

    test('three GPs at war with one blocker → other two sorted ascending', () {
      // Pins the deterministic ordering for the multi-GP-at-war happy
      // path (extension of the existing single canonical 2-GP test).
      // gp2 is the blocker; gp3 and gp4 are non-blockers and must appear
      // in stable ascending factionId order.
      final game = _gameWithNwProvinces(
        turnNumber: 110,
        nwProvinces: const [
          Province(id: 'newWorld|gp2_a', regionId: 'newWorld', ownerId: _gp2),
        ],
      );
      final snapshot = _colonialSnapshot(
        // Provide war list out of sorted order to exercise the sort.
        atWarWith: const [_gp4, _gp2, _gp3],
        invadableNw: const ['newWorld|gp2_a'],
        adjacentNw: const [_gp2],
      );
      expect(
        observerGoalPhaseFor(snapshot: snapshot, game: game),
        ObserverGoalPhase.colonial,
      );
      expect(primaryColonialGpBlocker(game: game, snapshot: snapshot), _gp2);
      expect(
        colonialPhaseGpPeaceTargets(game: game, snapshot: snapshot),
        const [_gp3, _gp4],
        reason:
            'Non-blocker GPs must be returned in stable ascending '
            'factionId order so downstream order generation is '
            'deterministic for a fixed seed (Must-have #7).',
      );
    });
  });
}
