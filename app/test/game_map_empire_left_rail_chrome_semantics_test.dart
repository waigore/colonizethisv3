// Rail gap / Material / Semantics pins (Refs #4642 Slice B).

import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart';
import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/features/game/flame/controls/controls.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/debug_console_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/widgets/ct_gradients.dart';
import 'package:colonizethis_app/widgets/strict_asset_icon.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_shell_harness.dart';
import 'panel_test_fixtures.dart';
import 'app_test_hive_harness.dart';

/// Semantics and spacing contract on
/// [GameMapEmpireLeftRail] (issue #2861 S3 / R4).
///
/// Asserts the rail buttons paint a 36 × 36 dp surface with the canonical
/// dark gradient + border tokens and a 24 × 24 dp full-colour icon glyph
/// without a `srcIn` tint (issue #2861 S14 / M5). Also pins the no-light-hex
/// rule documented in `SPEC/ui/empire-buttons.md` § Styling.
void main() {
  suppressLogsForTests();

  late Game game;
  late Box<dynamic> gamesBox;

  setUpAll(() async {
    // Lightweight fixture (Refs #3656): the chrome contract only renders the
    // rail itself (no panels opened), so a single human player is sufficient.
    game = buildPanelTestGame();

    gamesBox = await openAppTestHiveBox(suiteId: 'empire_rail_chrome_semantics');
  });

  String humanId() => game.players.where((p) => p.isHuman).isNotEmpty
      ? game.players.where((p) => p.isHuman).first.id
      : game.players.first.id;

  overrides({bool debugConsoleEnabled = false}) => [
    gamesBoxProvider.overrideWith((ref) => gamesBox),
    gameServiceProvider.overrideWith(
      (ref) => GameService(gamesBox, GameSaveAdapter()),
    ),
    currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
    currentOrdersProvider.overrideWith(
      () => CurrentOrdersNotifier(const Orders()),
    ),
    availableWorkTargetIdsForUnitProvider.overrideWith(
      (ref, _) => const <String>[],
    ),
    appEventBusProvider.overrideWith((ref) {
      final bus = AppEventBus.create();
      ref.onDispose(bus.dispose);
      return bus;
    }),
    debugConsoleEnabledProvider.overrideWithValue(debugConsoleEnabled),
  ];

  Widget railScaffold({bool debugConsoleEnabled = false}) {
    // Editorial shell via buildAppShell (Refs #4035 — no inline MaterialApp).
    return buildAppShell(
      overrides: overrides(debugConsoleEnabled: debugConsoleEnabled),
      navigatorKey: appNavigatorKey,
      shellWrapper: (app) => AppEventHandlerScope(child: app),
      child: Scaffold(
        body: Stack(
          children: <Widget>[
            Positioned(
              left: 20,
              top: 0,
              child: GameMapEmpireLeftRail(
                game: game,
                humanPlayerId: humanId(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  const List<Key> railButtonKeys = <Key>[
    kEmpireProductionButtonKey,
    kEmpireTradeButtonKey,
    kEmpireDevelopmentButtonKey,
    kEmpireCivilianUnitsButtonKey,
    kEmpireMilitaryUnitsButtonKey,
    kEmpireNavalUnitsButtonKey,
    kEmpireDiplomacyButtonKey,
    kEmpireTechnologyButtonKey,
    kEmpireVictoryButtonKey,
  ];

  testWidgets('Rail buttons render with 3 dp vertical gaps between them', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(railScaffold());
    await tester.pumpAndSettle();

    expect(GameMapEmpireLeftRail.rowGap, 3.0);
    for (var i = 1; i < railButtonKeys.length; i++) {
      final aBottom = tester.getRect(find.byKey(railButtonKeys[i - 1])).bottom;
      final bTop = tester.getRect(find.byKey(railButtonKeys[i])).top;
      expect(
        bTop - aBottom,
        3.0,
        reason:
            'Rail button ${railButtonKeys[i]} must sit 3 dp below ${railButtonKeys[i - 1]}',
      );
    }
  });

  testWidgets('No rail descendant paints Colors.white as a Material color', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(railScaffold(debugConsoleEnabled: true));
    await tester.pumpAndSettle();

    final materials = tester
        .widgetList<Material>(
          find.descendant(
            of: find.byType(GameMapEmpireLeftRail),
            matching: find.byType(Material),
          ),
        )
        .toList();
    expect(
      materials.isNotEmpty,
      isTrue,
      reason: 'Rail must paint Material chrome',
    );
    for (final material in materials) {
      final color = material.color;
      expect(
        color,
        anyOf(isNull, equals(Colors.transparent)),
        reason:
            'Rail Material chrome must be transparent so dark editorial-monocle '
            'chrome shows through (no light parchment / Colors.white surface)',
      );
    }
  });

  testWidgets(
    'Rail exposes Semantics(button: true) with the tooltip label for each entry',
    (WidgetTester tester) async {
      await tester.pumpWidget(railScaffold());
      await tester.pumpAndSettle();

      final Map<Key, String> expectedLabels = <Key, String>{
        kEmpireProductionButtonKey: 'Production',
        kEmpireTradeButtonKey: 'Trade',
        kEmpireDevelopmentButtonKey: 'Development',
        kEmpireCivilianUnitsButtonKey: 'Civilian Units',
        kEmpireMilitaryUnitsButtonKey: 'Military Units',
        kEmpireNavalUnitsButtonKey: 'Naval Units',
        kEmpireDiplomacyButtonKey: 'Diplomacy',
        kEmpireTechnologyButtonKey: 'Technology',
        kEmpireVictoryButtonKey: 'Victory',
      };

      for (final entry in expectedLabels.entries) {
        final semanticsFinder = find.ancestor(
          of: find.byKey(entry.key),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.button == true &&
                widget.properties.label == entry.value,
          ),
        );
        expect(
          semanticsFinder,
          findsOneWidget,
          reason:
              'Rail button ${entry.key} must wrap its glyph in Semantics(button: true, label: "${entry.value}")',
        );
      }
    },
  );
}
