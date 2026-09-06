// Widget goldens for Technology Tree assign-from-dialog ACs (Refs #4498).

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/technology/tech_definition_detail_dialog.dart';
import 'package:colonizethis_app/widgets/ct_confirm_dialog.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';
import 'panel_test_fixtures.dart';
import 'tech_tree_assign_dialog_goldens_fixtures.dart';

void main() {
  suppressLogsForTests();

  late Game baseGame;
  late Player basePlayer;

  setUpAll(() {
    baseGame = buildTechnologyPanelTestGame();
    basePlayer = baseGame.players.first;
  });

  testWidgets(
    'AC1 golden: assignable tree node shows Research this control',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('tech_tree_assign_research_this');
      final player = techTreeAssignDialogEmptySeatsPlayer(basePlayer);
      final game = techTreeAssignDialogGameWithPlayer(player, baseGame);

      await pumpTechTreeAssignDialogGolden(
        tester,
        boundaryKey: boundaryKey,
        game: game,
        player: player,
        onOrdersChanged: (_) {},
      );
      await openTechTreeAssignDialogNode(
        tester,
        techDisplayName(kTechIdCropRotation),
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('techTreeResearchThis')), findsOneWidget);
      expect(find.text('Research this'), findsOneWidget);

      await expectLater(
        find.byType(CtDialogShell),
        matchesGoldenFile('goldens/tech_tree_assign_research_this.png'),
      );
    },
  );

  testWidgets(
    'AC2 golden: all seats full shows replace-seat list',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('tech_tree_assign_replace_seats');
      final player = techTreeAssignDialogAllSeatsFullPlayer(basePlayer);
      final game = techTreeAssignDialogGameWithPlayer(player, baseGame);

      await pumpTechTreeAssignDialogGolden(
        tester,
        boundaryKey: boundaryKey,
        game: game,
        player: player,
        onOrdersChanged: (_) {},
      );
      await openTechTreeAssignDialogNode(
        tester,
        techDisplayName(kTechIdSheepRanching),
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('techTreeResearchThis')), findsNothing);
      expect(find.byKey(const Key('techTreeReplaceSeat_0')), findsOneWidget);

      await expectLater(
        find.byType(CtDialogShell),
        matchesGoldenFile('goldens/tech_tree_assign_replace_seats.png'),
      );
    },
  );

  testWidgets(
    'AC2 golden: replace-seat forfeit confirm dialog copy',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('tech_tree_assign_forfeit_confirm');
      const progress = 40;

      await pumpGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(540, 360),
        settle: false,
        includeLocalizations: true,
        scaffoldBackgroundColor:
            AppThemes.editorialMonocle.scaffoldBackgroundColor,
        child: Builder(
          builder: (context) {
            final l10n = appL10n(context);
            return CtConfirmDialog(
              title: l10n.technologyPanel_cancelWarningTitle,
              message: l10n.technologyPanel_cancelWarningMessage(
                techDisplayName(kTechIdSawMill),
                progress,
              ),
              confirmLabel: l10n.technologyPanel_cancelWarningConfirm,
              cancelLabel: l10n.technologyPanel_cancelWarningKeep,
            );
          },
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Forfeit research progress?'), findsOneWidget);

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/tech_tree_assign_forfeit_confirm.png'),
      );
    },
  );

  testWidgets(
    'AC3 golden: locked tree node shows waiting-on refusal reason',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('tech_tree_assign_locked_reason');
      final player = techTreeAssignDialogEmptySeatsPlayer(basePlayer);
      final game = techTreeAssignDialogGameWithPlayer(player, baseGame);

      await pumpTechTreeAssignDialogGolden(
        tester,
        boundaryKey: boundaryKey,
        game: game,
        player: player,
        onOrdersChanged: (_) {},
      );
      await openTechTreeAssignDialogNode(
        tester,
        techDisplayName(kTechIdSheepRanching),
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('techTreeAssignReason')), findsOneWidget);
      expect(find.textContaining('Waiting on:'), findsOneWidget);

      await expectLater(
        find.byType(CtDialogShell),
        matchesGoldenFile('goldens/tech_tree_assign_locked_reason.png'),
      );
    },
  );

  testWidgets(
    'AC5 golden: Choose-tech Details dialog has no Tree assign section',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>(
        'tech_tree_choose_tech_details_no_assign',
      );

      await pumpGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: techTreeAssignDialogGoldenHost,
        settle: false,
        includeLocalizations: true,
        scaffoldBackgroundColor:
            AppThemes.editorialMonocle.scaffoldBackgroundColor,
        child: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () {
                showTechDefinitionDetailDialog(
                  context,
                  game: baseGame,
                  player: basePlayer,
                  tech: techById(kTechIdCropRotation)!,
                );
              },
              child: const Text('Open details'),
            );
          },
        ),
      );
      await tester.tap(find.text('Open details'));
      await pumpForGolden(tester);

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('techTreeResearchThis')), findsNothing);
      expect(find.byKey(const Key('techTreeAssignReason')), findsNothing);

      await expectLater(
        find.byType(CtDialogShell),
        matchesGoldenFile('goldens/tech_tree_choose_tech_details_no_assign.png'),
      );
    },
  );
}
