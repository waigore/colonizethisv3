// Widget goldens for Technology Tree assign-from-dialog ACs (Refs #4498).
//
// Pins Tree-opened tech definition dialogs under AppThemes.editorialMonocle:
// Research this, replace-seat list, forfeit confirm, refusal reasons, and
// Choose-tech Details without assign controls.
//
// SPEC: SPEC/ui/tech-tree-widget.md, SPEC/ui/technology-panel.md.

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/technology/tech_definition_detail_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/technology/tech_tree_widget.dart';
import 'package:colonizethis_app/widgets/ct_confirm_dialog.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'golden_capture_harness.dart';
import 'panel_test_fixtures.dart';

const Size _kTreeDialogHost = Size(420, 700);

Game _gameWithPlayer(Player player, Game base) {
  return base.copyWith(players: [player, ...base.players.skip(1)]);
}

Player _emptySeatsPlayer(Player base) {
  return base.copyWith(techUnlocked: <String, bool>{});
}

Player _allSeatsFullPlayer(Player base) {
  return base.copyWith(
    techUnlocked: {kTechIdCropRotation: true},
    researchSlots: 3,
    researchSlotAssignments: {
      0: const ResearchSlotAssignment(
        techId: kTechIdSawMill,
        funding: ResearchFundingLevel.medium,
      ),
      1: const ResearchSlotAssignment(
        techId: kTechIdLandEnclosure,
        funding: ResearchFundingLevel.medium,
      ),
      2: const ResearchSlotAssignment(
        techId: kTechIdIronMining,
        funding: ResearchFundingLevel.medium,
      ),
    },
    researchProgressByTechId: {kTechIdSawMill: 40},
  );
}

Future<void> _pumpTreeGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required Game game,
  required Player player,
  void Function(Orders orders)? onOrdersChanged,
}) async {
  await pumpGoldenHost(
    tester,
    boundaryKey: boundaryKey,
    physicalSize: _kTreeDialogHost,
    settle: false,
    includeLocalizations: true,
    scaffoldBackgroundColor: AppThemes.editorialMonocle.scaffoldBackgroundColor,
    child: TechTreeWidget(
      game: game,
      player: player,
      onOrdersChanged: onOrdersChanged,
    ),
  );
}

Future<void> _openTreeNode(WidgetTester tester, String displayName) async {
  final node = find.text(displayName).first;
  await tester.ensureVisible(node);
  await tester.tap(node);
  await pumpForGolden(tester);
}

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
      final player = _emptySeatsPlayer(basePlayer);
      final game = _gameWithPlayer(player, baseGame);

      await _pumpTreeGolden(
        tester,
        boundaryKey: boundaryKey,
        game: game,
        player: player,
        onOrdersChanged: (_) {},
      );
      await _openTreeNode(tester, techDisplayName(kTechIdCropRotation));

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
      final player = _allSeatsFullPlayer(basePlayer);
      final game = _gameWithPlayer(player, baseGame);

      await _pumpTreeGolden(
        tester,
        boundaryKey: boundaryKey,
        game: game,
        player: player,
        onOrdersChanged: (_) {},
      );
      await _openTreeNode(tester, techDisplayName(kTechIdSheepRanching));

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
      final player = _emptySeatsPlayer(basePlayer);
      final game = _gameWithPlayer(player, baseGame);

      await _pumpTreeGolden(
        tester,
        boundaryKey: boundaryKey,
        game: game,
        player: player,
        onOrdersChanged: (_) {},
      );
      await _openTreeNode(tester, techDisplayName(kTechIdSheepRanching));

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
        physicalSize: _kTreeDialogHost,
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
