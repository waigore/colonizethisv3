// Widget goldens for combat mode choice land underfed soft-warn (CMPT10001 / #4242).
// SPEC/ui/combat-mode-choice-dialog.md § Forces food soft warning.

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/combat/combat_mode_choice_dialog.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'editorial_monocle_dark_token_assertions.dart';
import 'golden_capture_harness.dart';
import 'widget_test_assets.dart';

void main() {
  suppressLogsForTests();

  setUpAll(() async {
    await setUpNinePatchAssets();
  });

  testWidgets(
    'golden: combat mode choice shows land underfed soft warning (Refs #4242)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'combatModeChoiceUnderfedForcesGolden',
      );
      const warning =
          'Your armies are short on rations — they will fight somewhat weaker this turn.';

      await pumpGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(360, 320),
        settle: false,
        includeLocalizations: true,
        scaffoldBackgroundColor:
            AppThemes.editorialMonocle.scaffoldBackgroundColor,
        child: CombatModeChoiceDialog(
          bus: AppEventBus.create(),
          provinceName: 'Lisbon',
          isCapitalSiege: false,
          landForceFeedingWarning: warning,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.text(warning), findsOneWidget);
      expect(find.textContaining('Auto-Resolve'), findsOneWidget);
      expect(find.textContaining('Quick Battle'), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/combat_mode_choice_underfed_forces.png'),
      );
    },
  );
}
