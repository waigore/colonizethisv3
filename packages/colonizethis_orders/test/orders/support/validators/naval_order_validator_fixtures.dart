// Shared NavalOrderValidator topology and validator presets (Refs #3949).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_orders/src/orders/validators/naval_order_validator.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'naval_order_validator_test_support.dart';

MapTopology novSingleSea() => navalOrderValidatorTestTopology(
  nodes: [navalOrderValidatorTestSeaNode('sea1')],
);

MapTopology novTwoAdjacentSeas() => navalOrderValidatorTestTopology(
  nodes: [
    navalOrderValidatorTestSeaNode('sea1'),
    navalOrderValidatorTestSeaNode('sea2'),
  ],
  edges: const [TopologyEdge(id1: 'sea1', id2: 'sea2')],
);

MapTopology novThreeSeasLinear() => navalOrderValidatorTestTopology(
  nodes: [
    navalOrderValidatorTestSeaNode('sea1'),
    navalOrderValidatorTestSeaNode('sea2'),
    navalOrderValidatorTestSeaNode('sea3'),
  ],
  edges: const [TopologyEdge(id1: 'sea1', id2: 'sea2')],
);

MapTopology novSeaProvinceAdjacent({String provinceLocalId = 'P1'}) =>
    navalOrderValidatorTestTopology(
      nodes: [
        navalOrderValidatorTestSeaNode('sea1'),
        navalOrderValidatorTestProvinceNode(provinceLocalId),
      ],
      edges: [TopologyEdge(id1: 'sea1', id2: provinceLocalId)],
    );

MapTopology novTwoSeasOneProvince({required List<TopologyEdge> edges}) =>
    navalOrderValidatorTestTopology(
      nodes: [
        navalOrderValidatorTestSeaNode('sea1'),
        navalOrderValidatorTestSeaNode('sea2'),
        navalOrderValidatorTestProvinceNode('P1'),
      ],
      edges: edges,
    );

MapTopology novTwoSeasProvinceDockMismatch() => novTwoSeasOneProvince(
  edges: const [
    TopologyEdge(id1: 'sea1', id2: 'sea2'),
    TopologyEdge(id1: 'sea2', id2: 'P1'),
  ],
);

MapTopology novPortDualSea() => novTwoSeasOneProvince(
  edges: const [
    TopologyEdge(id1: 'P1', id2: 'sea1'),
    TopologyEdge(id1: 'P1', id2: 'sea2'),
  ],
);

MapTopology novPortSeaChain() => novTwoSeasOneProvince(
  edges: const [
    TopologyEdge(id1: 'P1', id2: 'sea1'),
    TopologyEdge(id1: 'sea1', id2: 'sea2'),
  ],
);

const novTwoHumanPlayers = [
  Player(id: 'p1', displayName: 'P1', isHuman: true),
  Player(id: 'p2', displayName: 'P2', isHuman: true),
];

List<Province> novOwnedP1Provinces() => [
  navalOrderValidatorTestOwnedProvince('P1'),
];

NavalOrderValidator novValidatorAtSea({
  required MapTopology topology,
  List<Fleet>? fleets,
  List<Province>? oldWorldProvinces,
  List<Player>? players,
}) => navalOrderValidatorForTest(
  game: navalOrderValidatorTestGame(
    fleets: fleets ?? [navalOrderValidatorTestFleetAtSea()],
    oldWorldProvinces: oldWorldProvinces ?? const [],
    players:
        players ??
        const [
          Player(
            id: kNavalOrderValidatorTestPlayerId,
            displayName: 'P1',
            isHuman: true,
          ),
        ],
  ),
  topology: topology,
);

NavalOrderValidator novValidatorInPort({
  required MapTopology topology,
  List<Fleet>? fleets,
  String portLocalId = 'P1',
}) => navalOrderValidatorForTest(
  game: navalOrderValidatorTestGame(
    oldWorldProvinces: novOwnedP1Provinces(),
    fleets: fleets ?? [navalOrderValidatorTestFleetInPort()],
  ),
  topology: topology,
);
