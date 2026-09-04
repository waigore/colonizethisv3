// Join Empire confirm preview goldens (Refs #4729).
// Pins Minor absorb / Tribe colony / GP absorb Effect copy under
// AppThemes.editorialMonocle at 360 dp (and Tribe at 320 dp).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/widgets/ct_confirm_dialog.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'diplomacy_confirm_preview_goldens_fixtures.dart';
import 'editorial_monocle_dark_token_assertions.dart';
import 'golden_capture_harness.dart';
import 'widget_test_assets.dart';

void main() {
  suppressLogsForTests();

  setUpAll(() async {
    await setUpNinePatchAssets();
  });

  testWidgets(
    'golden: Join Empire Minor absorb confirm (Refs #4729)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'diplomacy_confirm_join_empire_minor_golden',
      );
      final message = buildDiplomacyConfirmPreviewMessage(
        order: const DiplomaticOrder(
          type: DiplomaticOrderType.establishOverture,
          targetFactionId: 'minor1',
          overtureStage: OvertureStage.joinEmpire,
        ),
        game: diplomacyConfirmMinorOvertureGame(),
        humanPlayerId: diplomacyConfirmPreviewHumanId,
        targetDisplayName: 'Bavaria',
      );

      await pumpGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(360, 420),
        settle: false,
        scaffoldBackgroundColor:
            AppThemes.editorialMonocle.scaffoldBackgroundColor,
        child: CtConfirmDialog(title: 'Join Empire', message: message),
      );

      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.textContaining('absorbed'), findsOneWidget);
      expect(find.textContaining('leave the map'), findsOneWidget);
      expect(find.textContaining('£'), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/diplomacy_confirm_join_empire_minor.png'),
      );
    },
  );

  testWidgets(
    'golden: Join Empire Tribe colony confirm (Refs #4729)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'diplomacy_confirm_join_empire_tribe_golden',
      );
      final message = buildDiplomacyConfirmPreviewMessage(
        order: const DiplomaticOrder(
          type: DiplomaticOrderType.establishOverture,
          targetFactionId: 'tribe1',
          overtureStage: OvertureStage.joinEmpire,
        ),
        game: diplomacyConfirmTribeOvertureGame(),
        humanPlayerId: diplomacyConfirmPreviewHumanId,
        targetDisplayName: 'Aztec',
      );

      await pumpGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(360, 480),
        settle: false,
        scaffoldBackgroundColor:
            AppThemes.editorialMonocle.scaffoldBackgroundColor,
        child: CtConfirmDialog(title: 'Join Empire', message: message),
      );

      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.textContaining('colony'), findsOneWidget);
      expect(find.textContaining('31 Old World provinces'), findsOneWidget);
      expect(find.textContaining('absorbed'), findsNothing);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/diplomacy_confirm_join_empire_tribe.png'),
      );
    },
  );

  testWidgets(
    'golden: Join Empire Tribe colony confirm @ 320dp (Refs #4729)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'diplomacy_confirm_join_empire_tribe_320dp_golden',
      );
      final message = buildDiplomacyConfirmPreviewMessage(
        order: const DiplomaticOrder(
          type: DiplomaticOrderType.establishOverture,
          targetFactionId: 'tribe1',
          overtureStage: OvertureStage.joinEmpire,
        ),
        game: diplomacyConfirmTribeOvertureGame(),
        humanPlayerId: diplomacyConfirmPreviewHumanId,
        targetDisplayName: 'Aztec',
      );

      await pumpGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(kMinViewportWidth, 520),
        settle: false,
        scaffoldBackgroundColor:
            AppThemes.editorialMonocle.scaffoldBackgroundColor,
        child: CtConfirmDialog(title: 'Join Empire', message: message),
      );

      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.textContaining('colony'), findsOneWidget);
      expect(find.textContaining('31 Old World provinces'), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/diplomacy_confirm_join_empire_tribe_320dp.png',
        ),
      );
    },
  );

  testWidgets(
    'golden: Join Empire GP absorb confirm (Refs #4729)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'diplomacy_confirm_join_empire_gp_golden',
      );
      final message = diplomacyConfirmPreviewMessage(
        const DiplomaticOrder(
          type: DiplomaticOrderType.establishOverture,
          targetFactionId: diplomacyConfirmPreviewTargetGp,
          overtureStage: OvertureStage.joinEmpire,
        ),
      );

      await pumpGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(360, 420),
        settle: false,
        scaffoldBackgroundColor:
            AppThemes.editorialMonocle.scaffoldBackgroundColor,
        child: CtConfirmDialog(title: 'Join Empire', message: message),
      );

      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.textContaining('nearly defeated'), findsOneWidget);
      expect(find.textContaining('absorbed'), findsOneWidget);
      expect(find.textContaining('No treasury charge'), findsOneWidget);
      expect(find.textContaining('£'), findsNothing);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/diplomacy_confirm_join_empire_gp.png'),
      );
    },
  );
}
