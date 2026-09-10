// Fixtures and pump helper for CMPT10001 intel goldens (Refs #4438, #4764).
// Concern split under repo.app_test_file_size.

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/combat/combat_mode_choice_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/combat/combat_mode_choice_intel.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';

const combatModeChoiceIntelGoldensAttackerFull = CombatModeChoiceIntel(
  role: CombatModeChoiceRole.attacker,
  ownRegimentCount: 3,
  ownTypesByRegimentId: {'musketeers': 2, 'pikemen': 1},
  enemyRegimentCount: 2,
  enemyTypesByRegimentId: {'musketeers': 2},
  fortLevel: 1,
);

const combatModeChoiceIntelGoldensAttackerUnknown = CombatModeChoiceIntel(
  role: CombatModeChoiceRole.attacker,
  ownRegimentCount: 3,
  ownTypesByRegimentId: {'musketeers': 3},
  defendersUnknown: true,
);

const combatModeChoiceIntelGoldensDefenderFull = CombatModeChoiceIntel(
  role: CombatModeChoiceRole.defender,
  ownRegimentCount: 5,
  ownTypesByRegimentId: {'musketeers': 3, 'pikemen': 2},
  enemyRegimentCount: 4,
  enemyTypesByRegimentId: {'musketeers': 4},
  fortLevel: 2,
);

Future<void> pumpCombatModeChoiceIntelGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required CombatModeChoiceIntel intel,
  bool isCapitalSiege = false,
  bool detailsInitiallyOpen = false,
  Size physicalSize = const Size(360, 640),
}) async {
  await pumpGoldenHost(
    tester,
    boundaryKey: boundaryKey,
    physicalSize: physicalSize,
    settle: false,
    includeLocalizations: true,
    scaffoldBackgroundColor: AppThemes.editorialMonocle.scaffoldBackgroundColor,
    child: CombatModeChoiceDialog(
      bus: AppEventBus.create(),
      provinceName: 'Lisbon',
      isCapitalSiege: isCapitalSiege,
      intel: intel,
      detailsInitiallyOpen: detailsInitiallyOpen,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}
