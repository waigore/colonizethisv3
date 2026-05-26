// Unit tests for the DEVELOP-phase planner contracts in
// `packages/colonizethis_ai/lib/src/planning/develop_phase_planner.dart`
// (Refs #2509 S4 / S10).
//
// Spec contract (issue #2509 § DEVELOP phase planner):
//   planDevelopPeace:
//     "Peace ALL at-war Great Powers. No exceptions.
//      (No new wars. No NW acquisition. Only defend + improve.)"
//   planDevelopCivilian:
//     "For each owned province (OW + NW), scan unimproved extractable
//      resource tiles ... Sort remaining by effective yield ...
//      Assign nearest idle Builder to highest-yield unimproved tile."
//
// Both planners are pure functions with deterministic inputs (Refs #2509
// Must-have #7). Suppression is structural: callers only dispatch to this
// module when [observerGoalPhaseFor] resolves to DEVELOP, so the
// functions do NOT re-check the phase. These tests pin the in-module
// contracts only.
//
// `planDevelopPeace` tests:
//   1. **Empty `atWarWith`:** no live wars -> empty list.
//   2. **Single GP at war:** one GP front -> one-element list (DEVELOP has
//      no `gpWars.length <= 1` early return — every GP front must peace).
//   3. **Multi-GP unsorted input:** trailing `..sort()` returns GP fronts
//      in ascending `factionId` order regardless of `atWarWith` order
//      (determinism contract, Must-have #7).
//   4. **Non-GP-only `atWarWith`:** tribes and minor nations are filtered
//      out via `game.playerById` (DEVELOP is GP-vs-GP peace only).
//   5. **Mixed GP + non-GP `atWarWith`:** non-GP ids are dropped before
//      the sort, leaving only GP ids in ascending order.
//   6. **Determinism:** identical inputs yield identical results across
//      repeated calls (Must-have #7).
//
// `planDevelopCivilian` tests:
//   1. **No owned provinces:** empty owner set -> empty list (structural
//      gate; ownership is the outermost filter).
//   2. **No idle Builders:** owned provinces with resource tiles but no
//      idle Builder units -> empty list.
//   3. **All tiles already improved:** unimproved-tile filter removes
//      `improvementLevel >= 1` tiles -> empty list.
//   4. **Town tile excluded:** tile keys matching the province's
//      `townTileKey` are filtered out even when a resource entry exists
//      (regression guard against future model changes).
//   5. **Foreign-owned tiles excluded:** resource tiles in another
//      player's province never appear in output.
//   6. **Tile sorted by priority:** mixed OW + NW unimproved resource
//      tiles return NW (higher score) before OW; lex tie-break is
//      ascending by tile key.
//   7. **Builder-to-tile pairing:** `min(builders, tiles)` cap; surplus
//      builders / tiles ignored; output ascending by builder id over
//      priority-sorted tiles.
//   8. **Working / non-Builder units skipped:** non-Builder civilians
//      and Builders with `status == working` are excluded.
//   9. **Determinism:** identical inputs yield identical orders across
//      repeated calls (Must-have #7).
//
// This file is the in-module pin for the DEVELOP planner. The S5
// orchestrator wiring through `phase_planner_dispatch.dart` /
// `domain_planner_orchestrator.dart` is in place, so this pin guards the
// canonical `planDevelopPeace` contract. The function-unit pin on the
// legacy `developPhaseGpPeaceTargets` helper in
// `observer_goal_phase_develop_peace_target_branches_test.dart` keeps the
// no-`phasePlan` fallback path through `collectStalledGreatPowerPeaceTargets`
// covered.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/develop_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gp1 = 'gp1';
const String _gp2 = 'gp2';
const String _gp3 = 'gp3';
const String _gp4 = 'gp4';
const String _tribe1 = 'tribe1';
const String _minor1 = 'minor1';

