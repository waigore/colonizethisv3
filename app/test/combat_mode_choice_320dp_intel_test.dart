// 320 dp pin for CMPT10001 with force/fort/meaning lines. Refs #4438.

import 'package:colonizethis_app/features/game/widgets/combat/combat_mode_choice_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/combat/combat_mode_choice_intel.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'dialogs_320dp_min_viewport_support.dart';

void main() {
  suppressLogsForTests();

  testWidgets(
    'CombatModeChoiceDialog with force/fort/meanings @ 320×640 has no overflow',
    (WidgetTester tester) async {
      await pumpDialogs320At(
        tester,
        CombatModeChoiceDialog(
          bus: AppEventBus.create(),
          provinceName: 'Lisbon',
          isCapitalSiege: false,
          intel: const CombatModeChoiceIntel(
            role: CombatModeChoiceRole.attacker,
            ownRegimentCount: 3,
            ownTypesByRegimentId: {'musketeers': 2, 'pikemen': 1},
            enemyRegimentCount: 2,
            enemyTypesByRegimentId: {'musketeers': 2},
            fortLevel: 1,
          ),
        ),
        size: kDialogs320MinViewport,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Your army: 3 regiments'), findsOneWidget);
      expect(find.textContaining('Auto-Resolve'), findsOneWidget);
      expect(find.textContaining('Quick Battle'), findsOneWidget);
    },
  );
}
