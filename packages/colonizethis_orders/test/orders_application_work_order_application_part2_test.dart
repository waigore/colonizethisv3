import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('applyBuildAndWorkOrders work order application', () {
    const ow = 'oldWorld';
    const provinceId = 'oldWorld|P1';
    const tileKey = 'oldWorld|P1|0|0';

    test('counter_spy work order sets currentWork for Spy unit', () {
      final unit = Unit(
        id: 'spy1',
        type: kUnitTypeSpy,
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
              target: kWorkTargetCounterSpy,
              targetTileKey: tileKey,
            ),
          ],
        },
      );
      final next = applyBuildAndWorkOrders(game, orders);
      final spyAfter = next.worldState.oldWorld.units.single;
      expect(spyAfter.currentWork, isNotNull);
      expect(spyAfter.currentWork!.workTarget, kWorkTargetCounterSpy);
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
          type: kUnitTypeMerchant,
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
                target: kWorkTargetPurchaseLand,
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
        final merchantAfter = next.worldState.oldWorld.units.single;
        expect(merchantAfter.tileKey, tileKeyMinor);
        expect(merchantAfter.status, UnitStatus.idle);
        expect(merchantAfter.currentWork, isNull);
        expect(merchantAfter.originTileKey, isNull);
        expect(merchantAfter.assignedTileKey, isNull);
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
          type: kUnitTypeMerchant,
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
                target: kWorkTargetPurchaseLand,
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
          type: kUnitTypeMerchant,
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
                target: kWorkTargetPurchaseLand,
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
                  type: kUnitTypeMerchant,
                  ownerId: 'p1',
                  locationProvinceId: minorProvinceId,
                  tileKey: tileKeyMinor,
                ),
                Unit(
                  id: 'merchant2',
                  type: kUnitTypeMerchant,
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
                target: kWorkTargetPurchaseLand,
                targetTileKey: tileKeyMinor,
              ),
            ],
            'p2': [
              const WorkOrder(
                unitId: 'merchant2',
                target: kWorkTargetPurchaseLand,
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
  });
}
