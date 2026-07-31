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

    test('returns false for unknown province', () {
      final game = _twoProvinceSpyGame();
      expect(
        isForeignProvinceForPlayer(
          game: game,
          prefixedProvinceId: 'oldWorld|missing',
          humanPlayerId: 'h1',
        ),
        isFalse,
      );
    });
  });

  group('countOwnSpiesProjectedInProvince', () {
    const humanId = 'h1';

    test('counts Spies projected in foreign province', () {
      final game = _twoProvinceSpyGame();
      expect(
        countOwnSpiesProjectedInProvince(
          game: game,
          orders: const Orders(),
          humanPlayerId: humanId,
          prefixedProvinceId: 'oldWorld|p2',
        ),
        1,
      );
    });

    test('uses pending move destination for projection', () {
      final game = _twoProvinceSpyGame();
      const orders = Orders(
        moveOrdersByPlayerId: {
          humanId: [
            MoveOrder(
              unitId: 'spy1',
              destinationTileKey: 'oldWorld|p1|0|0',
            ),
          ],
        },
      );
      expect(
        countOwnSpiesProjectedInProvince(
          game: game,
          orders: orders,
          humanPlayerId: humanId,
          prefixedProvinceId: 'oldWorld|p2',
        ),
        0,
      );
      expect(
        countOwnSpiesProjectedInProvince(
          game: game,
          orders: orders,
          humanPlayerId: humanId,
          prefixedProvinceId: 'oldWorld|p1',
        ),
        1,
      );
    });
  });

  group('applySpyRelocateMoveToOrders', () {
    const humanId = 'h1';

    test('stages move and clears conflicting work order', () {
      const orders = Orders(
        workOrdersByPlayerId: {
          humanId: [
            WorkOrder(
              unitId: 'spy1',
              target: kWorkTargetCounterSpy,
              targetTileKey: 'oldWorld|p1|0|0',
            ),
          ],
        },
      );
      final next = applySpyRelocateMoveToOrders(
        orders: orders,
        humanPlayerId: humanId,
        spyUnitId: 'spy1',
        destinationTileKey: 'oldWorld|p1|1|0',
      );
      expect(next.workOrdersByPlayerId[humanId], isEmpty);
      expect(
        pendingCivilianMoveForUnit(
          orders: next,
          humanPlayerId: humanId,
          unitId: 'spy1',
        ),
        const MoveOrder(
          unitId: 'spy1',
          destinationTileKey: 'oldWorld|p1|1|0',
        ),
      );
    });

    test('replaces prior draft move for same Spy', () {
      const orders = Orders(
        moveOrdersByPlayerId: {
          humanId: [
            MoveOrder(
              unitId: 'spy1',
              destinationTileKey: 'oldWorld|p1|0|0',
            ),
          ],
        },
      );
      final next = applySpyRelocateMoveToOrders(
        orders: orders,
        humanPlayerId: humanId,
        spyUnitId: 'spy1',
        destinationTileKey: 'oldWorld|p1|2|0',
      );
      expect(next.moveOrdersByPlayerId[humanId], hasLength(1));
      expect(
        next.moveOrdersByPlayerId[humanId]!.single.destinationTileKey,
        'oldWorld|p1|2|0',
      );
    });
  });

  group('removePendingCivilianMoveForUnit', () {
    const humanId = 'h1';

    test('removes pending move when present', () {
      const orders = Orders(
        moveOrdersByPlayerId: {
          humanId: [
            MoveOrder(
              unitId: 'spy1',
              destinationTileKey: 'oldWorld|p1|0|0',
            ),
          ],
        },
      );
      final next = removePendingCivilianMoveForUnit(
        orders: orders,
        humanPlayerId: humanId,
        unitId: 'spy1',
      );
      expect(next.moveOrdersByPlayerId[humanId], isEmpty);
    });

    test('returns same orders when no pending move', () {
      const orders = Orders();
      expect(
        identical(
          removePendingCivilianMoveForUnit(
            orders: orders,
            humanPlayerId: humanId,
            unitId: 'spy1',
          ),
          orders,
        ),
        isTrue,
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

    test('returns false for unknown unit', () {
      final game = _twoProvinceSpyGame();
      expect(
        spyLeaveIntelWarningNeeded(
          game: game,
          orders: const Orders(),
          humanPlayerId: humanId,
          spyUnitId: 'missing',
          newDestinationTileKey: 'oldWorld|p1|0|0',
        ),
        isFalse,
      );
    });

    test('returns false when relocating from owned province', () {
      final game = Game(
        id: 'g1',
        players: const [
          Player(id: 'h1', displayName: 'Human', isHuman: true),
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
            ],
            units: [
              Unit(
                id: 'spy1',
                type: kUnitTypeSpy,
                ownerId: 'h1',
                locationProvinceId: 'oldWorld|p1',
                tileKey: 'oldWorld|p1|0|0',
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
          newDestinationTileKey: 'oldWorld|p1|1|0',
        ),
        isFalse,
      );
    });
  });
}
