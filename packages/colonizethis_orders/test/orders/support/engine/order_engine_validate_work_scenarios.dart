// Table-driven OrderEngine validateWork scenarios (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../scenario_runner.dart';
import 'order_engine_purchase_land_test_support.dart';
import 'order_engine_validate_work_expectation_shorthand.dart';
import 'order_engine_validate_work_fixtures.dart';

/// Canonical scenarios for order_engine_validate_work family tests.
List<RunnableScenario> orderEngineValidateWorkScenarios() => [
  // dart format off
  rs('rejects second pending work order for same unit in one turn',() { const tileA = ValidateWorkOw.tileKey; const tileB = '${ValidateWorkOw.provinceId}|1|0'; vwExpectDualWorkOrders(game: dualTilePendingWorkGame(),first: const WorkOrder(unitId: 'builder1',target: kWorkTargetBuildImprovement,targetTileKey: tileA),second: const WorkOrder(unitId: 'builder1',target: kWorkTargetBuildImprovement,targetTileKey: tileB),statuses: const [OrderValidationStatus.accepted,OrderValidationStatus.rejected,],lastReasonContains: 'Only one work order per unit is allowed each turn'); },),
  rs('rejects purchase_land when no embassy with Minor', () => vwExpectPurchaseLandRejected(overtureStates: null, reasonContains: 'embassy')),
  rs('rejects purchase_land when at war with faction',() => vwExpectPurchaseLandRejected(diplomacyRelations: const [DiplomacyRelation(factionId1: 'p1',factionId2: 'minor1',state: RelationState.atWar),],reasonContains: 'war'),),
  rs('rejects purchase_land when insufficient treasury', () => vwExpectPurchaseLandRejected(treasury: 15 * 10 - 1, reasonContains: 'Insufficient treasury')),
  rs('rejects purchase_land when tile has no resource', () => vwExpectPurchaseLandRejected(resourceByTileKey: {}, reasonContains: 'no resource')),
  rs('rejects purchase_land when mineral tile not prospected', () => vwExpectPurchaseLandMineral(prospected: false)),
  rs('accepts purchase_land with embassy, at peace, sufficient treasury, tile with resource', vwExpectPurchaseLandAccepted),
  rs('rejects second Builder/Engineer/Merchant work order on same tile for same player (per-tile exclusivity)',() { const exclusivityTileKey = ValidateWorkOw.tileKey; vwExpectDualWorkOrders(game: builderEngineerSameTileExclusivityGame(),first: const WorkOrder(unitId: 'builder1',target: kWorkTargetBuildImprovement,targetTileKey: exclusivityTileKey),second: const WorkOrder(unitId: 'engineer1',target: kWorkTargetBuildRoad,targetTileKey: exclusivityTileKey),statuses: const [OrderValidationStatus.accepted,OrderValidationStatus.rejected,],lastReasonContains: 'Tile already has development or purchase work'); },),
  rs('accepts purchase_land for mineral when prospected', () => vwExpectPurchaseLandMineral(prospected: true)),
  rs('rejects purchase_land when tile already purchased by another GP',() => vwExpectPurchaseLandRejected(purchasedTilesByTileKey: {PurchaseLandTestFixture.tileKey: 'p2'},reasonContains: 'Tile already purchased by another power'),),
  rs('rejects purchase_land when tile already owned by same player',() => vwExpectPurchaseLandRejected(purchasedTilesByTileKey: {PurchaseLandTestFixture.tileKey: 'p1'},reasonContains: 'You already own this tile'),),
  rs('rejects build_improvement on mineral tile when not prospected', () => vwExpectBuildImprovementMineral(prospected: false)),
  rs('accepts build_improvement on mineral tile after prospected', () => vwExpectBuildImprovementMineral(prospected: true)),
  rs('accepts build_improvement on grain when tile not prospected',() => vwExpectBuildImprovementOutcome(game: buildImprovementBaseGame(resourceByTileKey: {ValidateWorkOw.tileKey: 'grain'}),accepted: true),),
  rs('rejects build_improvement when tile has no resource',() => vwExpectBuildImprovementOutcome(game: buildImprovementBaseGame(resourceByTileKey: {}),accepted: false,reasonContains: 'no resource'),),
  rs('rejects build_improvement when improvement level already 4',() => vwExpectBuildImprovementOutcome(game: buildImprovementBaseGame(tileState: const TileMapState(improvementByTile: {'oldWorld|P1|0|0': 4}),stockpile: lumberCastIronStockpile(20)),accepted: false,reasonContains: 'maximum'),),
  rs('rejects build_improvement when tech cap would be exceeded (empty tech)',() => vwExpectBuildImprovementOutcome(game: buildImprovementBaseGame(techUnlocked: const {},tileState: const TileMapState(improvementByTile: {'oldWorld|P1|0|0': 1}),stockpile: lumberCastIronStockpile(10)),accepted: false,reasonContains: 'Insufficient tech',onRejected: (result) { expect(result.reason,contains('grain')); expect(result.reason,contains('cap 1')); }),),
  rs('rejects build_improvement when tech cap would be exceeded',() => vwExpectBuildImprovementOutcome(game: buildImprovementBaseGame(techUnlocked: const {kTechIdSawMill: true},tileState: const TileMapState(improvementByTile: {'oldWorld|P1|0|0': 1}),stockpile: lumberCastIronStockpile(10)),accepted: false,reasonContains: 'Insufficient tech'),),
  rs('accepts grain upgrade when exact next-level grain tech is unlocked',() => vwExpectBuildImprovementOutcome(game: buildImprovementBaseGame(techUnlocked: const {kTechIdLandEnclosure: true},tileState: const TileMapState(improvementByTile: {'oldWorld|P1|0|0': 1}),stockpile: lumberCastIronStockpile(10)),accepted: true),),
  rs('accepts build_improvement when tile has resource, level < 4, tech cap allows',() => vwExpectBuildImprovementOutcome(game: buildImprovementBaseGame(resourceByTileKey: {ValidateWorkOw.tileKey: 'grain'},tileState: const TileMapState(),techUnlocked: const {kTechIdCircularSaw: true}),accepted: true),),
  rs('rejects build_improvement in foreign, unpurchased province',() => vwExpectBuildImprovementOutcome(game: buildImprovementForeignProvinceGame(),targetTileKey: validateWorkForeignTileKey(),accepted: false,reasonContains: 'foreign or uncontrolled province'),),
  rs('rejects raising scrub timber from level 1 even with circular_saw',() => vwExpectBuildImprovementOutcome(game: scrubCapBaseGame(level: 1),tileMapByRegion: scrubCapTileMaps(TerrainType.scrubForest),accepted: false,reasonContains: 'Terrain caps',onRejected: (result) => expect(result.reason,contains('level 1'))),),
  rs('accepts raising hardwood timber from level 1 with circular_saw',() => vwExpectBuildImprovementOutcome(game: scrubCapBaseGame(level: 1),tileMapByRegion: scrubCapTileMaps(TerrainType.hardwoodForest),accepted: true),),
  rs('accepts initial scrub timber improvement (level 0 -> 1)',() => vwExpectBuildImprovementOutcome(game: scrubCapBaseGame(level: 0),tileMapByRegion: scrubCapTileMaps(TerrainType.scrubForest),accepted: true),),
  rs('accepts build_improvement on purchased tile in foreign province',() { final foreignTileKey = validateWorkForeignTileKey(); vwExpectBuildImprovementOutcome(game: buildImprovementForeignProvinceGame(purchasedTilesByTileKey: {foreignTileKey: 'p1'},),targetTileKey: foreignTileKey,accepted: true,); },),
  rs('rejects build_fort to level 2 without Mine Engineering',() => vwExpectFortBuildRejected(fortLevel: 1,stockpile: Stockpile() .applyDelta(CommodityCatalog.lumber.id,4) .applyDelta(CommodityCatalog.bronze.id,4),reasonContains: 'Mine Engineering'),),
  rs('rejects build_fort to level 3 without Modern Forts',() => vwExpectFortBuildRejected(fortLevel: 2,stockpile: Stockpile() .applyDelta(CommodityCatalog.steel.id,5) .applyDelta(CommodityCatalog.lumber.id,5),techUnlocked: const {kTechIdMineEngineering: true},reasonContains: 'Modern Forts'),),
  rs('rejects build_rail when tile terrain data is missing',() => vwExpectRailBuildOutcome(tileState: TileMapState().setRoadLevel(ValidateWorkOw.tileKey,1),tileMapByRegion: const {},accepted: false,reasonContains: 'terrain data required'),),
  rs('rejects build_rail when road level is 0',() => vwExpectRailBuildOutcome(tileState: TileMapState().setRoadLevel(ValidateWorkOw.tileKey,0),tileMapByRegion: {ValidateWorkOw.ow: railTileMap(TerrainType.plains)},accepted: false,reasonContains: 'existing road'),),
  rs('rejects build_rail on hills with only Early Steam',() => vwExpectRailBuildOutcome(tileState: TileMapState().setRoadLevel(ValidateWorkOw.tileKey,1),techUnlocked: const {kTechIdEarlySteamEngine: true},tileMapByRegion: {ValidateWorkOw.ow: railTileMap(TerrainType.hills)},accepted: false,reasonContains: 'Later Steam'),),
  rs('accepts build_rail on plains with Early Steam and road 1',() => vwExpectRailBuildOutcome(tileState: TileMapState().setRoadLevel(ValidateWorkOw.tileKey,1),tileMapByRegion: {ValidateWorkOw.ow: railTileMap(TerrainType.plains)},accepted: true),),
  rs('rejects build_road in minor province without embassy path', () => vwExpectRejectMinorProvinceRoad(game: minorProvinceEngineerRoadGame(), reasonContains: 'foreign province')),
  rs('rejects build_road in minor province even with embassy when occupancy disallows tile',() => vwExpectRejectMinorProvinceRoad(game: minorProvinceEngineerRoadGame(overtureStates: minorProvinceEmbassyOverture),reasonContains: 'cannot occupy'),),
  rs('rejects upgrade_town without National Bureaucracy', () => vwExpectUpgradeTownOutcome(accepted: false, techUnlocked: const {})),
  rs('accepts upgrade_town when National Bureaucracy unlocked', () => vwExpectUpgradeTownOutcome(accepted: true, techUnlocked: const {kTechIdNationalBureaucracy: true})),
  // dart format on
];
