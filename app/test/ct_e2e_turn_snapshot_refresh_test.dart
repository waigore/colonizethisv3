import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e_turn_snapshot_refresh.dart';
import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/core/services/turn_resolution/turn_resolution_result_applier.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'panel_test_fixtures.dart';
import 'app_test_hive_harness.dart';

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    gamesBox = await openAppTestHiveBox(suiteId: 'ct_e2e_turn_snapshot_refresh');
  });

  tearDown(() {
    ctE2eNavalPanelSnapshot = null;
  });

  test('refreshCtE2eNavalPanelSnapshotAfterTurnIfEnabled is no-op when CT_E2E off', () {
    expect(kCtE2EEnabled, isFalse);
    // Lightweight fixture (Refs #3656): the refresh hook only reads the game
    // for the CT_E2E-off no-op guard; no generated map/topology data is needed.
    final game = buildPanelTestGame();

    refreshCtE2eNavalPanelSnapshotAfterTurnIfEnabled(
      game: game,
      draftOrders: const Orders(),
      combinedTopology: const MapTopology(),
    );
    expect(ctE2eNavalPanelSnapshot, isNull);
  });

  test('refreshCtE2eNavalPanelSnapshotAfterTurnIfEnabled no-ops without current game', () {
    expect(kCtE2EEnabled, isFalse);

    refreshCtE2eNavalPanelSnapshotAfterTurnIfEnabled(
      game: null,
      draftOrders: const Orders(),
      combinedTopology: const MapTopology(),
    );
    expect(ctE2eNavalPanelSnapshot, isNull);
  });

  test('TurnResolutionResultApplier invokes snapshot refresh hook when CT_E2E off', () {
    expect(kCtE2EEnabled, isFalse);
    // Lightweight fixture (Refs #3656): the applier only needs a Game with a
    // stable id to confirm the snapshot hook stays a no-op and the current game
    // is preserved; no generated map/topology data is read.
    final game = buildPanelTestGame();
    final container = ProviderContainer(
      overrides: [
        gamesBoxProvider.overrideWith((ref) => gamesBox),
        gameServiceProvider.overrideWith(
          (ref) => GameService(gamesBox, GameSaveAdapter()),
        ),
        currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
        currentOrdersProvider.overrideWith(
          () => CurrentOrdersNotifier(const Orders()),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(turnResolutionResultApplierProvider).apply(
          TurnResolutionComplete(game),
        );
    expect(ctE2eNavalPanelSnapshot, isNull);
    expect(container.read(currentGameProvider)?.id, game.id);
  });
}
