import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_turn/src/turn/naval_resolution.dart';

import '../support/ship_reveal_test_support.dart';

void main() {
  group('Naval ship reveal (end of turn and player view)', () {
    test(
      'ship reveal finds province tiles when tile map keys province by local id only',
      () {
        final combinedTopology = nwShipRevealCoastalTopology();
        // Land bucket keyed by **local** id only (some maps/fixtures).
        final game = nwShipRevealCoastalGame(
          id: 'gLocalProvBucket',
          landProvinceBucketKey: NwShipRevealCoastalIds.localProvinceBucket,
        );

        final after = applyNavalMovesAndShipReveal(game, combinedTopology, {
          'gp1': [
            const NavalMoveOrder(
              fleetId: 'fNw',
              destinationSeaZoneId: NwShipRevealCoastalIds.prefixedDest,
            ),
          ],
        });
        final vis = after.worldState.playerVisibilityByTile['gp1']!;
        expect(
          vis[NwShipRevealCoastalIds.coastalLand],
          VisibilityLevel.fullyVisible.name,
        );
        expect(
          vis[NwShipRevealCoastalIds.inlandLand],
          VisibilityLevel.unknown.name,
        );
        expect(
          vis[NwShipRevealCoastalIds.seaDestWater],
          VisibilityLevel.fullyVisible.name,
        );
      },
    );

    test(
      'S->S entry remains fully visible after end-of-turn and in PlayerView',
      () {
        const ow = 'oldWorld';
        const startSea = '$ow|seaStart';
        const destSea = '$ow|seaDest';
        const destSeaTileA = '$ow|seaDest|2|0';
        const destSeaTileB = '$ow|seaDest|2|1';
        const destProv = '$ow|pDest';
        const destCoast = '$destProv|1|0';

        final topologies = shipRevealPrefixedLocalTopologyPair(
          regionId: ow,
          nodes: const [
            ('pDest', TopologyNodeType.province),
            ('seaStart', TopologyNodeType.seaZone),
            ('seaDest', TopologyNodeType.seaZone),
          ],
          edges: const [('pDest', 'seaDest'), ('seaStart', 'seaDest')],
        );

        final game = Game(
          id: 'gS2S',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.movement,
              turnNumber: 3,
            ),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: 'f1',
                ownerId: 'gp1',
                seaZoneId: startSea,
                regionId: ow,
                shipTypeIds: const ['carrack'],
              ),
            ],
            tileKeysByRegionAndProvince: const {
              ow: {
                destProv: [destCoast],
                destSea: [destSeaTileA, destSeaTileB],
              },
            },
            playerVisibilityByTile: {
              'gp1': {
                destSeaTileA: VisibilityLevel.unknown.name,
                destSeaTileB: VisibilityLevel.unknown.name,
              },
            },
          ),
          players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
        );

        final result = applyShipRevealThenEndOfTurnView(
          game: game,
          moveTopology: topologies.combined,
          endOfTurnTopology: topologies.local,
          regionId: ow,
          navalMoveOrdersByPlayerId: {
            'gp1': [
              const NavalMoveOrder(
                fleetId: 'f1',
                destinationSeaZoneId: destSea,
              ),
            ],
          },
          turnNumber: 3,
        );

        expect(
          result.ended.worldState.playerVisibilityByTile['gp1']?[destSeaTileA],
          VisibilityLevel.fullyVisible.name,
        );
        expect(
          result.ended.worldState.playerVisibilityByTile['gp1']?[destSeaTileB],
          VisibilityLevel.fullyVisible.name,
        );
        expect(
          result.view.visibilityForTile(destSeaTileA),
          VisibilityLevel.fullyVisible,
        );
        expect(
          result.view.visibilityForTile(destSeaTileB),
          VisibilityLevel.fullyVisible,
        );
      },
    );

    test(
      'P->S undock entry remains fully visible after end-of-turn and in PlayerView',
      () {
        const ow = 'oldWorld';
        const portProv = '$ow|pPort';
        const destSeaPrefixed = '$ow|seaDest';
        const destSeaTileA = '$ow|seaDest|4|0';
        const destSeaTileB = '$ow|seaDest|4|1';
        const coastTile = '$portProv|3|0';

        final topologies = shipRevealPrefixedLocalTopologyPair(
          regionId: ow,
          nodes: const [
            ('pPort', TopologyNodeType.province),
            ('seaDest', TopologyNodeType.seaZone),
          ],
          edges: const [('pPort', 'seaDest')],
        );

        final game = Game(
          id: 'gP2S',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.movement,
              turnNumber: 7,
            ),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: 'f2',
                ownerId: 'gp1',
                inPortAtProvinceId: portProv,
                regionId: ow,
                shipTypeIds: const ['carrack'],
              ),
            ],
            tileKeysByRegionAndProvince: const {
              ow: {
                portProv: [coastTile],
                destSeaPrefixed: [destSeaTileA, destSeaTileB],
              },
            },
            playerVisibilityByTile: {
              'gp1': {
                destSeaTileA: VisibilityLevel.unknown.name,
                destSeaTileB: VisibilityLevel.unknown.name,
              },
            },
          ),
          players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
        );

        final result = applyShipRevealThenEndOfTurnView(
          game: game,
          moveTopology: topologies.combined,
          endOfTurnTopology: topologies.local,
          regionId: ow,
          navalMoveOrdersByPlayerId: {
            'gp1': [
              const NavalMoveOrder(
                fleetId: 'f2',
                destinationSeaZoneId: destSeaPrefixed,
              ),
            ],
          },
          turnNumber: 7,
        );

        expect(
          result.ended.worldState.playerVisibilityByTile['gp1']?[destSeaTileA],
          VisibilityLevel.fullyVisible.name,
        );
        expect(
          result.ended.worldState.playerVisibilityByTile['gp1']?[destSeaTileB],
          VisibilityLevel.fullyVisible.name,
        );
        expect(
          result.view.visibilityForTile(destSeaTileA),
          VisibilityLevel.fullyVisible,
        );
        expect(
          result.view.visibilityForTile(destSeaTileB),
          VisibilityLevel.fullyVisible,
        );
      },
    );
  });
}
