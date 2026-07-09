part of 'order_engine_move_and_work_context_expectations.dart';

void oemwcWorkProspectAcceptedWhenMineralEligible() {
      const tileKey = 'oldWorld|P1|0|0';
      final topology = oecSingleProvinceTopology();
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$oemwcOw|P1', regionId: oemwcOw, ownerId: 'tribe1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: kUnitTypeExplorer,
                ownerId: 'p1',
                locationProvinceId: '$oemwcOw|P1',
                tileKey: tileKey,
              ),
            ],
          ),
          newWorld: const RegionData(),
          resourceByTileKey: const {tileKey: 'iron'},
          playerVisibilityByTile: const {
            'p1': {tileKey: 'fogged'},
          },
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe 1')],
        overtureStates: oemwcTribeConsulate,
      );
      final engine = OrderEngine();
      engine.addWorkOrder(
        'p1',
        const WorkOrder(
          unitId: 'u1',
          target: kWorkTargetProspect,
          targetTileKey: tileKey,
        ),
      );
      final results = engine.validatePlayerOrdersWithContext(
        game,
        topology,
        'p1',
      );
      expect(results.length, 1);
      expect(results[0].status, OrderValidationStatus.accepted);
}
void oemwcWorkProspectRejectedWithoutConsulate() {
      const tileKey = 'oldWorld|P1|0|0';
      final topology = oecSingleProvinceTopology();
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$oemwcOw|P1', regionId: oemwcOw, ownerId: 'tribe1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: kUnitTypeExplorer,
                ownerId: 'p1',
                locationProvinceId: '$oemwcOw|P1',
                tileKey: tileKey,
              ),
            ],
          ),
          newWorld: const RegionData(),
          resourceByTileKey: const {tileKey: 'iron'},
          playerVisibilityByTile: const {
            'p1': {tileKey: 'fogged'},
          },
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe 1')],
      );
      final engine = OrderEngine();
      engine.addWorkOrder(
        'p1',
        const WorkOrder(
          unitId: 'u1',
          target: kWorkTargetProspect,
          targetTileKey: tileKey,
        ),
      );
      final results = engine.validatePlayerOrdersWithContext(
        game,
        topology,
        'p1',
      );
      expect(results.length, 1);
      expect(results[0].status, OrderValidationStatus.rejected);
      expect(results[0].reason, contains('Establish a consulate'));
}
void oemwcWorkProspectRejectedOnForeignGpTile() {
      const targetTileKey = 'oldWorld|P2|0|0';
      final topology = oecTwoProvinceTopology();
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$oemwcOw|P1', regionId: oemwcOw, ownerId: 'p1'),
              Province(id: '$oemwcOw|P2', regionId: oemwcOw, ownerId: 'p2'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: kUnitTypeExplorer,
                ownerId: 'p1',
                locationProvinceId: '$oemwcOw|P1',
                tileKey: 'oldWorld|P1|0|0',
              ),
            ],
          ),
          newWorld: const RegionData(),
          resourceByTileKey: const {targetTileKey: 'iron'},
          playerVisibilityByTile: const {
            'p1': {'oldWorld|P1|0|0': 'fullyVisible', targetTileKey: 'fogged'},
          },
          tileKeysByRegionAndProvince: const {
            oemwcOw: {
              'oldWorld|P1': ['oldWorld|P1|0|0'],
              'oldWorld|P2': [targetTileKey],
            },
          },
        ),
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: true),
        ],
      );
      final engine = OrderEngine();
      engine.addWorkOrder(
        'p1',
        const WorkOrder(
          unitId: 'u1',
          target: kWorkTargetProspect,
          targetTileKey: targetTileKey,
        ),
      );
      final results = engine.validatePlayerOrdersWithContext(
        game,
        topology,
        'p1',
      );
      expect(results.length, 1);
      expect(results[0].status, OrderValidationStatus.rejected);
      expect(results[0].reason, contains('cannot occupy'));
}
void oemwcMoveRejectedWhenNotAdjacentNotOwn() {
      final topology = oemwcThreeProvinceChainTopology();
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$oemwcOw|P1', regionId: oemwcOw, ownerId: 'p1'),
              Province(id: '$oemwcOw|P2', regionId: oemwcOw, ownerId: 'p1'),
              Province(id: '$oemwcOw|P3', regionId: oemwcOw, ownerId: 'p2'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'musketeers',
                ownerId: 'p1',
                locationProvinceId: '$oemwcOw|P1',
              ),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: oemwcThreeTilesVisible,
        ),
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: true),
        ],
      );
      final engine = OrderEngine();
      engine.addMoveOrder(
        'p1',
        MoveOrder(unitId: 'u1', destinationTileKey: '$oemwcOw|P3|0|0'),
      );
      final results = engine.validatePlayerOrdersWithContext(
        game,
        topology,
        'p1',
      );
      expect(results.single.status, OrderValidationStatus.rejected);
}
void oemwcCivilianMoveAcceptedWhenNotAdjacentOwnProvince() {
      final topology = oemwcThreeProvinceChainTopology();
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$oemwcOw|P1', regionId: oemwcOw, ownerId: 'p1'),
              Province(id: '$oemwcOw|P2', regionId: oemwcOw, ownerId: 'p1'),
              Province(id: '$oemwcOw|P3', regionId: oemwcOw, ownerId: 'p1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: kUnitTypeBuilder,
                ownerId: 'p1',
                locationProvinceId: '$oemwcOw|P1',
              ),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: oemwcThreeTilesVisible,
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final engine = OrderEngine();
      engine.addMoveOrder(
        'p1',
        MoveOrder(unitId: 'u1', destinationTileKey: '$oemwcOw|P3|0|0'),
      );
      final results = engine.validatePlayerOrdersWithContext(
        game,
        topology,
        'p1',
      );
      expect(results.single.status, OrderValidationStatus.accepted);
}
void oemwcWorkProspectRejectedWhenAlreadyProspected() {
      const tileKey = 'oldWorld|P1|0|0';
      final topology = oecSingleProvinceTopology();
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$oemwcOw|P1', regionId: oemwcOw, ownerId: 'tribe1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: kUnitTypeExplorer,
                ownerId: 'p1',
                locationProvinceId: '$oemwcOw|P1',
                tileKey: tileKey,
              ),
            ],
          ),
          newWorld: const RegionData(),
          resourceByTileKey: const {tileKey: 'iron'},
          playerProspectedTiles: const {
            'p1': {tileKey},
          },
          playerVisibilityByTile: const {
            'p1': {tileKey: 'fogged'},
          },
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe 1')],
        overtureStates: oemwcTribeConsulate,
      );
      final engine = OrderEngine();
      engine.addWorkOrder(
        'p1',
        const WorkOrder(
          unitId: 'u1',
          target: kWorkTargetProspect,
          targetTileKey: tileKey,
        ),
      );
      final results = engine.validatePlayerOrdersWithContext(
        game,
        topology,
        'p1',
      );
      expect(results.length, 1);
      expect(results[0].status, OrderValidationStatus.rejected);
      expect(results[0].reason, contains('already prospected'));
}
