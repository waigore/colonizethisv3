import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_logic/src/turn/end_of_turn_resolver.dart';
import 'package:colonizethis_logic/src/world/naval_resolution.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('Naval ship reveal (end of turn and player view)', () {
    test(
      'ship reveal finds province tiles when tile map keys province by local id only',
      () {
        const nw = 'newWorld';
        const fullProv = '$nw|provA';
        const localProvBucket = 'provA';
        const localSeaDest = 'seaDest';
        const localSeaOrigin = 'seaOrigin';
        const prefixedDest = '$nw|$localSeaDest';
        const prefixedOrigin = '$nw|$localSeaOrigin';
        const coastalLand = '$nw|provA|1|0';
        const inlandLand = '$nw|provA|0|0';
        const seaDestWater = '$nw|$localSeaDest|2|0';
        const seaDestWaterB = '$nw|$localSeaDest|2|1';

        final combinedTopology = MapTopology(
          nodes: [
            TopologyNode(
              id: fullProv,
              regionId: nw,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: prefixedDest,
              regionId: nw,
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: prefixedOrigin,
              regionId: nw,
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: [
            TopologyEdge(id1: fullProv, id2: prefixedDest),
            TopologyEdge(id1: prefixedOrigin, id2: prefixedDest),
          ],
        );

        final visStart = <String, String>{
          for (final k in [
            coastalLand,
            inlandLand,
            seaDestWater,
            seaDestWaterB,
            '$nw|$localSeaOrigin|0|2',
          ])
            k: VisibilityLevel.unknown.name,
        };

        final game = Game(
          id: 'gLocalProvBucket',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.movement,
              turnNumber: 0,
            ),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
            fleets: [
              Fleet(
                id: 'fNw',
                ownerId: 'gp1',
                seaZoneId: prefixedOrigin,
                regionId: nw,
                shipTypeIds: ['carrack'],
              ),
            ],
            tileKeysByRegionAndProvince: {
              nw: {
                // Land bucket keyed by **local** id only (some maps/fixtures).
                localProvBucket: [coastalLand, inlandLand, '$nw|provA|0|1'],
                prefixedDest: [seaDestWater, seaDestWaterB],
                prefixedOrigin: ['$nw|$localSeaOrigin|0|2'],
              },
            },
            playerVisibilityByTile: {'gp1': visStart},
          ),
          players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
        );

        final after = applyNavalMovesAndShipReveal(game, combinedTopology, {
          'gp1': [
            NavalMoveOrder(fleetId: 'fNw', destinationSeaZoneId: prefixedDest),
          ],
        });
        final vis = after.worldState.playerVisibilityByTile['gp1']!;
        expect(vis[coastalLand], VisibilityLevel.fullyVisible.name);
        expect(vis[inlandLand], VisibilityLevel.unknown.name);
        expect(vis[seaDestWater], VisibilityLevel.fullyVisible.name);
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

        final combinedTopology = MapTopology(
          nodes: const [
            TopologyNode(
              id: '$ow|pDest',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: '$ow|seaStart',
              regionId: ow,
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: '$ow|seaDest',
              regionId: ow,
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [
            TopologyEdge(id1: '$ow|pDest', id2: '$ow|seaDest'),
            TopologyEdge(id1: '$ow|seaStart', id2: '$ow|seaDest'),
          ],
        );
        final localRegionTopology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'pDest',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'seaStart',
              regionId: ow,
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: 'seaDest',
              regionId: ow,
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [
            TopologyEdge(id1: 'pDest', id2: 'seaDest'),
            TopologyEdge(id1: 'seaStart', id2: 'seaDest'),
          ],
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

        final moved = applyNavalMovesAndShipReveal(game, combinedTopology, {
          'gp1': [
            const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: destSea),
          ],
        });
        final ended = runEndOfTurnPhase(
          moved.copyWith(
            worldState: moved.worldState.copyWith(
              turnState: const TurnState(
                phase: TurnPhase.endOfTurn,
                turnNumber: 3,
              ),
            ),
          ),
          topology: localRegionTopology,
          topologyByRegion: {ow: localRegionTopology},
        );
        final view = buildPlayerView(ended, localRegionTopology, 'gp1');

        expect(
          ended.worldState.playerVisibilityByTile['gp1']?[destSeaTileA],
          VisibilityLevel.fullyVisible.name,
        );
        expect(
          ended.worldState.playerVisibilityByTile['gp1']?[destSeaTileB],
          VisibilityLevel.fullyVisible.name,
        );
        expect(
          view.visibilityForTile(destSeaTileA),
          VisibilityLevel.fullyVisible,
        );
        expect(
          view.visibilityForTile(destSeaTileB),
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

        final combinedTopology = MapTopology(
          nodes: const [
            TopologyNode(
              id: '$ow|pPort',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: '$ow|seaDest',
              regionId: ow,
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [TopologyEdge(id1: '$ow|pPort', id2: '$ow|seaDest')],
        );
        final localRegionTopology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'pPort',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'seaDest',
              regionId: ow,
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [TopologyEdge(id1: 'pPort', id2: 'seaDest')],
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

        final moved = applyNavalMovesAndShipReveal(game, combinedTopology, {
          'gp1': [
            const NavalMoveOrder(
              fleetId: 'f2',
              destinationSeaZoneId: destSeaPrefixed,
            ),
          ],
        });
        final ended = runEndOfTurnPhase(
          moved.copyWith(
            worldState: moved.worldState.copyWith(
              turnState: const TurnState(
                phase: TurnPhase.endOfTurn,
                turnNumber: 7,
              ),
            ),
          ),
          topology: localRegionTopology,
          topologyByRegion: {ow: localRegionTopology},
        );
        final view = buildPlayerView(ended, localRegionTopology, 'gp1');

        expect(
          ended.worldState.playerVisibilityByTile['gp1']?[destSeaTileA],
          VisibilityLevel.fullyVisible.name,
        );
        expect(
          ended.worldState.playerVisibilityByTile['gp1']?[destSeaTileB],
          VisibilityLevel.fullyVisible.name,
        );
        expect(
          view.visibilityForTile(destSeaTileA),
          VisibilityLevel.fullyVisible,
        );
        expect(
          view.visibilityForTile(destSeaTileB),
          VisibilityLevel.fullyVisible,
        );
      },
    );
  });
}
