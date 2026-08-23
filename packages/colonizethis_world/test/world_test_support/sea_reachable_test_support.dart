import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/src/world/player_view.dart';

import 'topology_builders.dart';

/// PlayerView whose province ownership map is [ownersByProvinceId] (Refs #4330).
PlayerView seaReachableViewOwning(Map<String, String?> ownersByProvinceId) {
  final provincesById = <String, Province>{
    for (final entry in ownersByProvinceId.entries)
      entry.key: Province(
        id: entry.key,
        regionId: ProvinceId.regionIdFrom(entry.key),
        ownerId: entry.value,
      ),
  };
  return PlayerView(
    playerId: 'p1',
    player: const Player(id: 'p1', displayName: 'P1', isHuman: true),
    ownUnitsById: const {},
    provincesById: provincesById,
    visibilityByTile: const {},
    prospectedTiles: const {},
    diplomacyByOtherId: const {},
  );
}

/// Compact case row for [reachableNonOwnedProvinceIdsViaSeas].
typedef SeaReachableIdsCase = ({
  String description,
  MapTopology topology,
  Map<String, String?> owners,
  Set<String> anchors,
  String? regionIdFilter,
  Set<String> expected,
});

/// Compact case row for [reachableNonOwnedProvinceDistancesViaSeas].
typedef SeaReachableDistancesCase = ({
  String description,
  MapTopology topology,
  Map<String, String?> owners,
  Set<String> anchors,
  String? regionIdFilter,
  Map<String, int> expected,
});

MapTopology seaReachableTestGraph({
  required List<String> provinces,
  List<String> seas = const [],
  required List<(String, String)> edges,
}) => topologyFromGraph(
  nodes: [
    for (final id in provinces) prefixedProvinceNode(id),
    for (final id in seas) prefixedSeaZoneNode(id),
  ],
  edges: [for (final e in edges) TopologyEdge(id1: e.$1, id2: e.$2)],
);

/// Ids-suite cases (≥320 densify, Refs #4330 Slice C).
final List<SeaReachableIdsCase> seaReachableIdsCases = [
  (
    description:
        'reaches a foreign province across a sea zone from an owned anchor',
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
    expected: const {'oldWorld|enemy'},
  ),
  (
    description: 'ignores anchors the player does not actually own',
    topology: seaReachableTestGraph(
      provinces: const ['oldWorld|own', 'oldWorld|enemy'],
      edges: const [('oldWorld|own', 'oldWorld|enemy')],
    ),
    owners: const {'oldWorld|own': 'p2', 'oldWorld|enemy': 'p3'},
    anchors: const {'oldWorld|own'},
    regionIdFilter: null,
    expected: const {},
  ),
  (
    description: 'does not expand through a foreign province',
    topology: seaReachableTestGraph(
      provinces: const ['oldWorld|own', 'oldWorld|enemy', 'oldWorld|beyond'],
      edges: const [
        ('oldWorld|own', 'oldWorld|enemy'),
        ('oldWorld|enemy', 'oldWorld|beyond'),
      ],
    ),
    owners: const {
      'oldWorld|own': 'p1',
      'oldWorld|enemy': 'p2',
      'oldWorld|beyond': 'p3',
    },
    anchors: const {'oldWorld|own'},
    regionIdFilter: null,
    expected: const {'oldWorld|enemy'},
  ),
  (
    description: 'skips unowned (ownerless) provinces',
    topology: seaReachableTestGraph(
      provinces: const ['oldWorld|own', 'oldWorld|wild'],
      edges: const [('oldWorld|own', 'oldWorld|wild')],
    ),
    owners: const {'oldWorld|own': 'p1', 'oldWorld|wild': null},
    anchors: const {'oldWorld|own'},
    regionIdFilter: null,
    expected: const {},
  ),
  (
    description: 'regionIdFilter restricts collected foreign provinces',
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
    expected: const {'newWorld|colony'},
  ),
];
