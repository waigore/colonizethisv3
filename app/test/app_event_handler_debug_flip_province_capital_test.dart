import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_app/core/services/app_event_handler_debug_flip_province.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  group('applyDebugFlipProvinceOwnership capital behavior', () {
    test(
      'resolves immediate terminal outcome when owner has no eligible replacement capital',
      () {
        final game = Game(
          id: 'g-flip-no-replacement',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
            oldWorld: const RegionData(
              provinces: [
                Province(
                  id: 'oldWorld|P1',
                  regionId: 'oldWorld',
                  ownerId: 'ai_1',
                  displayName: 'New Bordeaux',
                  townTileKey: 'oldWorld|P1|0|0',
                ),
              ],
            ),
            newWorld: const RegionData(),
            tileKeysByRegionAndProvince: const {
              'oldWorld': {
                'oldWorld|P1': ['oldWorld|P1|0|0'],
              },
            },
            playerVisibilityByTile: {
              'human_1': {'oldWorld|P1|0|0': 'fogged'},
            },
          ),
          players: const [
            Player(id: 'human_1', displayName: 'Human', isHuman: true),
            Player(
              id: 'ai_1',
              displayName: 'AI',
              isHuman: false,
              capitalProvinceId: 'oldWorld|P1',
              capitalTile: CapitalTile(
                regionId: 'oldWorld',
                provinceId: 'oldWorld|P1',
                x: 0,
                y: 0,
              ),
            ),
          ],
        );
        const event = FlipDebugProvinceOwnershipEvent(
          humanPlayerId: 'human_1',
          fullProvinceId: 'oldWorld|P1',
        );

        final result = applyDebugFlipProvinceOwnership(
          currentGame: game,
          event: event,
          combinedTopology: const MapTopology(),
        );

        final next = result.game;
        expect(next, isNotNull);
        final ownerByProvince = {
          for (final p in next!.worldState.oldWorld.provinces) p.id: p.ownerId,
        };
        expect(ownerByProvince['oldWorld|P1'], 'human_1');
        expect(result.message, contains('Immediate terminal outcome resolved'));
      },
    );

    test(
      'flip foreign capital applies immediate reassignment and great power fall',
      () {
        final game = Game(
          id: 'g-flip-capital-fall',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
            oldWorld: const RegionData(
              provinces: [
                Province(
                  id: 'oldWorld|P1',
                  regionId: 'oldWorld',
                  ownerId: 'ai_1',
                  displayName: 'New Bordeaux',
                  townTileKey: 'oldWorld|P1|0|0',
                ),
                Province(
                  id: 'oldWorld|P2',
                  regionId: 'oldWorld',
                  ownerId: 'ai_1',
                  displayName: 'Inland Hold',
                  townTileKey: 'oldWorld|P2|1|1',
                ),
              ],
            ),
            newWorld: const RegionData(),
            portsByProvinceSeaboard: {'oldWorld|P1|sea1': 'oldWorld|P1|0|0'},
            tileKeysByRegionAndProvince: const {
              'oldWorld': {
                'oldWorld|P1': ['oldWorld|P1|0|0'],
                'oldWorld|P2': ['oldWorld|P2|1|1'],
              },
            },
            playerVisibilityByTile: {
              'human_1': {
                'oldWorld|P1|0|0': 'fogged',
                'oldWorld|P2|1|1': 'fogged',
              },
            },
          ),
          players: const [
            Player(id: 'human_1', displayName: 'Human', isHuman: true),
            Player(
              id: 'ai_1',
              displayName: 'AI',
              isHuman: false,
              capitalProvinceId: 'oldWorld|P1',
              capitalTile: CapitalTile(
                regionId: 'oldWorld',
                provinceId: 'oldWorld|P1',
                x: 0,
                y: 0,
              ),
            ),
          ],
        );
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'P1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'P2',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [],
        );
        const event = FlipDebugProvinceOwnershipEvent(
          humanPlayerId: 'human_1',
          fullProvinceId: 'oldWorld|P1',
        );

        final result = applyDebugFlipProvinceOwnership(
          currentGame: game,
          event: event,
          combinedTopology: topology,
        );

        final next = result.game;
        expect(next, isNotNull);
        final ownerByProvince = {
          for (final p in next!.worldState.oldWorld.provinces) p.id: p.ownerId,
        };
        expect(ownerByProvince['oldWorld|P1'], 'human_1');
        expect(ownerByProvince['oldWorld|P2'], 'human_1');
      },
    );
  });
}
