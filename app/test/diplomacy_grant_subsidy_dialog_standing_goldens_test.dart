// Standing-word golden pins for DIPL20001 (Refs #4632 / #4734 Slice F).
// Base grant/subsidy previews: diplomacy_grant_subsidy_dialog_goldens_test.dart.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'diplomacy_grant_subsidy_dialog_goldens_fixtures.dart';
import 'editorial_monocle_dark_token_assertions.dart';
import 'widget_test_assets.dart';

void main() {
  suppressLogsForTests();

  setUpAll(() async {
    await setUpNinePatchAssets();
  });

  testWidgets(
    'golden: DIPL20001 grant standing word becomes Neutral (Refs #4632)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'dipl20001_grant_standing_becomes_golden',
      );
      await pumpDiploGrantSubsidyGoldenDialog(
        tester,
        boundaryKey: boundaryKey,
        game: buildDiploGrantSubsidyGoldenGame(
          humanTreasury: 5 * grantAidAmountStep,
          pairScore: 45,
        ),
        isSubsidy: false,
      );

      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(
        find.text('Effect: Standing word becomes Neutral.'),
        findsOneWidget,
      );
      expect(find.textContaining('+5'), findsNothing);

      await expectLater(
        find.byKey(const Key('grantOrSubsidyDialogPreview')),
        matchesGoldenFile('goldens/dipl20001_grant_standing_becomes.png'),
      );
    },
  );

  testWidgets(
    'golden: DIPL20001 grant standing word stays Devoted (Refs #4632)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'dipl20001_grant_standing_stays_golden',
      );
      await pumpDiploGrantSubsidyGoldenDialog(
        tester,
        boundaryKey: boundaryKey,
        game: buildDiploGrantSubsidyGoldenGame(
          humanTreasury: 5 * grantAidAmountStep,
          pairScore: 95,
        ),
        isSubsidy: false,
      );

      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.text('Effect: Standing word stays Devoted.'), findsOneWidget);

      await expectLater(
        find.byKey(const Key('grantOrSubsidyDialogPreview')),
        matchesGoldenFile('goldens/dipl20001_grant_standing_stays.png'),
      );
    },
  );
}
