import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

Game _twoProvinceSpyGame() {
  return Game(
    id: 'g1',
    players: const [
      Player(id: 'h1', displayName: 'Human', isHuman: true),
      Player(id: 'gp2', displayName: 'Rival', isHuman: false),
    ],
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: const [
          Province(
            id: 'oldWorld|p1',
            regionId: 'oldWorld',
            displayName: 'Home',
            ownerId: 'h1',
          ),
          Province(
            id: 'oldWorld|p2',
            regionId: 'oldWorld',
            displayName: 'Rival Land',
            ownerId: 'gp2',
          ),
        ],
        units: [
          Unit(
            id: 'spy1',
            type: kUnitTypeSpy,
            ownerId: 'h1',
            locationProvinceId: 'oldWorld|p2',
            tileKey: 'oldWorld|p2|0|0',
          ),
        ],
      ),
      newWorld: const RegionData(),
    ),
  );
}

void main() {
  group('isForeignProvinceForPlayer', () {
    test('returns true for rival-owned province', () {
      final game = _twoProvinceSpyGame();
      expect(
        isForeignProvinceForPlayer(
          game: game,
          prefixedProvinceId: 'oldWorld|p2',
          humanPlayerId: 'h1',
        ),
        isTrue,
      );
    });

    test('returns false for human-owned province', () {
      final game = _twoProvinceSpyGame();
      expect(
        isForeignProvinceForPlayer(
          game: game,
          prefixedProvinceId: 'oldWorld|p1',
          humanPlayerId: 'h1',
        ),
        isFalse,
      );
    });
  });

  group('spyLeaveIntelWarningNeeded', () {
    const humanId = 'h1';

    test('warns when last Spy would leave foreign province', () {
      final game = _twoProvinceSpyGame();
      expect(
        spyLeaveIntelWarningNeeded(
          game: game,
          orders: const Orders(),
          humanPlayerId: humanId,
          spyUnitId: 'spy1',
          newDestinationTileKey: 'oldWorld|p1|0|0',
        ),
        isTrue,
      );
    });

    test('no warning when another Spy remains in foreign province', () {
      final game = Game(
        id: 'g1',
        players: const [
          Player(id: 'h1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'Rival', isHuman: false),
        ],
        worldState: WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                displayName: 'Home',
                ownerId: 'h1',
              ),
              Province(
                id: 'oldWorld|p2',
                regionId: 'oldWorld',
                displayName: 'Rival Land',
                ownerId: 'gp2',
              ),
            ],
            units: [
              Unit(
                id: 'spy1',
                type: kUnitTypeSpy,
                ownerId: 'h1',
                locationProvinceId: 'oldWorld|p2',
                tileKey: 'oldWorld|p2|0|0',
              ),
              Unit(
                id: 'spy2',
                type: kUnitTypeSpy,
                ownerId: 'h1',
                locationProvinceId: 'oldWorld|p2',
                tileKey: 'oldWorld|p2|1|0',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
      );
      expect(
        spyLeaveIntelWarningNeeded(
          game: game,
          orders: const Orders(),
          humanPlayerId: humanId,
          spyUnitId: 'spy1',
          newDestinationTileKey: 'oldWorld|p1|0|0',
        ),
        isFalse,
      );
    });

    test(
      'warns when other Spy pending move already vacates foreign province',
      () {
        final game = Game(
          id: 'g1',
          players: const [
            Player(id: 'h1', displayName: 'Human', isHuman: true),
            Player(id: 'gp2', displayName: 'Rival', isHuman: false),
          ],
          worldState: WorldState(
            turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: const [
                Province(
                  id: 'oldWorld|p1',
                  regionId: 'oldWorld',
                  displayName: 'Home',
                  ownerId: 'h1',
                ),
                Province(
                  id: 'oldWorld|p2',
                  regionId: 'oldWorld',
                  displayName: 'Rival Land',
                  ownerId: 'gp2',
                ),
              ],
              units: [
                Unit(
                  id: 'spy1',
                  type: kUnitTypeSpy,
                  ownerId: 'h1',
                  locationProvinceId: 'oldWorld|p2',
                  tileKey: 'oldWorld|p2|0|0',
                ),
                Unit(
                  id: 'spy2',
                  type: kUnitTypeSpy,
                  ownerId: 'h1',
                  locationProvinceId: 'oldWorld|p2',
                  tileKey: 'oldWorld|p2|1|0',
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
        );
        const orders = Orders(
          moveOrdersByPlayerId: {
            'h1': [
              MoveOrder(
                unitId: 'spy2',
                destinationTileKey: 'oldWorld|p1|0|0',
              ),
            ],
          },
        );
        expect(
          spyLeaveIntelWarningNeeded(
            game: game,
            orders: orders,
            humanPlayerId: humanId,
            spyUnitId: 'spy1',
            newDestinationTileKey: 'oldWorld|p1|1|0',
          ),
          isTrue,
        );
      },
    );

    test(
      'no warning when other Spy pending move stays in foreign province',
      () {
        final game = Game(
          id: 'g1',
          players: const [
            Player(id: 'h1', displayName: 'Human', isHuman: true),
            Player(id: 'gp2', displayName: 'Rival', isHuman: false),
          ],
          worldState: WorldState(
            turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: const [
                Province(
                  id: 'oldWorld|p1',
                  regionId: 'oldWorld',
                  displayName: 'Home',
                  ownerId: 'h1',
                ),
                Province(
                  id: 'oldWorld|p2',
                  regionId: 'oldWorld',
                  displayName: 'Rival Land',
                  ownerId: 'gp2',
                ),
              ],
              units: [
                Unit(
                  id: 'spy1',
                  type: kUnitTypeSpy,
                  ownerId: 'h1',
                  locationProvinceId: 'oldWorld|p2',
                  tileKey: 'oldWorld|p2|0|0',
                ),
                Unit(
                  id: 'spy2',
                  type: kUnitTypeSpy,
                  ownerId: 'h1',
                  locationProvinceId: 'oldWorld|p2',
                  tileKey: 'oldWorld|p2|1|0',
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
        );
        const orders = Orders(
          moveOrdersByPlayerId: {
            'h1': [
              MoveOrder(
                unitId: 'spy2',
                destinationTileKey: 'oldWorld|p2|2|0',
              ),
            ],
          },
        );
        expect(
          spyLeaveIntelWarningNeeded(
            game: game,
            orders: orders,
            humanPlayerId: humanId,
            spyUnitId: 'spy1',
            newDestinationTileKey: 'oldWorld|p1|0|0',
          ),
          isFalse,
        );
      },
    );
  });
}
