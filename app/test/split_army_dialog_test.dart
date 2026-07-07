import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/unit_orders/split_army_dialog.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_transfer_list.dart';

Widget _openDialogButton(VoidCallback onOpen) {
  return TextButton(onPressed: onOpen, child: const Text('open'));
}

void main() {
  suppressLogsForTests();

  Game gameWithArmy({required Army army, required List<Unit> units}) {
    const province = Province(
      id: 'cap',
      regionId: 'oldWorld',
      displayName: 'Lisbon',
    );
    return Game(
      id: 'g1',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
        oldWorld: RegionData(provinces: const [province], units: units),
        newWorld: const RegionData(),
      ),
      players: const [
        Player(id: 'gp1', displayName: 'Human', isHuman: true, treasury: 0),
      ],
    );
  }

  Future<void> openDialog(
    WidgetTester tester, {
    required Army army,
    required Game game,
    required bool isHomeArmy,
    required AppEventBus bus,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return _openDialogButton(() {
                showDialog<void>(
                  context: context,
                  builder: (ctx) => SplitArmyDialog(
                    army: army,
                    game: game,
                    humanPlayerId: 'gp1',
                    isHomeArmy: isHomeArmy,
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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  List<Unit> threeLevyOneMusk() => [
    Unit(
      id: 'levy_1',
      type: 'peasant_levy',
      ownerId: 'gp1',
      locationProvinceId: 'oldWorld|cap',
    ),
    Unit(
      id: 'levy_2',
      type: 'peasant_levy',
      ownerId: 'gp1',
      locationProvinceId: 'oldWorld|cap',
    ),
    Unit(
      id: 'levy_3',
      type: 'peasant_levy',
      ownerId: 'gp1',
      locationProvinceId: 'oldWorld|cap',
    ),
    Unit(
      id: 'mus_1',
      type: 'musketeer',
      ownerId: 'gp1',
      locationProvinceId: 'oldWorld|cap',
    ),
  ];

  testWidgets('same-type regiments show single row with aggregate count', (
    WidgetTester tester,
  ) async {
    final army = Army(
      id: 'army_1',
      ownerId: 'gp1',
      regionId: 'oldWorld',
      stationedProvinceId: 'oldWorld|cap',
      regimentUnitIds: const ['levy_1', 'levy_2', 'levy_3', 'mus_1'],
    );
    final game = gameWithArmy(army: army, units: threeLevyOneMusk());

    await openDialog(
      tester,
      army: army,
      game: game,
      isHomeArmy: false,
      bus: AppEventBus.create(),
    );

    expect(find.text('peasant_levy (3)'), findsOneWidget);
    expect(find.text('musketeer (1)'), findsOneWidget);
  });

  testWidgets('moving one levy updates both columns', (
    WidgetTester tester,
  ) async {
    final army = Army(
      id: 'army_1',
      ownerId: 'gp1',
      regionId: 'oldWorld',
      stationedProvinceId: 'oldWorld|cap',
      regimentUnitIds: const ['levy_1', 'levy_2', 'levy_3', 'mus_1'],
    );
    final game = gameWithArmy(army: army, units: threeLevyOneMusk());

    await openDialog(
      tester,
      army: army,
      game: game,
      isHomeArmy: false,
      bus: AppEventBus.create(),
    );

    await tester.tap(
      find.byKey(CtTransferListKeys.leftMoveOne('peasant_levy')),
    );
    await tester.pump();

    expect(find.text('peasant_levy (2)'), findsOneWidget);
    expect(find.text('peasant_levy (1)'), findsOneWidget);
    expect(find.text('musketeer (1)'), findsOneWidget);
  });

  testWidgets('confirm emits first regiments in army order for moved counts', (
    WidgetTester tester,
  ) async {
    ArmySplitRequestedEvent? captured;
    final bus = AppEventBus.create();
    final sub = bus.on<ArmySplitRequestedEvent>().listen((e) {
      captured = e;
    });
    addTearDown(sub.cancel);

    final army = Army(
      id: 'army_1',
      ownerId: 'gp1',
      regionId: 'oldWorld',
      stationedProvinceId: 'oldWorld|cap',
      regimentUnitIds: const ['levy_1', 'levy_2', 'levy_3', 'mus_1'],
    );
    final game = gameWithArmy(army: army, units: threeLevyOneMusk());

    await openDialog(
      tester,
      army: army,
      game: game,
      isHomeArmy: false,
      bus: bus,
    );

    await tester.tap(
      find.byKey(CtTransferListKeys.leftMoveOne('peasant_levy')),
    );
    await tester.pump();
    await tester.tap(find.text('Confirm Split'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(captured, isNotNull);
    expect(captured!.sourceArmyId, army.id);
    expect(captured!.humanPlayerId, 'gp1');
    expect(captured!.unitIdsToMove, ['levy_1']);
  });

  testWidgets('home army can confirm when original side is empty', (
    WidgetTester tester,
  ) async {
    ArmySplitRequestedEvent? captured;
    final bus = AppEventBus.create();
    final sub = bus.on<ArmySplitRequestedEvent>().listen((e) {
      captured = e;
    });
    addTearDown(sub.cancel);

    final units = [
      Unit(
        id: 'only',
        type: 'peasant_levy',
        ownerId: 'gp1',
        locationProvinceId: 'oldWorld|cap',
      ),
    ];
    final army = Army(
      id: 'home_army',
      ownerId: 'gp1',
      regionId: 'oldWorld',
      stationedProvinceId: 'oldWorld|cap',
      regimentUnitIds: const ['only'],
      isHomeArmy: true,
    );
    final game = gameWithArmy(army: army, units: units);

    await openDialog(
      tester,
      army: army,
      game: game,
      isHomeArmy: true,
      bus: bus,
    );

    await tester.tap(
      find.byKey(CtTransferListKeys.leftMoveAll('peasant_levy')),
    );
    await tester.pump();

    expect(find.text('No regiments'), findsOneWidget);
    final button = tester.widget<CtNinePatchButton>(
      find.widgetWithText(CtNinePatchButton, 'Confirm Split'),
    );
    expect(button.enabled, isTrue);

    await tester.tap(find.text('Confirm Split'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(captured?.unitIdsToMove, ['only']);
  });
}
