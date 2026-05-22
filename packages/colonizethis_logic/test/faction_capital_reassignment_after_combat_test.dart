import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  suppressLogsForTests();

  group('applyFactionCapitalReassignmentAfterCombat', () {
    const ow = 'oldWorld';

    MapTopology buildTopology({required Iterable<String> seaboards}) {
      return MapTopology(
        nodes: [
          const TopologyNode(
            id: 'P1',
            regionId: ow,
            type: TopologyNodeType.province,
          ),
          const TopologyNode(
            id: 'P2',
            regionId: ow,
            type: TopologyNodeType.province,
          ),
          const TopologyNode(
            id: 'P3',
            regionId: ow,
            type: TopologyNodeType.province,
          ),
          const TopologyNode(
            id: 'sea1',
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: [
          for (final id in seaboards) TopologyEdge(id1: id, id2: 'sea1'),
        ],
      );
    }

    test(
      'reassigns minor nation capital to deterministic seaboard owned province in original region',
      () {
        final topology = buildTopology(seaboards: const ['P2']);
        final game = Game(
          id: 'g-minor-reassign',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 5),
            oldWorld: const RegionData(
              provinces: [
                Province(
                  id: '$ow|P1',
                  regionId: ow,
                  ownerId: 'human_1',
                  townTileKey: '$ow|P1|0|0',
                ),
                Province(
                  id: '$ow|P2',
                  regionId: ow,
                  ownerId: 'minor_1',
                  townTileKey: '$ow|P2|2|2',
                ),
                Province(
                  id: '$ow|P3',
                  regionId: ow,
                  ownerId: 'minor_1',
                  townTileKey: '$ow|P3|3|3',
                ),
              ],
            ),
            newWorld: const RegionData(),
            portsByProvinceSeaboard: const {'$ow|P1|sea1': '$ow|P1|0|0'},
          ),
          players: const [
            Player(id: 'human_1', displayName: 'Human', isHuman: true),
          ],
          minorNations: const [
            MinorNation(
              id: 'minor_1',
              displayName: 'Minor',
              capitalProvinceId: '$ow|P1',
              capitalTile: CapitalTile(
                regionId: ow,
                provinceId: '$ow|P1',
                x: 0,
                y: 0,
              ),
            ),
          ],
        );

        final portsBefore = game.worldState.portsByProvinceSeaboard;
        final tileStateBefore = game.worldState.tileState;
        final next = applyFactionCapitalReassignmentAfterCombat(
          game,
          topology,
        );

        final minor = next.minorNations.single;
        expect(minor.capitalProvinceId, '$ow|P2');
        expect(minor.capitalTile!.toTileKey(), '$ow|P2|2|2');
        expect(next.worldState.portsByProvinceSeaboard, portsBefore);
        expect(next.worldState.tileState, tileStateBefore);
        final p2 = next.worldState.oldWorld.provinces
            .firstWhere((p) => p.id == '$ow|P2');
        expect(p2.townDevelopmentLevel, 0);
      },
    );

    test(
      'reassigns tribe capital using same deterministic picker with no port/road side effects',
      () {
        final topology = buildTopology(seaboards: const ['P2', 'P3']);
        final game = Game(
          id: 'g-tribe-reassign',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 5),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'human_1', displayName: 'Human', isHuman: true),
          ],
        );
        const newWorldId = 'newWorld';
        final tribeGame = game.copyWith(
          worldState: game.worldState.copyWith(
            newWorld: const RegionData(
              provinces: [
                Province(
                  id: '$newWorldId|P1',
                  regionId: newWorldId,
                  ownerId: 'human_1',
                  townTileKey: '$newWorldId|P1|0|0',
                ),
                Province(
                  id: '$newWorldId|P2',
                  regionId: newWorldId,
                  ownerId: 'tribe_1',
                  townTileKey: '$newWorldId|P2|1|1',
                ),
                Province(
                  id: '$newWorldId|P3',
                  regionId: newWorldId,
                  ownerId: 'tribe_1',
                  townTileKey: '$newWorldId|P3|3|3',
                ),
              ],
            ),
          ),
          tribes: const [
            Tribe(
              id: 'tribe_1',
              displayName: 'Tribe',
              capitalProvinceId: '$newWorldId|P1',
              capitalTile: CapitalTile(
                regionId: newWorldId,
                provinceId: '$newWorldId|P1',
                x: 0,
                y: 0,
              ),
            ),
          ],
        );

        final nwTopology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'P1',
              regionId: newWorldId,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'P2',
              regionId: newWorldId,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'P3',
              regionId: newWorldId,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'sea1',
              regionId: newWorldId,
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [
            TopologyEdge(id1: 'P2', id2: 'sea1'),
            TopologyEdge(id1: 'P3', id2: 'sea1'),
          ],
        );

        final next = applyFactionCapitalReassignmentAfterCombat(
          tribeGame,
          topology,
          topologyByRegion: {newWorldId: nwTopology},
        );

        final tribe = next.tribes.single;
        expect(tribe.capitalProvinceId, '$newWorldId|P2');
        expect(tribe.capitalTile!.toTileKey(), '$newWorldId|P2|1|1');
      },
    );

    test(
      'clears minor capital when no eligible reassignment exists in original region',
      () {
        final game = Game(
          id: 'g-minor-clear',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 5),
            oldWorld: const RegionData(
              provinces: [
                Province(
                  id: '$ow|P1',
                  regionId: ow,
                  ownerId: 'human_1',
                  townTileKey: '$ow|P1|0|0',
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'human_1', displayName: 'Human', isHuman: true),
          ],
          minorNations: const [
            MinorNation(
              id: 'minor_1',
              displayName: 'Minor',
              capitalProvinceId: '$ow|P1',
              capitalTile: CapitalTile(
                regionId: ow,
                provinceId: '$ow|P1',
                x: 0,
                y: 0,
              ),
            ),
          ],
        );

        final next = applyFactionCapitalReassignmentAfterCombat(
          game,
          const MapTopology(),
        );

        final minor = next.minorNations.single;
        expect(minor.capitalProvinceId, isNull);
        expect(minor.capitalTile, isNull);
      },
    );

    test('does not modify minor/tribe still owning their original capital', () {
      final game = Game(
        id: 'g-minor-no-change',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(
            provinces: [
              Province(
                id: '$ow|P1',
                regionId: ow,
                ownerId: 'minor_1',
                townTileKey: '$ow|P1|0|0',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'human_1', displayName: 'Human', isHuman: true),
        ],
        minorNations: const [
          MinorNation(
            id: 'minor_1',
            displayName: 'Minor',
            capitalProvinceId: '$ow|P1',
            capitalTile: CapitalTile(
              regionId: ow,
              provinceId: '$ow|P1',
              x: 0,
              y: 0,
            ),
          ),
        ],
      );

      final next = applyFactionCapitalReassignmentAfterCombat(
        game,
        const MapTopology(),
      );

      expect(next.minorNations.single.capitalProvinceId, '$ow|P1');
      expect(next.minorNations.single.capitalTile!.toTileKey(), '$ow|P1|0|0');
    });
  });

  group('applyFactionTerminalFall', () {
    const ow = 'oldWorld';
    const nw = 'newWorld';

    test(
      'minor falls when no owned provinces remain in original capital region; '
      'all provinces and units/fleets transferred or removed',
      () {
        final game = Game(
          id: 'g-minor-fall',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 7),
            oldWorld: RegionData(
              provinces: const [
                Province(
                  id: '$ow|P1',
                  regionId: ow,
                  ownerId: 'human_1',
                  townTileKey: '$ow|P1|0|0',
                ),
                Province(
                  id: '$ow|P2',
                  regionId: ow,
                  ownerId: 'human_1',
                  townTileKey: '$ow|P2|1|1',
                ),
              ],
              units: [
                Unit(
                  id: 'unit_1',
                  type: 'peasant_levies',
                  ownerId: 'minor_1',
                  locationProvinceId: '$ow|P2',
                ),
              ],
            ),
            newWorld: const RegionData(
              provinces: [
                Province(
                  id: '$nw|N1',
                  regionId: nw,
                  ownerId: 'minor_1',
                  townTileKey: '$nw|N1|2|2',
                ),
              ],
            ),
            fleets: [
              Fleet(
                id: 'fleet_1',
                ownerId: 'minor_1',
                regionId: nw,
                seaZoneId: '$nw|sea1',
              ),
              Fleet(
                id: 'fleet_2',
                ownerId: 'human_1',
                regionId: nw,
                seaZoneId: '$nw|sea1',
              ),
            ],
          ),
          players: const [
            Player(id: 'human_1', displayName: 'Human', isHuman: true),
          ],
          minorNations: const [
            MinorNation(id: 'minor_1', displayName: 'Minor'),
          ],
        );

        final next = applyFactionTerminalFall(
          game,
          previousCapitalByMinor: const {'minor_1': '$ow|P1'},
          previousCapitalByTribe: const {},
        );

        expect(next.minorNations, isEmpty);
        final nwProvince = next.worldState.newWorld.provinces.single;
        expect(nwProvince.id, '$nw|N1');
        expect(nwProvince.ownerId, 'human_1');
        expect(next.worldState.oldWorld.units, isEmpty);
        expect(next.worldState.fleets.length, 1);
        expect(next.worldState.fleets.single.ownerId, 'human_1');
      },
    );

    test(
      'tribe falls when no owned provinces remain in original capital region',
      () {
        final game = Game(
          id: 'g-tribe-fall',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 7),
            oldWorld: const RegionData(),
            newWorld: const RegionData(
              provinces: [
                Province(
                  id: '$nw|N1',
                  regionId: nw,
                  ownerId: 'human_1',
                  townTileKey: '$nw|N1|0|0',
                ),
              ],
            ),
          ),
          players: const [
            Player(id: 'human_1', displayName: 'Human', isHuman: true),
          ],
          tribes: const [Tribe(id: 'tribe_1', displayName: 'Tribe')],
        );

        final next = applyFactionTerminalFall(
          game,
          previousCapitalByMinor: const {},
          previousCapitalByTribe: const {'tribe_1': '$nw|N1'},
        );

        expect(next.tribes, isEmpty);
      },
    );

    test(
      'no fall when minor still owns provinces in original capital region',
      () {
        final game = Game(
          id: 'g-minor-no-fall',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: const RegionData(
              provinces: [
                Province(
                  id: '$ow|P1',
                  regionId: ow,
                  ownerId: 'human_1',
                  townTileKey: '$ow|P1|0|0',
                ),
                Province(
                  id: '$ow|P2',
                  regionId: ow,
                  ownerId: 'minor_1',
                  townTileKey: '$ow|P2|1|1',
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'human_1', displayName: 'Human', isHuman: true),
          ],
          minorNations: const [
            MinorNation(id: 'minor_1', displayName: 'Minor'),
          ],
        );

        final next = applyFactionTerminalFall(
          game,
          previousCapitalByMinor: const {'minor_1': '$ow|P1'},
          previousCapitalByTribe: const {},
        );

        expect(next.minorNations, isNotEmpty);
        expect(next.worldState.oldWorld.provinces.length, 2);
      },
    );

    test(
      'no fall when minor still owns the previous capital province '
      '(skipped without trigger)',
      () {
        final game = Game(
          id: 'g-minor-still-capital',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: const RegionData(
              provinces: [
                Province(
                  id: '$ow|P1',
                  regionId: ow,
                  ownerId: 'minor_1',
                  townTileKey: '$ow|P1|0|0',
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'human_1', displayName: 'Human', isHuman: true),
          ],
          minorNations: const [
            MinorNation(id: 'minor_1', displayName: 'Minor'),
          ],
        );

        final next = applyFactionTerminalFall(
          game,
          previousCapitalByMinor: const {'minor_1': '$ow|P1'},
          previousCapitalByTribe: const {},
        );

        expect(next.minorNations, isNotEmpty);
      },
    );
  });
}
