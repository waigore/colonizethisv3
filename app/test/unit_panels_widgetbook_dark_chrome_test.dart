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

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/widgets/civilian_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/military_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/naval_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/train_civilians_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/train_military_dialog.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

int _argb(Color c) {
  final int a = (c.a * 255.0).round() & 0xFF;
  final int r = (c.r * 255.0).round() & 0xFF;
  final int g = (c.g * 255.0).round() & 0xFF;
  final int b = (c.b * 255.0).round() & 0xFF;
  return (a << 24) | (r << 16) | (g << 8) | b;
}

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

void _expectEditorialMonocleTheme(WidgetTester tester) {
  // Resolve theme from any descendant of the editorial-monocle MaterialApp.
  final BuildContext ctx = tester.element(find.byType(Scaffold).first);
  final ThemeData theme = Theme.of(ctx);
  expect(theme.brightness, Brightness.dark);
  expect(
    _argb(theme.colorScheme.primary),
    _argb(EditorialMonoclePalette.accent),
  );
}

Widget _editorialMonocleHost({required Widget child}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppThemes.editorialMonocle,
    home: Scaffold(
      backgroundColor: AppThemes.editorialMonocle.scaffoldBackgroundColor,
      body: child,
    ),
  );
}

void main() {
  suppressLogsForTests();

  late InitGameResult debugInit;
  late Game game;
  late String humanPlayerId;

  setUpAll(() {
    debugInit = getDebugInitGameResult();
    game = debugInit.game;
    humanPlayerId = game.players.isNotEmpty
        ? game.players.firstWhere((p) => p.isHuman).id
        : game.players.first.id;
  });

  group('Widgetbook unit panel / train dialog dark chrome (#2866 S6)', () {
    testWidgets('Civilian Units Panel (Standalone story)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: _editorialMonocleHost(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
              child: CivilianUnitsPanel(
                game: game,
                humanPlayerId: humanPlayerId,
                bus: AppEventBus.create(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      _expectNoMaterialChromeBans(tester);
      _expectEditorialMonocleTheme(tester);
    });

    testWidgets('Military Units Panel (Standalone story)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _editorialMonocleHost(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
            child: MilitaryUnitsPanel(
              game: game,
              humanPlayerId: humanPlayerId,
              bus: AppEventBus.create(),
              topology: debugInit.combinedTopology,
              draftOrders: const Orders(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      _expectNoMaterialChromeBans(tester);
      _expectEditorialMonocleTheme(tester);
    });

    testWidgets('Naval Units Panel (Standalone story)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _editorialMonocleHost(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
            child: NavalUnitsPanel(
              game: game,
              humanPlayerId: humanPlayerId,
              bus: AppEventBus.create(),
              topology: debugInit.combinedTopology,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      _expectNoMaterialChromeBans(tester);
      _expectEditorialMonocleTheme(tester);
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
        _editorialMonocleHost(
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
      _expectEditorialMonocleTheme(tester);
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
        _editorialMonocleHost(
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
      _expectEditorialMonocleTheme(tester);
    });
  });
}
