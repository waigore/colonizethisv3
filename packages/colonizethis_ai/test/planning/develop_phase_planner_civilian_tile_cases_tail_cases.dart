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


void registerDevelopPhasePlannerCivilianTileCasesTail() {
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

    test('NW resource tile outranks OW tile (yield score)', () {
      // Score ordering pin (AC "build_improvement orders are generated
      // for the highest-yield unimproved tiles before lower-priority
      // work"). NW owned tile = base + NW bonus + owned-NW bonus; OW
      // tile = base alone. Distance-aware + same-region pairing (Refs
      // #2848 § S2): the NW tile must be paired with an NW Builder;
      // the OW tile with an OW Builder. `b1` sits in OW and is paired
      // against the lower-priority OW tile (no cross-region naval
      // transport in DEVELOP), while `b2` placed in NW takes the
      // higher-priority NW tile.
      final game = civilianGame(
        provinces: const [
          Province(id: owProv1, regionId: kOldWorldRegionId, ownerId: kDevelopPhaseGp1),
          Province(id: nwProv1, regionId: kNewWorldRegionId, ownerId: kDevelopPhaseGp1),
        ],
        owUnits: [idleBuilder('b1')],
        nwUnits: [idleBuilder('b2', regionId: kNewWorldRegionId)],
        resourceByTileKey: const {owTileA: 'grain', nwTileA: 'tobacco'},
      );
      final orders = planDevelopCivilian(
        game: game,
        snapshot: civilianSnapshot(),
      );
      expect(orders.length, 2);
      expect(orders.first.targetTileKey, nwTileA);
      expect(orders.first.unitId, 'b2');
      expect(orders[1].targetTileKey, owTileA);
      expect(orders[1].unitId, 'b1');
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
          Province(id: owProv1, regionId: kOldWorldRegionId, ownerId: kDevelopPhaseGp1),
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
      // `min(builders, tiles)` cap combined with same-region pairing
      // (Refs #2848 § S2): the NW tile carries the higher priority
      // score but the only Builder lives in OW, so distance-aware +
      // same-region selection skips the NW tile and pairs `b1` with
      // the in-region OW tile instead. The surplus NW tile is left
      // unimproved this turn (no naval Builder transport modeled).
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
      expect(orders.length, 1);
      expect(orders.single.targetTileKey, owTileA);
      expect(orders.single.unitId, 'b1');
    });

    test('tile count caps emitted orders below builder count', () {
      // Reverse cap: two builders, one tile -> exactly one order
      // bound to `b1` (lex-first builder id). The surplus builder
      // remains idle (no fabricated order, no duplicate targeting).
      final game = civilianGame(
        provinces: const [
          Province(id: owProv1, regionId: kOldWorldRegionId, ownerId: kDevelopPhaseGp1),
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
          Province(id: owProv1, regionId: kOldWorldRegionId, ownerId: kDevelopPhaseGp1),
        ],
        owUnits: [
          Unit(
            id: 'b_busy',
            type: kUnitTypeBuilder,
            ownerId: kDevelopPhaseGp1,
            locationProvinceId: owProv1,
            tileKey: '$owProv1|9|9',
            status: UnitStatus.working,
          ),
          Unit(
            id: 'farmer1',
            type: 'Farmer',
            ownerId: kDevelopPhaseGp1,
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

  });
}
