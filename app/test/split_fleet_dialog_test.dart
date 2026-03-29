import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/split_fleet_dialog.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_transfer_list.dart';

Widget _openDialogButton(VoidCallback onOpen) {
  return TextButton(onPressed: onOpen, child: const Text('open'));
}

void main() {
  suppressLogsForTests();

  Game _minimalGame({required List<Province> provinces}) {
    return Game(
      id: 'g1',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
        oldWorld: RegionData(provinces: provinces),
        newWorld: const RegionData(),
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
    required void Function(List<String> ships) onConfirm,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
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
                    onConfirm: onConfirm,
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
      game: _minimalGame(provinces: const []),
      isHomeFleet: false,
      onConfirm: (_) {},
    );

    expect(find.text('carrack (3)'), findsOneWidget);
    await tester.tap(find.byKey(CtTransferListKeys.leftMoveOne('carrack')));
    await tester.pump();

    expect(find.text('carrack (2)'), findsOneWidget);
    expect(find.text('carrack (1)'), findsOneWidget);
    expect(find.text('fluyte (1)'), findsOneWidget);
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
        game: _minimalGame(provinces: const []),
        isHomeFleet: false,
        onConfirm: (_) {},
      );

      await tester.tap(find.byKey(CtTransferListKeys.leftMoveOne('carrack')));
      await tester.pump();
      expect(find.text('carrack (2)'), findsOneWidget);
      expect(find.text('carrack (1)'), findsOneWidget);

      await tester.tap(find.byKey(CtTransferListKeys.leftMoveAll('carrack')));
      await tester.pump();
      expect(find.text('carrack (3)'), findsOneWidget);
      expect(find.text('fluyte (1)'), findsOneWidget);
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
        game: _minimalGame(provinces: const []),
        isHomeFleet: false,
        onConfirm: (_) {},
      );

      await tester.tap(find.byKey(CtTransferListKeys.leftMoveAll('carrack')));
      await tester.pump();
      expect(find.text('carrack (3)'), findsOneWidget);
      expect(find.text('fluyte (1)'), findsOneWidget);

      await tester.tap(find.byKey(CtTransferListKeys.rightMoveAll('carrack')));
      await tester.pump();
      expect(find.text('carrack (3)'), findsOneWidget);
      expect(find.text('fluyte (1)'), findsOneWidget);
      expect(find.text('carrack (2)'), findsNothing);
      expect(find.text('carrack (1)'), findsNothing);
    },
  );

  testWidgets('confirm sends only ships shown on new fleet side', (
    WidgetTester tester,
  ) async {
    List<String>? captured;
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
      game: _minimalGame(provinces: const []),
      isHomeFleet: false,
      onConfirm: (ships) => captured = ships,
    );

    await tester.tap(find.byKey(CtTransferListKeys.leftMoveOne('carrack')));
    await tester.pump();
    await tester.tap(find.text('Confirm Split'));
    await tester.pumpAndSettle();

    expect(captured, [fleet.ships.first.id]);
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
      game: _minimalGame(provinces: const []),
      isHomeFleet: false,
      onConfirm: (_) {},
    );

    expect(find.text('carrack (2)'), findsOneWidget);
    await tester.tap(find.byKey(CtTransferListKeys.leftMoveOne('carrack')));
    await tester.pump();
    expect(find.text('carrack (1)'), findsNWidgets(2));

    await tester.tap(find.byKey(CtTransferListKeys.leftMoveAll('carrack')));
    await tester.pump();
    expect(find.text('carrack (2)'), findsOneWidget);
    expect(find.text('carrack (1)'), findsNothing);

    await tester.tap(find.byKey(CtTransferListKeys.rightMoveOne('carrack')));
    await tester.pump();
    expect(find.text('carrack (1)'), findsNWidgets(2));
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
      game: _minimalGame(provinces: const []),
      isHomeFleet: false,
      onConfirm: (_) {},
    );

    await tester.tap(find.byKey(CtTransferListKeys.leftMoveOne('fluyte')));
    await tester.pump();
    expect(find.text('fluyte (1)'), findsNWidgets(2));

    await tester.tap(find.byKey(CtTransferListKeys.rightMoveOne('fluyte')));
    await tester.pump();
    expect(find.text('fluyte (2)'), findsOneWidget);
    expect(find.text('fluyte (1)'), findsNothing);
  });

  testWidgets('home fleet can split to zero original ships', (
    WidgetTester tester,
  ) async {
    List<String>? captured;
    final fleet = Fleet(
      id: 'f1',
      ownerId: 'gp1',
      regionId: 'oldWorld',
      seaZoneId: 'oldWorld|s1',
      shipTypeIds: const ['carrack', 'fluyte'],
    );

    await openDialog(
      tester,
      fleet: fleet,
      game: _minimalGame(provinces: const []),
      isHomeFleet: false,
      onConfirm: (_) {},
    );

    expect(buttonEnabled(tester, '<'), isFalse);
    expect(buttonEnabled(tester, '>'), isFalse);
    expect(buttonEnabled(tester, '<<'), isFalse);
    expect(buttonEnabled(tester, '>>'), isFalse);
  });

  testWidgets('selected type supports one and all transfers with exact counts', (
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
      game: _minimalGame(provinces: const []),
      isHomeFleet: false,
      onConfirm: (_) {},
    );

    expect(find.text('carrack (2)'), findsOneWidget);
    await tester.tap(find.text('carrack (2)'));
    await tester.pump();

    await tester.tap(find.widgetWithText(CtNinePatchButton, '>'));
    await tester.pump();
    expect(find.text('carrack (1)'), findsNWidgets(2));

    await tester.tap(find.widgetWithText(CtNinePatchButton, '>>'));
    await tester.pump();
    expect(find.text('carrack (2)'), findsOneWidget);
    expect(find.text('carrack (1)'), findsNothing);

    await tester.tap(find.widgetWithText(CtNinePatchButton, '<'));
    await tester.pump();
    expect(find.text('carrack (1)'), findsNWidgets(2));
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
      game: _minimalGame(provinces: const []),
      isHomeFleet: false,
      onConfirm: (_) {},
    );

    await tester.tap(find.text('fluyte (2)'));
    await tester.pump();
    await tester.tap(find.widgetWithText(CtNinePatchButton, '>'));
    await tester.pump();
    expect(find.text('fluyte (1)'), findsNWidgets(2));

    await tester.tap(find.widgetWithText(CtNinePatchButton, '<'));
    await tester.pump();
    expect(find.text('fluyte (2)'), findsOneWidget);
    expect(find.text('fluyte (1)'), findsNothing);
  });

  testWidgets('home fleet can split to zero original ships', (
    WidgetTester tester,
  ) async {
    List<String>? captured;
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
      game: _minimalGame(provinces: const []),
      isHomeFleet: true,
      onConfirm: (ships) => captured = ships,
    );

    await tester.tap(find.byKey(CtTransferListKeys.leftMoveAll('carrack')));
    await tester.pump();

    expect(find.text('No ships'), findsOneWidget);
    expect(buttonEnabled(tester, 'Confirm Split'), isTrue);

    await tester.tap(find.text('Confirm Split'));
    await tester.pumpAndSettle();
    expect(captured, isNotNull);
    expect(captured, hasLength(1));
    expect(captured!.first, fleet.ships.single.id);
  });
}
