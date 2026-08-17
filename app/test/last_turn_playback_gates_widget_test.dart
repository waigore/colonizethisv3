// Start-gate wiring and Skip chrome for last-turn playback (Refs #4486).

import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler.dart';
import 'package:colonizethis_app/features/game/flame/map_state/last_turn_playback_chrome.dart';
import 'package:colonizethis_app/features/game/flame/overlays/victory_overlay.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_event_handler_test_support.dart';
import 'app_shell_harness.dart';
import 'panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  testWidgets('Skip chrome ends playback without opening overlays', (
    tester,
  ) async {
    var skipped = false;
    await tester.pumpWidget(
      buildAppShell(
        child: Scaffold(
          body: LastTurnPlaybackChrome(
            caption: 'Pulse province battle resolved!',
            skipLabel: 'Skip',
            onSkip: () => skipped = true,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Pulse province battle resolved!'), findsOneWidget);
    await tester.tap(find.byKey(const Key('last_turn_playback_skip')));
    await tester.pump();
    expect(skipped, isTrue);
    expect(find.byType(VictoryOverlay), findsNothing);
  });

  testWidgets('narrow chrome insets leave tab/news/sheet gutters', (
    tester,
  ) async {
    final insets = lastTurnPlaybackChromeInsets(isNarrow: true);
    expect(insets.left, 56);
    expect(insets.right, 8);
    expect(insets.bottom, 88);
    await tester.binding.setSurfaceSize(const Size(320, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      buildAppShell(
        child: SizedBox(
          width: 320,
          height: 480,
          child: Stack(
            children: [
              lastTurnPlaybackChromeOverlay(
                isNarrow: true,
                caption: 'Pulse province battle resolved!',
                skipLabel: 'Skip',
                onSkip: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('View final state emits VictoryOverlayViewFinalStateEvent', (
    tester,
  ) async {
    ct_models.AppEventBus.reset();
    final bus = ct_models.AppEventBus.create();
    addTearDown(ct_models.AppEventBus.reset);
    ct_models.VictoryOverlayViewFinalStateEvent? emitted;
    final sub = bus.on<ct_models.VictoryOverlayViewFinalStateEvent>().listen(
      (e) => emitted = e,
    );
    addTearDown(sub.cancel);
    final game = buildVictoryPanelTestGame();
    final victory = ct_models.VictoryState(
      winnerPlayerId: game.players.first.id,
      type: ct_models.VictoryType.military,
      turnNumber: 1,
    );
    await tester.pumpWidget(
      buildAppShell(
        child: Scaffold(
          body: Stack(
            children: [VictoryOverlay(game: game, victory: victory, bus: bus)],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(emitted, isNull);
    await tester.tap(find.text('View final state'));
    await tester.pumpAndSettle();
    expect(emitted, isA<ct_models.VictoryOverlayViewFinalStateEvent>());
  });

  testWidgets('closing turn_news emits TurnNewsDialogClosedEvent', (
    tester,
  ) async {
    ct_models.AppEventBus.reset();
    final bus = ct_models.AppEventBus.create();
    addTearDown(ct_models.AppEventBus.reset);
    final navKey = GlobalKey<NavigatorState>();
    late AppEventHandler handler;
    handler = buildTestAppEventHandler(
      bus: bus,
      navigatorKey: navKey,
      dialogBuilders: {
        'turn_news': (ctx, params) => AlertDialog(
          content: const Text('news'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      },
    );
    handler.bind();
    addTearDown(handler.unbind);
    ct_models.TurnNewsDialogClosedEvent? closed;
    final sub = bus.on<ct_models.TurnNewsDialogClosedEvent>().listen(
      (e) => closed = e,
    );
    addTearDown(sub.cancel);
    await pumpAppEventHandlerEmitButton(
      tester,
      navigatorKey: navKey,
      label: 'open',
      onPressed: () => bus.emit(const ct_models.OpenDialogEvent('turn_news')),
    );
    await tapAppEventHandlerLabel(tester, 'open');
    expect(find.text('news'), findsOneWidget);
    expect(closed, isNull);
    await tapAppEventHandlerLabel(tester, 'Close');
    expect(closed, isA<ct_models.TurnNewsDialogClosedEvent>());
  });
}
