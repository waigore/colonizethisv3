import 'package:colonizethis_data/colonizethis_data.dart';

import 'sea_reachable_test_support.dart';

/// Distances-suite cases (≥320 densify, Refs #4330 Slice C).
final List<SeaReachableDistancesCase> seaReachableDistancesCases = [
  (
    description:
        'a direct province-province border foreign province has distance 1',
    topology: seaReachableTestGraph(
      provinces: const ['oldWorld|own', 'oldWorld|enemy'],
      edges: const [('oldWorld|own', 'oldWorld|enemy')],
    ),
    owners: const {'oldWorld|own': 'p1', 'oldWorld|enemy': 'p2'},
    anchors: const {'oldWorld|own'},
    regionIdFilter: null,
    expected: const {'oldWorld|enemy': 1},
  ),
  (
    description: 'counts each traversed edge, sea zone included',
    topology: seaReachableTestGraph(
      provinces: const ['oldWorld|own', 'oldWorld|enemy'],
      seas: const ['oldWorld|sea'],
      edges: const [
        ('oldWorld|own', 'oldWorld|sea'),
        ('oldWorld|sea', 'oldWorld|enemy'),
      ],
    ),
    owners: const {'oldWorld|own': 'p1', 'oldWorld|enemy': 'p2'},
    anchors: const {'oldWorld|own'},
    regionIdFilter: null,
    expected: const {'oldWorld|enemy': 2},
  ),
  (
    description: 'keeps the shortest distance when multiple paths exist',
    topology: seaReachableTestGraph(
      provinces: const ['oldWorld|own', 'oldWorld|enemy'],
      seas: const ['oldWorld|sea'],
      edges: const [
        ('oldWorld|own', 'oldWorld|enemy'),
        ('oldWorld|own', 'oldWorld|sea'),
        ('oldWorld|sea', 'oldWorld|enemy'),
      ],
    ),
    owners: const {'oldWorld|own': 'p1', 'oldWorld|enemy': 'p2'},
    anchors: const {'oldWorld|own'},
    regionIdFilter: null,
    expected: const {'oldWorld|enemy': 1},
  ),
  (
    description: 'regionIdFilter restricts the distance map entries',
    topology: seaReachableTestGraph(
      provinces: const ['oldWorld|own', 'newWorld|colony', 'oldWorld|enemy'],
      seas: const ['oldWorld|sea'],
      edges: const [
        ('oldWorld|own', 'oldWorld|sea'),
        ('oldWorld|sea', 'newWorld|colony'),
        ('oldWorld|sea', 'oldWorld|enemy'),
      ],
    ),
    owners: const {
      'oldWorld|own': 'p1',
      'newWorld|colony': 'p2',
      'oldWorld|enemy': 'p2',
    },
    anchors: const {'oldWorld|own'},
    regionIdFilter: 'newWorld',
    expected: const {'newWorld|colony': 2},
  ),
  (
    description:
        'canonical NW route via owned -> OW sea -> NW sea -> NW colony is distance 3',
    topology: seaReachableTestGraph(
      provinces: const ['oldWorld|own', 'newWorld|colony'],
      seas: const ['oldWorld|owSea', 'newWorld|nwSea'],
      edges: const [
        ('oldWorld|own', 'oldWorld|owSea'),
        ('oldWorld|owSea', 'newWorld|nwSea'),
        ('newWorld|nwSea', 'newWorld|colony'),
      ],
    ),
    owners: const {'oldWorld|own': 'p1', 'newWorld|colony': 'p2'},
    anchors: const {'oldWorld|own'},
    regionIdFilter: kNewWorldRegionId,
    expected: const {'newWorld|colony': 3},
  ),
  (
    description: 'distance BFS does not expand through foreign provinces',
    topology: seaReachableTestGraph(
      provinces: const ['oldWorld|own', 'newWorld|colony', 'newWorld|far'],
      seas: const ['newWorld|nwSea'],
      edges: const [
        ('oldWorld|own', 'newWorld|nwSea'),
        ('newWorld|nwSea', 'newWorld|colony'),
        ('newWorld|colony', 'newWorld|far'),
      ],
    ),
    owners: const {
      'oldWorld|own': 'p1',
      'newWorld|colony': 'p2',
      'newWorld|far': 'p3',
    },
    anchors: const {'oldWorld|own'},
    regionIdFilter: kNewWorldRegionId,
    expected: const {'newWorld|colony': 2},
  ),
];
