import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_ai_contracts/colonizethis_ai_contracts.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Spy civilian-work scoring (Refs #3834 R11).
void main() {
  const playerId = 'gp1';

  Game gameWith({
    List<Player> rivals = const [],
    List<DiplomacyRelation> diplomacyRelations = const [],
    List<Unit> oldWorldUnits = const [],
    String? capitalProvinceId,
  }) => Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(units: oldWorldUnits),
      newWorld: const RegionData(),
    ),
    players: [
      Player(
        id: playerId,
        displayName: 'GP1',
        isHuman: false,
        capitalProvinceId: capitalProvinceId,
      ),
      ...rivals,
    ],
    diplomacyRelations: diplomacyRelations,
  );

  PlayerView spyViewFor(
    Game game, {
    String locationProvinceId = 'oldWorld|p1',
  }) => PlayerView(
    playerId: playerId,
    player: game.players.first,
    ownUnitsById: {
      's1': Unit(
        id: 's1',
        type: kUnitTypeSpy,
        ownerId: playerId,
        locationProvinceId: locationProvinceId,
      ),
    },
    provincesById: const {},
    visibilityByTile: const {},
    prospectedTiles: const {},
    diplomacyByOtherId: const {},
  );

  WorkOrder spy(String target, String tileKey) =>
      WorkOrder(unitId: 's1', target: target, targetTileKey: tileKey);

  group('Spy counter_spy selection', () {
    test('DEVELOP phase prefers counter_spy assignment', () {
      const counterTile = 'oldWorld|p1|0|0';
      final game = gameWith(capitalProvinceId: 'oldWorld|p1');
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: [spy(kWorkTargetCounterSpy, counterTile)],
        view: spyViewFor(game),
        game: game,
        spyDevelopPhase: true,
      );
      expect(r.workOrders.single.target, kWorkTargetCounterSpy);
    });

    test('additional counter_spy sharply reduced when one already active', () {
      const tileA = 'oldWorld|p1|0|0';
      const tileB = 'oldWorld|p2|0|0';
      final game = gameWith(
        capitalProvinceId: 'oldWorld|p1',
        oldWorldUnits: [
          Unit(
            id: 'existing',
            type: kUnitTypeSpy,
            ownerId: playerId,
            locationProvinceId: 'oldWorld|p9',
            currentWork: const CurrentWork(
              workTarget: kWorkTargetCounterSpy,
              tileKey: 'oldWorld|p9|0|0',
              totalTurns: 0,
              remainingTurns: 1,
            ),
          ),
        ],
      );
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: [
          spy(kWorkTargetCounterSpy, tileA),
          spy(kWorkTargetCounterSpy, tileB),
        ],
        view: spyViewFor(game),
        game: game,
        spyDevelopPhase: true,
      );
      expect(r.workOrders, hasLength(1));
    });
  });

  group('Spy counter_spy context scoring', () {
    test('province with a foreign-owned Spy is preferred', () {
      const infestedTile = 'oldWorld|infested|0|0';
      const cleanTile = 'oldWorld|clean|0|0';
      final game = gameWith(
        oldWorldUnits: [
          Unit(
            id: 'enemySpy',
            type: kUnitTypeSpy,
            ownerId: 'gp2',
            locationProvinceId: 'oldWorld|infested',
          ),
        ],
      );
      final r = selectFullAiCivilianWorkOrders(
        workSuggestions: [
          spy(kWorkTargetCounterSpy, cleanTile),
          spy(kWorkTargetCounterSpy, infestedTile),
        ],
        view: spyViewFor(game),
        game: game,
        spyDevelopPhase: true,
      );
      expect(r.workOrders.single.targetTileKey, infestedTile);
    });
  });
}