/// Game scaffold with a 4-GP roster. Tribes / minors are added only when a
/// test needs to exercise the non-GP filter via [Game.playerById].
Game _developGame({
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
    id: 'g-2509-develop-phase-planner-peace',
    worldState: WorldState(
      turnState: const TurnState(turnNumber: 140, phase: TurnPhase.orders),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: players,
    tribes: tribes,
    minorNations: minorNations,
  );
}

/// Minimal snapshot with the active player [_gp1] and a configurable
/// at-war roster. The phase-routing fields (`conquest`, `colonial`) are
/// left empty: the planner does not re-check phase, so these tests stay
/// scoped to the in-module peace contract.
AIWorldSnapshot _developSnapshot({required List<String> atWarWith}) {
  return AIWorldSnapshot(
    playerId: _gp1,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: const ConquestSummary(),
    colonial: const ColonialSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}

void main() {
  group('planDevelopPeace', () {
    test('empty atWarWith -> empty', () {
      final game = _developGame();
      final snapshot = _developSnapshot(atWarWith: const []);
      expect(
        planDevelopPeace(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'No live wars -> the loop body never runs and the sort on an '
            'empty list is a no-op. A regression that returned the '
            'at-peace GP roster here would emit spurious `offerPeace` '
            'orders toward neutral powers.',
      );
    });

    test('single GP at war -> [that GP]', () {
      // Unlike EXPAND / COLONIAL, DEVELOP has no `gpWars.length <= 1`
      // guard. A lone GP war must still be peaced so the orchestrator
      // can drive improvement-first civilian work in DEVELOP. A
      // regression that copied the EXPAND / COLONIAL length guard
      // would leave the lone GP front open and starve the turn-150
      // 70% extractable-tile improvement gate.
      final game = _developGame();
      final snapshot = _developSnapshot(atWarWith: const [_gp2]);
      expect(
        planDevelopPeace(game: game, snapshot: snapshot),
        const [_gp2],
        reason:
            'DEVELOP peace rule covers every at-war GP, including a '
            'single GP front.',
      );
    });

    test('three GPs at war (unsorted input) -> ascending sorted', () {
      // Pins the trailing `..sort()` contract (Must-have #7). Input
      // order is shuffled to `[gp3, gp4, gp2]` so a regression that
      // dropped the sort (or replaced it with input-order
      // preservation) would surface here.
      final game = _developGame();
      final snapshot = _developSnapshot(
        atWarWith: const [_gp3, _gp4, _gp2],
      );
      expect(
        planDevelopPeace(game: game, snapshot: snapshot),
        const [_gp2, _gp3, _gp4],
        reason:
            'All at-war GPs returned in ascending `factionId` order '
            'regardless of input order (Refs #2509 Must-have #7 '
            'determinism).',
      );
    });

    test('only tribes/minors in atWarWith -> empty', () {
      // The `game.playerById(factionId) != null` filter drops every
      // non-GP faction. DEVELOP is GP-vs-GP peace only: minor / tribe
      // wars are pursued through other diplomacy paths (war pursuit,
      // embassy chain, purchase_land). A regression that returned
      // tribe / minor ids here would emit `offerPeace` toward non-GP
      // factions and fail downstream order validation.
      final game = _developGame(
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = _developSnapshot(
        atWarWith: const [_tribe1, _minor1],
      );
      expect(
        planDevelopPeace(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Non-GP factions in `atWarWith` are filtered out via '
            '`game.playerById` returning null for non-player ids. With '
            'only non-GP wars present, the planner must return empty.',
      );
    });

    test('mixed GP + non-GP atWarWith -> only GPs, sorted', () {
      // Composes the filter and the sort: tribe / minor ids in
      // `atWarWith` must drop **before** the sort runs. Shuffled input
      // `[gp3, tribe1, gp2, minor1]` exercises both arms in one
      // fixture. A regression that left non-GP ids in the output list
      // would break downstream `offerPeace` validation.
      final game = _developGame(
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = _developSnapshot(
        atWarWith: const [_gp3, _tribe1, _gp2, _minor1],
      );
      expect(
        planDevelopPeace(game: game, snapshot: snapshot),
        const [_gp2, _gp3],
        reason:
            'Non-GP factions are filtered out before the sort, leaving '
            'GP fronts in ascending `factionId` order.',
      );
    });

    test('determinism: identical inputs produce identical lists', () {
      // Pins Must-have #7 (determinism) at the in-module level. The
      // mixed-input fixture exercises both the filter and the sort,
      // so repeating the call must yield the same list.
      final game = _developGame(
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = _developSnapshot(
        atWarWith: const [_gp3, _tribe1, _gp2, _minor1],
      );
      final first = planDevelopPeace(game: game, snapshot: snapshot);
      final second = planDevelopPeace(game: game, snapshot: snapshot);
      expect(second, first);
    });
  });

  group('planDevelopCivilian', () {
    // gp1 is the active player; other GPs are foreign owners used in the
    // ownership-exclusion test.
    const String owProv1 = 'oldWorld|p_alpha';
    const String owProv2 = 'oldWorld|p_beta';
    const String nwProv1 = 'newWorld|p_gamma';

    // Tile keys laid out as regionId|provinceId|x|y per
    // SPEC/game/world-model-identity.md. The province id is derived back
    // out via [Unit.provinceIdFromTileKey], so the keys must match the
    // owned-province ids byte-for-byte.
    const String owTileA = 'oldWorld|p_alpha|1|1';
    const String owTileB = 'oldWorld|p_alpha|2|2';
    const String owTileTown = 'oldWorld|p_alpha|0|0';
    const String owTileImproved = 'oldWorld|p_beta|1|1';
    const String nwTileA = 'newWorld|p_gamma|1|1';

    Game civilianGame({
      required List<Province> provinces,
      required List<Unit> owUnits,
      List<Unit> nwUnits = const [],
      Map<String, String> resourceByTileKey = const {},
      TileMapState tileState = const TileMapState(),
    }) {
      final byRegion = <String, List<Province>>{};
      for (final province in provinces) {
        byRegion
            .putIfAbsent(province.regionId, () => <Province>[])
            .add(province);
      }
      return Game(
        id: 'g-2509-develop-phase-planner-civilian',
        worldState: WorldState(
          turnState: const TurnState(turnNumber: 145, phase: TurnPhase.orders),
          oldWorld: RegionData(
            provinces: byRegion[kOldWorldRegionId] ?? const [],
            units: owUnits,
          ),
          newWorld: RegionData(
            provinces: byRegion[kNewWorldRegionId] ?? const [],
            units: nwUnits,
          ),
          resourceByTileKey: resourceByTileKey,
          tileState: tileState,
        ),
        players: const [
          Player(id: _gp1, displayName: 'GP1', isHuman: false),
          Player(id: _gp2, displayName: 'GP2', isHuman: false),
        ],
      );
    }

    AIWorldSnapshot civilianSnapshot() {
      return AIWorldSnapshot(
        playerId: _gp1,
        threats: const ThreatSummary(atWarWith: []),
        opportunities: const OpportunitySummary(),
        conquest: const ConquestSummary(),
        colonial: const ColonialSummary(),
        economy: const EconomySummary(),
        relations: const {},
      );
    }

    Unit idleBuilder(String id, {String regionId = kOldWorldRegionId}) {
      final provinceId = regionId == kOldWorldRegionId ? owProv1 : nwProv1;
      return Unit(
        id: id,
        type: kUnitTypeBuilder,
        ownerId: _gp1,
        locationProvinceId: provinceId,
        tileKey: '$provinceId|9|9',
      );
    }

    test('no owned provinces -> empty', () {
      // Active player has no owned provinces; ownership is the outermost
      // structural filter so the function must short-circuit before
      // scanning resource tiles or builders. A regression that scanned
      // tiles for unowned provinces would emit `build_improvement` orders
      // toward foreign territory and fail order validation.
      final game = civilianGame(
        provinces: const [
          Province(id: owProv1, regionId: kOldWorldRegionId, ownerId: _gp2),
        ],
        owUnits: [idleBuilder('b1')],
        resourceByTileKey: const {owTileA: 'grain'},
      );
      expect(
        planDevelopCivilian(game: game, snapshot: civilianSnapshot()),
        isEmpty,
        reason:
            'Active player owns zero provinces -> no eligible tiles; the '
            'ownership filter must short-circuit before resource scanning.',
      );
    });

    test('no idle builders -> empty', () {
      // Active player owns a province with an unimproved resource tile,
      // but no Builder units are present. A regression that emitted a
      // `build_improvement` order without a builder would fail unit
      // assignment validation downstream.
      final game = civilianGame(
        provinces: const [
          Province(id: owProv1, regionId: kOldWorldRegionId, ownerId: _gp1),
        ],
        owUnits: const [],
        resourceByTileKey: const {owTileA: 'grain'},
      );
      expect(
        planDevelopCivilian(game: game, snapshot: civilianSnapshot()),
        isEmpty,
        reason:
            'No idle Builders -> no orders. The function must skip its '
            'tile scan when builders are empty (early-exit contract).',
      );
    });

    test('all tiles already improved -> empty', () {
      // The `improvementLevel >= 1` gate must drop every tile that is
      // already at improvement level 1+. A regression that emitted
      // `build_improvement` toward an already-improved tile would waste
      // a Builder cycle and could re-trigger work that the resolver
      // rejects.
      final game = civilianGame(
        provinces: const [
          Province(id: owProv2, regionId: kOldWorldRegionId, ownerId: _gp1),
        ],
        owUnits: [idleBuilder('b1')],
        resourceByTileKey: const {owTileImproved: 'iron'},
        tileState: const TileMapState(
          improvementByTile: {owTileImproved: 1},
        ),
      );
      expect(
        planDevelopCivilian(game: game, snapshot: civilianSnapshot()),
        isEmpty,
        reason:
            'All eligible tiles already at improvementLevel >= 1; the '
            'planner must emit no orders.',
      );
    });

    test('town tile is excluded even with resource entry', () {
      // `townTileKey` exclusion pins the spec rule "Exclude capital
      // tiles and province town tiles (no resources)". Even when the
      // (synthetic) world state pairs a resource with a town tile, the
      // planner must skip it: relying on `resourceByTileKey` alone would
      // permit a regression that places a resource on a town tile and
      // emits an improvement order against the town.
      final game = civilianGame(
        provinces: const [
          Province(
            id: owProv1,
            regionId: kOldWorldRegionId,
            ownerId: _gp1,
            townTileKey: owTileTown,
          ),
        ],
        owUnits: [idleBuilder('b1')],
        resourceByTileKey: const {
          owTileTown: 'grain',
          owTileA: 'grain',
        },
      );
      final orders = planDevelopCivilian(
        game: game,
        snapshot: civilianSnapshot(),
      );
      expect(orders.map((o) => o.targetTileKey), const [owTileA]);
    });

    test('foreign-owned tiles excluded from output', () {
      // Province ownership is the structural gate: even when a foreign
      // province has a richer resource yield than an owned tile, the
      // planner must only emit orders for tiles inside owned provinces.
      // A regression that scanned `resourceByTileKey` without the
      // province-ownership filter would route the lone Builder onto a
      // foreign NW tile and lose the entire owned-OW improvement.
      const foreignNwTile = 'newWorld|p_foreign|5|5';
      final game = civilianGame(
        provinces: const [
          Province(id: owProv1, regionId: kOldWorldRegionId, ownerId: _gp1),
          Province(
            id: 'newWorld|p_foreign',
            regionId: kNewWorldRegionId,
            ownerId: _gp2,
          ),
        ],
        owUnits: [idleBuilder('b1')],
        resourceByTileKey: const {
          foreignNwTile: 'gold',
          owTileA: 'grain',
        },
      );
      final orders = planDevelopCivilian(
        game: game,
        snapshot: civilianSnapshot(),
      );
      expect(orders.map((o) => o.targetTileKey), const [owTileA]);
    });

    test('NW resource tile outranks OW tile (yield score)', () {
      // Score ordering pin (AC "build_improvement orders are generated
      // for the highest-yield unimproved tiles before lower-priority
      // work"). NW owned tile = base + NW bonus + owned-NW bonus; OW
      // tile = base alone. With two builders and one tile per region,
      // builder `b1` (sorted first) must target the NW tile.
      final game = civilianGame(
        provinces: const [
          Province(id: owProv1, regionId: kOldWorldRegionId, ownerId: _gp1),
          Province(id: nwProv1, regionId: kNewWorldRegionId, ownerId: _gp1),
        ],
        owUnits: [idleBuilder('b1'), idleBuilder('b2')],
        resourceByTileKey: const {owTileA: 'grain', nwTileA: 'tobacco'},
      );
      final orders = planDevelopCivilian(
        game: game,
        snapshot: civilianSnapshot(),
      );
      expect(orders.length, 2);
      expect(orders.first.targetTileKey, nwTileA);
      expect(orders.first.unitId, 'b1');
      expect(orders[1].targetTileKey, owTileA);
      expect(orders[1].unitId, 'b2');
      expect(
        orders.every((o) => o.target == kWorkTargetBuildImprovement),
        isTrue,
        reason: 'Every emitted order must target build_improvement.',
      );
    });

    test('same-score tiles tie-break ascending by tile key', () {
      // Same-region same-score tiles fall back to lex tile-key sort.
      // Builder `b1` (lex-first builder id) -> `owTileA` (lex-first
      // tile key). A regression that flipped the tie-break would break
      // determinism on multi-tile OW provinces.
      final game = civilianGame(
        provinces: const [
          Province(id: owProv1, regionId: kOldWorldRegionId, ownerId: _gp1),
        ],
        owUnits: [idleBuilder('b1'), idleBuilder('b2')],
        resourceByTileKey: const {owTileA: 'grain', owTileB: 'iron'},
      );
      final orders = planDevelopCivilian(
        game: game,
        snapshot: civilianSnapshot(),
      );
      expect(orders.length, 2);
      expect(orders[0].unitId, 'b1');
      expect(orders[0].targetTileKey, owTileA);
      expect(orders[1].unitId, 'b2');
      expect(orders[1].targetTileKey, owTileB);
    });

    test('builder count caps emitted orders below tile count', () {
      // `min(builders, tiles)` cap: two tiles available, one builder ->
      // exactly one order targeting the higher-priority NW tile. The
      // surplus OW tile is left unimproved this turn (acceptable; the
      // remaining builder slot will fill on a subsequent turn).
      final game = civilianGame(
        provinces: const [
          Province(id: owProv1, regionId: kOldWorldRegionId, ownerId: _gp1),
          Province(id: nwProv1, regionId: kNewWorldRegionId, ownerId: _gp1),
        ],
        owUnits: [idleBuilder('b1')],
        resourceByTileKey: const {owTileA: 'grain', nwTileA: 'spices'},
      );
      final orders = planDevelopCivilian(
        game: game,
        snapshot: civilianSnapshot(),
      );
      expect(orders.length, 1);
      expect(orders.single.targetTileKey, nwTileA);
      expect(orders.single.unitId, 'b1');
    });

    test('tile count caps emitted orders below builder count', () {
      // Reverse cap: two builders, one tile -> exactly one order
      // bound to `b1` (lex-first builder id). The surplus builder
      // remains idle (no fabricated order, no duplicate targeting).
      final game = civilianGame(
        provinces: const [
          Province(id: owProv1, regionId: kOldWorldRegionId, ownerId: _gp1),
        ],
        owUnits: [idleBuilder('b1'), idleBuilder('b2')],
        resourceByTileKey: const {owTileA: 'grain'},
      );
      final orders = planDevelopCivilian(
        game: game,
        snapshot: civilianSnapshot(),
      );
      expect(orders.length, 1);
      expect(orders.single.unitId, 'b1');
      expect(orders.single.targetTileKey, owTileA);
    });

    test('working builders and non-Builder units excluded', () {
      // Only `status == idle` Builder units count. Working Builders
      // and idle non-Builder civilians (e.g. Farmer-like worker
      // placeholders typed as `'Farmer'`) must be skipped.
      final game = civilianGame(
        provinces: const [
          Province(id: owProv1, regionId: kOldWorldRegionId, ownerId: _gp1),
        ],
        owUnits: [
          Unit(
            id: 'b_busy',
            type: kUnitTypeBuilder,
            ownerId: _gp1,
            locationProvinceId: owProv1,
            tileKey: '$owProv1|9|9',
            status: UnitStatus.working,
          ),
          Unit(
            id: 'farmer1',
            type: 'Farmer',
            ownerId: _gp1,
            locationProvinceId: owProv1,
            tileKey: '$owProv1|8|8',
          ),
        ],
        resourceByTileKey: const {owTileA: 'grain'},
      );
      expect(
        planDevelopCivilian(game: game, snapshot: civilianSnapshot()),
        isEmpty,
        reason:
            'Working builders + non-Builder civilians are both filtered '
            'out; with no idle Builder present the planner returns empty.',
      );
    });

    test('determinism: identical inputs yield identical orders', () {
      // Mixed-region scenario exercises ownership, town exclusion,
      // improvement-level filter, score ordering, builder sort, and
      // the min cap in one fixture. Two calls must produce the same
      // list (Must-have #7).
      final game = civilianGame(
        provinces: const [
          Province(
            id: owProv1,
            regionId: kOldWorldRegionId,
            ownerId: _gp1,
            townTileKey: owTileTown,
          ),
          Province(id: nwProv1, regionId: kNewWorldRegionId, ownerId: _gp1),
        ],
        owUnits: [idleBuilder('b2'), idleBuilder('b1')],
        nwUnits: [idleBuilder('b3', regionId: kNewWorldRegionId)],
        resourceByTileKey: const {
          owTileA: 'grain',
          owTileB: 'iron',
          owTileTown: 'grain',
          nwTileA: 'spices',
        },
      );
      final first =
          planDevelopCivilian(game: game, snapshot: civilianSnapshot());
      final second =
          planDevelopCivilian(game: game, snapshot: civilianSnapshot());
      expect(
        first.map((o) => '${o.unitId}->${o.targetTileKey}').toList(),
        const ['b1->newWorld|p_gamma|1|1', 'b2->oldWorld|p_alpha|1|1', 'b3->oldWorld|p_alpha|2|2'],
        reason:
            'NW tile ranks first (highest score), then OW tiles in lex '
            'order; builder ids assigned ascending; town tile excluded.',
      );
      expect(second, first);
    });
  });
}
