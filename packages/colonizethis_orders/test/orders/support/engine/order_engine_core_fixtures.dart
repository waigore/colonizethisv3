// Shared OrderEngine core scenario fixtures (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const oecOw = 'oldWorld';

MapTopology oecTwoProvinceTopology() => MapTopology(
      nodes: const [
        TopologyNode(
          id: 'P1',
          regionId: oecOw,
          type: TopologyNodeType.province,
        ),
        TopologyNode(
          id: 'P2',
          regionId: oecOw,
          type: TopologyNodeType.province,
        ),
      ],
      edges: const [TopologyEdge(id1: 'P1', id2: 'P2')],
    );

MapTopology oecSingleProvinceTopology() => MapTopology(
      nodes: const [
        TopologyNode(
          id: 'P1',
          regionId: oecOw,
          type: TopologyNodeType.province,
        ),
      ],
      edges: const [],
    );

const oecBothTilesVisible = {
  'p1': {
    'oldWorld|P1|0|0': 'fullyVisible',
    'oldWorld|P2|0|0': 'fullyVisible',
  },
};

const oecP1VisibleP2Fogged = {
  'p1': {
    'oldWorld|P1|0|0': 'fullyVisible',
    'oldWorld|P2|0|0': 'fogged',
  },
};

Game oecBuilderOnP1Game({
  Map<String, Map<String, String>>? playerVisibilityByTile,
  String p2OwnerId = 'p1',
}) =>
    Game(
      id: 'g1',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
        oldWorld: RegionData(
          provinces: [
            Province(id: '$oecOw|P1', regionId: oecOw, ownerId: 'p1'),
            Province(id: '$oecOw|P2', regionId: oecOw, ownerId: p2OwnerId),
          ],
          units: [
            Unit(
              id: 'u1',
              type: kUnitTypeBuilder,
              ownerId: 'p1',
              locationProvinceId: '$oecOw|P1',
            ),
          ],
        ),
        newWorld: const RegionData(),
        playerVisibilityByTile: playerVisibilityByTile ?? oecBothTilesVisible,
      ),
      players: p2OwnerId == 'p2'
          ? const [
              Player(id: 'p1', displayName: 'P1', isHuman: true),
              Player(id: 'p2', displayName: 'P2', isHuman: true),
            ]
          : const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      diplomacyRelations: const [],
    );

Game oecExplorerOnP1Game({
  Map<String, Map<String, String>>? playerVisibilityByTile,
  String p2OwnerId = 'p1',
  List<Tribe> tribes = const [],
}) =>
    Game(
      id: 'g1',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
        oldWorld: RegionData(
          provinces: [
            Province(id: '$oecOw|P1', regionId: oecOw, ownerId: 'p1'),
            Province(id: '$oecOw|P2', regionId: oecOw, ownerId: p2OwnerId),
          ],
          units: [
            Unit(
              id: 'u1',
              type: kUnitTypeExplorer,
              ownerId: 'p1',
              locationProvinceId: '$oecOw|P1',
            ),
          ],
        ),
        newWorld: const RegionData(),
        playerVisibilityByTile: playerVisibilityByTile ?? const {},
      ),
      players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      tribes: tribes,
    );

Game oecMilitaryOnP1Game() => Game(
      id: 'g1',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
        oldWorld: RegionData(
          provinces: [
            Province(id: '$oecOw|P1', regionId: oecOw, ownerId: 'p1'),
            Province(id: '$oecOw|P2', regionId: oecOw, ownerId: 'p2'),
          ],
          units: [
            Unit(
              id: 'u1',
              type: 'pikemen',
              ownerId: 'p1',
              locationProvinceId: '$oecOw|P1',
            ),
          ],
        ),
        newWorld: const RegionData(),
        armies: [
          Army(
            id: fieldArmyIdFor('p1', '$oecOw|P1'),
            ownerId: 'p1',
            regionId: oecOw,
            stationedProvinceId: '$oecOw|P1',
            regimentUnitIds: const ['u1'],
            isHomeArmy: false,
          ),
        ],
        playerVisibilityByTile: oecP1VisibleP2Fogged,
      ),
      players: const [
        Player(id: 'p1', displayName: 'P1', isHuman: true),
        Player(id: 'p2', displayName: 'P2', isHuman: true),
      ],
      diplomacyRelations: const [],
    );

OrderEngine oecProjectorEngine() => OrderEngine(projector: projectOrderEffects);
