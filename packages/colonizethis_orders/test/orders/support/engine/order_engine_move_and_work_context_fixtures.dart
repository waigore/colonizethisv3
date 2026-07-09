// Shared OrderEngine move/work-context scenario fixtures (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'order_engine_core_fixtures.dart';

const oemwcOw = oecOw;

const oemwcTribeConsulate = [
  OvertureState(
    gpId: 'p1',
    targetId: 'tribe1',
    stage: OvertureStage.tradeConsulate,
  ),
];

MapTopology oemwcThreeProvinceChainTopology() => MapTopology(
      nodes: const [
        TopologyNode(
          id: 'P1',
          regionId: oemwcOw,
          type: TopologyNodeType.province,
        ),
        TopologyNode(
          id: 'P2',
          regionId: oemwcOw,
          type: TopologyNodeType.province,
        ),
        TopologyNode(
          id: 'P3',
          regionId: oemwcOw,
          type: TopologyNodeType.province,
        ),
      ],
      edges: const [
        TopologyEdge(id1: 'P1', id2: 'P2'),
        TopologyEdge(id1: 'P2', id2: 'P3'),
      ],
    );

const oemwcThreeTilesVisible = {
  'p1': {
    'oldWorld|P1|0|0': 'fullyVisible',
    'oldWorld|P2|0|0': 'fullyVisible',
    'oldWorld|P3|0|0': 'fullyVisible',
  },
};
