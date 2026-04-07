import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('applyBuildAndWorkOrders work order application', () {
    const ow = 'oldWorld';
    const provinceId = 'oldWorld|P1';
    const tileKey = 'oldWorld|P1|0|0';

    test('unknown work target is skipped and unit stays idle', () {
      final unit = Unit(
        id: 'u1',
        type: 'Builder',
        ownerId: 'p1',
        locationProvinceId: provinceId,
        tileKey: tileKey,
      );
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
            units: [unit],
          ),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final orders = Orders(
        workOrdersByPlayerId: {
          'p1': [
            WorkOrder(
              unitId: 'u1',
              target: 'unknown_target',
              targetTileKey: tileKey,
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders);
      final u = next.worldState.oldWorld.units.single;
      expect(u.status, UnitStatus.idle);
      expect(u.currentWork, isNull);
    });

    test('counter_spy work order sets currentWork for Spy unit', () {
      final unit = Unit(
        id: 'spy1',
        type: 'Spy',
        ownerId: 'p1',
        locationProvinceId: provinceId,
        tileKey: tileKey,
      );
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p2')],
            units: [unit],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: true),
        ],
      );
      final orders = Orders(
        workOrdersByPlayerId: {
          'p1': [
            WorkOrder(
              unitId: 'spy1',
              target: 'counter_spy',
              targetTileKey: tileKey,
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders);
      final spyAfter = next.worldState.oldWorld.units.single;
      expect(spyAfter.currentWork, isNotNull);
      expect(spyAfter.currentWork!.workTarget, 'counter_spy');
      expect(spyAfter.currentWork!.totalTurns, 0);
      expect(spyAfter.currentWork!.remainingTurns, 1);
    });

    test(
      'purchase_land success: treasury deducted and tile recorded in purchasedTilesByTileKey',
      () {
        const minorProvinceId = 'oldWorld|M1';
        const tileKeyMinor = 'oldWorld|M1|0|0';
        const cost = 15 * 10; // grain base price 10
        final unit = Unit(
          id: 'merchant1',
          type: 'Merchant',
          ownerId: 'p1',
          locationProvinceId: minorProvinceId,
          tileKey: tileKeyMinor,
        );
        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [
                Province(id: provinceId, regionId: ow, ownerId: 'p1'),
                Province(id: minorProvinceId, regionId: ow, ownerId: 'minor1'),
              ],
              units: [unit],
            ),
            newWorld: const RegionData(),
            resourceByTileKey: {tileKeyMinor: 'grain'},
            tileKeysByRegionAndProvince: {
              ow: {
                provinceId: [tileKey],
                minorProvinceId: [tileKeyMinor],
              },
            },
          ),
          players: [
            Player(
              id: 'p1',
              displayName: 'P1',
              isHuman: true,
              treasury: cost + 100,
            ),
          ],
          minorNations: const [
            MinorNation(id: 'minor1', displayName: 'Minor 1'),
          ],
          overtureStates: const [
            OvertureState(
              gpId: 'p1',
              targetId: 'minor1',
              stage: OvertureStage.embassy,
              sinceTurn: 0,
            ),
          ],
        );
        final orders = Orders(
          workOrdersByPlayerId: {
            'p1': [
              const WorkOrder(
                unitId: 'merchant1',
                target: 'purchase_land',
                targetTileKey: tileKeyMinor,
              ),
            ],
          },
        );
        final next = applyBuildAndWorkOrders(game, orders);
        expect(next.worldState.purchasedTilesByTileKey[tileKeyMinor], 'p1');
        expect(
          next.players.single.treasury,
          game.players.single.treasury - cost,
        );
      },
    );

    test(
      'purchase_land rejected when no Embassy with province owner (Minor/Tribe)',
      () {
        const minorProvinceId = 'oldWorld|M1';
        const tileKeyMinor = 'oldWorld|M1|0|0';
        const cost = 15 * 10; // grain base price 10
        final unit = Unit(
          id: 'merchant1',
          type: 'Merchant',
          ownerId: 'p1',
          locationProvinceId: minorProvinceId,
          tileKey: tileKeyMinor,
        );
        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: const [
                Province(id: provinceId, regionId: ow, ownerId: 'p1'),
                Province(id: minorProvinceId, regionId: ow, ownerId: 'minor1'),
              ],
              units: [unit],
            ),
            newWorld: const RegionData(),
            resourceByTileKey: const {tileKeyMinor: 'grain'},
            tileKeysByRegionAndProvince: const {
              ow: {
                provinceId: [tileKey],
                minorProvinceId: [tileKeyMinor],
              },
            },
          ),
          players: [
            Player(
              id: 'p1',
              displayName: 'P1',
              isHuman: true,
              treasury: cost + 100,
            ),
          ],
          minorNations: const [
            MinorNation(id: 'minor1', displayName: 'Minor 1'),
          ],
          // No overtureStates → no Embassy with province owner.
          overtureStates: const [],
        );
        final orders = Orders(
          workOrdersByPlayerId: {
            'p1': [
              const WorkOrder(
                unitId: 'merchant1',
                target: 'purchase_land',
                targetTileKey: tileKeyMinor,
              ),
            ],
          },
        );
        final next = applyBuildAndWorkOrders(game, orders);
        expect(next.worldState.purchasedTilesByTileKey[tileKeyMinor], isNull);
        expect(next.players.single.treasury, game.players.single.treasury);
      },
    );

    test(
      'purchase_land rejected when at war with province owner (Minor/Tribe)',
      () {
        const minorProvinceId = 'oldWorld|M1';
        const tileKeyMinor = 'oldWorld|M1|0|0';
        const cost = 15 * 10; // grain base price 10
        final unit = Unit(
          id: 'merchant1',
          type: 'Merchant',
          ownerId: 'p1',
          locationProvinceId: minorProvinceId,
          tileKey: tileKeyMinor,
        );
        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: const [
                Province(id: provinceId, regionId: ow, ownerId: 'p1'),
                Province(id: minorProvinceId, regionId: ow, ownerId: 'minor1'),
              ],
              units: [unit],
            ),
            newWorld: const RegionData(),
            resourceByTileKey: const {tileKeyMinor: 'grain'},
            tileKeysByRegionAndProvince: const {
              ow: {
                provinceId: [tileKey],
                minorProvinceId: [tileKeyMinor],
              },
            },
          ),
          players: [
            Player(
              id: 'p1',
              displayName: 'P1',
              isHuman: true,
              treasury: cost + 100,
            ),
          ],
          minorNations: const [
            MinorNation(id: 'minor1', displayName: 'Minor 1'),
          ],
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: 'p1',
              factionId2: 'minor1',
              state: RelationState.atWar,
            ),
          ],
        );
        final orders = Orders(
          workOrdersByPlayerId: {
            'p1': [
              const WorkOrder(
                unitId: 'merchant1',
                target: 'purchase_land',
                targetTileKey: tileKeyMinor,
              ),
            ],
          },
        );
        final next = applyBuildAndWorkOrders(game, orders);
        expect(next.worldState.purchasedTilesByTileKey[tileKeyMinor], isNull);
        expect(next.players.single.treasury, game.players.single.treasury);
      },
    );

    test(
      'purchase_land same tile by two GPs: first wins, second does not deduct or overwrite',
      () {
        const minorProvinceId = 'oldWorld|M1';
        const tileKeyMinor = 'oldWorld|M1|0|0';
        const cost = 15 * 10; // grain base price 10
        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [
                Province(id: provinceId, regionId: ow, ownerId: 'p1'),
                Province(id: minorProvinceId, regionId: ow, ownerId: 'minor1'),
              ],
              units: [
                Unit(
                  id: 'merchant1',
                  type: 'Merchant',
                  ownerId: 'p1',
                  locationProvinceId: minorProvinceId,
                  tileKey: tileKeyMinor,
                ),
                Unit(
                  id: 'merchant2',
                  type: 'Merchant',
                  ownerId: 'p2',
                  locationProvinceId: minorProvinceId,
                  tileKey: tileKeyMinor,
                ),
              ],
            ),
            newWorld: const RegionData(),
            resourceByTileKey: {tileKeyMinor: 'grain'},
            tileKeysByRegionAndProvince: {
              ow: {
                provinceId: [tileKey],
                minorProvinceId: [tileKeyMinor],
              },
            },
          ),
          players: [
            Player(
              id: 'p1',
              displayName: 'P1',
              isHuman: true,
              treasury: cost + 100,
              capitalProvinceId: provinceId,
            ),
            Player(
              id: 'p2',
              displayName: 'P2',
              isHuman: false,
              treasury: cost + 100,
              capitalProvinceId: provinceId,
            ),
          ],
          minorNations: const [
            MinorNation(id: 'minor1', displayName: 'Minor 1'),
          ],
          overtureStates: const [
            OvertureState(
              gpId: 'p1',
              targetId: 'minor1',
              stage: OvertureStage.embassy,
              sinceTurn: 0,
            ),
            OvertureState(
              gpId: 'p2',
              targetId: 'minor1',
              stage: OvertureStage.embassy,
              sinceTurn: 0,
            ),
          ],
        );
        final orders = Orders(
          workOrdersByPlayerId: {
            'p1': [
              const WorkOrder(
                unitId: 'merchant1',
                target: 'purchase_land',
                targetTileKey: tileKeyMinor,
              ),
            ],
            'p2': [
              const WorkOrder(
                unitId: 'merchant2',
                target: 'purchase_land',
                targetTileKey: tileKeyMinor,
              ),
            ],
          },
        );
        final next = applyBuildAndWorkOrders(game, orders);
        expect(next.worldState.purchasedTilesByTileKey[tileKeyMinor], 'p1');
        final p1After = next.playerById('p1')!;
        final p2After = next.playerById('p2')!;
        expect(p1After.treasury, game.playerById('p1')!.treasury - cost);
        expect(p2After.treasury, game.playerById('p2')!.treasury);
      },
    );

    test(
      'build_road with insufficient materials does not set currentWork or deduct stockpile',
      () {
        final unit = Unit(
          id: 'u1',
          type: 'Engineer',
          ownerId: 'p1',
          locationProvinceId: provinceId,
          tileKey: tileKey,
        );
        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [
                Province(id: provinceId, regionId: ow, ownerId: 'p1'),
              ],
              units: [unit],
            ),
            newWorld: const RegionData(),
          ),
          players: [
            const Player(
              id: 'p1',
              displayName: 'P1',
              isHuman: true,
              stockpile: Stockpile(),
            ),
          ],
        );
        final orders = Orders(
          workOrdersByPlayerId: {
            'p1': [
              WorkOrder(
                unitId: 'u1',
                target: 'build_road',
                targetTileKey: tileKey,
              ),
            ],
          },
        );
        final next = applyBuildAndWorkOrders(game, orders);
        final u = next.worldState.oldWorld.units.single;
        expect(u.currentWork, isNull);
        expect(u.status, UnitStatus.idle);
        expect(
          next.players.single.stockpile.quantityOf(CommodityCatalog.lumber.id),
          0,
        );
      },
    );

    test(
      'build_road with sufficient materials deducts materials and sets currentWork',
      () {
        final unit = Unit(
          id: 'u1',
          type: 'Engineer',
          ownerId: 'p1',
          locationProvinceId: provinceId,
          tileKey: tileKey,
        );
        final cost = workOrderCostBuildRoad;
        var stockpile = const Stockpile();
        for (final e in cost.entries) {
          stockpile = stockpile.applyDelta(e.key, e.value);
        }
        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [
                Province(id: provinceId, regionId: ow, ownerId: 'p1'),
              ],
              units: [unit],
            ),
            newWorld: const RegionData(),
          ),
          players: [
            Player(
              id: 'p1',
              displayName: 'P1',
              isHuman: true,
              stockpile: stockpile,
            ),
          ],
        );
        final orders = Orders(
          workOrdersByPlayerId: {
            'p1': [
              WorkOrder(
                unitId: 'u1',
                target: 'build_road',
                targetTileKey: tileKey,
              ),
            ],
          },
        );
        final next = applyBuildAndWorkOrders(game, orders);
        final u = next.worldState.oldWorld.units.single;
        // build_road totalTurns=1, so work completes in same phase; unit idle and road level 1.
        expect(u.currentWork, isNull);
        expect(u.status, UnitStatus.idle);
        expect(next.worldState.tileState.roadLevel(tileKey), 1);
        for (final e in cost.entries) {
          expect(
            next.players.single.stockpile.quantityOf(e.key),
            game.players.single.stockpile.quantityOf(e.key) - e.value,
          );
        }
      },
    );
  });
}
