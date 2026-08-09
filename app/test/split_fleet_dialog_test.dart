import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/unit_orders/split_fleet_dialog.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_transfer_list.dart';

import 'app_shell_harness.dart';

Widget _openDialogButton(VoidCallback onOpen) {
  return TextButton(onPressed: onOpen, child: const Text('open'));
}

void main() {
  suppressLogsForTests();

  Game minimalGame({
    required List<Province> provinces,
    Map<String, String> seaZoneDisplayNameById = const {},
  }) {
    return Game(
      id: 'g1',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
        oldWorld: RegionData(provinces: provinces),
        newWorld: const RegionData(),
        seaZoneDisplayNameById: seaZoneDisplayNameById,
      ),
      players: const [
        Player(id: 'gp1', displayName: 'Human', isHuman: true, treasury: 0),
      ],
    );
  }

  Future<void> openDialog(
    WidgetTester tester, {
    required Fleet fleet,
    required Game game,
    required bool isHomeFleet,
    required AppEventBus bus,
  }) async {
    // Editorial shell via buildAppShell (Refs #4035 — no inline MaterialApp).
    await tester.pumpWidget(
      buildAppShell(
        child: Scaffold(
          body: Builder(
            builder: (context) {
              return _openDialogButton(() {
                showDialog<void>(
                  context: context,
                  builder: (ctx) => SplitFleetDialog(
                    originalFleet: fleet,
                    game: game,
                    humanPlayerId: 'gp1',
                    isHomeFleet: isHomeFleet,
                    bus: bus,
                  ),
                );
              });
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('at-sea location subtitle uses sea-zone display name', (
    WidgetTester tester,
  ) async {
    final fleet = Fleet(
      id: 'f_sea_label',
      ownerId: 'gp1',
      regionId: 'oldWorld',
      seaZoneId: 's1',
      shipTypeIds: const ['carrack'],
    );

    await openDialog(
      tester,
      fleet: fleet,
      game: minimalGame(
        provinces: const [],
        seaZoneDisplayNameById: const {'oldWorld|s1': 'Adriatic Display'},
      ),
      isHomeFleet: false,
      bus: AppEventBus.create(),
    );

    expect(find.textContaining('Adriatic Display'), findsWidgets);
  });

  bool buttonEnabled(WidgetTester tester, String label) {
    final button = tester.widget<CtNinePatchButton>(
      find.widgetWithText(CtNinePatchButton, label),
    );
    return button.enabled;
  }

  testWidgets('moving exactly one from three of a type leaves 2 and 1', (
    WidgetTester tester,
  ) async {
    final fleet = Fleet(
      id: 'f1',
      ownerId: 'gp1',
      regionId: 'oldWorld',
      seaZoneId: 'oldWorld|s1',
      shipTypeIds: const ['carrack', 'carrack', 'carrack', 'fluyte'],
    );

    await openDialog(
      tester,
      fleet: fleet,
      game: minimalGame(provinces: const []),
      isHomeFleet: false,
      bus: AppEventBus.create(),
    );

    expect(find.text('Carrack (3)'), findsOneWidget);
    await tester.tap(find.byKey(CtTransferListKeys.leftMoveOne('carrack')));
    await tester.pump();

    expect(find.text('Carrack (2)'), findsOneWidget);
    expect(find.text('Carrack (1)'), findsOneWidget);
    expect(find.text('Fluyte (1)'), findsOneWidget);
  });

  testWidgets(
    'bulk >> moves all remaining of a type after a single-carrier move (non-Home)',
    (WidgetTester tester) async {
      final fleet = Fleet(
        id: 'f1b',
        ownerId: 'gp1',
        regionId: 'oldWorld',
        seaZoneId: 'oldWorld|s1',
        shipTypeIds: const ['carrack', 'carrack', 'carrack', 'fluyte'],
      );

      await openDialog(
        tester,
        fleet: fleet,
        game: minimalGame(provinces: const []),
        isHomeFleet: false,
        bus: AppEventBus.create(),
      );

      await tester.tap(find.byKey(CtTransferListKeys.leftMoveOne('carrack')));
      await tester.pump();
      expect(find.text('Carrack (2)'), findsOneWidget);
      expect(find.text('Carrack (1)'), findsOneWidget);

      await tester.tap(find.byKey(CtTransferListKeys.leftMoveAll('carrack')));
      await tester.pump();
      expect(find.text('Carrack (3)'), findsOneWidget);
      expect(find.text('Fluyte (1)'), findsOneWidget);
    },
  );

  testWidgets(
    '<< moves all of a type from new back to original in one action',
    (WidgetTester tester) async {
      final fleet = Fleet(
        id: 'f1c',
        ownerId: 'gp1',
        regionId: 'oldWorld',
        seaZoneId: 'oldWorld|s1',
        shipTypeIds: const ['carrack', 'carrack', 'carrack', 'fluyte'],
      );

      await openDialog(
        tester,
        fleet: fleet,
        game: minimalGame(provinces: const []),
        isHomeFleet: false,
        bus: AppEventBus.create(),
      );

      await tester.tap(find.byKey(CtTransferListKeys.leftMoveAll('carrack')));
      await tester.pump();
      expect(find.text('Carrack (3)'), findsOneWidget);
      expect(find.text('Fluyte (1)'), findsOneWidget);

      await tester.tap(find.byKey(CtTransferListKeys.rightMoveAll('carrack')));
      await tester.pump();
      expect(find.text('Carrack (3)'), findsOneWidget);
      expect(find.text('Fluyte (1)'), findsOneWidget);
      expect(find.text('Carrack (2)'), findsNothing);
      expect(find.text('Carrack (1)'), findsNothing);
    },
  );

  testWidgets('confirm emits split request with only ships on new fleet side', (
    WidgetTester tester,
  ) async {
    NavalSplitFleetRequestedEvent? captured;
    final bus = AppEventBus.create();
    final sub = bus.on<NavalSplitFleetRequestedEvent>().listen((e) {
      captured = e;
    });
    addTearDown(sub.cancel);

    final fleet = Fleet(
      id: 'f1d',
      ownerId: 'gp1',
      regionId: 'oldWorld',
      seaZoneId: 'oldWorld|s1',
      shipTypeIds: const ['carrack', 'carrack', 'fluyte'],
    );

    await openDialog(
      tester,
      fleet: fleet,
      game: minimalGame(provinces: const []),
      isHomeFleet: false,
      bus: bus,
    );

    await tester.tap(find.byKey(CtTransferListKeys.leftMoveOne('carrack')));
    await tester.pump();
    await tester.tap(find.text('Confirm Split'));
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured!.shipInstanceIdsToNewFleet, [fleet.ships.first.id]);
    expect(captured!.originalFleetId, fleet.id);
    expect(captured!.humanPlayerId, 'gp1');
  });

  testWidgets('per-row controls: one and all transfers with exact counts', (
    WidgetTester tester,
  ) async {
    final fleet = Fleet(
      id: 'f2',
      ownerId: 'gp1',
      regionId: 'oldWorld',
      seaZoneId: 'oldWorld|s1',
      shipTypeIds: const ['carrack', 'carrack', 'fluyte'],
    );

    await openDialog(
      tester,
      fleet: fleet,
      game: minimalGame(provinces: const []),
      isHomeFleet: false,
      bus: AppEventBus.create(),
    );

    expect(find.text('Carrack (2)'), findsOneWidget);
    await tester.tap(find.byKey(CtTransferListKeys.leftMoveOne('carrack')));
    await tester.pump();
    expect(find.text('Carrack (1)'), findsNWidgets(2));

    await tester.tap(find.byKey(CtTransferListKeys.leftMoveAll('carrack')));
    await tester.pump();
    expect(find.text('Carrack (2)'), findsOneWidget);
    expect(find.text('Carrack (1)'), findsNothing);

    await tester.tap(find.byKey(CtTransferListKeys.rightMoveOne('carrack')));
    await tester.pump();
    expect(find.text('Carrack (1)'), findsNWidgets(2));
  });

  testWidgets('arrow semantics: < is right-to-left and > is left-to-right', (
    WidgetTester tester,
  ) async {
    final fleet = Fleet(
      id: 'f3',
      ownerId: 'gp1',
      regionId: 'oldWorld',
      seaZoneId: 'oldWorld|s1',
      shipTypeIds: const ['fluyte', 'fluyte'],
    );

    await openDialog(
      tester,
      fleet: fleet,
      game: minimalGame(provinces: const []),
      isHomeFleet: false,
      bus: AppEventBus.create(),
    );

    await tester.tap(find.byKey(CtTransferListKeys.leftMoveOne('fluyte')));
    await tester.pump();
    expect(find.text('Fluyte (1)'), findsNWidgets(2));

    await tester.tap(find.byKey(CtTransferListKeys.rightMoveOne('fluyte')));
    await tester.pump();
    expect(find.text('Fluyte (2)'), findsOneWidget);
    expect(find.text('Fluyte (1)'), findsNothing);
  });

  testWidgets('home fleet can split to zero original ships', (
    WidgetTester tester,
  ) async {
    NavalSplitFleetRequestedEvent? captured;
    final bus = AppEventBus.create();
    final sub = bus.on<NavalSplitFleetRequestedEvent>().listen((e) {
      captured = e;
    });
    addTearDown(sub.cancel);

    final fleet = Fleet(
      id: 'home_fleet',
      ownerId: 'gp1',
      regionId: 'oldWorld',
      seaZoneId: 'oldWorld|s1',
      shipTypeIds: const ['carrack'],
    );

    await openDialog(
      tester,
      fleet: fleet,
      game: minimalGame(provinces: const []),
      isHomeFleet: true,
      bus: bus,
    );

    await tester.tap(find.byKey(CtTransferListKeys.leftMoveAll('carrack')));
    await tester.pump();

    expect(find.text('No ships'), findsOneWidget);
    expect(buttonEnabled(tester, 'Confirm Split'), isTrue);

    await tester.tap(find.text('Confirm Split'));
    await tester.pumpAndSettle();
    expect(captured, isNotNull);
    expect(captured!.shipInstanceIdsToNewFleet, hasLength(1));
    expect(captured!.shipInstanceIdsToNewFleet.first, fleet.ships.single.id);
  });
}
