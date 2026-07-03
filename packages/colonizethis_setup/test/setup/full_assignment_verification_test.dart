import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_test/test.dart';

import 'init_game_orchestrator_test_support.dart';

MapTopology _topology(String regionId, List<String> provinceIds) => MapTopology(
  nodes: <TopologyNode>[
    for (final id in provinceIds)
      TopologyNode(
        id: id,
        regionId: regionId,
        type: TopologyNodeType.province,
      ),
    TopologyNode(
      id: 'sea-1',
      regionId: regionId,
      type: TopologyNodeType.seaZone,
    ),
  ],
);

WorldState _worldState({
  required List<Province> oldWorld,
  required List<Province> newWorld,
}) => WorldState(
  turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
  oldWorld: RegionData(provinces: oldWorld),
  newWorld: RegionData(provinces: newWorld),
);

Province _province(String regionId, String localId, String? ownerId) => Province(
  id: ProvinceId.full(regionId, localId),
  regionId: regionId,
  ownerId: ownerId,
);

void main() {
  group('verifyFullProvinceAssignment', () {
    final topologyByRegion = <String, MapTopology>{
      kRegionOldWorld: _topology(kRegionOldWorld, <String>['ow1', 'ow2', 'ow3']),
      kRegionNewWorld: _topology(kRegionNewWorld, <String>['nw1', 'nw2']),
    };

    test('passes when every topology province is owned', () {
      final worldState = _worldState(
        oldWorld: <Province>[
          _province(kRegionOldWorld, 'ow1', 'gp1'),
          _province(kRegionOldWorld, 'ow2', 'gp2'),
          _province(kRegionOldWorld, 'ow3', 'minor1'),
        ],
        newWorld: <Province>[
          _province(kRegionNewWorld, 'nw1', 'tribe1'),
          _province(kRegionNewWorld, 'nw2', 'tribe2'),
        ],
      );

      expect(
        () => verifyFullProvinceAssignment(
          worldState: worldState,
          topologyByRegion: topologyByRegion,
        ),
        returnsNormally,
      );
    });

    test('throws when a topology province is dropped from WorldState', () {
      final worldState = _worldState(
        oldWorld: <Province>[
          _province(kRegionOldWorld, 'ow1', 'gp1'),
          _province(kRegionOldWorld, 'ow2', 'gp2'),
          // ow3 dropped.
        ],
        newWorld: <Province>[
          _province(kRegionNewWorld, 'nw1', 'tribe1'),
          _province(kRegionNewWorld, 'nw2', 'tribe2'),
        ],
      );

      expect(
        () => verifyFullProvinceAssignment(
          worldState: worldState,
          topologyByRegion: topologyByRegion,
        ),
        throwsA(
          isA<SetupTopologyDataException>()
              .having((e) => e.code, 'code', kGaUnassignedProvincesCode)
              .having(
                (e) => e.toString(),
                'details',
                contains('${kRegionOldWorld}|ow3'),
              ),
        ),
      );
    });

    test('throws when a province ownerId is empty', () {
      final worldState = _worldState(
        oldWorld: <Province>[
          _province(kRegionOldWorld, 'ow1', 'gp1'),
          _province(kRegionOldWorld, 'ow2', 'gp2'),
          _province(kRegionOldWorld, 'ow3', ''),
        ],
        newWorld: <Province>[
          _province(kRegionNewWorld, 'nw1', 'tribe1'),
          _province(kRegionNewWorld, 'nw2', 'tribe2'),
        ],
      );

      expect(
        () => verifyFullProvinceAssignment(
          worldState: worldState,
          topologyByRegion: topologyByRegion,
        ),
        throwsA(
          isA<SetupTopologyDataException>()
              .having((e) => e.code, 'code', kGaUnassignedProvincesCode)
              .having(
                (e) => e.toString(),
                'details',
                contains('empty ownerId'),
              ),
        ),
      );
    });

    test('throws when a province ownerId is null', () {
      final worldState = _worldState(
        oldWorld: <Province>[
          _province(kRegionOldWorld, 'ow1', 'gp1'),
          _province(kRegionOldWorld, 'ow2', 'gp2'),
          _province(kRegionOldWorld, 'ow3', null),
        ],
        newWorld: <Province>[
          _province(kRegionNewWorld, 'nw1', 'tribe1'),
          _province(kRegionNewWorld, 'nw2', 'tribe2'),
        ],
      );

      expect(
        () => verifyFullProvinceAssignment(
          worldState: worldState,
          topologyByRegion: topologyByRegion,
        ),
        throwsA(
          isA<SetupTopologyDataException>().having(
            (e) => e.code,
            'code',
            kGaUnassignedProvincesCode,
          ),
        ),
      );
    });
  });

  group('default app init regression (#3447 AC6)', () {
    test(
      'GameSetupConfig.defaultConfig init is unchanged (no GA verifier on app path)',
      () {
        final init = runInitGame(
          config: GameSetupConfig.defaultConfig,
          options: defaultInitOptions,
        );

        expect(init.game.worldState.oldWorld.provinces.length, 60);
        expect(init.game.worldState.newWorld.provinces.length, 30);
        expect(
          init.game.worldState.oldWorld.provinces.every(
            (p) => p.ownerId != null && p.ownerId!.isNotEmpty,
          ),
          isTrue,
        );
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}
