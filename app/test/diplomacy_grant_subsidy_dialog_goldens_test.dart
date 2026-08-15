// Widget goldens for DIPL20001 Grant / Set Subsidy Cost–Effect preview
// (Refs #4415). Pins GrantOrSubsidyDialog under AppThemes.editorialMonocle.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_dialogs.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'editorial_monocle_dark_token_assertions.dart';
import 'golden_capture_harness.dart';
import 'widget_test_assets.dart';

const _humanId = 'gp1';
const _targetId = 'gp2';
const Size _dialogHost = Size(420, 560);

Game _buildGame({required int humanTreasury}) {
  return Game(
    id: 'g_dipl20001_golden',
    worldState: const WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(),
      newWorld: RegionData(),
    ),
    players: [
      Player(
        id: _humanId,
        displayName: 'Castile',
        isHuman: true,
        treasury: humanTreasury,
      ),
      const Player(
        id: _targetId,
        displayName: 'England',
        isHuman: false,
        treasury: 0,
      ),
    ],
  );
}

Future<void> _pumpDialogGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required Game game,
  required bool isSubsidy,
  Size physicalSize = _dialogHost,
}) async {
  await pumpGoldenHost(
    tester,
    boundaryKey: boundaryKey,
    physicalSize: physicalSize,
    settle: false,
    includeLocalizations: true,
    scaffoldBackgroundColor: AppThemes.editorialMonocle.scaffoldBackgroundColor,
    child: GrantOrSubsidyDialog(
      game: game,
      humanPlayerId: _humanId,
      targetFactionId: _targetId,
      isSubsidy: isSubsidy,
      bus: AppEventBus.create(),
    ),
  );
}

void main() {
  suppressLogsForTests();

  setUpAll(() async {
    await setUpNinePatchAssets();
  });

  testWidgets('golden: DIPL20001 grant Cost/Effect preview (Refs #4415)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>('dipl20001_grant_preview_golden');
    await _pumpDialogGolden(
      tester,
      boundaryKey: boundaryKey,
      game: _buildGame(humanTreasury: 5 * grantAidAmountStep),
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

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/dipl20001_grant_preview.png'),
    );
  });

  testWidgets('golden: DIPL20001 subsidy Cost/Effect preview (Refs #4415)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>('dipl20001_subsidy_preview_golden');
    await _pumpDialogGolden(
      tester,
      boundaryKey: boundaryKey,
      game: _buildGame(humanTreasury: 0),
      isSubsidy: true,
    );

    expect(tester.takeException(), isNull);
    expectEditorialMonocleDarkChrome(tester);
    expect(find.text('Set subsidy'), findsOneWidget);
    expect(find.text('Cost: No per-turn gold charge.'), findsOneWidget);
    expect(
      find.text(
        'Effect: 5% subsidy with England while active; '
        'market terms are affected.',
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
      await _pumpDialogGolden(
        tester,
        boundaryKey: boundaryKey,
        game: _buildGame(humanTreasury: grantAidAmountStep - 1),
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
      await _pumpDialogGolden(
        tester,
        boundaryKey: boundaryKey,
        game: _buildGame(humanTreasury: 5 * grantAidAmountStep),
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
