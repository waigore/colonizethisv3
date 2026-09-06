// Move army invasion vs general capacity line (#4233).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';

import 'move_army_general_capacity_cases.dart';

void main() {
  suppressLogsForTests();

  testWidgets('owned destination hides invasion capacity line', (tester) async {
    final game = buildMoveArmyGeneralCapacityGame(
      generals: const [General(id: 'g1', ownerId: kMoveArmyCapPlayerId)],
    );
    await pumpMoveArmyGeneralCapacityDialog(
      tester,
      game: game,
      draftOrders: const Orders(),
    );
    await tester.tap(find.text('Owned Dest'));
    await tester.pump();

    expect(find.textContaining('Invasions this turn'), findsNothing);
  });

  testWidgets('invasion destination shows invasion vs general counts', (
    tester,
  ) async {
    final draft = Orders(
      armyMoveOrdersByPlayerId: {
        kMoveArmyCapPlayerId: [
          const ArmyMoveOrder(
            armyId: 'a_other',
            destinationProvinceId: kMoveArmyCapInvasionDest,
          ),
        ],
      },
    );
    final game = buildMoveArmyGeneralCapacityGame(
      generals: const [
        General(id: 'g1', ownerId: kMoveArmyCapPlayerId),
        General(id: 'g2', ownerId: kMoveArmyCapPlayerId),
      ],
    );
    await pumpMoveArmyGeneralCapacityDialog(
      tester,
      game: game,
      draftOrders: draft,
    );

    await tester.tap(find.text('Invade Dest'));
    await tester.pump();

    expect(find.text('Invasions this turn: 2 · Generals: 2'), findsOneWidget);
    final confirm = find.widgetWithText(CtNinePatchButton, 'Confirm');
    expect(tester.widget<CtNinePatchButton>(confirm).onPressed, isNotNull);
  });

  testWidgets('soft warning when invasions exceed generals', (tester) async {
    final draft = Orders(
      armyMoveOrdersByPlayerId: {
        kMoveArmyCapPlayerId: [
          const ArmyMoveOrder(
            armyId: 'a_other',
            destinationProvinceId: kMoveArmyCapInvasionDest,
          ),
        ],
      },
    );
    final game = buildMoveArmyGeneralCapacityGame(
      generals: const [General(id: 'g1', ownerId: kMoveArmyCapPlayerId)],
      generalCap: 1,
    );
    await pumpMoveArmyGeneralCapacityDialog(
      tester,
      game: game,
      draftOrders: draft,
    );
    await tester.tap(find.text('Invade Dest'));
    await tester.pump();

    expect(find.text('Invasions this turn: 2 · Generals: 1'), findsOneWidget);
    expect(
      find.text(
        'More invasions than generals — extra armies fight with weaker command.',
      ),
      findsOneWidget,
    );
    final confirm = find.widgetWithText(CtNinePatchButton, 'Confirm');
    expect(tester.widget<CtNinePatchButton>(confirm).onPressed, isNotNull);
  });

  testWidgets('soft warning when land forces are underfed on invasion', (
    tester,
  ) async {
    final game = buildMoveArmyGeneralCapacityGame(
      stockpile: const Stockpile().applyDelta('grain', 2),
      extraUnits: [
        Unit(
          id: 'u2',
          type: 'pikemen',
          ownerId: kMoveArmyCapPlayerId,
          locationProvinceId: kMoveArmyCapFrom,
        ),
        Unit(
          id: 'u3',
          type: 'pikemen',
          ownerId: kMoveArmyCapPlayerId,
          locationProvinceId: kMoveArmyCapFrom,
        ),
      ],
    );
    await pumpMoveArmyGeneralCapacityDialog(
      tester,
      game: game,
      draftOrders: const Orders(),
    );
    await tester.tap(find.text('Invade Dest'));
    await tester.pump();

    expect(
      find.text(
        'Your armies are very short on rations — they will fight much weaker this turn.',
      ),
      findsOneWidget,
    );
    final confirm = find.widgetWithText(CtNinePatchButton, 'Confirm');
    expect(tester.widget<CtNinePatchButton>(confirm).onPressed, isNotNull);
  });
}
