import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../world_test_support/world_test_support.dart';
import 'connectivity_resolver_non_gp_cases.dart';

void main() {
  _connectivity_resolver_non_gp_testTests();
}

void _connectivity_resolver_non_gp_testTests() {
  group('resolveNonGreatPowerConnectivity', () {
    for (final case_ in nonGpConnectivityCases) {
      test(case_.description, () {
        case_.verify(
          resolveNonGreatPowerConnectivity(
            game: case_.game,
            tileMapByRegion: case_.tileMapByRegion,
            topology: case_.topology,
          ),
        );
      });
    }

    for (final case_ in _nullCapitalCases) {
      test(case_.description, () {
        final result = resolveNonGreatPowerConnectivity(
          game: case_.game,
          tileMapByRegion: case_.tileMapByRegion,
          topology: case_.topology,
        );

        expect(result[case_.factionId], isNotNull);
        expect(result[case_.factionId]!.connected, isEmpty);
        if (case_.assertEmptyPathMaps) {
          expect(result[case_.factionId]!.pathTransportCap, isEmpty);
          expect(result[case_.factionId]!.connectedByRoadRule, isEmpty);
        }
      });
    }
  });
}

typedef _NullCapitalCase = ({
  String description,
  String factionId,
  Game game,
  MapTopology topology,
  Map<String, TileMapResult> tileMapByRegion,
  bool assertEmptyPathMaps,
});

List<_NullCapitalCase> get _nullCapitalCases {
  const ow = 'oldWorld';
  const nw = 'newWorld';
  return [
    (
      description: 'minor with null capitalTile gets empty ConnectivityResult',
      factionId: 'minor_lux',
      assertEmptyPathMaps: true,
      topology: singleProvinceTopology(regionId: ow, provinceLocalId: 'p1'),
      tileMapByRegion: {
        'oldWorld': tileMapFromGrid([
          ['p1', 'p1'],
        ]),
      },
      game: ordersPhaseGame(
        oldWorldProvinces: [
          Province(id: '$ow|p1', regionId: ow, ownerId: 'minor_lux'),
        ],
        players: const [],
        minorNations: [const MinorNation(id: 'minor_lux')],
      ),
    ),
    (
      description: 'tribe with null capitalTile gets empty ConnectivityResult',
      factionId: 'tribe_iro',
      assertEmptyPathMaps: false,
      topology: singleProvinceTopology(regionId: nw, provinceLocalId: 'p1'),
      tileMapByRegion: {
        'newWorld': tileMapFromGrid([
          ['p1'],
        ]),
      },
      game: ordersPhaseGame(
        newWorldProvinces: [
          Province(id: '$nw|p1', regionId: nw, ownerId: 'tribe_iro'),
        ],
        players: const [],
        tribes: [const Tribe(id: 'tribe_iro')],
      ),
    ),
  ];
}
