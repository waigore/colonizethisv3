import 'package:colonizethis_app/features/game/widgets/grant_or_subsidy_listener.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  setUp(() {
    AppEventBus.reset();
  });

  testWidgets('GrantOrSubsidyListener emits append command after confirm', (
    WidgetTester tester,
  ) async {
    final game = buildGrantOrSubsidyListenerTestGame();
    final humanPlayerId = game.players.firstWhere((p) => p.isHuman).id;
    final targetFactionId = game.players.firstWhere((p) => !p.isHuman).id;
    final bus = AppEventBus.create();

    final appendFuture = bus
        .on<AppendDiplomaticOrderRequestedEvent>()
        .first
        .timeout(const Duration(seconds: 2));

    final confirmSub = bus.on<ConfirmDialogEvent>().listen((event) {
      event.result(true);
    });
    addTearDown(confirmSub.cancel);

    await tester.pumpWidget(
      MaterialApp(
        home: GrantOrSubsidyListener(
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
  });
}
