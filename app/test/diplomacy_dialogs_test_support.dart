// Shared GrantOrSubsidyDialog pump helper (Refs #4352 Slice D).
// SPEC: SPEC/ui/grant-or-subsidy-dialog.md.

import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_dialogs.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'panel_test_fixtures.dart';

Future<Game> pumpGrantOrSubsidyDialog(
  WidgetTester tester, {
  required int humanTreasury,
  bool isSubsidy = false,
  AppEventBus? bus,
}) async {
  final base = buildDiplomacyScreenTestGame();
  final humanPlayerId = base.players.first.id;
  final targetFactionId = base.players.length >= 2
      ? base.players[1].id
      : (base.minorNations.isNotEmpty ? base.minorNations.first.id : 'm1');

  final game = base.copyWith(
    players: [
      base.players.first.copyWith(treasury: humanTreasury),
      ...base.players.skip(1),
    ],
  );

  final dialogBus = bus ?? AppEventBus.create();

  await tester.pumpWidget(
    buildAppShell(
      child: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            child: const Text('Open'),
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (ctx) => GrantOrSubsidyDialog(
                  game: game,
                  humanPlayerId: humanPlayerId,
                  targetFactionId: targetFactionId,
                  isSubsidy: isSubsidy,
                  bus: dialogBus,
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  return game;
}
