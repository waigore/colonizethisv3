// Widget ACs for Train Military/Naval peasant reservation (Refs #4566).
// SPEC/ui/train-military-dialog.md, SPEC/ui/train-naval-dialog.md.

import 'package:colonizethis_app/features/game/widgets/train/train_military_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/train/train_naval_dialog.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'panel_test_fixtures.dart';

const _capital = 'oldWorld|cap';

Game _game({int peasants = 8, int treasury = 50000}) {
  return buildPanelTestGame(
    id: 'train-peasant-reservation-widget',
    players: [
      Player(
        id: kPanelTestHumanPlayerId,
        displayName: 'Test Human',
        isHuman: true,
        capitalProvinceId: _capital,
        capitalTile: const CapitalTile(
          regionId: 'oldWorld',
          provinceId: _capital,
          x: 0,
          y: 0,
        ),
        treasury: treasury,
        workerPool: WorkerPool(peasants: peasants),
        stockpile: Stockpile(
          quantities: {
            for (final id in [
              'fabric',
              'castIron',
              'lumber',
              'horses',
              'steel',
              'bronze',
              'coal',
            ])
              id: 100,
          },
        ),
        techUnlocked: {
          for (final techId in unlockingTechByRegimentId.values) techId: true,
          for (final techId in unlockingTechByShipId.values) techId: true,
        },
      ),
    ],
  );
}

Orders _workerTrains(int count) => Orders(
  recruitWorkerOrdersByPlayerId: {
    kPanelTestHumanPlayerId: List<RecruitWorkerOrder>.generate(
      count,
      (_) => const RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
    ),
  },
);

Orders _shipBuilds(int count) => Orders(
  buildUnitOrdersByPlayerId: {
    kPanelTestHumanPlayerId: List<BuildUnitOrder>.generate(
      count,
      (_) => BuildUnitOrder(
        unitType: 'carrack',
        isMilitary: false,
        spawnProvinceId: _capital,
      ),
    ),
  },
);

Orders _regimentBuilds(int count) => Orders(
  buildUnitOrdersByPlayerId: {
    kPanelTestHumanPlayerId: List<BuildUnitOrder>.generate(
      count,
      (_) => BuildUnitOrder(
        unitType: 'peasant_levies',
        isMilitary: true,
        spawnProvinceId: _capital,
      ),
    ),
  },
);

Future<void> _pumpMilitary(
  WidgetTester tester, {
  required Game game,
  Orders currentOrders = const Orders(),
}) async {
  await tester.pumpWidget(
    buildAppShell(
      child: Scaffold(
        body: TrainMilitaryDialog(
          game: game,
          humanPlayerId: kPanelTestHumanPlayerId,
          currentOrders: currentOrders,
          bus: AppEventBus.create(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpNaval(
  WidgetTester tester, {
  required Game game,
  Orders currentOrders = const Orders(),
}) async {
  await tester.pumpWidget(
    buildAppShell(
      child: Scaffold(
        body: TrainNavalDialog(
          game: game,
          humanPlayerId: kPanelTestHumanPlayerId,
          currentOrders: currentOrders,
          bus: AppEventBus.create(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  suppressLogsForTests();

  testWidgets(
    'UNIT50001: 3 apprentice trains → Peasants 5/8 + worker-training gist',
    (tester) async {
      await _pumpMilitary(
        tester,
        game: _game(),
        currentOrders: _workerTrains(3),
      );
      expect(find.textContaining('5 / 8'), findsOneWidget);
      expect(
        find.textContaining('already promised to worker training'),
        findsOneWidget,
      );
      expect(find.textContaining('already promised to ships'), findsNothing);
    },
  );

  testWidgets(
    'UNIT50001: + accepts five then refuses sixth when 3 workers reserved',
    (tester) async {
      await _pumpMilitary(
        tester,
        game: _game(),
        currentOrders: _workerTrains(3),
      );
      final plusButtons = find.widgetWithText(CtNinePatchButton, '+');
      expect(plusButtons, findsWidgets);
      for (var i = 0; i < 5; i++) {
        await tester.ensureVisible(plusButtons.first);
        await tester.tap(plusButtons.first);
        await tester.pumpAndSettle();
      }
      expect(find.textContaining('0 / 8'), findsOneWidget);
      // Sixth tap must not move remaining below zero.
      await tester.tap(plusButtons.first);
      await tester.pumpAndSettle();
      expect(find.textContaining('0 / 8'), findsOneWidget);
      expect(find.textContaining('-1 / 8'), findsNothing);
    },
  );

  testWidgets('UNIT50001: 2 ships → Peasants 6/8 + ships gist', (tester) async {
    await _pumpMilitary(
      tester,
      game: _game(),
      currentOrders: _shipBuilds(2),
    );
    expect(find.textContaining('6 / 8'), findsOneWidget);
    expect(find.textContaining('already promised to ships'), findsOneWidget);
    expect(
      find.textContaining('already promised to worker training'),
      findsNothing,
    );
  });

  testWidgets(
    'UNIT50001: own staged regiments counted once; gist omitted',
    (tester) async {
      await _pumpMilitary(
        tester,
        game: _game(),
        currentOrders: _regimentBuilds(2),
      );
      expect(find.textContaining('6 / 8'), findsOneWidget);
      expect(
        find.textContaining('already promised'),
        findsNothing,
      );
    },
  );

  testWidgets('UNIT50001: clean pool omits promised gist', (tester) async {
    await _pumpMilitary(tester, game: _game());
    expect(find.textContaining('8 / 8'), findsOneWidget);
    expect(find.textContaining('already promised'), findsNothing);
  });

  testWidgets(
    'UNIT50001: Peasants chip tooltip lists families without order class names',
    (tester) async {
      await _pumpMilitary(
        tester,
        game: _game(),
        currentOrders: _workerTrains(2),
      );
      final tooltip = tester.widget<Tooltip>(
        find.descendant(
          of: find.byType(TrainMilitaryDialog),
          matching: find.byWidgetPredicate(
            (w) =>
                w is Tooltip &&
                (w.message?.contains('already promised') ?? false),
          ),
        ),
      );
      expect(tooltip.message, contains('already promised to worker training'));
      expect(tooltip.message, isNot(contains('RecruitWorkerOrder')));
      expect(tooltip.message, isNot(contains('BuildUnitOrder')));
    },
  );

  testWidgets(
    'UNIT60001: military builds reduce available ship peasants',
    (tester) async {
      await _pumpNaval(
        tester,
        game: _game(),
        currentOrders: _regimentBuilds(2),
      );
      expect(find.textContaining('6 / 8'), findsOneWidget);
      expect(
        find.textContaining('already promised to regiments'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'UNIT60001: worker trains reduce available ship peasants',
    (tester) async {
      await _pumpNaval(
        tester,
        game: _game(),
        currentOrders: _workerTrains(3),
      );
      expect(find.textContaining('5 / 8'), findsOneWidget);
      expect(
        find.textContaining('already promised to worker training'),
        findsOneWidget,
      );
    },
  );
}
