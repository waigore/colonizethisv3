import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_app/core/services/app_event_handler_debug_flip_province.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  group('applyDebugFlipProvinceOwnership minor/tribe capital behavior', () {
    test(
      'flips minor capital and reassigns to deterministic seaboard owned province in same region',
      () {
        final game = Game(
          id: 'g-minor-flip-reassign',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
            oldWorld: const RegionData(
              provinces: [
                Province(
                  id: 'oldWorld|P1',
                  regionId: 'oldWorld',
                  ownerId: 'minor_1',
                  displayName: 'Minor Capital',
                  townTileKey: 'oldWorld|P1|0|0',
                ),
                Province(
                  id: 'oldWorld|P2',
                  regionId: 'oldWorld',
                  ownerId: 'minor_1',
                  displayName: 'Minor Inland',
                  townTileKey: 'oldWorld|P2|1|1',
                ),
              ],
            ),
            newWorld: const RegionData(),
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
          ],
          minorNations: const [
            MinorNation(
              id: 'minor_1',
              displayName: 'Minor',
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
        expect(ownerByProvince['oldWorld|P2'], 'minor_1');

        final minor = next.minorNations.single;
        expect(minor.capitalProvinceId, 'oldWorld|P2');
        expect(minor.capitalTile!.toTileKey(), 'oldWorld|P2|1|1');

        expect(next.worldState.portsByProvinceSeaboard, isEmpty);

        final p2 = next.worldState.oldWorld.provinces.firstWhere(
          (p) => p.id == 'oldWorld|P2',
        );
        expect(p2.townDevelopmentLevel, 0);
      },
    );

    test(
      'flips tribe capital and reassigns deterministically without port/road changes',
      () {
        final game = Game(
          id: 'g-tribe-flip-reassign',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
            oldWorld: const RegionData(),
            newWorld: const RegionData(
              provinces: [
                Province(
                  id: 'newWorld|N1',
                  regionId: 'newWorld',
                  ownerId: 'tribe_1',
                  displayName: 'Tribe Capital',
                  townTileKey: 'newWorld|N1|0|0',
                ),
                Province(
                  id: 'newWorld|N2',
                  regionId: 'newWorld',
                  ownerId: 'tribe_1',
                  displayName: 'Tribe Hold',
                  townTileKey: 'newWorld|N2|2|2',
                ),
              ],
            ),
            tileKeysByRegionAndProvince: const {
              'newWorld': {
                'newWorld|N1': ['newWorld|N1|0|0'],
                'newWorld|N2': ['newWorld|N2|2|2'],
              },
            },
            playerVisibilityByTile: {
              'human_1': {
                'newWorld|N1|0|0': 'fogged',
                'newWorld|N2|2|2': 'fogged',
              },
            },
          ),
          players: const [
            Player(id: 'human_1', displayName: 'Human', isHuman: true),
          ],
          tribes: const [
            Tribe(
              id: 'tribe_1',
              displayName: 'Tribe',
              capitalProvinceId: 'newWorld|N1',
              capitalTile: CapitalTile(
                regionId: 'newWorld',
                provinceId: 'newWorld|N1',
                x: 0,
                y: 0,
              ),
            ),
          ],
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
        expect(n2.townDevelopmentLevel, 0);
      },
    );

    test(
      'flips minor sole-province capital and applies terminal fall with deterministic feedback',
      () {
        final game = Game(
          id: 'g-minor-flip-fall',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
            oldWorld: const RegionData(
              provinces: [
                Province(
                  id: 'oldWorld|P1',
                  regionId: 'oldWorld',
                  ownerId: 'minor_1',
                  displayName: 'Minor Capital',
                  townTileKey: 'oldWorld|P1|0|0',
                ),
              ],
            ),
            newWorld: const RegionData(
              provinces: [
                Province(
                  id: 'newWorld|N1',
                  regionId: 'newWorld',
                  ownerId: 'minor_1',
                  displayName: 'Minor Outpost',
                  townTileKey: 'newWorld|N1|3|3',
                ),
              ],
            ),
            tileKeysByRegionAndProvince: const {
              'oldWorld': {
                'oldWorld|P1': ['oldWorld|P1|0|0'],
              },
              'newWorld': {
                'newWorld|N1': ['newWorld|N1|3|3'],
              },
            },
            playerVisibilityByTile: {
              'human_1': {
                'oldWorld|P1|0|0': 'fogged',
              },
            },
          ),
          players: const [
            Player(id: 'human_1', displayName: 'Human', isHuman: true),
          ],
          minorNations: const [
            MinorNation(
              id: 'minor_1',
              displayName: 'Minor',
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
        final game = Game(
          id: 'g-tribe-flip-fall',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
            oldWorld: const RegionData(),
            newWorld: const RegionData(
              provinces: [
                Province(
                  id: 'newWorld|N1',
                  regionId: 'newWorld',
                  ownerId: 'tribe_1',
                  displayName: 'Tribe Capital',
                  townTileKey: 'newWorld|N1|0|0',
                ),
              ],
            ),
            tileKeysByRegionAndProvince: const {
              'newWorld': {
                'newWorld|N1': ['newWorld|N1|0|0'],
              },
            },
            playerVisibilityByTile: {
              'human_1': {
                'newWorld|N1|0|0': 'fogged',
              },
            },
          ),
          players: const [
            Player(id: 'human_1', displayName: 'Human', isHuman: true),
          ],
          tribes: const [
            Tribe(
              id: 'tribe_1',
              displayName: 'Tribe',
              capitalProvinceId: 'newWorld|N1',
              capitalTile: CapitalTile(
                regionId: 'newWorld',
                provinceId: 'newWorld|N1',
                x: 0,
                y: 0,
              ),
            ),
          ],
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
        final game = Game(
          id: 'g-minor-flip-non-capital',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
            oldWorld: const RegionData(
              provinces: [
                Province(
                  id: 'oldWorld|P1',
                  regionId: 'oldWorld',
                  ownerId: 'minor_1',
                  displayName: 'Minor Capital',
                  townTileKey: 'oldWorld|P1|0|0',
                ),
                Province(
                  id: 'oldWorld|P2',
                  regionId: 'oldWorld',
                  ownerId: 'minor_1',
                  displayName: 'Minor Inland',
                  townTileKey: 'oldWorld|P2|1|1',
                ),
              ],
            ),
            newWorld: const RegionData(),
            tileKeysByRegionAndProvince: const {
              'oldWorld': {
                'oldWorld|P1': ['oldWorld|P1|0|0'],
                'oldWorld|P2': ['oldWorld|P2|1|1'],
              },
            },
            playerVisibilityByTile: {
              'human_1': {
                'oldWorld|P2|1|1': 'fogged',
              },
            },
          ),
          players: const [
            Player(id: 'human_1', displayName: 'Human', isHuman: true),
          ],
          minorNations: const [
            MinorNation(
              id: 'minor_1',
              displayName: 'Minor',
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
        final game = Game(
          id: 'g-minor-flip-json',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
            oldWorld: const RegionData(
              provinces: [
                Province(
                  id: 'oldWorld|P1',
                  regionId: 'oldWorld',
                  ownerId: 'minor_1',
                  displayName: 'Minor Capital',
                  townTileKey: 'oldWorld|P1|0|0',
                ),
                Province(
                  id: 'oldWorld|P2',
                  regionId: 'oldWorld',
                  ownerId: 'minor_1',
                  displayName: 'Minor Inland',
                  townTileKey: 'oldWorld|P2|1|1',
                ),
              ],
            ),
            newWorld: const RegionData(),
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
          ],
          minorNations: const [
            MinorNation(
              id: 'minor_1',
              displayName: 'Minor',
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
