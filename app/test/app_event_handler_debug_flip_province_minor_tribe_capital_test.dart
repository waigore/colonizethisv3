import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_app/core/services/debug/app_event_handler_debug_flip_province.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/debug_handler_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  group('applyDebugFlipProvinceOwnership minor/tribe capital behavior', () {
    test(
      'flips minor capital and reassigns to deterministic seaboard owned province in same region',
      () {
        final game = buildDebugHandlerFlipCapitalGame(
          id: 'g-minor-flip-reassign',
          oldWorldProvinces: [
            debugHandlerTownProvince('oldWorld|P1', 'minor_1', 'Minor Capital'),
            debugHandlerTownProvince(
              'oldWorld|P2',
              'minor_1',
              'Minor Inland',
              1,
              1,
            ),
          ],
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
          minorCapitalProvinceId: 'oldWorld|P1',
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
        expect(ownerByProvince['oldWorld|P2'], 'minor_1');

        final minor = next.minorNations.single;
        expect(minor.capitalProvinceId, 'oldWorld|P2');
        expect(minor.capitalTile!.toTileKey(), 'oldWorld|P2|1|1');

        expect(next.worldState.portsByProvinceSeaboard, isEmpty);

        final p2 = next.worldState.oldWorld.provinces.firstWhere(
          (p) => p.id == 'oldWorld|P2',
        );
        expect(p2.townDevelopmentLevel, kTownDevelopmentLevelMin);
      },
    );

    test(
      'flips tribe capital and reassigns deterministically without port/road changes',
      () {
        final game = buildDebugHandlerFlipCapitalGame(
          id: 'g-tribe-flip-reassign',
          newWorldProvinces: [
            debugHandlerTownProvince('newWorld|N1', 'tribe_1', 'Tribe Capital'),
            debugHandlerTownProvince(
              'newWorld|N2',
              'tribe_1',
              'Tribe Hold',
              2,
              2,
            ),
          ],
          tileKeysByRegionAndProvince: {
            'newWorld': {
              'newWorld|N1': [debugHandlerTileKey('newWorld|N1')],
              'newWorld|N2': [debugHandlerTileKey('newWorld|N2', 2, 2)],
            },
          },
          playerVisibilityByTile: {
            'human_1': {
              debugHandlerTileKey('newWorld|N1'): 'fogged',
              debugHandlerTileKey('newWorld|N2', 2, 2): 'fogged',
            },
          },
          tribeCapitalProvinceId: 'newWorld|N1',
        );
        const event = FlipDebugProvinceOwnershipEvent(
          humanPlayerId: 'human_1',
          fullProvinceId: 'newWorld|N1',
        );

        final result = applyDebugFlipProvinceOwnership(
          currentGame: game,
          event: event,
          combinedTopology: const MapTopology(),
        );

        final next = result.game;
        expect(next, isNotNull);
        final ownerByProvince = {
          for (final p in next!.worldState.newWorld.provinces) p.id: p.ownerId,
        };
        expect(ownerByProvince['newWorld|N1'], 'human_1');
        expect(ownerByProvince['newWorld|N2'], 'tribe_1');

        final tribe = next.tribes.single;
        expect(tribe.capitalProvinceId, 'newWorld|N2');
        expect(tribe.capitalTile!.toTileKey(), 'newWorld|N2|2|2');

        final n2 = next.worldState.newWorld.provinces.firstWhere(
          (p) => p.id == 'newWorld|N2',
        );
        expect(n2.townDevelopmentLevel, kTownDevelopmentLevelMin);
      },
    );

    test(
      'flips minor sole-province capital and applies terminal fall with deterministic feedback',
      () {
        final game = buildDebugHandlerFlipCapitalGame(
          id: 'g-minor-flip-fall',
          oldWorldProvinces: [
            debugHandlerTownProvince('oldWorld|P1', 'minor_1', 'Minor Capital'),
          ],
          newWorldProvinces: [
            debugHandlerTownProvince(
              'newWorld|N1',
              'minor_1',
              'Minor Outpost',
              3,
              3,
            ),
          ],
          tileKeysByRegionAndProvince: {
            'oldWorld': {
              'oldWorld|P1': [debugHandlerTileKey('oldWorld|P1')],
            },
            'newWorld': {
              'newWorld|N1': [debugHandlerTileKey('newWorld|N1', 3, 3)],
            },
          },
          playerVisibilityByTile: {
            'human_1': {debugHandlerTileKey('oldWorld|P1'): 'fogged'},
          },
          minorCapitalProvinceId: 'oldWorld|P1',
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
        expect(next!.minorNations, isEmpty);
        final ownerByProvince = {
          for (final p in next.worldState.oldWorld.provinces) p.id: p.ownerId,
          for (final p in next.worldState.newWorld.provinces) p.id: p.ownerId,
        };
        expect(ownerByProvince['oldWorld|P1'], 'human_1');
        expect(ownerByProvince['newWorld|N1'], 'human_1');
        expect(result.message, contains('Immediate terminal outcome resolved'));
      },
    );

    test(
      'flips tribe sole-region capital and applies terminal fall',
      () {
        final game = buildDebugHandlerFlipCapitalGame(
          id: 'g-tribe-flip-fall',
          newWorldProvinces: [
            debugHandlerTownProvince('newWorld|N1', 'tribe_1', 'Tribe Capital'),
          ],
          tileKeysByRegionAndProvince: {
            'newWorld': {
              'newWorld|N1': [debugHandlerTileKey('newWorld|N1')],
            },
          },
          playerVisibilityByTile: {
            'human_1': {debugHandlerTileKey('newWorld|N1'): 'fogged'},
          },
          tribeCapitalProvinceId: 'newWorld|N1',
        );
        const event = FlipDebugProvinceOwnershipEvent(
          humanPlayerId: 'human_1',
          fullProvinceId: 'newWorld|N1',
        );

        final result = applyDebugFlipProvinceOwnership(
          currentGame: game,
          event: event,
          combinedTopology: const MapTopology(),
        );

        final next = result.game;
        expect(next, isNotNull);
        expect(next!.tribes, isEmpty);
        expect(
          next.worldState.newWorld.provinces.single.ownerId,
          'human_1',
        );
        expect(result.message, contains('Immediate terminal outcome resolved'));
      },
    );

    test(
      'flipping a non-capital province does not modify minor/tribe capital fields',
      () {
        final game = buildDebugHandlerFlipCapitalGame(
          id: 'g-minor-flip-non-capital',
          oldWorldProvinces: [
            debugHandlerTownProvince('oldWorld|P1', 'minor_1', 'Minor Capital'),
            debugHandlerTownProvince(
              'oldWorld|P2',
              'minor_1',
              'Minor Inland',
              1,
              1,
            ),
          ],
          tileKeysByRegionAndProvince: {
            'oldWorld': {
              'oldWorld|P1': [debugHandlerTileKey('oldWorld|P1')],
              'oldWorld|P2': [debugHandlerTileKey('oldWorld|P2', 1, 1)],
            },
          },
          playerVisibilityByTile: {
            'human_1': {debugHandlerTileKey('oldWorld|P2', 1, 1): 'fogged'},
          },
          minorCapitalProvinceId: 'oldWorld|P1',
        );
        const event = FlipDebugProvinceOwnershipEvent(
          humanPlayerId: 'human_1',
          fullProvinceId: 'oldWorld|P2',
        );

        final result = applyDebugFlipProvinceOwnership(
          currentGame: game,
          event: event,
          combinedTopology: const MapTopology(),
        );

        final next = result.game;
        expect(next, isNotNull);
        final minor = next!.minorNations.single;
        expect(minor.capitalProvinceId, 'oldWorld|P1');
        expect(minor.capitalTile!.toTileKey(), 'oldWorld|P1|0|0');
        expect(result.message, isNot(contains('terminal outcome')));
      },
    );

    test(
      'reassigned minor capital round-trips through Game.toJson/fromJson',
      () {
        final game = buildDebugHandlerFlipCapitalGame(
          id: 'g-minor-flip-json',
          oldWorldProvinces: [
            debugHandlerTownProvince('oldWorld|P1', 'minor_1', 'Minor Capital'),
            debugHandlerTownProvince(
              'oldWorld|P2',
              'minor_1',
              'Minor Inland',
              1,
              1,
            ),
          ],
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
          minorCapitalProvinceId: 'oldWorld|P1',
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

        final next = result.game!;
        final roundTrip = Game.fromJson(next.toJson());
        final minorBefore = next.minorNations.single;
        final minorAfter = roundTrip.minorNations.single;
        expect(minorAfter.id, minorBefore.id);
        expect(minorAfter.capitalProvinceId, minorBefore.capitalProvinceId);
        expect(
          minorAfter.capitalTile?.toTileKey(),
          minorBefore.capitalTile?.toTileKey(),
        );
      },
    );
  });
}
