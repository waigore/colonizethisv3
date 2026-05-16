import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('suggestDiplomaticOrders', () {
    test(
      'returns alliance (single diplo per target) for other GP when at peace and not allied',
      () {
        const api = DefaultOrderSuggestionAPI();
        const topology = MapTopology(nodes: [], edges: []);
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp1', displayName: 'A', isHuman: false),
            Player(id: 'gp2', displayName: 'B', isHuman: false),
          ],
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'gp2',
              state: RelationState.atPeace,
              level: RelationLevel.neutral,
            ),
          ],
        );
        final view = buildPlayerView(game, topology, 'gp1');
        final list = api.suggestDiplomaticOrders(
          view,
          game,
          topology,
          const Orders(),
        );
        final toGp2 = list.where((o) => o.targetFactionId == 'gp2').toList();
        expect(toGp2, hasLength(1));
        expect(toGp2.single.type, DiplomaticOrderType.alliance);
      },
    );

    test('returns declareWar toward GP when at peace and already allied', () {
      const api = DefaultOrderSuggestionAPI();
      const topology = MapTopology(nodes: [], edges: []);
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'A', isHuman: false),
          Player(id: 'gp2', displayName: 'B', isHuman: false),
        ],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            state: RelationState.atPeace,
            level: RelationLevel.allied,
          ),
        ],
      );
      final view = buildPlayerView(game, topology, 'gp1');
      final list = api.suggestDiplomaticOrders(
        view,
        game,
        topology,
        const Orders(),
      );
      final toGp2 = list.where((o) => o.targetFactionId == 'gp2').toList();
      expect(toGp2, hasLength(1));
      expect(toGp2.single.type, DiplomaticOrderType.declareWar);
    });

    test(
      'does not suggest diplomatic orders for completely unknown factions',
      () {
        const api = DefaultOrderSuggestionAPI();
        const topology = MapTopology(nodes: [], edges: []);
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
          ),
          players: const [Player(id: 'gp1', displayName: 'A', isHuman: false)],
          minorNations: const [
            MinorNation(id: 'minor1', displayName: 'Minor 1'),
          ],
        );
        final view = buildPlayerView(game, topology, 'gp1');
        final list = api.suggestDiplomaticOrders(
          view,
          game,
          topology,
          const Orders(),
        );
        expect(list.any((o) => o.targetFactionId == 'minor1'), isFalse);
      },
    );

    test('returns offerPeace when at war with another GP', () {
      const api = DefaultOrderSuggestionAPI();
      const topology = MapTopology(nodes: [], edges: []);
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'A', isHuman: false),
          Player(id: 'gp2', displayName: 'B', isHuman: false),
        ],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            state: RelationState.atWar,
            level: RelationLevel.hostile,
          ),
        ],
      );
      final view = buildPlayerView(game, topology, 'gp1');
      final list = api.suggestDiplomaticOrders(
        view,
        game,
        topology,
        const Orders(),
      );
      final offerPeace = list
          .where((o) => o.type == DiplomaticOrderType.offerPeace)
          .toList();
      expect(offerPeace.any((o) => o.targetFactionId == 'gp2'), isTrue);
    });

    test('returns alliance candidate when at peace and not allied', () {
      const api = DefaultOrderSuggestionAPI();
      const topology = MapTopology(nodes: [], edges: []);
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'A', isHuman: false),
          Player(id: 'gp2', displayName: 'B', isHuman: false),
        ],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            state: RelationState.atPeace,
            level: RelationLevel.friendly,
          ),
        ],
      );
      final view = buildPlayerView(game, topology, 'gp1');
      final list = api.suggestDiplomaticOrders(
        view,
        game,
        topology,
        const Orders(),
      );
      final alliance = list
          .where((o) => o.type == DiplomaticOrderType.alliance)
          .toList();
      expect(alliance.any((o) => o.targetFactionId == 'gp2'), isTrue);
    });

    test('returns establishOverture for minor when treasury suffices', () {
      const api = DefaultOrderSuggestionAPI();
      const topology = MapTopology(nodes: [], edges: []);
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: 'oldWorld|m1',
                regionId: 'oldWorld',
                ownerId: 'minor1',
              ),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'gp1': {'oldWorld|m1|0|0': 'fullyVisible'},
          },
          tileKeysByRegionAndProvince: {
            'oldWorld': {
              'oldWorld|m1': ['oldWorld|m1|0|0'],
            },
          },
        ),
        players: [
          const Player(id: 'gp1', displayName: 'A', isHuman: false).copyWith(
            treasury: 600,
            techUnlocked: const {kTechIdDiplomaticExpertise: true},
          ),
        ],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
      );
      final view = buildPlayerView(game, topology, 'gp1');
      final list = api.suggestDiplomaticOrders(
        view,
        game,
        topology,
        const Orders(),
      );
      final overture = list
          .where((o) => o.type == DiplomaticOrderType.establishOverture)
          .toList();
      expect(overture.any((o) => o.targetFactionId == 'minor1'), isTrue);
      expect(
        overture.any(
          (o) =>
              o.targetFactionId == 'minor1' &&
              o.overtureStage == OvertureStage.tradeConsulate,
        ),
        isTrue,
      );
    });

    test(
      'does not suggest tradeConsulate/embassy/nap overture toward minor without diplomatic expertise',
      () {
        const api = DefaultOrderSuggestionAPI();
        const topology = MapTopology(nodes: [], edges: []);
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: 'oldWorld|m1',
                  regionId: 'oldWorld',
                  ownerId: 'minor1',
                ),
              ],
            ),
            newWorld: const RegionData(),
            playerVisibilityByTile: const {
              'gp1': {'oldWorld|m1|0|0': 'fullyVisible'},
            },
            tileKeysByRegionAndProvince: {
              'oldWorld': {
                'oldWorld|m1': ['oldWorld|m1|0|0'],
              },
            },
          ),
          players: [
            const Player(id: 'gp1', displayName: 'A', isHuman: false).copyWith(
              treasury: 600,
              techUnlocked: const <String, bool>{},
            ),
          ],
          minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'minor1',
              state: RelationState.atPeace,
              level: RelationLevel.neutral,
            ),
          ],
        );
        final view = buildPlayerView(game, topology, 'gp1');
        final list = api.suggestDiplomaticOrders(
          view,
          game,
          topology,
          const Orders(),
        );
        final overture = list
            .where((o) => o.type == DiplomaticOrderType.establishOverture)
            .where((o) => o.targetFactionId == 'minor1')
            .toList();
        expect(
          overture.any(
            (o) =>
                o.overtureStage == OvertureStage.tradeConsulate ||
                o.overtureStage == OvertureStage.embassy ||
                o.overtureStage == OvertureStage.nap,
          ),
          isFalse,
        );
      },
    );

    test(
      'toward minor at peace with join-empire overture suggests declareWar (primary before economic)',
      () {
        const api = DefaultOrderSuggestionAPI();
        const topology = MapTopology(nodes: [], edges: []);
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
          ),
          players: [
            const Player(
              id: 'gp1',
              displayName: 'A',
              isHuman: false,
            ).copyWith(treasury: 5000),
          ],
          minorNations: const [
            MinorNation(id: 'minor1', displayName: 'Minor 1'),
          ],
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'minor1',
              state: RelationState.atPeace,
              level: RelationLevel.neutral,
            ),
          ],
          overtureStates: const [
            OvertureState(
              gpId: 'gp1',
              targetId: 'minor1',
              stage: OvertureStage.joinEmpire,
              sinceTurn: 0,
            ),
          ],
        );
        final view = buildPlayerView(game, topology, 'gp1');
        final list = api.suggestDiplomaticOrders(
          view,
          game,
          topology,
          const Orders(),
        );
        final toMinor1 = list
            .where((o) => o.targetFactionId == 'minor1')
            .toList();
        expect(toMinor1, hasLength(1));
        expect(toMinor1.single.type, DiplomaticOrderType.declareWar);
      },
    );
  });
}
