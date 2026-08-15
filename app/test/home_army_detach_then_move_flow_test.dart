import 'dart:async';

import 'package:colonizethis_app/features/game/widgets/unit_orders/home_army_detach_then_move_flow.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/move_army_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/split_army_dialog.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_transfer_list.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_world/colonizethis_world.dart' show applyArmySplit;
import 'package:flutter_test/flutter_test.dart';

import 'move_dialogs_specs_test_support.dart';

void main() {
  suppressLogsForTests();

  const playerId = 'gp_detach';
  const from = 'oldWorld|p_from';
  const dest = 'oldWorld|p_dest';

  MapTopology topology() => const MapTopology(
    nodes: [
      TopologyNode(
        id: from,
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: dest,
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: [TopologyEdge(id1: from, id2: dest)],
  );

  Game buildGame() {
    return Game(
      id: 'g_detach',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(
          provinces: const [
            Province(
              id: from,
              regionId: 'oldWorld',
              ownerId: playerId,
              displayName: 'From',
            ),
            Province(
              id: dest,
              regionId: 'oldWorld',
              ownerId: playerId,
              displayName: 'Dest',
            ),
          ],
          units: [
            Unit(
              id: 'u1',
              type: 'pikemen',
              ownerId: playerId,
              locationProvinceId: from,
            ),
          ],
        ),
        newWorld: const RegionData(),
        armies: const [
          Army(
            id: 'home',
            ownerId: playerId,
            regionId: 'oldWorld',
            stationedProvinceId: from,
            regimentUnitIds: ['u1'],
            isHomeArmy: true,
          ),
        ],
        tileKeysByRegionAndProvince: const {
          'oldWorld': {
            from: ['oldWorld|p_from|0|0'],
            dest: ['oldWorld|p_dest|0|0'],
          },
        },
        playerVisibilityByTile: const {
          playerId: {
            'oldWorld|p_from|0|0': 'fullyVisible',
            'oldWorld|p_dest|0|0': 'fullyVisible',
          },
        },
      ),
      players: const [
        Player(
          id: playerId,
          displayName: 'Human',
          isHuman: true,
          capitalProvinceId: from,
        ),
      ],
    );
  }

  test('newFieldArmyAfterSplit reads the created non-Home army', () {
    final before = buildGame();
    final after = applyArmySplit(
      game: before,
      playerId: playerId,
      sourceArmyId: 'home',
      unitIdsToMove: const ['u1'],
    );
    final created = newFieldArmyAfterSplit(before: before, after: after);
    expect(created, isNotNull);
    expect(created!.isHomeArmy, isFalse);
    expect(created.regimentUnitIds, ['u1']);
    expect(created.id, isNot(equals('home')));
  });

  testWidgets('confirm split then cancel DLG20001 emits no army move', (
    tester,
  ) async {
    final game = buildGame();
    final bus = AppEventBus();
    final l10n = AppLocalizationsEn();
    ArmyMoveRequestedEvent? move;
    final splitSub = bus.on<ArmySplitRequestedEvent>().listen((event) {
      final next = applyArmySplit(
        game: game,
        playerId: event.humanPlayerId,
        sourceArmyId: event.sourceArmyId,
        unitIdsToMove: event.unitIdsToMove,
      );
      bus.emit(LandArmiesUpdatedEvent(game: next));
    });
    final moveSub = bus.on<ArmyMoveRequestedEvent>().listen((event) {
      move = event;
    });
    addTearDown(() async {
      await splitSub.cancel();
      await moveSub.cancel();
    });

    await tester.pumpWidget(
      moveDialogsSpecsFrameWithOpener((context) {
        return () {
          unawaited(
            showHomeArmyDetachThenMoveFlow(
              context: context,
              game: game,
              topology: topology(),
              humanPlayerId: playerId,
              draftOrders: const Orders(),
              bus: bus,
            ),
          );
        };
      }),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(SplitArmyDialog), findsOneWidget);
    expect(find.text(l10n.splitArmy_detachTitle), findsOneWidget);

    await tester.tap(find.byKey(CtTransferListKeys.leftMoveAll('pikemen')));
    await tester.pump();
    final confirm = find.text(l10n.splitArmy_detachConfirm);
    await tester.ensureVisible(confirm);
    await tester.pumpAndSettle();
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(find.byType(MoveArmyDialog), findsOneWidget);
    expect(find.byType(SplitArmyDialog), findsNothing);
    expect(
      tester
          .widget<MoveArmyDialog>(find.byType(MoveArmyDialog))
          .army
          .isHomeArmy,
      isFalse,
    );

    await tester.tap(find.text(l10n.common_cancel));
    await tester.pumpAndSettle();

    expect(move, isNull);
    expect(find.byType(MoveArmyDialog), findsNothing);
  });

  testWidgets('confirm split then confirm move emits for the new field army', (
    tester,
  ) async {
    final game = buildGame();
    final bus = AppEventBus();
    final l10n = AppLocalizationsEn();
    ArmyMoveRequestedEvent? move;
    final splitSub = bus.on<ArmySplitRequestedEvent>().listen((event) {
      final next = applyArmySplit(
        game: game,
        playerId: event.humanPlayerId,
        sourceArmyId: event.sourceArmyId,
        unitIdsToMove: event.unitIdsToMove,
      );
      bus.emit(LandArmiesUpdatedEvent(game: next));
    });
    final moveSub = bus.on<ArmyMoveRequestedEvent>().listen((event) {
      move = event;
    });
    addTearDown(() async {
      await splitSub.cancel();
      await moveSub.cancel();
    });

    await tester.pumpWidget(
      moveDialogsSpecsFrameWithOpener((context) {
        return () {
          unawaited(
            showHomeArmyDetachThenMoveFlow(
              context: context,
              game: game,
              topology: topology(),
              humanPlayerId: playerId,
              draftOrders: const Orders(),
              bus: bus,
            ),
          );
        };
      }),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(CtTransferListKeys.leftMoveAll('pikemen')));
    await tester.pump();
    final detachConfirm = find.text(l10n.splitArmy_detachConfirm);
    await tester.ensureVisible(detachConfirm);
    await tester.pumpAndSettle();
    await tester.tap(detachConfirm);
    await tester.pumpAndSettle();

    final dialog = tester.widget<MoveArmyDialog>(find.byType(MoveArmyDialog));
    expect(dialog.army.isHomeArmy, isFalse);
    final newArmyId = dialog.army.id;

    await tester.tap(find.text('Dest'));
    await tester.pump();
    await tester.tap(
      find.widgetWithText(CtNinePatchButton, l10n.common_confirm),
    );
    await tester.pumpAndSettle();

    expect(move, isNotNull);
    expect(move!.moveOrder.armyId, newArmyId);
    expect(move!.moveOrder.armyId, isNot('home'));
    expect(find.byType(MoveArmyDialog), findsNothing);
  });

  testWidgets('cancel split does not open DLG20001', (tester) async {
    final game = buildGame();
    final bus = AppEventBus();
    final l10n = AppLocalizationsEn();
    ArmyMoveRequestedEvent? move;
    final moveSub = bus.on<ArmyMoveRequestedEvent>().listen((event) {
      move = event;
    });
    addTearDown(moveSub.cancel);

    await tester.pumpWidget(
      moveDialogsSpecsFrameWithOpener((context) {
        return () {
          unawaited(
            showHomeArmyDetachThenMoveFlow(
              context: context,
              game: game,
              topology: topology(),
              humanPlayerId: playerId,
              draftOrders: const Orders(),
              bus: bus,
            ),
          );
        };
      }),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(SplitArmyDialog), findsOneWidget);
    await tester.tap(find.text(l10n.common_cancel));
    await tester.pumpAndSettle();

    expect(find.byType(MoveArmyDialog), findsNothing);
    expect(find.byType(SplitArmyDialog), findsNothing);
    expect(move, isNull);
  });
}
