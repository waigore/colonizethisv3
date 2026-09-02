// Embassy/NAP overture confirm preview goldens (Refs #4682).

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
    'golden: Embassy overture confirm preview with unlock copy (Refs #4682)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'diplomacy_confirm_embassy_golden',
      );
      final message = buildDiplomacyConfirmPreviewMessage(
        order: const DiplomaticOrder(
          type: DiplomaticOrderType.establishOverture,
          targetFactionId: 'minor1',
          overtureStage: OvertureStage.embassy,
        ),
        game: diplomacyConfirmMinorOvertureGame(),
        humanPlayerId: diplomacyConfirmPreviewHumanId,
        targetDisplayName: 'Bavaria',
      );

      await pumpGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(360, 400),
        settle: false,
        scaffoldBackgroundColor:
            AppThemes.editorialMonocle.scaffoldBackgroundColor,
        child: CtConfirmDialog(title: 'Embassy', message: message),
      );

      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.textContaining('£$overtureEmbassyCost'), findsOneWidget);
      expect(find.textContaining('Grant Aid'), findsOneWidget);
      expect(find.textContaining('Purchase land'), findsOneWidget);
      expect(find.textContaining('intervene'), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/diplomacy_confirm_embassy.png'),
      );
    },
  );

  testWidgets(
    'golden: NAP overture confirm preview with join-empire path (Refs #4682)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('diplomacy_confirm_nap_golden');
      final message = buildDiplomacyConfirmPreviewMessage(
        order: const DiplomaticOrder(
          type: DiplomaticOrderType.establishOverture,
          targetFactionId: 'minor1',
          overtureStage: OvertureStage.nap,
        ),
        game: diplomacyConfirmMinorOvertureGame(),
        humanPlayerId: diplomacyConfirmPreviewHumanId,
        targetDisplayName: 'Bavaria',
      );

      await pumpGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(360, 320),
        settle: false,
        scaffoldBackgroundColor:
            AppThemes.editorialMonocle.scaffoldBackgroundColor,
        child: CtConfirmDialog(title: 'NAP', message: message),
      );

      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.textContaining('No treasury charge'), findsOneWidget);
      expect(find.textContaining('Join Empire'), findsOneWidget);
      expect(find.textContaining('Declare War'), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/diplomacy_confirm_nap.png'),
      );
    },
  );
}
