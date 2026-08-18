import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../world_test_support/world_test_support.dart';

/// Outcome pins for [resolveNonGreatPowerConnectivity] (Refs #4515).
typedef NonGpConnectivityCase = ({
  String description,
  Game game,
  MapTopology topology,
  Map<String, TileMapResult> tileMapByRegion,
  void Function(Map<String, ConnectivityResult> result) verify,
});

final List<NonGpConnectivityCase> nonGpConnectivityCases = [
  (
    description: 'empty map when no minors and no tribes',
    topology: singleProvinceTopology(
      regionId: 'oldWorld',
      provinceLocalId: 'p1',
    ),
    tileMapByRegion: {
      'oldWorld': tileMapFromGrid([
        ['p1', 'p1'],
        ['p1', 'p1'],
      ]),
    },
    game: ordersPhaseGame(
      oldWorldProvinces: [
        const Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'pl1'),
      ],
      players: const [Player(id: 'pl1', displayName: 'Spain', isHuman: true)],
    ),
    verify: (result) => expect(result, isEmpty),
  ),
  (
    description:
        'minor with capital and no roads: capital + 4-adjacent owned tiles connected',
    topology: singleProvinceTopology(
      regionId: 'oldWorld',
      provinceLocalId: 'p1',
    ),
    tileMapByRegion: {
      'oldWorld': tileMapFromGrid([
        ['p1', 'p1', 'p1'],
        ['p1', 'p1', 'p1'],
        ['p1', 'p1', 'p1'],
      ]),
    },
    game: ordersPhaseGame(
      oldWorldProvinces: [
        const Province(
          id: 'oldWorld|p1',
          regionId: 'oldWorld',
          ownerId: 'minor_lux',
        ),
      ],
      players: const [],
      minorNations: [
        MinorNation(
          id: 'minor_lux',
          displayName: 'Luxembourg',
          capitalProvinceId: 'oldWorld|p1',
          capitalTile: const CapitalTile(
            regionId: 'oldWorld',
            provinceId: 'oldWorld|p1',
            x: 1,
            y: 1,
          ),
        ),
      ],
    ),
    verify: (result) {
      expect(result['minor_lux'], isNotNull);
      final connected = result['minor_lux']!.connected;
      expect(connected.contains('oldWorld|p1|1|1'), isTrue);
      expect(connected.contains('oldWorld|p1|0|1'), isTrue);
      expect(connected.contains('oldWorld|p1|2|1'), isTrue);
      expect(connected.contains('oldWorld|p1|1|0'), isTrue);
      expect(connected.contains('oldWorld|p1|1|2'), isTrue);
      expect(connected.contains('oldWorld|p1|0|0'), isFalse);
    },
  ),
  (
    description:
        'tribe in NW: road chain extends connectivity beyond adjacency',
    topology: singleProvinceTopology(
      regionId: 'newWorld',
      provinceLocalId: 'p1',
    ),
    tileMapByRegion: {
      'newWorld': tileMapFromGrid([
        ['p1', 'p1', 'p1'],
        ['p1', 'p1', 'p1'],
      ]),
    },
    game: ordersPhaseGame(
      newWorldProvinces: [
        const Province(
          id: 'newWorld|p1',
          regionId: 'newWorld',
          ownerId: 'tribe_iro',
        ),
      ],
      tileState: TileMapState()
          .setRoadLevel('newWorld|p1|0|0', 1)
          .setRoadLevel('newWorld|p1|1|0', 1)
          .setRoadLevel('newWorld|p1|2|0', 1),
      players: const [],
      tribes: [
        Tribe(
          id: 'tribe_iro',
          displayName: 'Iroquois',
          capitalProvinceId: 'newWorld|p1',
          capitalTile: const CapitalTile(
            regionId: 'newWorld',
            provinceId: 'newWorld|p1',
            x: 0,
            y: 0,
          ),
        ),
      ],
    ),
    verify: (result) {
      final connected = result['tribe_iro']!.connected;
      expect(connected.contains('newWorld|p1|0|0'), isTrue);
      expect(connected.contains('newWorld|p1|1|0'), isTrue);
      expect(connected.contains('newWorld|p1|2|0'), isTrue);
      expect(connected.contains('newWorld|p1|2|1'), isTrue);
    },
  ),
  (
    description: 'multi-faction: keys map separately by minor id and tribe id',
    topology: threeProvinceDualRegionLandTopology(),
    tileMapByRegion: {
      'oldWorld': tileMapFromGrid([
        ['p1', 'p1'],
        ['p2', 'p2'],
      ]),
      'newWorld': tileMapFromGrid([
        ['p3', 'p3'],
      ]),
    },
    game: ordersPhaseGame(
      oldWorldProvinces: [
        const Province(
          id: 'oldWorld|p1',
          regionId: 'oldWorld',
          ownerId: 'minor_lux',
        ),
        const Province(
          id: 'oldWorld|p2',
          regionId: 'oldWorld',
          ownerId: 'minor_den',
        ),
      ],
      newWorldProvinces: [
        const Province(
          id: 'newWorld|p3',
          regionId: 'newWorld',
          ownerId: 'tribe_iro',
        ),
      ],
      players: const [],
      minorNations: [
        MinorNation(
          id: 'minor_lux',
          capitalProvinceId: 'oldWorld|p1',
          capitalTile: const CapitalTile(
            regionId: 'oldWorld',
            provinceId: 'oldWorld|p1',
            x: 0,
            y: 0,
          ),
        ),
        MinorNation(
          id: 'minor_den',
          capitalProvinceId: 'oldWorld|p2',
          capitalTile: const CapitalTile(
            regionId: 'oldWorld',
            provinceId: 'oldWorld|p2',
            x: 0,
            y: 1,
          ),
        ),
      ],
      tribes: [
        Tribe(
          id: 'tribe_iro',
          capitalProvinceId: 'newWorld|p3',
          capitalTile: const CapitalTile(
            regionId: 'newWorld',
            provinceId: 'newWorld|p3',
            x: 0,
            y: 0,
          ),
        ),
      ],
    ),
    verify: (result) {
      expect(result.keys.toSet(), {'minor_lux', 'minor_den', 'tribe_iro'});
      expect(
        result['minor_lux']!.connected.contains('oldWorld|p1|0|0'),
        isTrue,
      );
      expect(
        result['minor_den']!.connected.contains('oldWorld|p2|0|1'),
        isTrue,
      );
      expect(
        result['tribe_iro']!.connected.contains('newWorld|p3|0|0'),
        isTrue,
      );
      expect(
        result['minor_lux']!.connected.contains('newWorld|p3|0|0'),
        isFalse,
      );
      expect(
        result['minor_den']!.connected.contains('newWorld|p3|0|0'),
        isFalse,
      );
      expect(
        result['tribe_iro']!.connected.contains('oldWorld|p1|0|0'),
        isFalse,
      );
      expect(
        result['tribe_iro']!.connected.contains('oldWorld|p2|0|1'),
        isFalse,
      );
    },
  ),
];
