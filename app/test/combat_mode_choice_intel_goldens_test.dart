// Widget goldens for CMPT10001 force/fort/Details/mode-meaning (Refs #4438).
// SPEC/ui/combat-mode-choice-dialog.md § States and variants CMPT10001c–f / a.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/combat/combat_mode_choice_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/combat/combat_mode_choice_intel.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'editorial_monocle_dark_token_assertions.dart';
import 'golden_capture_harness.dart';
import 'widget_test_assets.dart';

const _attackerFull = CombatModeChoiceIntel(
  role: CombatModeChoiceRole.attacker,
  ownRegimentCount: 3,
  ownTypesByRegimentId: {'musketeers': 2, 'pikemen': 1},
  enemyRegimentCount: 2,
  enemyTypesByRegimentId: {'musketeers': 2},
  fortLevel: 1,
);

const _attackerUnknown = CombatModeChoiceIntel(
  role: CombatModeChoiceRole.attacker,
  ownRegimentCount: 3,
  ownTypesByRegimentId: {'musketeers': 3},
  defendersUnknown: true,
);

const _defenderFull = CombatModeChoiceIntel(
  role: CombatModeChoiceRole.defender,
  ownRegimentCount: 5,
  ownTypesByRegimentId: {'musketeers': 3, 'pikemen': 2},
  enemyRegimentCount: 4,
  enemyTypesByRegimentId: {'musketeers': 4},
  fortLevel: 2,
);

void main() {
  suppressLogsForTests();

  setUpAll(() async {
    await setUpNinePatchAssets();
  });

  Future<void> pumpIntelGolden(
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
      scaffoldBackgroundColor:
          AppThemes.editorialMonocle.scaffoldBackgroundColor,
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

  testWidgets(
    'golden: attacker full intel shows own, defenders, wood siege (Refs #4438)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'combatModeChoiceAttackerFullGolden',
      );
      await pumpIntelGolden(
        tester,
        boundaryKey: boundaryKey,
        intel: _attackerFull,
      );
      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.text('Your army: 3 regiments'), findsOneWidget);
      expect(find.text('Defenders: 2 regiments'), findsOneWidget);
      expect(find.text('Wood fort siege'), findsOneWidget);
      expect(find.text('Unopposed capture'), findsNothing);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/combat_mode_choice_attacker_full.png'),
      );
    },
  );

  testWidgets(
    'golden: attacker unknown intel shows Defenders unknown without fort (Refs #4438)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'combatModeChoiceAttackerUnknownGolden',
      );
      await pumpIntelGolden(
        tester,
        boundaryKey: boundaryKey,
        intel: _attackerUnknown,
      );
      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.text('Your army: 3 regiments'), findsOneWidget);
      expect(find.text('Defenders unknown'), findsOneWidget);
      expect(find.textContaining('fort'), findsNothing);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/combat_mode_choice_attacker_unknown.png'),
      );
    },
  );

  testWidgets(
    'golden: defender full intel uses Attackers label not Defenders (Refs #4438)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'combatModeChoiceDefenderFullGolden',
      );
      await pumpIntelGolden(
        tester,
        boundaryKey: boundaryKey,
        intel: _defenderFull,
      );
      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.text('Your army: 5 regiments'), findsOneWidget);
      expect(find.text('Attackers: 4 regiments'), findsOneWidget);
      expect(find.textContaining('Defenders:'), findsNothing);
      expect(find.text('Stone fort siege'), findsOneWidget);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/combat_mode_choice_defender_full.png'),
      );
    },
  );

  testWidgets(
    'golden: Details open shows own and enemy type lines (Refs #4438)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('combatModeChoiceDetailsOpenGolden');
      await pumpIntelGolden(
        tester,
        boundaryKey: boundaryKey,
        intel: _attackerFull,
        detailsInitiallyOpen: true,
      );
      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.textContaining('Musketeers'), findsWidgets);
      expect(find.textContaining('Pikemen'), findsOneWidget);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/combat_mode_choice_details_open.png'),
      );
    },
  );

  testWidgets(
    'golden: capital siege omits Auto-Resolve and keeps fort line (Refs #4438)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'combatModeChoiceCapitalSiegeGolden',
      );
      await pumpIntelGolden(
        tester,
        boundaryKey: boundaryKey,
        intel: _attackerFull,
        isCapitalSiege: true,
      );
      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.textContaining('Auto-Resolve'), findsNothing);
      expect(find.text('Decides the battle at once.'), findsNothing);
      expect(find.text('Wood fort siege'), findsOneWidget);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/combat_mode_choice_capital_siege.png'),
      );
    },
  );

  testWidgets('golden: attacker full intel wraps at 320 dp (Refs #4438)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>(
      'combatModeChoiceAttackerFull320Golden',
    );
    await pumpIntelGolden(
      tester,
      boundaryKey: boundaryKey,
      intel: _attackerFull,
      physicalSize: const Size(kMinViewportWidth, 640),
    );
    expect(tester.takeException(), isNull);
    expectEditorialMonocleDarkChrome(tester);
    expect(find.text('Your army: 3 regiments'), findsOneWidget);
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/combat_mode_choice_attacker_full_320.png'),
    );
  });
}
