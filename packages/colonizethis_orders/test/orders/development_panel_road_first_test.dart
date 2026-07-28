import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/test.dart';

import 'support/suggestion/order_suggestion_core_fixtures.dart';

TileMapResult _threeTileRowMap() => TileMapResult(
  width: 3,
  height: 1,
  grid: const [
    ['p1', 'p1', 'p1'],
  ],
  terrainGrid: const [
    [TerrainType.plains, TerrainType.plains, TerrainType.plains],
  ],
);

void main() {
  group('development panel road first (Refs #4175 Slice C)', () {
    test('shortestOwnedTilePathToConnectedNetwork finds path on owned tiles', () {
      final tile0 = OscIds.tile('p1', 0, 0);
      final tile1 = OscIds.tile('p1', 1, 0);
      final tile2 = OscIds.tile('p1', 2, 0);
      final game = oscGame(
        worldState: oscWorld(
          oldWorld: RegionData(
            provinces: [oscProvince('p1', ownerId: OscIds.playerId)],
          ),
          tileKeysByRegionAndProvince: oscTilesByProvince({
            'p1': [tile0, tile1, tile2],
          }),
        ),
      );
      final path = shortestOwnedTilePathToConnectedNetwork(
        game: game,
        playerId: OscIds.playerId,
        startTileKey: tile2,
        connectedTileKeys: {tile0},
        tileMapByRegion: {'oldWorld': _threeTileRowMap()},
        topology: oscProvinceTopology(['p1']),
      );
      expect(path, [tile2, tile1, tile0]);
    });

    test('resolveDevelopmentRoadFirstState disables without idle Engineers', () {
      final tile0 = OscIds.tile('p1', 0, 0);
      final tile2 = OscIds.tile('p1', 2, 0);
      final game = oscGame(
        worldState: oscWorld(
          oldWorld: RegionData(
            provinces: [oscProvince('p1', ownerId: OscIds.playerId)],
            units: [oscBuilder(id: 'b1', provinceLocal: 'p1', tileKey: tile0)],
          ),
          tileKeysByRegionAndProvince: oscTilesByProvince({
            'p1': [tile0, OscIds.tile('p1', 1, 0), tile2],
          }),
        ),
      );
      final state = resolveDevelopmentRoadFirstState(
        game: game,
        playerId: OscIds.playerId,
        currentOrders: const Orders(),
        topology: oscProvinceTopology(['p1']),
        tileMapByRegion: {'oldWorld': _threeTileRowMap()},
        improveTargetTileKey: tile2,
        connectedTileKeys: {tile0},
      );
      expect(state.enabled, isFalse);
      expect(state.disabledReason, 'No idle Engineers');
    });

    test('resolveDevelopmentRoadFirstState enables with engineer and materials', () {
      final tile0 = OscIds.tile('p1', 0, 0);
      final tile1 = OscIds.tile('p1', 1, 0);
      final tile2 = OscIds.tile('p1', 2, 0);
      final player = oscBuilderPlayer(lumberCastIron: 20);
      final game = oscGame(
        worldState: oscWorld(
          oldWorld: RegionData(
            provinces: [oscProvince('p1', ownerId: OscIds.playerId)],
            units: [
              Unit(
                id: 'e1',
                type: kUnitTypeEngineer,
                ownerId: OscIds.playerId,
                locationProvinceId: OscIds.prov('p1'),
                tileKey: tile0,
              ),
            ],
          ),
          tileKeysByRegionAndProvince: oscTilesByProvince({
            'p1': [tile0, tile1, tile2],
          }),
          playerVisibilityByTile: oscVisibility({
            tile0: 'fullyVisible',
            tile1: 'fullyVisible',
            tile2: 'fullyVisible',
          }),
        ),
        players: [player],
      );
      final state = resolveDevelopmentRoadFirstState(
        game: game,
        playerId: OscIds.playerId,
        currentOrders: const Orders(),
        topology: oscProvinceTopology(['p1']),
        tileMapByRegion: {'oldWorld': _threeTileRowMap()},
        improveTargetTileKey: tile2,
        connectedTileKeys: {tile0},
      );
      expect(state.enabled, isTrue);
      expect(state.candidate?.engineerUnitId, 'e1');
      expect(state.candidate?.targetTileKey, tile1);
    });
  });
}
