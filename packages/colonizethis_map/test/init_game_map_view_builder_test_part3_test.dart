import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('buildInitGameMapViewData', () {
    test(
      'civilian markers include explicit owner ids when isHuman is false',
      () {
        final owMap = TileMapResult(
          width: 3,
          height: 1,
          grid: [
            ['p1', 'p2', 'p3'],
          ],
        );
        final nwMap = TileMapResult(
          width: 1,
          height: 1,
          grid: [
            ['p1'],
          ],
        );
        final owTopology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'p2',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'p3',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [],
        );
        final nwTopology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [],
        );
        final game = Game(
          id: 'observe_civilian_markers',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: const [
                Province(id: 'oldWorld|p1', regionId: 'oldWorld'),
                Province(id: 'oldWorld|p2', regionId: 'oldWorld'),
                Province(id: 'oldWorld|p3', regionId: 'oldWorld'),
              ],
              units: [
                Unit(
                  id: 'u_gp1',
                  type: kUnitTypeBuilder,
                  ownerId: 'gp1',
                  locationProvinceId: 'oldWorld|p1',
                  tileKey: 'oldWorld|p1|0|0',
                  status: UnitStatus.idle,
                ),
                Unit(
                  id: 'u_gp2',
                  type: kUnitTypeExplorer,
                  ownerId: 'gp2',
                  locationProvinceId: 'oldWorld|p3',
                  tileKey: 'oldWorld|p3|2|0',
                  status: UnitStatus.idle,
                ),
              ],
            ),
            newWorld: const RegionData(
              provinces: [Province(id: 'newWorld|p1', regionId: 'newWorld')],
              units: [],
            ),
          ),
          players: const [
            Player(id: 'gp1', displayName: 'Spain', isHuman: false),
            Player(id: 'gp2', displayName: 'France', isHuman: false),
          ],
          minorNations: const [],
          tribes: const [],
        );

        final defaultView = buildInitGameMapViewData(
          game: game,
          tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
          topologyByRegion: {'oldWorld': owTopology, 'newWorld': nwTopology},
          cellSize: 8,
        );
        expect(defaultView.oldWorld.civilianTileMarkers, isEmpty);

        final observeView = buildInitGameMapViewData(
          game: game,
          tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
          topologyByRegion: {'oldWorld': owTopology, 'newWorld': nwTopology},
          cellSize: 8,
          civilianMarkerOwnerIds: {'gp1', 'gp2'},
        );
        expect(observeView.oldWorld.civilianTileMarkers, hasLength(2));
      },
    );
  });
}
