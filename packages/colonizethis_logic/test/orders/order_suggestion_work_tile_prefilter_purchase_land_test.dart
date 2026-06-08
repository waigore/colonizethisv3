import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/src/constants.dart';
import 'package:colonizethis_diplomacy/src/diplomacy/diplomacy_resolver.dart';
import 'package:colonizethis_logic/src/orders/order_suggestion_work_tile_prefilter.dart';
import 'package:colonizethis_world/src/world/province_lookup.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('rawCandidateTilesForWorkTarget (purchase_land)', () {
    test(
      'includes resource tiles in minor-owned provinces, excludes GP-owned',
      () {
        const playerId = 'gp1';
        const ow = 'oldWorld';
        final player = Player(
          id: playerId,
          displayName: 'GP',
          isHuman: false,
          treasury: 500,
        );
        final ownProvince = Province(
          id: '$ow|p1',
          regionId: ow,
          ownerId: playerId,
        );
        final minorProvince = Province(
          id: '$ow|minor1',
          regionId: ow,
          ownerId: 'minor1',
        );
        const minorTile = 'oldWorld|minor1|0|0';
        const gpTile = 'oldWorld|p1|0|0';
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [ownProvince, minorProvince],
            units: const [],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            ow: {
              '$ow|p1': [gpTile],
              '$ow|minor1': [minorTile],
            },
          },
          resourceByTileKey: {minorTile: 'grain', gpTile: 'timber'},
        );
        final game = Game(
          id: 'g1',
          worldState: world,
          players: [player],
          minorNations: const [
            MinorNation(id: 'minor1', displayName: 'Minor 1'),
          ],
        );

        final tiles = rawCandidateTilesForWorkTarget(
          game: game,
          playerId: playerId,
          workTarget: kWorkTargetPurchaseLand,
        );

        expect(tiles, contains(minorTile));
        expect(tiles, isNot(contains(gpTile)));

        final membership = DiplomacyFactionMembership.from(game);
        final tilesWithExplicitMembership = rawCandidateTilesForWorkTarget(
          game: game,
          playerId: playerId,
          workTarget: kWorkTargetPurchaseLand,
          factionMembership: membership,
        );
        expect(tilesWithExplicitMembership, tiles);
      },
    );

    test('includes resource tiles in tribe-owned provinces', () {
      const playerId = 'gp1';
      const ow = 'oldWorld';
      final player = Player(
        id: playerId,
        displayName: 'GP',
        isHuman: false,
        treasury: 500,
      );
      final tribeProvince = Province(
        id: '$ow|tribe1',
        regionId: ow,
        ownerId: 'tribe1',
      );
      const tribeTile = 'oldWorld|tribe1|0|0';
      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(provinces: [tribeProvince], units: const []),
        newWorld: const RegionData(),
        tileKeysByRegionAndProvince: {
          ow: {
            '$ow|tribe1': [tribeTile],
          },
        },
        resourceByTileKey: {tribeTile: 'grain'},
      );
      final game = Game(
        id: 'g1',
        worldState: world,
        players: [player],
        tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe 1')],
      );

      final tiles = rawCandidateTilesForWorkTarget(
        game: game,
        playerId: playerId,
        workTarget: kWorkTargetPurchaseLand,
      );

      expect(tiles, contains(tribeTile));
    });

    test(
      'playerOwnedProvinceIds yields same candidates as internal scan (build_road)',
      () {
        const playerId = 'gp1';
        const ow = 'oldWorld';
        final player = Player(
          id: playerId,
          displayName: 'GP',
          isHuman: false,
          treasury: 500,
        );
        final ownProvince = Province(
          id: '$ow|p1',
          regionId: ow,
          ownerId: playerId,
        );
        final minorProvince = Province(
          id: '$ow|minor1',
          regionId: ow,
          ownerId: 'minor1',
        );
        const minorTile = 'oldWorld|minor1|0|0';
        const gpTile = 'oldWorld|p1|0|0';
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [ownProvince, minorProvince],
            units: const [],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            ow: {
              '$ow|p1': [gpTile],
              '$ow|minor1': [minorTile],
            },
          },
        );
        final game = Game(
          id: 'g1',
          worldState: world,
          players: [player],
          minorNations: const [
            MinorNation(id: 'minor1', displayName: 'Minor 1'),
          ],
        );

        final defaultTiles = rawCandidateTilesForWorkTarget(
          game: game,
          playerId: playerId,
          workTarget: kWorkTargetBuildRoad,
        );
        final owned = <String>{
          for (final p in allProvinces(game.worldState))
            if (p.ownerId == playerId) p.id,
        };
        final explicitTiles = rawCandidateTilesForWorkTarget(
          game: game,
          playerId: playerId,
          workTarget: kWorkTargetBuildRoad,
          playerOwnedProvinceIds: owned,
        );
        expect(explicitTiles, defaultTiles);
      },
    );
  });
}
