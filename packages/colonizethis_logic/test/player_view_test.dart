import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_test/game_test_fixtures.dart';

void main() {
  group('PlayerView', () {
    test('buildPlayerView collects own units, provinces and diplomacy', () {
      final player = const Player(
        id: 'gp1',
        displayName: 'Test GP',
        isHuman: false,
      );
      final otherPlayer = const Player(
        id: 'gp2',
        displayName: 'Other GP',
        isHuman: false,
      );

      const ow = 'oldWorld';
      final p1 = Province(id: '$ow|p1', regionId: ow, displayName: 'P1');
      final p2 = Province(
        id: '$ow|p2',
        regionId: ow,
        displayName: 'P2',
        ownerId: 'gp2',
      );

      final u1 = TestFixtures.testMilitaryUnit(
        id: 'u1',
        type: 'inf',
        ownerId: 'gp1',
        locationProvinceId: '$ow|p1',
      );
      final u2 = TestFixtures.testMilitaryUnit(
        id: 'u2',
        type: 'inf',
        ownerId: 'gp2',
        locationProvinceId: '$ow|p2',
      );

      final world = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(provinces: [p1, p2], units: [u1, u2]),
        newWorld: const RegionData(),
        playerVisibilityByTile: const {
          'gp1': {'oldWorld|p1|0|0': 'fullyVisible'},
        },
        playerProspectedTiles: const {
          'gp1': {'oldWorld|p1|0|0'},
        },
      );

      final relation = const DiplomacyRelation(
        factionId1: 'gp1',
        factionId2: 'gp2',
      );

      final game = Game(
        id: 'g1',
        worldState: world,
        players: [player, otherPlayer],
        diplomacyRelations: [relation],
      );

      final topology = MapTopology(nodes: const [], edges: const []);

      final view = buildPlayerView(game, topology, 'gp1');

      expect(view.playerId, 'gp1');
      expect(view.player.id, 'gp1');

      // Own units: only u1 should be visible as owned by gp1.
      expect(view.ownUnitsById.length, 1);
      expect(view.ownUnitsById['u1'], isNotNull);
      expect(view.ownUnitsById['u1']!.ownerId, 'gp1');

      // Provinces: keyed by regionId|provinceId so both regions can share ids.
      expect(
        view.provincesById.keys,
        containsAll(<String>['oldWorld|p1', 'oldWorld|p2']),
      );
      expect(view.provinceByRegionAndId('oldWorld', 'p1')?.displayName, 'P1');
      expect(view.provinceByRegionAndId('oldWorld', 'p2')?.ownerId, 'gp2');

      // Diplomacy: relation with gp2 is indexed.
      final rel = view.relationWith('gp2');
      expect(rel, isNotNull);
      expect(rel!.factionId1 == 'gp1' || rel.factionId2 == 'gp1', isTrue);

      // relationWith when player is factionId2 (other is factionId1)
      final viewGp2 = buildPlayerView(game, topology, 'gp2');
      final relGp2 = viewGp2.relationWith('gp1');
      expect(relGp2, isNotNull);
      expect(relGp2!.factionId1, 'gp1');
      expect(relGp2.factionId2, 'gp2');

      // provinceByRegionAndId with prefixed id
      expect(
        view.provinceByRegionAndId('oldWorld', 'oldWorld|p1')?.displayName,
        'P1',
      );

      // unitsInProvince with local id
      expect(view.unitsInProvince('oldWorld', 'p1').map((u) => u.id).toList(), [
        'u1',
      ]);

      // Visibility and prospection: values are propagated from WorldState.
      expect(
        view.visibilityForTile('oldWorld|p1|0|0'),
        VisibilityLevel.fullyVisible,
      );
      expect(view.tileIsProspected('oldWorld|p1|0|0'), isTrue);
    });

    test('buildPlayerView maps unknown visibility level name to unknown', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          playerVisibilityByTile: {
            'gp1': {'tileA': 'fullyVisible', 'tileB': 'NotARealLevelName'},
          },
        ),
        players: const [Player(id: 'gp1', displayName: 'P', isHuman: true)],
      );
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, 'gp1');
      expect(view.visibilityByTile['tileA'], VisibilityLevel.fullyVisible);
      expect(view.visibilityByTile['tileB'], VisibilityLevel.unknown);
    });

    test(
      'resourceIdVisibleToPlayer hides prospect minerals until prospected',
      () {
        expect(
          resourceIdVisibleToPlayer(
            authoritativeResourceId: 'gold',
            visibility: VisibilityLevel.fullyVisible,
            tileProspectedByPlayer: false,
          ),
          isNull,
        );
        expect(
          resourceIdVisibleToPlayer(
            authoritativeResourceId: 'gold',
            visibility: VisibilityLevel.fullyVisible,
            tileProspectedByPlayer: true,
          ),
          'gold',
        );
        expect(
          resourceIdVisibleToPlayer(
            authoritativeResourceId: 'grain',
            visibility: VisibilityLevel.fullyVisible,
            tileProspectedByPlayer: false,
          ),
          'grain',
        );
      },
    );

    test('resourceIdVisibleToPlayer hides all resources when unknown', () {
      expect(
        resourceIdVisibleToPlayer(
          authoritativeResourceId: 'grain',
          visibility: VisibilityLevel.unknown,
          tileProspectedByPlayer: false,
        ),
        isNull,
      );
    });

    test(
      'resourceIdVisibleToPlayer hides prospect minerals when fogged and not prospected',
      () {
        expect(
          resourceIdVisibleToPlayer(
            authoritativeResourceId: 'iron',
            visibility: VisibilityLevel.fogged,
            tileProspectedByPlayer: false,
          ),
          isNull,
        );
        expect(
          resourceIdVisibleToPlayer(
            authoritativeResourceId: 'timber',
            visibility: VisibilityLevel.fogged,
            tileProspectedByPlayer: false,
          ),
          'timber',
        );
      },
    );

    test('buildPlayerView throws when playerId not in game', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      const topology = MapTopology(nodes: [], edges: []);
      expect(
        () => buildPlayerView(game, topology, 'nonexistent'),
        throwsA(isA<LogicValidationException>()),
      );
    });

    test('other player does not see our Spy (Spy invisible to non-owners)', () {
      const ow = 'oldWorld';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
              Province(id: '$ow|p2', regionId: ow, ownerId: 'gp2'),
            ],
            units: [
              Unit(
                id: 'spy1',
                type: kUnitTypeSpy,
                ownerId: 'gp1',
                locationProvinceId: '$ow|p2',
                tileKey: '$ow|p2|0|0',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'GP1', isHuman: true),
          Player(id: 'gp2', displayName: 'GP2', isHuman: true),
        ],
      );
      final topology = MapTopology(nodes: const [], edges: const []);
      final viewP2 = buildPlayerView(game, topology, 'gp2');
      expect(viewP2.ownUnitsById, isEmpty);
      expect(viewP2.ownUnitsById.containsKey('spy1'), isFalse);
    });

    test(
      'Spy in other-faction province makes that province tiles fully visible for Spy owner',
      () {
        const ow = 'oldWorld';
        const tileKeyP2 = 'oldWorld|p2|0|0';
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
                Province(id: '$ow|p2', regionId: ow, ownerId: 'gp2'),
              ],
              units: [
                Unit(
                  id: 'spy1',
                  type: kUnitTypeSpy,
                  ownerId: 'gp1',
                  locationProvinceId: '$ow|p2',
                  tileKey: tileKeyP2,
                ),
              ],
            ),
            newWorld: const RegionData(),
            tileKeysByRegionAndProvince: {
              ow: {
                '$ow|p2': [tileKeyP2],
              },
            },
          ),
          players: const [
            Player(id: 'gp1', displayName: 'GP1', isHuman: true),
            Player(id: 'gp2', displayName: 'GP2', isHuman: true),
          ],
        );
        final topology = MapTopology(nodes: const [], edges: const []);
        final viewGp1 = buildPlayerView(game, topology, 'gp1');
        expect(
          viewGp1.visibilityForTile(tileKeyP2),
          VisibilityLevel.fullyVisible,
        );
      },
    );

    test(
      'province panel intel shows for own province even if tiles are fogged',
      () {
        const ow = 'oldWorld';
        const provinceId = '$ow|p1';
        const tileKey = '$provinceId|0|0';
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(id: provinceId, regionId: ow, ownerId: 'gp1'),
              ],
            ),
            newWorld: const RegionData(),
            tileKeysByRegionAndProvince: {
              ow: {
                provinceId: [tileKey],
              },
            },
            playerVisibilityByTile: const {
              'gp1': {tileKey: 'fogged'},
            },
          ),
          players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
        );
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, 'gp1');
        expect(
          provincePanelShowsFullTileDerivedIntel(
            game: game,
            view: view,
            humanPlayerId: 'gp1',
            provinceId: provinceId,
          ),
          isTrue,
        );
      },
    );

    test(
      'province panel intel is hidden for foreign province with partial visibility and no spy intel',
      () {
        const ow = 'oldWorld';
        const provinceId = '$ow|p2';
        const tileA = '$provinceId|0|0';
        const tileB = '$provinceId|0|1';
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(id: provinceId, regionId: ow, ownerId: 'gp2'),
              ],
            ),
            newWorld: const RegionData(),
            tileKeysByRegionAndProvince: {
              ow: {
                provinceId: [tileA, tileB],
              },
            },
            playerVisibilityByTile: const {
              'gp1': {tileA: 'fullyVisible', tileB: 'fogged'},
            },
          ),
          players: const [
            Player(id: 'gp1', displayName: 'GP1', isHuman: true),
            Player(id: 'gp2', displayName: 'GP2', isHuman: false),
          ],
        );
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, 'gp1');
        expect(
          provincePanelShowsFullTileDerivedIntel(
            game: game,
            view: view,
            humanPlayerId: 'gp1',
            provinceId: provinceId,
          ),
          isFalse,
        );
      },
    );

  });
}
