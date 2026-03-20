import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/split_fleet_dialog.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';

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

  testWidgets(
    'SplitFleetDialog at sea shows region label and can confirm split',
    (WidgetTester tester) async {
      List<String>? captured;
      final fleet = Fleet(
        id: 'f1',
        ownerId: 'gp1',
        regionId: 'oldWorld',
        seaZoneId: 'oldWorld|s1',
        shipTypeIds: const ['carrack', 'carrack', 'fluyte'],
      );
      final game = _minimalGame(provinces: const []);

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
                      isHomeFleet: false,
                      onConfirm: (ships) => captured = ships,
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

      expect(find.textContaining('Region'), findsWidgets);

      await tester.tap(find.byIcon(Icons.arrow_forward).first);
      await tester.pump();
      await tester.tap(find.text('Confirm Split'));
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(captured!.length, 1);
    },
  );

  testWidgets(
    'SplitFleetDialog in port shows province name and home fleet blocks moves',
    (WidgetTester tester) async {
      const ow = 'oldWorld';
      final province = Province(
        id: '$ow|p1',
        regionId: ow,
        displayName: 'TestPort',
        ownerId: 'gp1',
      );
      final game = _minimalGame(provinces: [province]);
      final fleet = Fleet(
        id: 'f2',
        ownerId: 'gp1',
        regionId: ow,
        inPortAtProvinceId: province.id,
        shipTypeIds: const ['fluyte'],
      );

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
                      isHomeFleet: false,
                      onConfirm: (_) {},
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

      expect(find.text('TestPort — Old World'), findsNWidgets(2));

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pump();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('SplitFleetDialog home fleet can be split', (
    WidgetTester tester,
  ) async {
    final fleet = Fleet(
      id: 'home_fleet',
      ownerId: 'gp1',
      regionId: 'oldWorld',
      seaZoneId: 'oldWorld|s1',
      shipTypeIds: const ['carrack'],
    );
    final game = _minimalGame(provinces: const []);

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
                    isHomeFleet: true,
                    onConfirm: (_) {},
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

    final confirm = tester.widget<CtNinePatchButton>(
      find.widgetWithText(CtNinePatchButton, 'Confirm Split'),
    );
    expect(confirm.enabled, isTrue);

    final bulkBack = find.descendant(
      of: find.byType(SplitFleetDialog),
      matching: find.byWidgetPredicate(
        (w) =>
            w is CtNinePatchButton &&
            w.child is Icon &&
            (w.child! as Icon).icon == Icons.arrow_back,
      ),
    );
    expect(tester.widget<CtNinePatchButton>(bulkBack.first).enabled, isTrue);
  });

  testWidgets('SplitFleetDialog long-press moves all of one type', (
    WidgetTester tester,
  ) async {
    List<String>? captured;
    final fleet = Fleet(
      id: 'f3',
      ownerId: 'gp1',
      regionId: 'oldWorld',
      seaZoneId: 's1',
      shipTypeIds: const ['a', 'a', 'b'],
    );
    final game = _minimalGame(provinces: const []);

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
                    isHomeFleet: false,
                    onConfirm: (ships) => captured = ships,
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

    await tester.longPress(find.byIcon(Icons.arrow_forward).first);
    await tester.pump();
    await tester.tap(find.text('Confirm Split'));
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured!.where((s) => s == 'a').length, 2);
  });
}
