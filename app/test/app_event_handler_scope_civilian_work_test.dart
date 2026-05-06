import 'dart:io';

import 'package:colonizethis_app/core/services/app_event_handler_scope.dart';
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kWorkTargetExplore, kWorkTargetProspect, kUnitTypeExplorer;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

class _ScopeProbe extends ConsumerWidget {
  const _ScopeProbe();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(currentOrdersProvider);
    return const SizedBox.shrink();
  }
}

void main() {
  suppressLogsForTests();

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_app_event_handler_scope_civilian_work');
    await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  tearDownAll(() async {
    await Hive.box<dynamic>(HiveBoxNames.games).clear();
    await Hive.close();
    final dir = Directory(
      './.dart_tool/test_hive_app_event_handler_scope_civilian_work',
    );
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  });

  setUp(() {
    AppEventBus.reset();
  });

  testWidgets(
    'civilian work upsert validates merged draft once and keeps one order per unit',
    (tester) async {
      final bus = AppEventBus.create();
      resetCivilianWorkUpsertValidationPassCountForTests();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appEventBusProvider.overrideWith((ref) {
              ref.onDispose(bus.dispose);
              return bus;
            }),
          ],
          child: const AppEventHandlerScope(
            child: MaterialApp(home: Scaffold(body: _ScopeProbe())),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(_ScopeProbe)),
      );

      const playerId = 'gp1';
      const explorerId = 'u_explorer';
      const secondExplorerId = 'u_explorer_two';
      final game = Game(
        id: 'g_upsert_validation_once',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                ownerId: playerId,
              ),
            ],
            units: [
              Unit(
                id: explorerId,
                type: kUnitTypeExplorer,
                ownerId: playerId,
                locationProvinceId: 'oldWorld|p1',
                tileKey: 'oldWorld|p1|0|0',
                status: UnitStatus.idle,
              ),
              Unit(
                id: secondExplorerId,
                type: kUnitTypeExplorer,
                ownerId: playerId,
                locationProvinceId: 'oldWorld|p1',
                tileKey: 'oldWorld|p1|0|0',
                status: UnitStatus.idle,
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: const {
            'oldWorld': {
              'oldWorld|p1': ['oldWorld|p1|0|0', 'oldWorld|p1|0|1'],
            },
          },
          playerVisibilityByTile: const {
            playerId: {
              'oldWorld|p1|0|0': 'fullyVisible',
              'oldWorld|p1|0|1': 'unknown',
            },
          },
        ),
        players: const [
          Player(
            id: playerId,
            displayName: 'Human',
            isHuman: true,
            treasury: 5000,
          ),
        ],
      );

      container.read(currentGameProvider.notifier).setGame(game);
      container
          .read(currentOrdersProvider.notifier)
          .replaceAll(
            const Orders(
              workOrdersByPlayerId: {
                playerId: [
                  WorkOrder(
                    unitId: explorerId,
                    target: kWorkTargetProspect,
                    targetTileKey: 'oldWorld|p1|0|0',
                  ),
                  WorkOrder(
                    unitId: secondExplorerId,
                    target: kWorkTargetExplore,
                    targetTileKey: 'oldWorld|p1|0|0',
                  ),
                ],
              },
            ),
          );

      bus.emit(
        UpsertPendingCivilianWorkOrderRequestedEvent(
          playerId: playerId,
          workOrder: const WorkOrder(
            unitId: explorerId,
            target: kWorkTargetExplore,
            targetTileKey: 'oldWorld|p1|0|0',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(civilianWorkUpsertValidationPassCountForTests, 1);

      final nextOrders = container.read(currentOrdersProvider);
      final workOrders = nextOrders.workOrdersByPlayerId[playerId] ?? const [];
      final explorerOrders = workOrders
          .where((o) => o.unitId == explorerId)
          .toList();
      expect(explorerOrders, hasLength(1));
      expect(explorerOrders.single.target, kWorkTargetExplore);
      expect(workOrders.where((o) => o.unitId == secondExplorerId).length, 1);
    },
  );
}
