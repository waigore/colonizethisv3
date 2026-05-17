import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_app/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_app/config/ct_e2e_turn_snapshot_refresh.dart';
import 'package:colonizethis_app/core/services/game_service.dart';
import 'package:colonizethis_app/features/game/flame/turn_resolution_result_applier.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_ct_e2e_turn_snapshot_refresh');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  tearDown(() {
    ctE2eNavalPanelSnapshot = null;
  });

  testWidgets('refreshCtE2eNavalPanelSnapshotAfterTurnIfEnabled is no-op when CT_E2E off', (
    WidgetTester tester,
  ) async {
    expect(kCtE2EEnabled, isFalse);
    final init = getDebugInitGameResult();
    late WidgetRef capturedRef;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gamesBoxProvider.overrideWith((ref) => gamesBox),
          gameServiceProvider.overrideWith(
            (ref) => GameService(gamesBox, GameSaveAdapter()),
          ),
          currentGameProvider.overrideWith(() => CurrentGameNotifier(init.game)),
          currentOrdersProvider.overrideWith(
            () => CurrentOrdersNotifier(const Orders()),
          ),
        ],
        child: Consumer(
          builder: (context, ref, child) {
            capturedRef = ref;
            return const SizedBox();
          },
        ),
      ),
    );

    refreshCtE2eNavalPanelSnapshotAfterTurnIfEnabled(capturedRef);
    expect(ctE2eNavalPanelSnapshot, isNull);
  });

  testWidgets('refreshCtE2eNavalPanelSnapshotAfterTurnIfEnabled no-ops without current game', (
    WidgetTester tester,
  ) async {
    expect(kCtE2EEnabled, isFalse);
    late WidgetRef capturedRef;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gamesBoxProvider.overrideWith((ref) => gamesBox),
          gameServiceProvider.overrideWith(
            (ref) => GameService(gamesBox, GameSaveAdapter()),
          ),
        ],
        child: Consumer(
          builder: (context, ref, child) {
            capturedRef = ref;
            return const SizedBox();
          },
        ),
      ),
    );

    refreshCtE2eNavalPanelSnapshotAfterTurnIfEnabled(capturedRef);
    expect(ctE2eNavalPanelSnapshot, isNull);
  });

  testWidgets('applyTurnResolutionResult invokes snapshot refresh hook when CT_E2E off', (
    WidgetTester tester,
  ) async {
    expect(kCtE2EEnabled, isFalse);
    final init = getDebugInitGameResult();
    late WidgetRef capturedRef;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gamesBoxProvider.overrideWith((ref) => gamesBox),
          gameServiceProvider.overrideWith(
            (ref) => GameService(gamesBox, GameSaveAdapter()),
          ),
          currentGameProvider.overrideWith(() => CurrentGameNotifier(init.game)),
          currentOrdersProvider.overrideWith(
            () => CurrentOrdersNotifier(const Orders()),
          ),
        ],
        child: Consumer(
          builder: (context, ref, child) {
            capturedRef = ref;
            return const SizedBox();
          },
        ),
      ),
    );

    applyTurnResolutionResult(
      capturedRef,
      TurnResolutionComplete(init.game),
    );
    expect(ctE2eNavalPanelSnapshot, isNull);
    expect(capturedRef.read(currentGameProvider)?.id, init.game.id);
  });
}
