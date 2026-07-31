// Spy relocate leave-intel confirm on map tile pick (Refs #4219 AC3).
// SPEC: SPEC/ui/civilian-units-panel.md; logic: spy_relocate_intel_test.dart.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/features/game/flame/map_state/map_state.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/map_view_provider.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_shell_harness.dart';
import 'civilian_units_panel_test_support.dart';
import 'map_view_test_fixtures.dart';
import 'panel_fixtures/core.dart';

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_spy_relocate_leave_intel');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  Future<({AppEventBus bus, Game game, GameMapAreaState state})>
  pumpSpyRelocateMapArea(
    WidgetTester tester, {
    required Game game,
  }) async {
    final mapViewData = buildLightweightMapViewData();
    final bus = AppEventBus.create();
    addTearDown(bus.dispose);

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

    final state = tester.state<GameMapAreaState>(find.byType(GameMapArea));
    final spy = game.worldState.oldWorld.units.single;
    state.civilianRelocateSelection = spy;
    return (bus: bus, game: game, state: state);
  }

  testWidgets(
    'relocating last Spy out of foreign province emits leave-intel confirm',
    (WidgetTester tester) async {
      final game = buildCivilianSpyFixtureGame(
        id: 'g_spy_leave_intel_map',
        humanId: kPanelTestHumanPlayerId,
        foreignStation: true,
      );
      final harness = await pumpSpyRelocateMapArea(tester, game: game);

      final confirmEvents = <ConfirmDialogEvent>[];
      harness.bus.on<ConfirmDialogEvent>().listen((event) {
        confirmEvents.add(event);
        event.result(false);
      });

      await harness.state.onTileSelectedForRelocate('oldWorld|p1|0|0');
      await tester.pump();

      expect(confirmEvents, hasLength(1));
      expect(confirmEvents.single.title, 'Leave intel?');
      expect(
        confirmEvents.single.message,
        contains('fog after end of turn'),
      );
      expect(confirmEvents.single.confirmLabel, 'Relocate anyway');
      expect(confirmEvents.single.cancelLabel, 'Stay');
    },
  );

  testWidgets(
    'leave-intel confirm cancel does not emit CivilianMoveRequestedEvent',
    (WidgetTester tester) async {
      final game = buildCivilianSpyFixtureGame(
        id: 'g_spy_leave_intel_cancel',
        humanId: kPanelTestHumanPlayerId,
        foreignStation: true,
      );
      final harness = await pumpSpyRelocateMapArea(tester, game: game);

      harness.bus.on<ConfirmDialogEvent>().listen((event) {
        event.result(false);
      });
      final moveEvents = <CivilianMoveRequestedEvent>[];
      harness.bus.on<CivilianMoveRequestedEvent>().listen(moveEvents.add);

      await harness.state.onTileSelectedForRelocate('oldWorld|p1|0|0');
      await tester.pump();

      expect(moveEvents, isEmpty);
    },
  );

  testWidgets(
    'leave-intel confirm accept emits CivilianMoveRequestedEvent',
    (WidgetTester tester) async {
      final game = buildCivilianSpyFixtureGame(
        id: 'g_spy_leave_intel_confirm',
        humanId: kPanelTestHumanPlayerId,
        foreignStation: true,
      );
      final harness = await pumpSpyRelocateMapArea(tester, game: game);

      harness.bus.on<ConfirmDialogEvent>().listen((event) {
        event.result(true);
      });
      final moveEvents = <CivilianMoveRequestedEvent>[];
      harness.bus.on<CivilianMoveRequestedEvent>().listen(moveEvents.add);

      const destTile = 'oldWorld|p1|0|0';
      await harness.state.onTileSelectedForRelocate(destTile);
      await tester.pump();

      expect(moveEvents, hasLength(1));
      expect(moveEvents.single.moveOrder.unitId, 'spy1');
      expect(moveEvents.single.moveOrder.destinationTileKey, destTile);
    },
  );
}
