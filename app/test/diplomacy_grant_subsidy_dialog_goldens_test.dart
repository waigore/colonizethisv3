// Widget goldens for DIPL20001 Grant / Set Subsidy Cost–Effect preview
// (Refs #4415). Pins GrantOrSubsidyDialog under AppThemes.editorialMonocle.
// Standing-word pins: diplomacy_grant_subsidy_dialog_standing_goldens_test.dart.

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

  testWidgets('golden: DIPL20001 grant Cost/Effect preview (Refs #4415)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>('dipl20001_grant_preview_golden');
    await pumpDiploGrantSubsidyGoldenDialog(
      tester,
      boundaryKey: boundaryKey,
      game: buildDiploGrantSubsidyGoldenGame(
        humanTreasury: 5 * grantAidAmountStep,
      ),
      isSubsidy: false,
    );

    expect(tester.takeException(), isNull);
    expectEditorialMonocleDarkChrome(tester);
    expect(find.byType(CtDialogShell), findsOneWidget);
    expect(find.text('Grant aid'), findsOneWidget);
    expect(
      find.byKey(const Key('grantOrSubsidyDialogPreview')),
      findsOneWidget,
    );
    expect(
      find.text('Cost: £1000 from your treasury when the grant resolves.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Effect: Standing with England improves when the grant resolves.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Effect: A larger gift this turn does not improve standing further.',
      ),
      findsOneWidget,
    );
    expect(find.text('Effect: Standing word stays Neutral.'), findsOneWidget);

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/dipl20001_grant_preview.png'),
    );
  });

  testWidgets('golden: DIPL20001 subsidy Cost/Effect preview (Refs #4415)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>('dipl20001_subsidy_preview_golden');
    await pumpDiploGrantSubsidyGoldenDialog(
      tester,
      boundaryKey: boundaryKey,
      game: buildDiploGrantSubsidyGoldenGame(humanTreasury: 0),
      isSubsidy: true,
    );

    expect(tester.takeException(), isNull);
    expectEditorialMonocleDarkChrome(tester);
    expect(find.text('Set subsidy'), findsOneWidget);
    expect(find.text('Cost: No per-turn gold charge.'), findsOneWidget);
    expect(
      find.text(
        'Effect: ${subsidyFillPriceConsequence(targetDisplayName: 'England', percent: 5)}',
      ),
      findsOneWidget,
    );

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/dipl20001_subsidy_preview.png'),
    );
  });

  testWidgets(
    'golden: DIPL20001 grant below-minimum omits Cost/Effect (Refs #4415)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'dipl20001_grant_below_minimum_golden',
      );
      await pumpDiploGrantSubsidyGoldenDialog(
        tester,
        boundaryKey: boundaryKey,
        game: buildDiploGrantSubsidyGoldenGame(
          humanTreasury: grantAidAmountStep - 1,
        ),
        isSubsidy: false,
      );

      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(
        find.byKey(const Key('grantOrSubsidyDialogWarning')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('grantOrSubsidyDialogPreview')),
        findsNothing,
      );
      expect(find.textContaining('Cost:'), findsNothing);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/dipl20001_grant_below_minimum.png'),
      );
    },
  );

  testWidgets(
    'golden: DIPL20001 grant Cost/Effect preview @ 320dp (Refs #4415)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'dipl20001_grant_preview_320dp_golden',
      );
      await pumpDiploGrantSubsidyGoldenDialog(
        tester,
        boundaryKey: boundaryKey,
        game: buildDiploGrantSubsidyGoldenGame(
          humanTreasury: 5 * grantAidAmountStep,
        ),
        isSubsidy: false,
        physicalSize: const Size(kMinViewportWidth, 640),
      );

      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(
        find.byKey(const Key('grantOrSubsidyDialogPreview')),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Submit'), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/dipl20001_grant_preview_320dp.png'),
      );
    },
  );
}
