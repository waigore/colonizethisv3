import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_app_debug/colonizethis_app_debug.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'debug_handler_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  group('applyDebugFlipProvinceOwnership capital behavior', () {
    test(
      'resolves immediate terminal outcome when owner has no eligible replacement capital',
      () {
        final game = buildDebugHandlerFlipCapitalGame(
          id: 'g-flip-no-replacement',
          oldWorldProvinces: [
            debugHandlerTownProvince('oldWorld|P1', 'ai_1', 'New Bordeaux'),
          ],
          tileKeysByRegionAndProvince: {
            'oldWorld': {
              'oldWorld|P1': [debugHandlerTileKey('oldWorld|P1')],
            },
          },
          playerVisibilityByTile: {
            'human_1': {debugHandlerTileKey('oldWorld|P1'): 'fogged'},
          },
          aiCapitalProvinceId: 'oldWorld|P1',
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
        final game = buildDebugHandlerFlipCapitalGame(
          id: 'g-flip-capital-fall',
          oldWorldProvinces: [
            debugHandlerTownProvince('oldWorld|P1', 'ai_1', 'New Bordeaux'),
            debugHandlerTownProvince('oldWorld|P2', 'ai_1', 'Inland Hold', 1, 1),
          ],
          portsByProvinceSeaboard: {'oldWorld|P1|sea1': 'oldWorld|P1|0|0'},
          tileKeysByRegionAndProvince: {
            'oldWorld': {
              'oldWorld|P1': [debugHandlerTileKey('oldWorld|P1')],
              'oldWorld|P2': [debugHandlerTileKey('oldWorld|P2', 1, 1)],
            },
          },
          playerVisibilityByTile: {
            'human_1': {
              debugHandlerTileKey('oldWorld|P1'): 'fogged',
              debugHandlerTileKey('oldWorld|P2', 1, 1): 'fogged',
            },
          },
          aiCapitalProvinceId: 'oldWorld|P1',
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
