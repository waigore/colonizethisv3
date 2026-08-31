// Widget goldens for diplomacy confirm preview bodies (Refs #4181).
// Pins CtConfirmDialog rendering of first-order Cost/Effect/When copy under
// AppThemes.editorialMonocle at standard and 320 dp widths.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/widgets/ct_confirm_dialog.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'editorial_monocle_dark_token_assertions.dart';
import 'golden_capture_harness.dart';
import 'widget_test_assets.dart';

const _humanId = 'gp1';
const _targetGp = 'gp2';

Game _previewGame() => diplomacyGame(
  players: const [
    Player(
      id: _humanId,
      displayName: 'England',
      isHuman: true,
      treasury: 50_000,
    ),
    Player(id: _targetGp, displayName: 'Spain', isHuman: false),
  ],
);

String _previewMessage(DiplomaticOrder order) =>
    buildDiplomacyConfirmPreviewMessage(
      order: order,
      game: _previewGame(),
      humanPlayerId: _humanId,
      targetDisplayName: 'Spain',
    );

void main() {
  suppressLogsForTests();

  setUpAll(() async {
    await setUpNinePatchAssets();
  });

  testWidgets(
    'golden: Break Alliance confirm preview with immediate timing (Refs #4181)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'diplomacy_confirm_break_alliance_golden',
      );
      final message = _previewMessage(
        const DiplomaticOrder(
          type: DiplomaticOrderType.breakAlliance,
          targetFactionId: _targetGp,
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
      expect(find.byType(CtNinePatchButton), findsNWidgets(2));

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/diplomacy_confirm_break_alliance.png'),
      );
    },
  );

  testWidgets('golden: Declare War confirm preview @ 320dp (Refs #4181)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>(
      'diplomacy_confirm_declare_war_320dp_golden',
    );
    final message = _previewMessage(
      const DiplomaticOrder(
        type: DiplomaticOrderType.declareWar,
        targetFactionId: _targetGp,
      ),
    );

    await pumpGoldenHost(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: const Size(kMinViewportWidth, 360),
      settle: false,
      scaffoldBackgroundColor:
          AppThemes.editorialMonocle.scaffoldBackgroundColor,
      child: CtConfirmDialog(title: 'Declare War', message: message),
    );

    expect(tester.takeException(), isNull);
    expectEditorialMonocleDarkChrome(tester);
    expect(find.textContaining('War with Spain'), findsOneWidget);
    expect(find.textContaining('overtures'), findsOneWidget);
    expect(find.textContaining('When:'), findsNothing);

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/diplomacy_confirm_declare_war_320dp.png'),
    );
  });

  testWidgets(
    'golden: Consulate overture confirm preview with single £ cost (Refs #4181)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'diplomacy_confirm_consulate_golden',
      );
      final message = buildDiplomacyConfirmPreviewMessage(
        order: const DiplomaticOrder(
          type: DiplomaticOrderType.establishOverture,
          targetFactionId: 'minor1',
          overtureStage: OvertureStage.tradeConsulate,
        ),
        game: diplomacyGame(
          players: const [
            Player(id: _humanId, displayName: 'England', isHuman: true),
          ],
          minorNations: const [
            MinorNation(id: 'minor1', displayName: 'Bavaria'),
          ],
        ),
        humanPlayerId: _humanId,
        targetDisplayName: 'Bavaria',
      );

      await pumpGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(360, 340),
        settle: false,
        scaffoldBackgroundColor:
            AppThemes.editorialMonocle.scaffoldBackgroundColor,
        child: CtConfirmDialog(title: 'Consulate', message: message),
      );

      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.textContaining('£$overtureConsulateCost'), findsOneWidget);
      expect(find.textContaining('Explore and Prospect'), findsOneWidget);
      expect(find.textContaining('First right'), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/diplomacy_confirm_consulate.png'),
      );
    },
  );

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
        game: diplomacyGame(
          players: const [
            Player(id: _humanId, displayName: 'England', isHuman: true),
          ],
          minorNations: const [
            MinorNation(id: 'minor1', displayName: 'Bavaria'),
          ],
        ),
        humanPlayerId: _humanId,
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
        game: diplomacyGame(
          players: const [
            Player(id: _humanId, displayName: 'England', isHuman: true),
          ],
          minorNations: const [
            MinorNation(id: 'minor1', displayName: 'Bavaria'),
          ],
        ),
        humanPlayerId: _humanId,
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

  testWidgets(
    'golden: Establish Favored partner confirm first-order Effect (Refs #4586)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'diplomacy_confirm_establish_favored_partner_golden',
      );
      final message = _previewMessage(
        const DiplomaticOrder(
          type: DiplomaticOrderType.establishFtp,
          targetFactionId: _targetGp,
        ),
      );

      await pumpGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(360, 420),
        settle: false,
        scaffoldBackgroundColor:
            AppThemes.editorialMonocle.scaffoldBackgroundColor,
        child: CtConfirmDialog(
          title: 'Establish Favored partner',
          message: message,
        ),
      );

      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.text('Establish Favored partner'), findsOneWidget);
      expect(find.textContaining('No treasury charge'), findsOneWidget);
      expect(find.textContaining('Favored Trading Partners'), findsOneWidget);
      expect(find.textContaining('same bid rank'), findsOneWidget);
      expect(find.textContaining('Prices do not change'), findsOneWidget);
      expect(find.textContaining('First right of refusal'), findsOneWidget);
      expect(find.textContaining('When:'), findsNothing);
      expect(find.textContaining('65'), findsNothing);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/diplomacy_confirm_establish_favored_partner.png',
        ),
      );
    },
  );

  testWidgets(
    'golden: Boycott confirm full embargo copy with two colonies (Refs #4584)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('diplomacy_confirm_boycott_golden');
      final game = _twoColonyPreviewGame();
      final message = buildDiplomacyConfirmPreviewMessage(
        order: const DiplomaticOrder(
          type: DiplomaticOrderType.boycott,
          targetFactionId: _targetGp,
        ),
        game: game,
        humanPlayerId: _humanId,
        targetDisplayName: 'Spain',
      );

      await pumpGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(360, 420),
        settle: false,
        scaffoldBackgroundColor:
            AppThemes.editorialMonocle.scaffoldBackgroundColor,
        child: CtConfirmDialog(title: 'Boycott', message: message),
      );

      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.textContaining('No treasury charge'), findsOneWidget);
      expect(find.textContaining('will not fill'), findsOneWidget);
      expect(find.textContaining('cannot purchase land'), findsOneWidget);
      expect(
        find.textContaining('cancelled when this resolves'),
        findsOneWidget,
      );
      expect(find.textContaining('Aztec'), findsWidgets);
      expect(find.textContaining('Inca'), findsWidgets);
      expect(find.textContaining('When:'), findsNothing);
      expect(find.text('65'), findsNothing);
      expect(find.textContaining('tribe_aztec'), findsNothing);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/diplomacy_confirm_boycott.png'),
      );
    },
  );

  testWidgets(
    'golden: Revoke Boycott confirm restores court work copy (Refs #4584)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'diplomacy_confirm_revoke_boycott_golden',
      );
      final game = _twoColonyPreviewGame();
      final message = buildDiplomacyConfirmPreviewMessage(
        order: const DiplomaticOrder(
          type: DiplomaticOrderType.revokeBoycott,
          targetFactionId: _targetGp,
        ),
        game: game,
        humanPlayerId: _humanId,
        targetDisplayName: 'Spain',
      );

      await pumpGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(360, 360),
        settle: false,
        scaffoldBackgroundColor:
            AppThemes.editorialMonocle.scaffoldBackgroundColor,
        child: CtConfirmDialog(title: 'Revoke Boycott', message: message),
      );

      expect(tester.takeException(), isNull);
      expectEditorialMonocleDarkChrome(tester);
      expect(find.textContaining('No treasury charge'), findsOneWidget);
      expect(find.textContaining('Ends the embargo'), findsOneWidget);
      expect(find.textContaining('purchase land'), findsOneWidget);
      expect(find.textContaining('When:'), findsNothing);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/diplomacy_confirm_revoke_boycott.png'),
      );
    },
  );
}

Game _twoColonyPreviewGame() => diplomacyGame(
  players: const [
    Player(
      id: _humanId,
      displayName: 'England',
      isHuman: true,
      treasury: 50_000,
    ),
    Player(id: _targetGp, displayName: 'Spain', isHuman: false),
  ],
  tribes: const [
    Tribe(id: 'tribe_aztec', displayName: 'Aztec'),
    Tribe(id: 'tribe_inca', displayName: 'Inca'),
  ],
  colonyStates: const [
    ColonyState(tribeId: 'tribe_aztec', colonyOfGpId: _humanId, sinceTurn: 1),
    ColonyState(tribeId: 'tribe_inca', colonyOfGpId: _humanId, sinceTurn: 1),
  ],
);
