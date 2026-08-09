import 'dart:io';

import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart';
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show
        kWorkTargetCounterSpy,
        kWorkTargetExplore,
        kWorkTargetProspect,
        kUnitTypeExplorer,
        kUnitTypeSpy;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_shell_harness.dart';

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

      // Editorial shell via buildAppShell (Refs #4035 — no inline MaterialApp).
      await tester.pumpWidget(
        buildAppShell(
          overrides: [
            appEventBusProvider.overrideWith((ref) {
              ref.onDispose(bus.dispose);
              return bus;
            }),
          ],
          shellWrapper: (app) => AppEventHandlerScope(child: app),
          child: const Scaffold(body: _ScopeProbe()),
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

  testWidgets(
    'CivilianMoveRequestedEvent stages validated Spy MoveOrder (Refs #4219)',
    (tester) async {
      final bus = AppEventBus.create();

      await tester.pumpWidget(
        buildAppShell(
          overrides: [
            appEventBusProvider.overrideWith((ref) {
              ref.onDispose(bus.dispose);
              return bus;
            }),
          ],
          shellWrapper: (app) => AppEventHandlerScope(child: app),
          child: const Scaffold(body: _ScopeProbe()),
        ),
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(_ScopeProbe)),
      );

      const humanId = 'h1';
      const rivalId = 'gp2';
      const spyId = 'spy1';
      const homeTile = 'oldWorld|p1|0|0';
      const destTile = 'oldWorld|p2|0|0';

      final game = Game(
        id: 'g_spy_move_handler',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                displayName: 'Home',
                ownerId: humanId,
              ),
              Province(
                id: 'oldWorld|p2',
                regionId: 'oldWorld',
                displayName: 'Rival Land',
                ownerId: rivalId,
              ),
            ],
            units: [
              Unit(
                id: spyId,
                type: kUnitTypeSpy,
                ownerId: humanId,
                locationProvinceId: 'oldWorld|p1',
                tileKey: homeTile,
                status: UnitStatus.idle,
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: const {
            'oldWorld': {
              'oldWorld|p1': [homeTile, 'oldWorld|p1|1|0'],
              'oldWorld|p2': [destTile, 'oldWorld|p2|1|0'],
            },
          },
          playerVisibilityByTile: const {
            humanId: {
              homeTile: 'fullyVisible',
              destTile: 'fullyVisible',
              'oldWorld|p1|1|0': 'fullyVisible',
              'oldWorld|p2|1|0': 'fullyVisible',
            },
          },
        ),
        players: const [
          Player(id: humanId, displayName: 'Human', isHuman: true),
          Player(id: rivalId, displayName: 'Rival', isHuman: false),
        ],
      );

      container.read(currentGameProvider.notifier).setGame(game);
      container.read(currentOrdersProvider.notifier).replaceAll(const Orders());

      bus.emit(
        CivilianMoveRequestedEvent(
          humanPlayerId: humanId,
          moveOrder: const MoveOrder(
            unitId: spyId,
            destinationTileKey: destTile,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final nextOrders = container.read(currentOrdersProvider);
      final moveOrders = nextOrders.moveOrdersByPlayerId[humanId] ?? const [];
      expect(moveOrders, hasLength(1));
      expect(moveOrders.single.unitId, spyId);
      expect(moveOrders.single.destinationTileKey, destTile);
    },
  );

  testWidgets(
    'CivilianMoveRequestedEvent clears conflicting counter-spy WorkOrder (Refs #4219)',
    (tester) async {
      final bus = AppEventBus.create();

      await tester.pumpWidget(
        buildAppShell(
          overrides: [
            appEventBusProvider.overrideWith((ref) {
              ref.onDispose(bus.dispose);
              return bus;
            }),
          ],
          shellWrapper: (app) => AppEventHandlerScope(child: app),
          child: const Scaffold(body: _ScopeProbe()),
        ),
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(_ScopeProbe)),
      );

      const humanId = 'h1';
      const rivalId = 'gp2';
      const spyId = 'spy1';
      const homeTile = 'oldWorld|p1|0|0';
      const destTile = 'oldWorld|p2|0|0';

      final game = Game(
        id: 'g_spy_move_xor_work',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                displayName: 'Home',
                ownerId: humanId,
              ),
              Province(
                id: 'oldWorld|p2',
                regionId: 'oldWorld',
                displayName: 'Rival Land',
                ownerId: rivalId,
              ),
            ],
            units: [
              Unit(
                id: spyId,
                type: kUnitTypeSpy,
                ownerId: humanId,
                locationProvinceId: 'oldWorld|p1',
                tileKey: homeTile,
                status: UnitStatus.idle,
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: const {
            'oldWorld': {
              'oldWorld|p1': [homeTile],
              'oldWorld|p2': [destTile],
            },
          },
          playerVisibilityByTile: const {
            humanId: {
              homeTile: 'fullyVisible',
              destTile: 'fullyVisible',
            },
          },
        ),
        players: const [
          Player(id: humanId, displayName: 'Human', isHuman: true),
          Player(id: rivalId, displayName: 'Rival', isHuman: false),
        ],
      );

      container.read(currentGameProvider.notifier).setGame(game);
      container
          .read(currentOrdersProvider.notifier)
          .replaceAll(
            Orders(
              workOrdersByPlayerId: {
                humanId: [
                  WorkOrder(
                    unitId: spyId,
                    target: kWorkTargetCounterSpy,
                    targetTileKey: homeTile,
                  ),
                ],
              },
            ),
          );

      bus.emit(
        CivilianMoveRequestedEvent(
          humanPlayerId: humanId,
          moveOrder: const MoveOrder(
            unitId: spyId,
            destinationTileKey: destTile,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final nextOrders = container.read(currentOrdersProvider);
      expect(nextOrders.workOrdersByPlayerId[humanId], isEmpty);
      final moveOrders = nextOrders.moveOrdersByPlayerId[humanId] ?? const [];
      expect(moveOrders.single.destinationTileKey, destTile);
    },
  );
}
