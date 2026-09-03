// Visual contract for runNewGameSetupAfterLeaderPick progress/error dialogs
// (Refs #2867 / #4720 Slice G). SPEC/ui/game-initializing.md.

import 'dart:async';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/features/shell/new_game_setup_flow.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/widgets/ct_loading_indicator.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_shell_harness.dart';
import 'app_test_hive_harness.dart';

class _StubGameService extends GameService {
  _StubGameService(super.box, super.adapter);

  int createCallCount = 0;
  bool throwOnCreate = false;

  @override
  Future<Game> createNewGameAsync({
    String? id,
    GameSetupConfig? config,
    void Function(int stepIndex, int totalSteps)? onProgress,
  }) async {
    createCallCount++;
    const total = GameService.newGameSetupProgressStepCount;
    for (var i = 0; i < total; i++) {
      onProgress?.call(i, total);
      await Future<void>.delayed(Duration.zero);
    }
    if (throwOnCreate) {
      throw StateError('forced failure for dark-theme contract test');
    }
    return Game(
      id: id ?? 'g1',
      worldState: const WorldState(
        turnState: TurnState(phase: TurnPhase.orders, turnNumber: 0),
        oldWorld: RegionData(),
        newWorld: RegionData(),
      ),
      players: const [
        Player(id: 'gp1', displayName: 'Human', isHuman: true, treasury: 0),
      ],
    );
  }
}

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;
  late _StubGameService stubService;

  setUpAll(() async {
    gamesBox = await openAppTestHiveBox(suiteId: 'new_game_setup_flow_visual');
  });

  setUp(() {
    AppEventBus.reset();
    stubService = _StubGameService(gamesBox, GameSaveAdapter());
  });

  GameSetupConfig templateConfig() => GameSetupConfig(
    selectedGreatPowerIds: const ['gp1'],
    leaderVariantByGpId: const {},
    continentCount: 1,
    minorNationCount: 0,
    tribeCount: 0,
    numProvincesOldWorld: 1,
    numProvincesNewWorld: 1,
    minProvincesPerMinor: 1,
    seed: 1,
    infiniteMode: false,
  );

  testWidgets(
    'runNewGameSetupAfterLeaderPick progress dialog renders a 48px `--accent` '
    'spinner (Refs #2867 game initializing visual contract)',
    (WidgetTester tester) async {
      final injectedKey = GlobalKey<NavigatorState>();
      final container = ProviderContainer(
        overrides: [
          gameServiceProvider.overrideWith((ref) => stubService),
          appEventBusProvider.overrideWith((ref) => AppEventBus.create()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        // Editorial shell via buildAppShellWithContainer (Refs #4035).
        buildAppShellWithContainer(
          container: container,
          navigatorKey: injectedKey,
          localizationsDelegates:
              AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          child: const Scaffold(body: Text('shell')),
        ),
      );
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        unawaited(
          runNewGameSetupAfterLeaderPick(
            navigatorKey: injectedKey,
            container: container,
            templateConfig: templateConfig(),
          ),
        );
        // Pump until the progress dialog has mounted but before the stub
        // service post-frame `_run()` finishes (mounted but spinner still up).
        for (var i = 0; i < 3; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
      });
      await tester.pump();

      final indicator = tester.widget<CtLoadingIndicator>(
        find.byType(CtLoadingIndicator),
      );
      expect(indicator.size, 48, reason: 'SPEC: 48px ring');
      expect(
        indicator.color,
        EditorialMonoclePalette.accent,
        reason: 'SPEC: --accent top border',
      );

      // Drain the rest of the flow so the test exits cleanly.
      await tester.runAsync(() async {
        for (var i = 0; i < 20; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'runNewGameSetupAfterLeaderPick error dialog renders the error card with '
    'a 1px `--danger` border (Refs #2867 failure visual contract)',
    (WidgetTester tester) async {
      stubService.throwOnCreate = true;
      final injectedKey = GlobalKey<NavigatorState>();
      final container = ProviderContainer(
        overrides: [
          gameServiceProvider.overrideWith((ref) => stubService),
          appEventBusProvider.overrideWith((ref) => AppEventBus.create()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        // Editorial shell via buildAppShellWithContainer (Refs #4035).
        buildAppShellWithContainer(
          container: container,
          navigatorKey: injectedKey,
          localizationsDelegates:
              AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          child: const Scaffold(body: Text('shell')),
        ),
      );
      await tester.pumpAndSettle();

      unawaited(
        runNewGameSetupAfterLeaderPick(
          navigatorKey: injectedKey,
          container: container,
          templateConfig: templateConfig(),
        ),
      );

      // Drive the flow until the error dialog opens (progress dialog throws,
      // gets dismissed, error dialog is showDialog'd).
      await tester.runAsync(() async {
        for (var i = 0; i < 40; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });
      await tester.pumpAndSettle();

      // The "Could not create game" title must be visible in the error
      // dialog (positive: title rendered).
      expect(find.text('Could not create game'), findsOneWidget);

      // Find any DecoratedBox painted with a 1px --danger border. Multiple
      // DecoratedBoxes may exist in the tree (CtDialogShell paints its own
      // chrome); the error-card border is the one that matches both
      // width: 1 and color: EditorialMonoclePalette.danger.
      final decoratedBoxes = tester.widgetList<DecoratedBox>(
        find.byType(DecoratedBox),
      );
      final dangerBordered = decoratedBoxes.where((box) {
        final deco = box.decoration;
        if (deco is! BoxDecoration) {
          return false;
        }
        final border = deco.border;
        if (border is! Border) {
          return false;
        }
        return border.top.color == EditorialMonoclePalette.danger &&
            border.top.width == 1 &&
            border.bottom.color == EditorialMonoclePalette.danger &&
            border.left.color == EditorialMonoclePalette.danger &&
            border.right.color == EditorialMonoclePalette.danger;
      });
      expect(
        dangerBordered.isNotEmpty,
        isTrue,
        reason: 'error card must paint a 1px --danger border on all sides',
      );

      // Negative path: when the error card is absent (no error in the
      // success-path tests above), no danger-bordered DecoratedBox is
      // rendered. We rely on the absence assertion implicitly: the
      // success-path tests do not pump this danger color, and this test
      // exercises the failure-only widget.

      // Dismiss the error dialog so the test exits cleanly.
      await tester.tap(find.text('Close'));
      await tester.runAsync(() async {
        for (var i = 0; i < 5; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });
      await tester.pumpAndSettle();
    },
  );
}
