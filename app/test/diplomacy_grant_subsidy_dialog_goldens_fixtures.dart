// Fixtures for DIPL20001 Grant / Set Subsidy golden tests (Refs #4415 / #4734 Slice F).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_dialogs.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';

const diploGrantSubsidyGoldenHumanId = 'gp1';
const diploGrantSubsidyGoldenTargetId = 'gp2';
const Size diploGrantSubsidyGoldenDialogHost = Size(420, 560);

Game buildDiploGrantSubsidyGoldenGame({
  required int humanTreasury,
  num? pairScore,
}) {
  return Game(
    id: 'g_dipl20001_golden',
    worldState: const WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(),
      newWorld: RegionData(),
    ),
    players: [
      Player(
        id: diploGrantSubsidyGoldenHumanId,
        displayName: 'Castile',
        isHuman: true,
        treasury: humanTreasury,
      ),
      const Player(
        id: diploGrantSubsidyGoldenTargetId,
        displayName: 'England',
        isHuman: false,
        treasury: 0,
      ),
    ],
    diplomacyRelations: pairScore == null
        ? const []
        : [
            DiplomacyRelation(
              factionId1: diploGrantSubsidyGoldenHumanId,
              factionId2: diploGrantSubsidyGoldenTargetId,
              score: pairScore,
            ),
          ],
  );
}

Future<void> pumpDiploGrantSubsidyGoldenDialog(
  WidgetTester tester, {
  required Key boundaryKey,
  required Game game,
  required bool isSubsidy,
  Size physicalSize = diploGrantSubsidyGoldenDialogHost,
}) async {
  await pumpGoldenHost(
    tester,
    boundaryKey: boundaryKey,
    physicalSize: physicalSize,
    settle: false,
    includeLocalizations: true,
    scaffoldBackgroundColor: AppThemes.editorialMonocle.scaffoldBackgroundColor,
    child: GrantOrSubsidyDialog(
      game: game,
      humanPlayerId: diploGrantSubsidyGoldenHumanId,
      targetFactionId: diploGrantSubsidyGoldenTargetId,
      isSubsidy: isSubsidy,
      bus: AppEventBus.create(),
    ),
  );
}
