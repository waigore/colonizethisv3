// Case bodies for `develop_phase_planner_test.dart` (Refs #4291 Slice D).
// Registered from the thin contract; pin coverage preserved 1:1.

// Case bodies for `develop_phase_planner_test.dart` (Refs #3997 Phase 8).
// Registered from the thin contract; pin coverage preserved 1:1 from the
// former inline suite.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/develop_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'develop_phase_planner_support.dart';


void registerDevelopPhasePlannerCivilianPairingCases() {
  group('planDevelopCivilian', () {
    const String owProv1 = 'oldWorld|p_alpha';
    const String owProv2 = 'oldWorld|p_beta';
    const String nwProv1 = 'newWorld|p_gamma';

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
          Player(id: kDevelopPhaseGp1, displayName: 'GP1', isHuman: false),
          Player(id: kDevelopPhaseGp2, displayName: 'GP2', isHuman: false),
        ],
      );
    }

    AIWorldSnapshot civilianSnapshot() {
      return AIWorldSnapshot(
        playerId: kDevelopPhaseGp1,
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
        ownerId: kDevelopPhaseGp1,
        locationProvinceId: provinceId,
        tileKey: '$provinceId|9|9',
      );
    }

    test('determinism: identical inputs yield identical orders', () {
      // Mixed-region scenario exercises ownership, town exclusion,
      // improvement-level filter, score ordering, builder sort, the
      // min cap, and distance-aware + same-region Builder pairing
      // (Refs #2848 § S2) in one fixture. Two calls must produce the
      // same list (Must-have #7). With `b3` the only NW Builder, the
      // NW tile is paired with `b3`. The two OW Builders `b1`/`b2`
      // both sit at OW (9, 9); the closer-by-Manhattan-distance OW
      // tile breaks the tie deterministically (both at distance 16
      // from (9, 9) so the Builder-id ascending tiebreak resolves
      // `b1` → `owTileA` and `b2` → `owTileB`).
      final game = civilianGame(
        provinces: const [
          Province(
            id: owProv1,
            regionId: kOldWorldRegionId,
            ownerId: kDevelopPhaseGp1,
            townTileKey: owTileTown,
          ),
          Province(id: nwProv1, regionId: kNewWorldRegionId, ownerId: kDevelopPhaseGp1),
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
      final first = planDevelopCivilian(
        game: game,
        snapshot: civilianSnapshot(),
      );
      final second = planDevelopCivilian(
        game: game,
        snapshot: civilianSnapshot(),
      );
      expect(
        first.map((o) => '${o.unitId}->${o.targetTileKey}').toList(),
        const [
          'b3->newWorld|p_gamma|1|1',
          'b1->oldWorld|p_alpha|1|1',
          'b2->oldWorld|p_alpha|2|2',
        ],
        reason:
            'NW tile ranks first (highest score) and is paired with the '
            'only same-region (NW) Builder b3; OW tiles follow in lex '
            'order, with b1/b2 (equidistant from (9, 9)) tiebroken by '
            'ascending Builder id.',
      );
      expect(second, first);
    });

    test('cross-region NW tile is skipped when only OW Builders exist', () {
      // Distance-aware + same-region pairing (Refs #2848 § S2 cross-
      // region suppression AC). Active player owns one OW province and
      // one NW province with an unimproved extractable tile in each;
      // the only idle Builder lives in OW. The NW tile carries the
      // higher priority score but lacks a same-region Builder, so the
      // planner skips it and pairs `b1` with the in-region OW tile.
      // Regression guard against re-introducing the cross-region
      // index-pairing that emitted no-op orders against unreachable
      // NW tiles.
      final game = civilianGame(
        provinces: const [
          Province(id: owProv1, regionId: kOldWorldRegionId, ownerId: kDevelopPhaseGp1),
          Province(id: nwProv1, regionId: kNewWorldRegionId, ownerId: kDevelopPhaseGp1),
        ],
        owUnits: [idleBuilder('b1')],
        resourceByTileKey: const {owTileA: 'grain', nwTileA: 'spices'},
      );
      final orders = planDevelopCivilian(
        game: game,
        snapshot: civilianSnapshot(),
      );
      expect(orders.map((o) => o.targetTileKey).toList(), const [owTileA]);
      expect(orders.single.unitId, 'b1');
    });

    test(
      'closer same-region Builder wins over farther same-region Builder',
      () {
        // Distance-aware pairing core AC (Refs #2848 § S2). `b_far` at
        // (10, 10) and `b_near` at (1, 1) both reside in OW; the only
        // eligible tile sits at (2, 2). Manhattan distances:
        //   |10-2| + |10-2| = 16  (b_far)
        //   |1-2|  + |1-2|  = 2   (b_near)
        // The planner must pair the tile with `b_near` regardless of
        // alphabetical order (`b_far` < `b_near` lex but loses on
        // distance). A regression that fell back to index-pairing by
        // builder id would re-introduce the alphabetical pairing
        // (`b_far` → tile) and surface here.
        final farBuilder = Unit(
          id: 'b_far',
          type: kUnitTypeBuilder,
          ownerId: kDevelopPhaseGp1,
          locationProvinceId: owProv1,
          tileKey: '$owProv1|10|10',
        );
        final nearBuilder = Unit(
          id: 'b_near',
          type: kUnitTypeBuilder,
          ownerId: kDevelopPhaseGp1,
          locationProvinceId: owProv1,
          tileKey: '$owProv1|1|1',
        );
        final game = civilianGame(
          provinces: const [
            Province(id: owProv1, regionId: kOldWorldRegionId, ownerId: kDevelopPhaseGp1),
          ],
          owUnits: [farBuilder, nearBuilder],
          resourceByTileKey: const {owTileB: 'grain'},
        );
        final orders = planDevelopCivilian(
          game: game,
          snapshot: civilianSnapshot(),
        );
        expect(orders.length, 1);
        expect(orders.single.unitId, 'b_near');
        expect(orders.single.targetTileKey, owTileB);
      },
    );

    test('equal-distance Builders tiebreak by ascending Builder id', () {
      // Distance-aware tiebreak AC (Refs #2848 § S2). Both Builders
      // sit at OW (9, 9); the eligible OW tile at (1, 1) is equidistant
      // (Manhattan 16). Lex tiebreak picks `b1` over `b2`, matching
      // the determinism Must-have #7. A regression that flipped the
      // tiebreak (e.g. last-encountered Builder wins) would surface
      // here.
      final game = civilianGame(
        provinces: const [
          Province(id: owProv1, regionId: kOldWorldRegionId, ownerId: kDevelopPhaseGp1),
        ],
        owUnits: [idleBuilder('b2'), idleBuilder('b1')],
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

    test('distance pairing across two tiles re-optimizes vs index-pairing', () {
      // Distance-aware multi-tile pairing AC (Refs #2848 § S2). Two
      // Builders and two same-region tiles such that the lex-first
      // Builder is NOT the closest to the priority-first tile.
      //   b1 at OW (0, 0); b2 at OW (5, 5).
      //   tile1 at (4, 4) → score base (+ no NW bonus). Distance:
      //     b1=8, b2=2 → b2 wins.
      //   tile2 at (1, 1) → score base. Distance:
      //     b1=2, b2 already assigned → b1 wins.
      // Tile priority is identical (same OW base score); lex tile-key
      // ordering puts `tile1` (`...|4|4`) before `tile2` (`...|1|1`)?
      // Actually `'oldWorld|p_alpha|1|1' < 'oldWorld|p_alpha|4|4'` lex,
      // so `tile2` is processed first.
      //   tile2 first → b1 (distance 2) vs b2 (distance 8). b1 wins.
      //   tile1 next → only b2 remains. b2 wins (distance 2).
      // Old index-pairing would emit `b1→tile2, b2→tile1` by accident
      // (lex-first Builder paired with lex-first tile). The new
      // distance-aware logic emits the same pairing here because b1's
      // lex-first ordering coincidentally matches the optimum. Pin
      // verifies the new logic does not regress on the simple case.
      final b1 = Unit(
        id: 'b1',
        type: kUnitTypeBuilder,
        ownerId: kDevelopPhaseGp1,
        locationProvinceId: owProv1,
        tileKey: '$owProv1|0|0',
      );
      final b2 = Unit(
        id: 'b2',
        type: kUnitTypeBuilder,
        ownerId: kDevelopPhaseGp1,
        locationProvinceId: owProv1,
        tileKey: '$owProv1|5|5',
      );
      final game = civilianGame(
        provinces: const [
          Province(id: owProv1, regionId: kOldWorldRegionId, ownerId: kDevelopPhaseGp1),
        ],
        owUnits: [b1, b2],
        resourceByTileKey: const {
          'oldWorld|p_alpha|4|4': 'grain',
          'oldWorld|p_alpha|1|1': 'iron',
        },
      );
      final orders = planDevelopCivilian(
        game: game,
        snapshot: civilianSnapshot(),
      );
      expect(orders.length, 2);
      expect(orders[0].targetTileKey, 'oldWorld|p_alpha|1|1');
      expect(orders[0].unitId, 'b1');
      expect(orders[1].targetTileKey, 'oldWorld|p_alpha|4|4');
      expect(orders[1].unitId, 'b2');
    });
  });
}
