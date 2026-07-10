// Table-driven OrderEngine validateWork scenarios (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../scenario_runner.dart';
import 'order_engine_purchase_land_test_support.dart';
import 'order_engine_validate_work_expectation_shorthand.dart';
import 'order_engine_validate_work_fixtures.dart';

/// One row in [orderEngineValidateWorkScenarios].
class OrderEngineValidateWorkScenario implements RefsScenario {
  const OrderEngineValidateWorkScenario({
    required this.label,
    required this.run,
    this.refs,
  });

  @override
  final String label;
  final void Function() run;
  @override
  final String? refs;
}

void runOrderEngineValidateWorkScenario(
  OrderEngineValidateWorkScenario scenario,
) {
  scenario.run();
}

/// Canonical scenarios for order_engine_validate_work family tests.
List<OrderEngineValidateWorkScenario> orderEngineValidateWorkScenarios() => [
  // dart format off
  OrderEngineValidateWorkScenario(
    label: 'rejects second pending work order for same unit in one turn',
    run: () {
      const tileA = ValidateWorkOw.tileKey;
      const tileB = '${ValidateWorkOw.provinceId}|1|0';
      vwExpectDualWorkOrders(
        game: dualTilePendingWorkGame(),
        first: const WorkOrder(
          unitId: 'builder1',
          target: kWorkTargetBuildImprovement,
          targetTileKey: tileA,
        ),
        second: const WorkOrder(
          unitId: 'builder1',
          target: kWorkTargetBuildImprovement,
          targetTileKey: tileB,
        ),
        statuses: const [
          OrderValidationStatus.accepted,
          OrderValidationStatus.rejected,
        ],
        lastReasonContains: 'Only one work order per unit is allowed each turn',
      );
    },
  ),
  OrderEngineValidateWorkScenario(
    label: 'rejects purchase_land when no embassy with Minor',
    run: () => vwExpectPurchaseLandRejected(
      overtureStates: null,
      reasonContains: 'embassy',
    ),
  ),
  OrderEngineValidateWorkScenario(
    label: 'rejects purchase_land when at war with faction',
    run: () => vwExpectPurchaseLandRejected(
      diplomacyRelations: const [
        DiplomacyRelation(
          factionId1: 'p1',
          factionId2: 'minor1',
          state: RelationState.atWar,
        ),
      ],
      reasonContains: 'war',
    ),
  ),
  OrderEngineValidateWorkScenario(
    label: 'rejects purchase_land when insufficient treasury',
    run: () => vwExpectPurchaseLandRejected(
      treasury: 15 * 10 - 1,
      reasonContains: 'Insufficient treasury',
    ),
  ),
  OrderEngineValidateWorkScenario(
    label: 'rejects purchase_land when tile has no resource',
    run: () => vwExpectPurchaseLandRejected(
      resourceByTileKey: {},
      reasonContains: 'no resource',
    ),
  ),
  OrderEngineValidateWorkScenario(
    label: 'rejects purchase_land when mineral tile not prospected',
    run: () => vwExpectPurchaseLandMineral(prospected: false),
  ),
  OrderEngineValidateWorkScenario(
    label: 'accepts purchase_land with embassy, at peace, sufficient treasury, tile with resource',
    run: vwExpectPurchaseLandAccepted,
  ),
  OrderEngineValidateWorkScenario(
    label: 'rejects second Builder/Engineer/Merchant work order on same tile for same player (per-tile exclusivity)',
    run: () {
      const exclusivityTileKey = ValidateWorkOw.tileKey;
      vwExpectDualWorkOrders(
        game: builderEngineerSameTileExclusivityGame(),
        first: const WorkOrder(
          unitId: 'builder1',
          target: kWorkTargetBuildImprovement,
          targetTileKey: exclusivityTileKey,
        ),
        second: const WorkOrder(
          unitId: 'engineer1',
          target: kWorkTargetBuildRoad,
          targetTileKey: exclusivityTileKey,
        ),
        statuses: const [
          OrderValidationStatus.accepted,
          OrderValidationStatus.rejected,
        ],
        lastReasonContains: 'Tile already has development or purchase work',
      );
    },
  ),
  OrderEngineValidateWorkScenario(
    label: 'accepts purchase_land for mineral when prospected',
    run: () => vwExpectPurchaseLandMineral(prospected: true),
  ),
  OrderEngineValidateWorkScenario(
    label: 'rejects purchase_land when tile already purchased by another GP',
    run: () => vwExpectPurchaseLandRejected(
      purchasedTilesByTileKey: {PurchaseLandTestFixture.tileKey: 'p2'},
      reasonContains: 'Tile already purchased by another power',
    ),
  ),
  OrderEngineValidateWorkScenario(
    label: 'rejects purchase_land when tile already owned by same player',
    run: () => vwExpectPurchaseLandRejected(
      purchasedTilesByTileKey: {PurchaseLandTestFixture.tileKey: 'p1'},
      reasonContains: 'You already own this tile',
    ),
  ),
  OrderEngineValidateWorkScenario(
    label: 'rejects build_improvement on mineral tile when not prospected',
    run: () => vwExpectBuildImprovementMineral(prospected: false),
  ),
  OrderEngineValidateWorkScenario(
    label: 'accepts build_improvement on mineral tile after prospected',
    run: () => vwExpectBuildImprovementMineral(prospected: true),
  ),
  OrderEngineValidateWorkScenario(
    label: 'accepts build_improvement on grain when tile not prospected',
    run: () => vwExpectBuildImprovementOutcome(
      game: buildImprovementBaseGame(
        resourceByTileKey: {ValidateWorkOw.tileKey: 'grain'},
      ),
      accepted: true,
    ),
  ),
  OrderEngineValidateWorkScenario(
    label: 'rejects build_improvement when tile has no resource',
    run: () => vwExpectBuildImprovementOutcome(
      game: buildImprovementBaseGame(resourceByTileKey: {}),
      accepted: false,
      reasonContains: 'no resource',
    ),
  ),
  OrderEngineValidateWorkScenario(
    label: 'rejects build_improvement when improvement level already 4',
    run: () => vwExpectBuildImprovementOutcome(
      game: buildImprovementBaseGame(
        tileState: const TileMapState(improvementByTile: {'oldWorld|P1|0|0': 4}),
        stockpile: lumberCastIronStockpile(20),
      ),
      accepted: false,
      reasonContains: 'maximum',
    ),
  ),
  OrderEngineValidateWorkScenario(
    label: 'rejects build_improvement when tech cap would be exceeded (empty tech)',
    run: () => vwExpectBuildImprovementOutcome(
      game: buildImprovementBaseGame(
        techUnlocked: const {},
        tileState: const TileMapState(improvementByTile: {'oldWorld|P1|0|0': 1}),
        stockpile: lumberCastIronStockpile(10),
      ),
      accepted: false,
      reasonContains: 'Insufficient tech',
      onRejected: (result) {
        expect(result.reason, contains('grain'));
        expect(result.reason, contains('cap 1'));
      },
    ),
  ),
  OrderEngineValidateWorkScenario(
    label: 'rejects build_improvement when tech cap would be exceeded',
    run: () => vwExpectBuildImprovementOutcome(
      game: buildImprovementBaseGame(
        techUnlocked: const {kTechIdSawMill: true},
        tileState: const TileMapState(improvementByTile: {'oldWorld|P1|0|0': 1}),
        stockpile: lumberCastIronStockpile(10),
      ),
      accepted: false,
      reasonContains: 'Insufficient tech',
    ),
  ),
  OrderEngineValidateWorkScenario(
    label: 'accepts grain upgrade when exact next-level grain tech is unlocked',
    run: () => vwExpectBuildImprovementOutcome(
      game: buildImprovementBaseGame(
        techUnlocked: const {kTechIdLandEnclosure: true},
        tileState: const TileMapState(improvementByTile: {'oldWorld|P1|0|0': 1}),
        stockpile: lumberCastIronStockpile(10),
      ),
      accepted: true,
    ),
  ),
  OrderEngineValidateWorkScenario(
    label: 'accepts build_improvement when tile has resource, level < 4, tech cap allows',
    run: () => vwExpectBuildImprovementOutcome(
      game: buildImprovementBaseGame(
        resourceByTileKey: {ValidateWorkOw.tileKey: 'grain'},
        tileState: const TileMapState(),
        techUnlocked: const {kTechIdCircularSaw: true},
      ),
      accepted: true,
    ),
  ),
  OrderEngineValidateWorkScenario(
    label: 'rejects build_improvement in foreign, unpurchased province',
    run: () => vwExpectBuildImprovementOutcome(
      game: buildImprovementForeignProvinceGame(),
      targetTileKey: validateWorkForeignTileKey(),
      accepted: false,
      reasonContains: 'foreign or uncontrolled province',
    ),
  ),
  OrderEngineValidateWorkScenario(
    label: 'rejects raising scrub timber from level 1 even with circular_saw',
    run: () => vwExpectBuildImprovementOutcome(
      game: scrubCapBaseGame(level: 1),
      tileMapByRegion: scrubCapTileMaps(TerrainType.scrubForest),
      accepted: false,
      reasonContains: 'Terrain caps',
      onRejected: (result) => expect(result.reason, contains('level 1')),
    ),
  ),
  OrderEngineValidateWorkScenario(
    label: 'accepts raising hardwood timber from level 1 with circular_saw',
    run: () => vwExpectBuildImprovementOutcome(
      game: scrubCapBaseGame(level: 1),
      tileMapByRegion: scrubCapTileMaps(TerrainType.hardwoodForest),
      accepted: true,
    ),
  ),
  OrderEngineValidateWorkScenario(
    label: 'accepts initial scrub timber improvement (level 0 -> 1)',
    run: () => vwExpectBuildImprovementOutcome(
      game: scrubCapBaseGame(level: 0),
      tileMapByRegion: scrubCapTileMaps(TerrainType.scrubForest),
      accepted: true,
    ),
  ),
  OrderEngineValidateWorkScenario(
    label: 'accepts build_improvement on purchased tile in foreign province',
    run: () {
      final foreignTileKey = validateWorkForeignTileKey();
      vwExpectBuildImprovementOutcome(
        game: buildImprovementForeignProvinceGame(
          purchasedTilesByTileKey: {foreignTileKey: 'p1'},
        ),
        targetTileKey: foreignTileKey,
        accepted: true,
      );
    },
  ),
  OrderEngineValidateWorkScenario(
    label: 'rejects build_fort to level 2 without Mine Engineering',
    run: () => vwExpectFortBuildRejected(
      fortLevel: 1,
      stockpile: Stockpile()
          .applyDelta(CommodityCatalog.lumber.id, 4)
          .applyDelta(CommodityCatalog.bronze.id, 4),
      reasonContains: 'Mine Engineering',
    ),
  ),
  OrderEngineValidateWorkScenario(
    label: 'rejects build_fort to level 3 without Modern Forts',
    run: () => vwExpectFortBuildRejected(
      fortLevel: 2,
      stockpile: Stockpile()
          .applyDelta(CommodityCatalog.steel.id, 5)
          .applyDelta(CommodityCatalog.lumber.id, 5),
      techUnlocked: const {kTechIdMineEngineering: true},
      reasonContains: 'Modern Forts',
    ),
  ),
  OrderEngineValidateWorkScenario(
    label: 'rejects build_rail when tile terrain data is missing',
    run: () => vwExpectRailBuildOutcome(
      tileState: TileMapState().setRoadLevel(ValidateWorkOw.tileKey, 1),
      tileMapByRegion: const {},
      accepted: false,
      reasonContains: 'terrain data required',
    ),
  ),
  OrderEngineValidateWorkScenario(
    label: 'rejects build_rail when road level is 0',
    run: () => vwExpectRailBuildOutcome(
      tileState: TileMapState().setRoadLevel(ValidateWorkOw.tileKey, 0),
      tileMapByRegion: {ValidateWorkOw.ow: railTileMap(TerrainType.plains)},
      accepted: false,
      reasonContains: 'existing road',
    ),
  ),
  OrderEngineValidateWorkScenario(
    label: 'rejects build_rail on hills with only Early Steam',
    run: () => vwExpectRailBuildOutcome(
      tileState: TileMapState().setRoadLevel(ValidateWorkOw.tileKey, 1),
      techUnlocked: const {kTechIdEarlySteamEngine: true},
      tileMapByRegion: {ValidateWorkOw.ow: railTileMap(TerrainType.hills)},
      accepted: false,
      reasonContains: 'Later Steam',
    ),
  ),
  OrderEngineValidateWorkScenario(
    label: 'accepts build_rail on plains with Early Steam and road 1',
    run: () => vwExpectRailBuildOutcome(
      tileState: TileMapState().setRoadLevel(ValidateWorkOw.tileKey, 1),
      tileMapByRegion: {ValidateWorkOw.ow: railTileMap(TerrainType.plains)},
      accepted: true,
    ),
  ),
  OrderEngineValidateWorkScenario(
    label: 'rejects build_road in minor province without embassy path',
    run: () => vwExpectRejectMinorProvinceRoad(
      game: minorProvinceEngineerRoadGame(),
      reasonContains: 'foreign province',
    ),
  ),
  OrderEngineValidateWorkScenario(
    label: 'rejects build_road in minor province even with embassy when occupancy disallows tile',
    run: () => vwExpectRejectMinorProvinceRoad(
      game: minorProvinceEngineerRoadGame(
        overtureStates: minorProvinceEmbassyOverture,
      ),
      reasonContains: 'cannot occupy',
    ),
  ),
  OrderEngineValidateWorkScenario(
    label: 'rejects upgrade_town without National Bureaucracy',
    run: () => vwExpectUpgradeTownOutcome(accepted: false, techUnlocked: const {}),
  ),
  OrderEngineValidateWorkScenario(
    label: 'accepts upgrade_town when National Bureaucracy unlocked',
    run: () => vwExpectUpgradeTownOutcome(
      accepted: true,
      techUnlocked: const {kTechIdNationalBureaucracy: true},
    ),
  ),
  // dart format on
];
