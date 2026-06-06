import 'package:colonizethis_ai/src/util/orders_extensions.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  test('appendMoveOrders appends without mutating other players', () {
    const base = Orders(
      moveOrdersByPlayerId: {
        'p1': [MoveOrder(unitId: 'u1', destinationTileKey: 'r1|a')],
        'p2': [MoveOrder(unitId: 'u2', destinationTileKey: 'r1|b')],
      },
    );

    final updated = base.appendMoveOrders('p1', const [
      MoveOrder(unitId: 'u3', destinationTileKey: 'r1|c'),
    ]);

    expect(updated.moveOrdersByPlayerId['p1']?.length, 2);
    expect(updated.moveOrdersByPlayerId['p2'], base.moveOrdersByPlayerId['p2']);
    expect(base.moveOrdersByPlayerId['p1']?.length, 1);
  });

  group('OrdersBuilder (Refs #3288)', () {
    Orders nonEmptyBase() => const Orders(
      moveOrdersByPlayerId: {
        'p1': [MoveOrder(unitId: 'm1', destinationTileKey: 'r1|a')],
        'p2': [MoveOrder(unitId: 'm2', destinationTileKey: 'r1|b')],
      },
      workOrdersByPlayerId: {
        'p2': [WorkOrder(unitId: 'w0', target: 'explore', targetTileKey: 't0')],
      },
    );

    test('empty builder reproduces the seed orders', () {
      final base = nonEmptyBase();
      final built = OrdersBuilder(base).build();
      expect(built, base);
      // Untouched family maps fall through to the seed references.
      expect(
        identical(built.moveOrdersByPlayerId, base.moveOrdersByPlayerId),
        isTrue,
      );
    });

    test('default builder builds an empty Orders', () {
      expect(OrdersBuilder().build(), const Orders());
    });

    test('single add per family equals the spread-append helper', () {
      final base = nonEmptyBase();

      void check(Orders viaBuilder, Orders viaAppend) {
        expect(viaBuilder, viaAppend);
      }

      check(
        (OrdersBuilder(base)..addMoveOrders('p1', const [
              MoveOrder(unitId: 'm3', destinationTileKey: 'r1|c'),
            ]))
            .build(),
        base.appendMoveOrders('p1', const [
          MoveOrder(unitId: 'm3', destinationTileKey: 'r1|c'),
        ]),
      );

      check(
        (OrdersBuilder(base)..addBuildOrders('p1', const [
              BuildUnitOrder(
                unitType: 'soldier',
                isMilitary: true,
                spawnProvinceId: 'r1|x',
              ),
            ]))
            .build(),
        base.appendBuildOrders('p1', const [
          BuildUnitOrder(
            unitType: 'soldier',
            isMilitary: true,
            spawnProvinceId: 'r1|x',
          ),
        ]),
      );

      check(
        (OrdersBuilder(base)..addWorkOrders('p1', const [
              WorkOrder(unitId: 'w1', target: 'build', targetTileKey: 't1'),
            ]))
            .build(),
        base.appendWorkOrders('p1', const [
          WorkOrder(unitId: 'w1', target: 'build', targetTileKey: 't1'),
        ]),
      );

      check(
        (OrdersBuilder(base)..addRecruitWorkerOrders('p1', const [
              RecruitWorkerOrder(targetTier: WorkerTier.peasant),
            ]))
            .build(),
        base.appendRecruitWorkerOrders('p1', const [
          RecruitWorkerOrder(targetTier: WorkerTier.peasant),
        ]),
      );

      check(
        (OrdersBuilder(base)..addDiplomaticOrders('p1', const [
              DiplomaticOrder(
                type: DiplomaticOrderType.offerPeace,
                targetFactionId: 'gp2',
              ),
            ]))
            .build(),
        base.appendDiplomaticOrders('p1', const [
          DiplomaticOrder(
            type: DiplomaticOrderType.offerPeace,
            targetFactionId: 'gp2',
          ),
        ]),
      );

      check(
        (OrdersBuilder(base)..addResearchOrders('p1', const [
              ResearchOrder(
                slotIndex: 0,
                techId: 'tech',
                funding: ResearchFundingLevel.low,
              ),
            ]))
            .build(),
        base.appendResearchOrders('p1', const [
          ResearchOrder(
            slotIndex: 0,
            techId: 'tech',
            funding: ResearchFundingLevel.low,
          ),
        ]),
      );

      check(
        (OrdersBuilder(base)..addNavalMoveOrders('p1', const [
              NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 's1'),
            ]))
            .build(),
        base.appendNavalMoveOrders('p1', const [
          NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 's1'),
        ]),
      );

      check(
        (OrdersBuilder(base)..addNavalMissionOrders('p1', const [
              NavalMissionOrder(fleetId: 'f1', mission: 'patrol'),
            ]))
            .build(),
        base.appendNavalMissionOrders('p1', const [
          NavalMissionOrder(fleetId: 'f1', mission: 'patrol'),
        ]),
      );

      check(
        (OrdersBuilder(base)..addTradeOrders('p1', [
              TradeOrder(
                commodityId: 'grain',
                type: TradeOrderType.bid,
                quantity: 2,
                priority: 1,
              ),
            ]))
            .build(),
        base.appendTradeOrders('p1', [
          TradeOrder(
            commodityId: 'grain',
            type: TradeOrderType.bid,
            quantity: 2,
            priority: 1,
          ),
        ]),
      );
    });

    test('addArmyMoveOrders matches an equivalent copyWith append', () {
      const base = Orders(
        armyMoveOrdersByPlayerId: {
          'p1': [ArmyMoveOrder(armyId: 'a0', destinationProvinceId: 'r1|p0')],
        },
      );
      final built =
          (OrdersBuilder(base)..addArmyMoveOrders('p1', const [
                ArmyMoveOrder(armyId: 'a1', destinationProvinceId: 'r1|p1'),
              ]))
              .build();
      expect(built.armyMoveOrdersByPlayerId['p1'], const [
        ArmyMoveOrder(armyId: 'a0', destinationProvinceId: 'r1|p0'),
        ArmyMoveOrder(armyId: 'a1', destinationProvinceId: 'r1|p1'),
      ]);
    });

    test('sequential multi-family adds equal the chained append pipeline and '
        'leave the seed unmutated', () {
      final base = nonEmptyBase();

      final viaBuilder =
          (OrdersBuilder(base)
                ..addWorkOrders('p1', const [
                  WorkOrder(unitId: 'w1', target: 'build', targetTileKey: 't1'),
                ])
                ..addWorkOrders('p1', const [
                  WorkOrder(unitId: 'w2', target: 'build', targetTileKey: 't2'),
                ])
                ..addRecruitWorkerOrders('p1', const [
                  RecruitWorkerOrder(targetTier: WorkerTier.peasant),
                ])
                ..addBuildOrders('p1', const [
                  BuildUnitOrder(
                    unitType: 'soldier',
                    isMilitary: true,
                    spawnProvinceId: 'r1|x',
                  ),
                ]))
              .build();

      final viaAppend = base
          .appendWorkOrders('p1', const [
            WorkOrder(unitId: 'w1', target: 'build', targetTileKey: 't1'),
          ])
          .appendWorkOrders('p1', const [
            WorkOrder(unitId: 'w2', target: 'build', targetTileKey: 't2'),
          ])
          .appendRecruitWorkerOrders('p1', const [
            RecruitWorkerOrder(targetTier: WorkerTier.peasant),
          ])
          .appendBuildOrders('p1', const [
            BuildUnitOrder(
              unitType: 'soldier',
              isMilitary: true,
              spawnProvinceId: 'r1|x',
            ),
          ]);

      expect(viaBuilder, viaAppend);
      // Two appends to the same family/player concatenate in call order.
      expect(
        viaBuilder.workOrdersByPlayerId['p1']?.map((o) => o.unitId).toList(),
        ['w1', 'w2'],
      );
      // Seed maps are never mutated by the builder.
      expect(base.workOrdersByPlayerId['p1'], isNull);
      expect(base.workOrdersByPlayerId['p2']?.length, 1);
    });
  });
}
