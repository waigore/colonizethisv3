import 'dart:async';

import 'package:colonizethis_app/features/game/widgets/unit_orders/home_fleet_detach_then_sail_flow.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/move_fleet_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/split_fleet_dialog.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_transfer_list.dart';
import 'package:colonizethis_app_l10n/l10n/app_localizations_en.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_world/colonizethis_world.dart'
    show applyNavalSplitFleet, homeFleetIdFor;
import 'package:flutter_test/flutter_test.dart';

import 'move_dialogs_specs_test_support.dart';
import 'naval_units_panel_test_support.dart';

void main() {
  suppressLogsForTests();

  const playerId = 'gp_detach_sail';
  final l10n = AppLocalizationsEn();

  Game buildGame({
    List<ShipInstance> homeShips = const [
      ShipInstance(id: 'home_1', typeId: 'carrack'),
    ],
  }) {
    return buildNavalPanelCapitalHomeAndPeersGame(
      humanId: playerId,
      gameId: 'g_detach_sail',
      displayName: 'Detach Sail',
      peerFleets: const [],
      homeShips: homeShips,
    );
  }

  test('newSeaGoingFleetAfterSplit reads the created non-Home fleet', () {
    final before = buildGame();
    final after = applyNavalSplitFleet(
      game: before,
      humanPlayerId: playerId,
      originalFleetId: homeFleetIdFor(playerId),
      shipInstanceIdsToNewFleet: const ['home_1'],
    );
    final created = newSeaGoingFleetAfterSplit(before: before, after: after);
    expect(created, isNotNull);
    expect(created!.id, isNot(equals(homeFleetIdFor(playerId))));
    expect(created.ships.map((s) => s.id), ['home_1']);
  });

  testWidgets('confirm split then cancel DLG30001 emits no fleet move', (
    tester,
  ) async {
    final game = buildGame();
    final bus = AppEventBus.create();
    NavalMoveFleetRequestedEvent? move;
    final splitSub = bus.on<NavalSplitFleetRequestedEvent>().listen((event) {
      final next = applyNavalSplitFleet(
        game: game,
        humanPlayerId: event.humanPlayerId,
        originalFleetId: event.originalFleetId,
        shipInstanceIdsToNewFleet: event.shipInstanceIdsToNewFleet,
      );
      bus.emit(NavalFleetsUpdatedEvent(game: next));
    });
    final moveSub = bus.on<NavalMoveFleetRequestedEvent>().listen((event) {
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
            showHomeFleetDetachThenSailFlow(
              context: context,
              game: game,
              topology: buildUnitsPanelCapitalAdjacentSeaTopology(),
              humanPlayerId: playerId,
              bus: bus,
            ),
          );
        };
      }),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(SplitFleetDialog), findsOneWidget);
    expect(find.text(l10n.splitFleet_detachTitle), findsOneWidget);

    await tester.tap(find.byKey(CtTransferListKeys.leftMoveAll('carrack')));
    await tester.pump();
    final confirm = find.text(l10n.splitFleet_detachConfirm);
    await tester.ensureVisible(confirm);
    await tester.pumpAndSettle();
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(find.byType(MoveFleetDialog), findsOneWidget);
    expect(find.byType(SplitFleetDialog), findsNothing);
    expect(
      tester.widget<MoveFleetDialog>(find.byType(MoveFleetDialog)).fleet.id,
      isNot(equals(homeFleetIdFor(playerId))),
    );

    await tester.tap(find.text(l10n.common_cancel));
    await tester.pumpAndSettle();

    expect(move, isNull);
    expect(find.byType(MoveFleetDialog), findsNothing);
  });

  testWidgets('confirm split then confirm move emits for the new fleet', (
    tester,
  ) async {
    final game = buildGame();
    final bus = AppEventBus.create();
    NavalMoveFleetRequestedEvent? move;
    final splitSub = bus.on<NavalSplitFleetRequestedEvent>().listen((event) {
      final next = applyNavalSplitFleet(
        game: game,
        humanPlayerId: event.humanPlayerId,
        originalFleetId: event.originalFleetId,
        shipInstanceIdsToNewFleet: event.shipInstanceIdsToNewFleet,
      );
      bus.emit(NavalFleetsUpdatedEvent(game: next));
    });
    final moveSub = bus.on<NavalMoveFleetRequestedEvent>().listen((event) {
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
            showHomeFleetDetachThenSailFlow(
              context: context,
              game: game,
              topology: buildUnitsPanelCapitalAdjacentSeaTopology(),
              humanPlayerId: playerId,
              bus: bus,
            ),
          );
        };
      }),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(CtTransferListKeys.leftMoveAll('carrack')));
    await tester.pump();
    final detachConfirm = find.text(l10n.splitFleet_detachConfirm);
    await tester.ensureVisible(detachConfirm);
    await tester.pumpAndSettle();
    await tester.tap(detachConfirm);
    await tester.pumpAndSettle();

    final dialog = tester.widget<MoveFleetDialog>(find.byType(MoveFleetDialog));
    expect(dialog.fleet.id, isNot(equals(homeFleetIdFor(playerId))));
    final newFleetId = dialog.fleet.id;

    await tester.tap(find.text('zone_alpha'));
    await tester.pump();
    await tester.tap(
      find.widgetWithText(CtNinePatchButton, l10n.common_confirm),
    );
    await tester.pumpAndSettle();

    expect(move, isNotNull);
    expect(move!.moveOrder.fleetId, newFleetId);
    expect(move!.moveOrder.fleetId, isNot(homeFleetIdFor(playerId)));
    expect(find.byType(MoveFleetDialog), findsNothing);
  });

  testWidgets('cancel split does not open DLG30001', (tester) async {
    final game = buildGame();
    final bus = AppEventBus.create();
    NavalMoveFleetRequestedEvent? move;
    final moveSub = bus.on<NavalMoveFleetRequestedEvent>().listen((event) {
      move = event;
    });
    addTearDown(moveSub.cancel);

    await tester.pumpWidget(
      moveDialogsSpecsFrameWithOpener((context) {
        return () {
          unawaited(
            showHomeFleetDetachThenSailFlow(
              context: context,
              game: game,
              topology: buildUnitsPanelCapitalAdjacentSeaTopology(),
              humanPlayerId: playerId,
              bus: bus,
            ),
          );
        };
      }),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(SplitFleetDialog), findsOneWidget);
    await tester.tap(find.text(l10n.common_cancel));
    await tester.pumpAndSettle();

    expect(find.byType(MoveFleetDialog), findsNothing);
    expect(find.byType(SplitFleetDialog), findsNothing);
    expect(move, isNull);
  });
}
