// Break Alliance confirm preview goldens (Refs #4719).
// Pins rest-of-turn lock Effect lines at standard and 320 dp widths.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/widgets/ct_confirm_dialog.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
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
    'golden: Break Alliance confirm preview with immediate timing and lock (Refs #4181, #4719)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'diplomacy_confirm_break_alliance_golden',
      );
      final message = diplomacyConfirmPreviewMessage(
        const DiplomaticOrder(
          type: DiplomaticOrderType.breakAlliance,
          targetFactionId: diplomacyConfirmPreviewTargetGp,
        ),
      );

      await pumpGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(360, 320),
        settle: false,
        scaffoldBackgroundColor:
            AppThemes.editorialMonocle.scaffoldBackgroundColor,
        child: CtConfirmDialog(title: 'Break Alliance', message: message),
      );

      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.byType(CtDialogShell), findsOneWidget);
      expect(find.text('Break Alliance'), findsOneWidget);
      expect(find.textContaining('When:'), findsOneWidget);
      expect(find.textContaining('immediately'), findsOneWidget);
      expect(find.textContaining('Until next turn'), findsOneWidget);
      expect(find.textContaining('Favored Trading Partner'), findsOneWidget);
      expect(find.textContaining('Declare War'), findsOneWidget);
      expect(find.textContaining('Offer Peace'), findsOneWidget);
      expect(find.textContaining('lock clears next turn'), findsOneWidget);
      expect(find.textContaining('Boycott'), findsNothing);
      expect(find.byType(CtNinePatchButton), findsNWidgets(2));

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/diplomacy_confirm_break_alliance.png'),
      );
    },
  );

  testWidgets(
    'golden: Break Alliance confirm preview @ 320dp (Refs #4719)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'diplomacy_confirm_break_alliance_320dp_golden',
      );
      final message = diplomacyConfirmPreviewMessage(
        const DiplomaticOrder(
          type: DiplomaticOrderType.breakAlliance,
          targetFactionId: diplomacyConfirmPreviewTargetGp,
        ),
      );

      await pumpGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(kMinViewportWidth, 420),
        settle: false,
        scaffoldBackgroundColor:
            AppThemes.editorialMonocle.scaffoldBackgroundColor,
        child: CtConfirmDialog(title: 'Break Alliance', message: message),
      );

      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.textContaining('Until next turn'), findsOneWidget);
      expect(find.textContaining('lock clears next turn'), findsOneWidget);
      expect(find.textContaining('Boycott'), findsNothing);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/diplomacy_confirm_break_alliance_320dp.png',
        ),
      );
    },
  );
}
