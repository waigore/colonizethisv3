// Widget goldens for Declare War third-party visual ACs (Refs #4409).
//
// Pins CtConfirmDialog / DLG20001 Declare war? / GAME30002 Formal allies
// under AppThemes.editorialMonocle. SPEC: diplomacy-panel.md,
// move-army-dialog.md, diplomacy-detail-screen.md.

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/widgets/ct_confirm_dialog.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'diplomacy_declare_war_third_party_goldens_fixtures.dart';
import 'diplomacy_panel_test_support.dart';
import 'editorial_monocle_dark_token_assertions.dart';
import 'golden_capture_harness.dart';
import 'widget_test_assets.dart';

void main() {
  suppressLogsForTests();

  setUpAll(() async {
    await setUpNinePatchAssets();
  });

  setUp(AppEventBus.reset);

  testWidgets(
    'golden: Declare War confirm names a persisted formal ally (Refs #4409)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'diplomacy_confirm_declare_war_named_ally_golden',
      );
      final game = declareWarGoldenNamedAllyGame();
      await pumpDeclareWarConfirmGolden(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(360, 420),
        game: game,
      );

      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.byType(CtConfirmDialog), findsOneWidget);
      expect(
        find.textContaining(
          'France holds a formal alliance with Spain and may be called to defend',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('will join'), findsNothing);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/diplomacy_confirm_declare_war_named_ally.png',
        ),
      );
    },
  );

  testWidgets(
    'golden: Declare War confirm emits one Effect line per ally sorted (Refs #4409)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'diplomacy_confirm_declare_war_two_allies_golden',
      );
      final game = declareWarGoldenNamedAllyGame(includeEnglandAlly: true);
      await pumpDeclareWarConfirmGolden(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(360, 520),
        game: game,
      );

      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.textContaining('England'), findsOneWidget);
      expect(find.textContaining('France'), findsOneWidget);
      expect(find.textContaining('England and France'), findsNothing);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/diplomacy_confirm_declare_war_two_allies.png',
        ),
      );
    },
  );

  testWidgets(
    'golden: DLG20001 Declare war? shares the named-ally Effect line (Refs #4409)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'move_army_declare_war_named_ally_golden',
      );
      final l10n = lookupAppLocalizations(const Locale('en'));
      final game = declareWarGoldenNamedAllyGame();

      await pumpGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(360, 440),
        settle: false,
        includeLocalizations: true,
        scaffoldBackgroundColor:
            AppThemes.editorialMonocle.scaffoldBackgroundColor,
        child: declareWarGoldenInvadeConfirm(l10n: l10n, game: game),
      );

      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.byType(CtDialogShell), findsOneWidget);
      expect(find.text('Declare war?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Declare war and move'), findsOneWidget);
      expect(
        find.textContaining(
          'France holds a formal alliance with Spain and may be called to defend',
        ),
        findsOneWidget,
      );

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/move_army_declare_war_named_ally.png'),
      );
    },
  );

  testWidgets(
    'GAME30002 golden: Formal allies names a persisted other-court treaty',
    (WidgetTester tester) async {
      await configureGoldenSurface(tester, size: const Size(600, 900));
      const boundaryKey = ValueKey<String>(
        'diplomacy_detail_formal_allies_golden',
      );
      final game = declareWarGoldenNamedAllyGame();
      await tester.pumpWidget(
        declareWarGoldenDetailHost(game: game, boundaryKey: boundaryKey),
      );
      await pumpDiplomacyPanelBuilt(tester);

      expect(find.text('CURRENT RELATION'), findsOneWidget);
      expect(find.text('Formal allies: France'), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/diplomacy_detail_formal_allies.png'),
      );
    },
  );

  testWidgets(
    'GAME30002 golden: Formal allies omitted when the viewed GP has none',
    (WidgetTester tester) async {
      await configureGoldenSurface(tester, size: const Size(600, 900));
      const boundaryKey = ValueKey<String>(
        'diplomacy_detail_formal_allies_omitted_golden',
      );
      final game = declareWarGoldenNoAllyGame();
      await tester.pumpWidget(
        declareWarGoldenDetailHost(game: game, boundaryKey: boundaryKey),
      );
      await pumpDiplomacyPanelBuilt(tester);

      expect(find.text('CURRENT RELATION'), findsOneWidget);
      expect(find.textContaining('Formal allies:'), findsNothing);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/diplomacy_detail_formal_allies_omitted.png'),
      );
    },
  );
}
