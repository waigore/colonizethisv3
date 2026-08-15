import 'package:colonizethis_ai/colonizethis_ai.dart' show kDefaultMood;
import 'package:colonizethis_app/features/game/widgets/diplomacy/grant_or_subsidy_listener.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  setUp(() {
    AppEventBus.reset();
  });

  testWidgets(
    'GrantOrSubsidyListener appends grant immediately without ConfirmDialogEvent',
    (WidgetTester tester) async {
      final game = buildGrantOrSubsidyListenerTestGame();
      final humanPlayerId = game.players.firstWhere((p) => p.isHuman).id;
      final targetFactionId = game.players.firstWhere((p) => !p.isHuman).id;
      final bus = AppEventBus.create();

      final appendFuture = bus
          .on<AppendDiplomaticOrderRequestedEvent>()
          .first
          .timeout(const Duration(seconds: 2));
      final moodFuture = bus.on<NegotiationMoodUpdateEvent>().first.timeout(
        const Duration(seconds: 2),
      );

      var confirmEmitted = false;
      final confirmSub = bus.on<ConfirmDialogEvent>().listen((_) {
        confirmEmitted = true;
      });
      addTearDown(confirmSub.cancel);

      await tester.pumpWidget(
        buildAppShell(
          child: GrantOrSubsidyListener(
            bus: bus,
            game: game,
            humanPlayerId: humanPlayerId,
            child: const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pump();

      bus.emit(
        GrantOrSubsidySubmittedEvent(
          targetFactionId: targetFactionId,
          amount: 1000,
          isSubsidy: false,
        ),
      );
      await tester.pump();

      final append = await appendFuture;
      expect(append.playerId, humanPlayerId);
      expect(append.order.type, DiplomaticOrderType.grantAid);
      expect(append.order.targetFactionId, targetFactionId);
      expect(append.order.amount, 1000);
      expect(confirmEmitted, isFalse);

      final mood = await moodFuture;
      final turn = game.worldState.turnState.turnNumber;
      final base = game.globalGameSeed ?? 0;
      expect(mood.leaderId, targetFactionId);
      expect(mood.offerQualityDelta, 0.7);
      expect(mood.stallCounter, 0);
      expect(mood.currentMood, kDefaultMood);
      expect(mood.seed, base ^ (turn * kDeterministicHashMixPrime32) ^ 1000);
    },
  );

  testWidgets(
    'GrantOrSubsidyListener appends subsidy with 0.5 mood delta and no confirm',
    (WidgetTester tester) async {
      final game = buildGrantOrSubsidyListenerTestGame();
      final humanPlayerId = game.players.firstWhere((p) => p.isHuman).id;
      final targetFactionId = game.players.firstWhere((p) => !p.isHuman).id;
      final bus = AppEventBus.create();

      final appendFuture = bus
          .on<AppendDiplomaticOrderRequestedEvent>()
          .first
          .timeout(const Duration(seconds: 2));
      final moodFuture = bus.on<NegotiationMoodUpdateEvent>().first.timeout(
        const Duration(seconds: 2),
      );

      var confirmEmitted = false;
      final confirmSub = bus.on<ConfirmDialogEvent>().listen((_) {
        confirmEmitted = true;
      });
      addTearDown(confirmSub.cancel);

      await tester.pumpWidget(
        buildAppShell(
          child: GrantOrSubsidyListener(
            bus: bus,
            game: game,
            humanPlayerId: humanPlayerId,
            child: const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pump();

      bus.emit(
        GrantOrSubsidySubmittedEvent(
          targetFactionId: targetFactionId,
          amount: 10,
          isSubsidy: true,
        ),
      );
      await tester.pump();

      final append = await appendFuture;
      expect(append.order.type, DiplomaticOrderType.setSubsidy);
      expect(append.order.amount, 10);
      expect(confirmEmitted, isFalse);

      final mood = await moodFuture;
      expect(mood.offerQualityDelta, 0.5);
      expect(mood.stallCounter, 0);
    },
  );

  testWidgets(
    'GrantOrSubsidyListener readOnly ignores GrantOrSubsidySubmittedEvent',
    (WidgetTester tester) async {
      final game = buildGrantOrSubsidyListenerTestGame();
      final humanPlayerId = game.players.firstWhere((p) => p.isHuman).id;
      final targetFactionId = game.players.firstWhere((p) => !p.isHuman).id;
      final bus = AppEventBus.create();

      var appendEmitted = false;
      var moodEmitted = false;
      var confirmEmitted = false;
      final appendSub = bus.on<AppendDiplomaticOrderRequestedEvent>().listen((
        _,
      ) {
        appendEmitted = true;
      });
      final moodSub = bus.on<NegotiationMoodUpdateEvent>().listen((_) {
        moodEmitted = true;
      });
      final confirmSub = bus.on<ConfirmDialogEvent>().listen((_) {
        confirmEmitted = true;
      });
      addTearDown(appendSub.cancel);
      addTearDown(moodSub.cancel);
      addTearDown(confirmSub.cancel);

      await tester.pumpWidget(
        buildAppShell(
          child: GrantOrSubsidyListener(
            bus: bus,
            game: game,
            humanPlayerId: humanPlayerId,
            readOnly: true,
            child: const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pump();

      bus.emit(
        GrantOrSubsidySubmittedEvent(
          targetFactionId: targetFactionId,
          amount: 1000,
          isSubsidy: false,
        ),
      );
      await tester.pump();

      expect(appendEmitted, isFalse);
      expect(moodEmitted, isFalse);
      expect(confirmEmitted, isFalse);
    },
  );
}
