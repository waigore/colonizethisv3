// Hive + pump helpers for civilian-work AppEventHandlerScope tests (Refs #4582).

import 'dart:io';

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kUnitTypeExplorer, kUnitTypeSpy;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_shell_harness.dart';
import 'app_test_hive_harness.dart';

class CivilianWorkScopeProbe extends ConsumerWidget {
  const CivilianWorkScopeProbe();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(currentOrdersProvider);
    return const SizedBox.shrink();
  }
}

Future<void> openCivilianWorkHive() async {
  await openAppTestHiveBox(suiteId: 'app_event_handler_scope_civilian_work');
}

Future<void> closeCivilianWorkHive() async {
  await Hive.box<dynamic>(HiveBoxNames.games).clear();
  await Hive.close();
  final dir = Directory(
    './.dart_tool/test_hive_app_event_handler_scope_civilian_work',
  );
  if (dir.existsSync()) {
    await dir.delete(recursive: true);
  }
}

Future<ProviderContainer> pumpCivilianWorkScope(
  WidgetTester tester,
  AppEventBus bus,
) async {
  await tester.pumpWidget(
    buildAppShell(
      overrides: [
        appEventBusProvider.overrideWith((ref) {
          ref.onDispose(bus.dispose);
          return bus;
        }),
      ],
      shellWrapper: (app) => AppEventHandlerScope(child: app),
      child: const Scaffold(body: CivilianWorkScopeProbe()),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(
    tester.element(find.byType(CivilianWorkScopeProbe)),
  );
}

Game civilianWorkTwoExplorerGame({
  required String playerId,
  required String explorerId,
  required String secondExplorerId,
}) {
  return Game(
    id: 'g_upsert_validation_once',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: playerId),
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
      playerVisibilityByTile: {
        playerId: {
          'oldWorld|p1|0|0': 'fullyVisible',
          'oldWorld|p1|0|1': 'unknown',
        },
      },
    ),
    players: [
      Player(id: playerId, displayName: 'Human', isHuman: true, treasury: 5000),
    ],
  );
}

Game civilianWorkSpyMoveGame({
  required String humanId,
  required String rivalId,
  required String spyId,
  required String homeTile,
  required String destTile,
  required String gameId,
}) {
  return Game(
    id: gameId,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
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
      tileKeysByRegionAndProvince: {
        'oldWorld': {
          'oldWorld|p1': [homeTile, 'oldWorld|p1|1|0'],
          'oldWorld|p2': [destTile, 'oldWorld|p2|1|0'],
        },
      },
      playerVisibilityByTile: {
        humanId: {
          homeTile: 'fullyVisible',
          destTile: 'fullyVisible',
          'oldWorld|p1|1|0': 'fullyVisible',
          'oldWorld|p2|1|0': 'fullyVisible',
        },
      },
    ),
    players: [
      Player(id: humanId, displayName: 'Human', isHuman: true),
      Player(id: rivalId, displayName: 'Rival', isHuman: false),
    ],
  );
}
