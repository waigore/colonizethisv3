import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'army_move_picker_destinations_test_support.dart';

void main() {
  test('picker includes adjacent own-province move (no declare war)', () {
    const p1 = 'gp1';
    const p2 = 'gp2';
    const loc1 = '$ow|P1';
    const loc2 = '$ow|P2';
    final army = fieldArmy(ow, p1, 'P1', 'u1');
    final game = Game(
      id: 'g',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(
          provinces: [
            Province(id: loc1, regionId: ow, ownerId: p1),
            Province(id: loc2, regionId: ow, ownerId: p1),
          ],
          units: [
            Unit(
              id: 'u1',
              type: 'musketeers',
              ownerId: p1,
              locationProvinceId: loc1,
            ),
          ],
        ),
        newWorld: const RegionData(),
        armies: [army],
        playerVisibilityByTile: {
          p1: vis([(loc1, '$ow|P1|0|0'), (loc2, '$ow|P2|0|0')]),
        },
        tileKeysByRegionAndProvince: {
          ow: {
            loc1: ['$ow|P1|0|0'],
            loc2: ['$ow|P2|0|0'],
          },
        },
      ),
      players: const [
        Player(id: p1, displayName: 'A', isHuman: true),
        Player(id: p2, displayName: 'B', isHuman: true),
      ],
    );
    final list = armyMovePickerDestinations(
      game: game,
      topology: adjacencyOw,
      playerId: p1,
      army: army,
      currentOrders: const Orders(),
    );
    expect(list.map((e) => e.fullProvinceId), contains(loc2));
    expect(list.every((e) => !e.requiresDeclareWarOnConfirm), isTrue);
  });

  test('picker includes cross-region own province (different landmass)', () {
    const p1 = 'gp1';
    const locOw = '$ow|P1';
    const locNw = '$nw|N1';
    final army = fieldArmy(ow, p1, 'P1', 'u1');
    final game = Game(
      id: 'g',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(
          provinces: [Province(id: locOw, regionId: ow, ownerId: p1)],
          units: [
            Unit(
              id: 'u1',
              type: 'musketeers',
              ownerId: p1,
              locationProvinceId: locOw,
            ),
          ],
        ),
        newWorld: RegionData(
          provinces: [
            Province(
              id: locNw,
              regionId: nw,
              ownerId: p1,
              displayName: 'Colony',
            ),
          ],
        ),
        armies: [army],
        playerVisibilityByTile: {
          p1: vis([(locOw, '$ow|P1|0|0'), (locNw, '$nw|N1|0|0')]),
        },
        tileKeysByRegionAndProvince: {
          ow: {
            locOw: ['$ow|P1|0|0'],
          },
          nw: {
            locNw: ['$nw|N1|0|0'],
          },
        },
      ),
      players: const [Player(id: p1, displayName: 'A', isHuman: true)],
    );
    final list = armyMovePickerDestinations(
      game: game,
      topology: const MapTopology(),
      playerId: p1,
      army: army,
      currentOrders: const Orders(),
    );
    expect(list.map((e) => e.fullProvinceId), contains(locNw));
    final nwEntry = list.firstWhere((e) => e.fullProvinceId == locNw);
    expect(nwEntry.isPlayerOwned, isTrue);
    expect(nwEntry.requiresDeclareWarOnConfirm, isFalse);
  });

  test(
    'adjacent enemy province requires declare war on confirm when at peace',
    () {
      const p1 = 'gp1';
      const p2 = 'gp2';
      const loc1 = '$ow|P1';
      const loc2 = '$ow|P2';
      final army = fieldArmy(ow, p1, 'P1', 'u1');
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: loc1, regionId: ow, ownerId: p1),
              Province(id: loc2, regionId: ow, ownerId: p2),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'musketeers',
                ownerId: p1,
                locationProvinceId: loc1,
              ),
            ],
          ),
          newWorld: const RegionData(),
          armies: [army],
          playerVisibilityByTile: {
            p1: vis([(loc1, '$ow|P1|0|0'), (loc2, '$ow|P2|0|0')]),
          },
          tileKeysByRegionAndProvince: {
            ow: {
              loc1: ['$ow|P1|0|0'],
              loc2: ['$ow|P2|0|0'],
            },
          },
        ),
        players: const [
          Player(id: p1, displayName: 'A', isHuman: true),
          Player(id: p2, displayName: 'B', isHuman: true),
        ],
        diplomacyRelations: const [],
      );
      final list = armyMovePickerDestinations(
        game: game,
        topology: adjacencyOw,
        playerId: p1,
        army: army,
        currentOrders: const Orders(),
      );
      final inv = list.firstWhere((e) => e.fullProvinceId == loc2);
      expect(inv.requiresDeclareWarOnConfirm, isTrue);
      expect(inv.ownerFactionId, p2);
    },
  );

  test('two reachable enemy provinces of same owner both require declare war '
      '(Refs #2394 trial-validator cache keyed by defender)', () {
    const p1 = 'gp1';
    const p2 = 'gp2';
    const loc1 = '$ow|P1';
    const loc2 = '$ow|P2';
    const loc3 = '$ow|P3';
    final army = fieldArmy(ow, p1, 'P1', 'u1');
    final topology = MapTopology(
      nodes: const [
        TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
        TopologyNode(id: 'P2', regionId: ow, type: TopologyNodeType.province),
        TopologyNode(id: 'P3', regionId: ow, type: TopologyNodeType.province),
      ],
      edges: const [
        TopologyEdge(id1: 'P1', id2: 'P2'),
        TopologyEdge(id1: 'P1', id2: 'P3'),
      ],
    );
    final game = Game(
      id: 'g_two_enemy_same_owner',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(
          provinces: [
            Province(id: loc1, regionId: ow, ownerId: p1),
            Province(id: loc2, regionId: ow, ownerId: p2),
            Province(id: loc3, regionId: ow, ownerId: p2),
          ],
          units: [
            Unit(
              id: 'u1',
              type: 'musketeers',
              ownerId: p1,
              locationProvinceId: loc1,
            ),
          ],
        ),
        newWorld: const RegionData(),
        armies: [army],
        playerVisibilityByTile: {
          p1: vis([
            (loc1, '$ow|P1|0|0'),
            (loc2, '$ow|P2|0|0'),
            (loc3, '$ow|P3|0|0'),
          ]),
        },
        tileKeysByRegionAndProvince: {
          ow: {
            loc1: ['$ow|P1|0|0'],
            loc2: ['$ow|P2|0|0'],
            loc3: ['$ow|P3|0|0'],
          },
        },
      ),
      players: const [
        Player(id: p1, displayName: 'A', isHuman: true),
        Player(id: p2, displayName: 'B', isHuman: true),
      ],
      diplomacyRelations: const [],
    );
    final list = armyMovePickerDestinations(
      game: game,
      topology: topology,
      playerId: p1,
      army: army,
      currentOrders: const Orders(),
    );
    final a = list.firstWhere((e) => e.fullProvinceId == loc2);
    final b = list.firstWhere((e) => e.fullProvinceId == loc3);
    expect(a.requiresDeclareWarOnConfirm, isTrue);
    expect(b.requiresDeclareWarOnConfirm, isTrue);
    expect(a.ownerFactionId, p2);
    expect(b.ownerFactionId, p2);
  });

  test('at war with enemy: invasion confirm not required', () {
    const p1 = 'gp1';
    const p2 = 'gp2';
    const loc1 = '$ow|P1';
    const loc2 = '$ow|P2';
    final army = fieldArmy(ow, p1, 'P1', 'u1');
    final game = Game(
      id: 'g',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(
          provinces: [
            Province(id: loc1, regionId: ow, ownerId: p1),
            Province(id: loc2, regionId: ow, ownerId: p2),
          ],
          units: [
            Unit(
              id: 'u1',
              type: 'musketeers',
              ownerId: p1,
              locationProvinceId: loc1,
            ),
          ],
        ),
        newWorld: const RegionData(),
        armies: [army],
        playerVisibilityByTile: {
          p1: vis([(loc1, '$ow|P1|0|0'), (loc2, '$ow|P2|0|0')]),
        },
        tileKeysByRegionAndProvince: {
          ow: {
            loc1: ['$ow|P1|0|0'],
            loc2: ['$ow|P2|0|0'],
          },
        },
      ),
      players: const [
        Player(id: p1, displayName: 'A', isHuman: true),
        Player(id: p2, displayName: 'B', isHuman: true),
      ],
      diplomacyRelations: const [
        DiplomacyRelation(
          factionId1: p1,
          factionId2: p2,
          state: RelationState.atWar,
        ),
      ],
    );
    final list = armyMovePickerDestinations(
      game: game,
      topology: adjacencyOw,
      playerId: p1,
      army: army,
      currentOrders: const Orders(),
    );
    final inv = list.firstWhere((e) => e.fullProvinceId == loc2);
    expect(inv.requiresDeclareWarOnConfirm, isFalse);
  });
}
