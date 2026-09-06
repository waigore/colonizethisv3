// Fixtures for Technology Tree assign-from-dialog goldens (Refs #4498 / #4734 Slice F).

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/technology/tech_tree_widget.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';

const Size techTreeAssignDialogGoldenHost = Size(420, 700);

Game techTreeAssignDialogGameWithPlayer(Player player, Game base) {
  return base.copyWith(players: [player, ...base.players.skip(1)]);
}

Player techTreeAssignDialogEmptySeatsPlayer(Player base) {
  return base.copyWith(techUnlocked: <String, bool>{});
}

Player techTreeAssignDialogAllSeatsFullPlayer(Player base) {
  return base.copyWith(
    techUnlocked: {kTechIdCropRotation: true},
    researchSlots: 3,
    researchSlotAssignments: {
      0: const ResearchSlotAssignment(
        techId: kTechIdSawMill,
        funding: ResearchFundingLevel.medium,
      ),
      1: const ResearchSlotAssignment(
        techId: kTechIdLandEnclosure,
        funding: ResearchFundingLevel.medium,
      ),
      2: const ResearchSlotAssignment(
        techId: kTechIdIronMining,
        funding: ResearchFundingLevel.medium,
      ),
    },
    researchProgressByTechId: {kTechIdSawMill: 40},
  );
}

Future<void> pumpTechTreeAssignDialogGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required Game game,
  required Player player,
  void Function(Orders orders)? onOrdersChanged,
}) async {
  await pumpGoldenHost(
    tester,
    boundaryKey: boundaryKey,
    physicalSize: techTreeAssignDialogGoldenHost,
    settle: false,
    includeLocalizations: true,
    scaffoldBackgroundColor: AppThemes.editorialMonocle.scaffoldBackgroundColor,
    child: TechTreeWidget(
      game: game,
      player: player,
      onOrdersChanged: onOrdersChanged,
    ),
  );
}

Future<void> openTechTreeAssignDialogNode(
  WidgetTester tester,
  String displayName,
) async {
  final node = find.text(displayName).first;
  await tester.ensureVisible(node);
  await tester.tap(node);
  await pumpForGolden(tester);
}
