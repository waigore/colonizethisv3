import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_orders/src/orders/bundled_civilian_work_order.dart';
import 'package:colonizethis_turn/src/turn/phases/movement_phase_bundled_work.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('bundled civilian work move leg', () {
    test('skips implicit move leg for purchased foreign tile', () {
      const ow = 'oldWorld';
      const p1 = '$ow|p1';
      const p2 = '$ow|p2';
      const fromTile = '$p1|0|0';
      const purchasedTile = '$p2|0|0';

      final unit = Unit(
        id: 'u1',
        type: kUnitTypeBuilder,
        ownerId: 'gp1',
        locationProvinceId: p1,
        tileKey: fromTile,
      );
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: p1, regionId: ow, ownerId: 'gp1'),
              Province(id: p2, regionId: ow, ownerId: 'gp2'),
            ],
            units: [unit],
          ),
          newWorld: const RegionData(),
          purchasedTilesByTileKey: const {purchasedTile: 'gp1'},
        ),
        players: const [
          Player(id: 'gp1', displayName: 'GP1', isHuman: true),
          Player(id: 'gp2', displayName: 'GP2', isHuman: false),
        ],
      );

      final order = const WorkOrder(
        unitId: 'u1',
        target: kWorkTargetBuildImprovement,
        targetTileKey: purchasedTile,
      );

      expect(
        civilianBundledWorkNeedsProvinceMoveLeg(game, unit, order),
        isFalse,
      );
    });

    test('skips implicit move leg for steal_tech target', () {
      const ow = 'oldWorld';
      const p1 = '$ow|p1';
      const p2 = '$ow|p2';
      final unit = Unit(
        id: 'spy1',
        type: kUnitTypeSpy,
        ownerId: 'gp1',
        locationProvinceId: p1,
        tileKey: '$p1|0|0',
      );
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: p1, regionId: ow, ownerId: 'gp1'),
              Province(id: p2, regionId: ow, ownerId: 'gp2'),
            ],
            units: [unit],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'GP1', isHuman: true),
          Player(
            id: 'gp2',
            displayName: 'GP2',
            isHuman: false,
            capitalProvinceId: p2,
          ),
        ],
      );

      final order = const WorkOrder(
        unitId: 'spy1',
        target: kWorkTargetStealTech,
        targetTileKey: '$p2|0|0',
      );

      expect(
        civilianBundledWorkNeedsProvinceMoveLeg(game, unit, order),
        isFalse,
      );
    });
  });

  group('applyImplicitBundledCivilianWorkOrderMoves', () {
    test('moves civilian to bundled entry tile before work phase', () {
      const ow = 'oldWorld';
      const p1 = '$ow|p1';
      const p2 = '$ow|p2';
      const fromTile = '$p1|0|0';
      const destTile = '$p2|0|0';

      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.movement, turnNumber: 2),
          oldWorld: RegionData(
            provinces: const [
              Province(id: p1, regionId: ow, ownerId: 'gp1'),
              Province(id: p2, regionId: ow, ownerId: 'gp1'),
            ],
            units: [
              Unit(
                id: 'builder1',
                type: kUnitTypeBuilder,
                ownerId: 'gp1',
                locationProvinceId: p1,
                tileKey: fromTile,
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: const {
            ow: {
              p1: [fromTile],
              p2: [destTile],
            },
          },
          playerVisibilityByTile: const {
            'gp1': {fromTile: 'fullyVisible', destTile: 'fullyVisible'},
          },
          resourceByTileKey: const {destTile: 'grain'},
        ),
        players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
      );
      final orders = const Orders(
        workOrdersByPlayerId: {
          'gp1': [
            WorkOrder(
              unitId: 'builder1',
              target: kWorkTargetBuildImprovement,
              targetTileKey: destTile,
            ),
          ],
        },
      );
      const topology = MapTopology(
        nodes: [
          TopologyNode(id: 'p1', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(id: 'p2', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: [],
      );

      final moved = applyImplicitBundledCivilianWorkOrderMoves(
        game,
        topology,
        orders,
      );

      final unit = moved.worldState.oldWorld.units.single;
      expect(unit.locationProvinceId, p2);
      expect(unit.tileKey, destTile);
    });

    test(
      'implicit bundled move uses first MoveValidator-legal tile when earlier sorted tiles are unknown',
      () {
        const ow = 'oldWorld';
        const p1 = '$ow|p1';
        const p2 = '$ow|p2';
        const fromTile = '$p1|0|0';
        const destTileUnknown = '$p2|0|0';
        const destTileVisible = '$p2|1|0';

        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.movement,
              turnNumber: 2,
            ),
            oldWorld: RegionData(
              provinces: const [
                Province(id: p1, regionId: ow, ownerId: 'gp1'),
                Province(id: p2, regionId: ow, ownerId: 'gp1'),
              ],
              units: [
                Unit(
                  id: 'builder1',
                  type: kUnitTypeBuilder,
                  ownerId: 'gp1',
                  locationProvinceId: p1,
                  tileKey: fromTile,
                ),
              ],
            ),
            newWorld: const RegionData(),
            tileKeysByRegionAndProvince: {
              ow: {
                p1: [fromTile],
                p2: [destTileUnknown, destTileVisible],
              },
            },
            playerVisibilityByTile: const {
              'gp1': {
                fromTile: 'fullyVisible',
                destTileUnknown: 'unknown',
                destTileVisible: 'fullyVisible',
              },
            },
            resourceByTileKey: const {destTileVisible: 'grain'},
          ),
          players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
        );
        final orders = Orders(
          workOrdersByPlayerId: {
            'gp1': [
              WorkOrder(
                unitId: 'builder1',
                target: kWorkTargetBuildImprovement,
                targetTileKey: destTileVisible,
              ),
            ],
          },
        );
        const topology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'p1',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'p2',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
          ],
          edges: [],
        );

        final moved = applyImplicitBundledCivilianWorkOrderMoves(
          game,
          topology,
          orders,
        );

        final unit = moved.worldState.oldWorld.units.single;
        expect(unit.locationProvinceId, p2);
        expect(unit.tileKey, destTileVisible);
      },
    );

    test('implicit bundled move prefers targetTileKey when it is legal', () {
      const ow = 'oldWorld';
      const p1 = '$ow|p1';
      const p2 = '$ow|p2';
      const fromTile = '$p1|0|0';
      const firstSortedLegal = '$p2|0|0';
      const preferredTargetTile = '$p2|1|0';

      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.movement, turnNumber: 2),
          oldWorld: RegionData(
            provinces: const [
              Province(id: p1, regionId: ow, ownerId: 'gp1'),
              Province(id: p2, regionId: ow, ownerId: 'gp1'),
            ],
            units: [
              Unit(
                id: 'builder1',
                type: kUnitTypeBuilder,
                ownerId: 'gp1',
                locationProvinceId: p1,
                tileKey: fromTile,
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: const {
            ow: {
              p1: [fromTile],
              p2: [firstSortedLegal, preferredTargetTile],
            },
          },
          playerVisibilityByTile: const {
            'gp1': {
              fromTile: 'fullyVisible',
              firstSortedLegal: 'fullyVisible',
              preferredTargetTile: 'fullyVisible',
            },
          },
          resourceByTileKey: const {preferredTargetTile: 'grain'},
        ),
        players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
      );
      final orders = const Orders(
        workOrdersByPlayerId: {
          'gp1': [
            WorkOrder(
              unitId: 'builder1',
              target: kWorkTargetBuildImprovement,
              targetTileKey: preferredTargetTile,
            ),
          ],
        },
      );
      const topology = MapTopology(
        nodes: [
          TopologyNode(id: 'p1', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(id: 'p2', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: [],
      );

      final moved = applyImplicitBundledCivilianWorkOrderMoves(
        game,
        topology,
        orders,
      );

      final unit = moved.worldState.oldWorld.units.single;
      expect(unit.locationProvinceId, p2);
      expect(unit.tileKey, preferredTargetTile);
    });
  });
}
