// Per-story chrome assertions for the five unit panels / train dialogs under
// `AppThemes.editorialMonocle`. Refs #2866 S6 — Widgetbook AC bar:
//
//   * stories render without throwing,
//   * no Material chrome widgets (AppBar / Switch / Divider /
//     LinearProgressIndicator / Slider) appear in the tree,
//   * the host theme resolves to editorial-monocle (dark + accent token).
//
// Rendered widgets mirror the Widgetbook "Standalone" use cases (catalog.dart
// + catalog_part2.dart + catalog_part3.dart) so this test pins the dark-theme
// contract those stories produce — without re-running the full Widgetbook
// chrome at test time.

import 'package:colonizethis_app/features/game/widgets/units/civilian/civilian_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/units/military/military_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/units/naval/naval_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/train/train_civilians_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/train/train_military_dialog.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_shell_harness.dart';
import 'support/editorial_monocle_dark_token_assertions.dart';
import 'support/panel_test_fixtures.dart';

void _expectNoMaterialChromeBans(WidgetTester tester) {
  expect(find.byType(AppBar), findsNothing, reason: 'AppBar is banned chrome');
  expect(find.byType(Switch), findsNothing, reason: 'Switch is banned chrome');
  expect(
    find.byType(Divider),
    findsNothing,
    reason: 'Material Divider is banned — use CtBrassDivider',
  );
  expect(
    find.byType(LinearProgressIndicator),
    findsNothing,
    reason: 'LinearProgressIndicator is banned — use CtProgressBar',
  );
  expect(find.byType(Slider), findsNothing, reason: 'Slider is banned chrome');
}

Widget _catalogUnitsHost({required Widget child}) {
  return buildAppShell(
    child: Scaffold(
      backgroundColor: AppThemes.editorialMonocle.scaffoldBackgroundColor,
      body: child,
    ),
  );
}

void main() {
  suppressLogsForTests();

  late Game game;
  late String humanPlayerId;

  setUpAll(() {
    // Refs #3656: a shared lightweight fixture (civilians + army/regiments +
    // home/non-home fleets, with capital + train tech) replaces the ~11s
    // `getDebugInitGameResult()` map generation. These stories assert chrome
    // only (no exception, no Material chrome, editorial-monocle theme) and never
    // read generated map/topology data.
    game = buildUnitPanelsTestGame();
    humanPlayerId = game.players.firstWhere((p) => p.isHuman).id;
  });

  group('Widgetbook unit panel / train dialog dark chrome (#2866 S6)', () {
    testWidgets('Civilian Units Panel (Standalone story)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _catalogUnitsHost(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
            child: CivilianUnitsPanel(
              game: game,
              humanPlayerId: humanPlayerId,
              bus: AppEventBus.create(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      _expectNoMaterialChromeBans(tester);
      expectEditorialMonocleDarkChrome(tester);
    });

    testWidgets('Military Units Panel (Standalone story)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _catalogUnitsHost(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
            child: MilitaryUnitsPanel(
              game: game,
              humanPlayerId: humanPlayerId,
              bus: AppEventBus.create(),
              topology: const MapTopology(),
              draftOrders: const Orders(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      _expectNoMaterialChromeBans(tester);
      expectEditorialMonocleDarkChrome(tester);
    });

    testWidgets('Naval Units Panel (Standalone story)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _catalogUnitsHost(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
            child: NavalUnitsPanel(
              game: game,
              humanPlayerId: humanPlayerId,
              bus: AppEventBus.create(),
              topology: const MapTopology(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      _expectNoMaterialChromeBans(tester);
      expectEditorialMonocleDarkChrome(tester);
    });

    testWidgets('Train Civilians Dialog (Standalone story)', (
      WidgetTester tester,
    ) async {
      final Player player =
          game.playerById(humanPlayerId) ?? game.players.first;
      final Game richGame = game.copyWith(
        players: [
          player.copyWith(
            treasury: 10000,
            stockpile: player.stockpile.merge(
              const Stockpile(quantities: {'paper': 100}),
            ),
          ),
          ...game.players.where((p) => p.id != humanPlayerId),
        ],
      );

      await tester.pumpWidget(
        _catalogUnitsHost(
          child: Center(
            child: TrainCiviliansDialog(
              game: richGame,
              humanPlayerId: humanPlayerId,
              currentOrders: const Orders(),
              bus: AppEventBus.create(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      _expectNoMaterialChromeBans(tester);
      expectEditorialMonocleDarkChrome(tester);
    });

    testWidgets('Train Military Dialog (Standalone story)', (
      WidgetTester tester,
    ) async {
      final Player player =
          game.playerById(humanPlayerId) ?? game.players.first;
      final Game richGame = game.copyWith(
        players: [
          player.copyWith(
            treasury: 10000,
            workerPool: player.workerPool.copyWith(peasants: 20),
            stockpile: player.stockpile.merge(
              const Stockpile(
                quantities: {
                  'fabric': 50,
                  'castIron': 50,
                  'lumber': 50,
                  'horses': 50,
                  'steel': 50,
                  'bronze': 50,
                },
              ),
            ),
          ),
          ...game.players.where((p) => p.id != humanPlayerId),
        ],
      );

      await tester.pumpWidget(
        _catalogUnitsHost(
          child: Center(
            child: TrainMilitaryDialog(
              game: richGame,
              humanPlayerId: humanPlayerId,
              currentOrders: const Orders(),
              bus: AppEventBus.create(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      _expectNoMaterialChromeBans(tester);
      expectEditorialMonocleDarkChrome(tester);
    });
  });
}
