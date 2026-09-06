import 'package:colonizethis_app/features/game/flame/map_area/game_map_canvas_stack_selection_prompt_tokens.dart';
import 'package:colonizethis_app/features/game/flame/map_state/game_map_area.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/map_view_provider.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_shell_harness.dart';
import 'map_view_test_fixtures.dart';
import 'panel_test_fixtures.dart';

Future<void> pumpSelectionPromptDarkTokensMode(
  WidgetTester tester, {
  required Box<dynamic> gamesBox,
}) async {
  final game = buildSelectionPromptTestGame();
  final mapViewData = buildLightweightMapViewData();
  final bus = AppEventBus.create();
  addTearDown(bus.dispose);

  final sampleUnitId = game.worldState.oldWorld.units.first.id;

  await tester.pumpWidget(
    buildAppShell(
      overrides: [
        appEventBusProvider.overrideWith((ref) => bus),
        currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
        gamesBoxProvider.overrideWith((ref) => gamesBox),
        gameServiceProvider.overrideWith(
          (ref) => GameService(gamesBox, GameSaveAdapter()),
        ),
        currentOrdersProvider.overrideWith(
          () => CurrentOrdersNotifier(const Orders()),
        ),
        mapViewDataProvider.overrideWith((ref) => mapViewData),
      ],
      child: Scaffold(
        body: GameMapArea(game: game, mapViewData: mapViewData),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));

  bus.emit(
    StartCivilianWorkTargetSelectionEvent(
      unitId: sampleUnitId,
      workTarget: kWorkTargetExplore,
    ),
  );
  await tester.pump();

  var selectionReady = false;
  for (var i = 0; i < 200; i++) {
    await tester.pump(const Duration(milliseconds: 5));
    if (find.text('Select a tile, or click cancel').evaluate().isNotEmpty) {
      selectionReady = true;
      break;
    }
  }
  expect(
    selectionReady,
    isTrue,
    reason:
        'selection prompt overlay must mount once the bus event commits the '
        'work-target selection mode entry path',
  );
}

DecoratedBox selectionPromptBannerDecoratedBox(WidgetTester tester) {
  final candidates = tester
      .widgetList<DecoratedBox>(find.byType(DecoratedBox))
      .where((d) {
        final decoration = d.decoration;
        if (decoration is! BoxDecoration) return false;
        final color = decoration.color;
        if (color == null) return false;
        final expected = EditorialMonoclePalette.bgDeep.withValues(
          alpha: kMapSelectionPromptBackgroundAlpha,
        );
        return color.toARGB32() == expected.toARGB32();
      })
      .toList();
  expect(
    candidates.length,
    1,
    reason:
        'exactly one DecoratedBox in the tree should paint the bgDeep + 0.85 '
        'alpha banner fill (the selection prompt overlay)',
  );
  return candidates.single;
}
