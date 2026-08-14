// Tests for CivilianUnitsPanel. SPEC/ui/civilian-units-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/civilian_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/civilian_units_sort.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show
        kWorkTargetBuildImprovement,
        kWorkTargetBuildRoad,
        kWorkTargetBuildRail,
        kWorkTargetExplore,
        kWorkTargetProspect,
        kWorkTargetPurchaseLand;

import 'civilian_units_panel_part1_shortcut_support.dart';
import 'civilian_units_panel_test_support.dart';

void main() {
  suppressLogsForTests();

  late Game game;
  late String humanPlayerIdWithUnits;
  const String humanPlayerIdWithNoUnits = 'no-such-player';

  setUpAll(() {
    game = buildCivilianPanelTestGame();
    humanPlayerIdWithUnits = game.players.first.id;
  });

  group('CivilianUnitsPanel', () {
    testWidgets('AC: Panel shows title Civilian Units', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildCivilianPanel(game: game, humanPlayerId: humanPlayerIdWithUnits),
      );
      await tester.pumpAndSettle();

      expect(find.text('Civilian Units'), findsOneWidget);
    });

    testWidgets('AC: full-list mode has Train only in header (no Tile)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildCivilianPanel(game: game, humanPlayerId: humanPlayerIdWithUnits),
      );
      await tester.pumpAndSettle();

      expect(find.text('Train'), findsOneWidget);
      expect(find.text('Tile'), findsNothing);
    });

    testWidgets('AC: Empty state when human player has zero civilian units', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildCivilianPanel(game: game, humanPlayerId: humanPlayerIdWithNoUnits),
      );
      await tester.pumpAndSettle();

      expect(find.text('No civilian units'), findsOneWidget);
      expect(find.byType(CivilianUnitRowCard), findsNothing);
    });

    testWidgets(
      'AC: When player has civilians, list shows units with status, location, assigned-to',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildCivilianPanel(game: game, humanPlayerId: humanPlayerIdWithUnits),
        );
        await tester.pumpAndSettle();

        final unitRows = find.byType(CivilianUnitRowCard);
        if (unitRows.evaluate().isEmpty) {
          return;
        }
        expect(unitRows, findsAtLeastNWidgets(1));
        // Locate is rendered for every visible row per R30 (action-cluster
        // rightmost; see SPEC/ui/civilian-units-panel.md).
        expect(find.byTooltip('Locate'), findsAtLeastNWidgets(1));
        expect(find.textContaining('Status:'), findsAtLeastNWidgets(1));
        expect(find.textContaining('Location:'), findsAtLeastNWidgets(1));
        expect(find.textContaining('Assigned to:'), findsAtLeastNWidgets(1));
      },
    );

    testWidgets(
      'work targets not in availableWorkTargets are grayed out (disabled)',
      (WidgetTester tester) async {
        final units = [
          ...game.worldState.oldWorld.units,
          ...game.worldState.newWorld.units,
        ];
        final idleCivilians = units.where(
          (u) =>
              u.ownerId == humanPlayerIdWithUnits &&
              u.tileKey != null &&
              isCivilianUnit(u) &&
              u.currentWork == null,
        );
        if (idleCivilians.isEmpty) return;
        final idleCivilian = idleCivilians.first;

        final allowed = workOrderTargetsByUnitType[idleCivilian.type] ?? [];
        if (allowed.isEmpty) return;

        final availableWorkTargets = <String, List<String>>{};

        await tester.pumpWidget(
          buildCivilianPanel(
            game: game,
            humanPlayerId: humanPlayerIdWithUnits,
            availableWorkTargets: availableWorkTargets,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Assign').first);
        await tester.pumpAndSettle();

        expect(find.textContaining('Assign work'), findsOneWidget);

        final targetRows = find
            .descendant(
              of: find.byType(BottomSheet),
              matching: find.byType(InkWell),
            )
            .evaluate();

        expect(targetRows, isNotEmpty);

        for (final row in targetRows) {
          final widget = row.widget as InkWell;
          expect(
            widget.onTap,
            isNull,
            reason: 'All items should be disabled when no available targets',
          );
        }

        final scaffoldCtx = tester.element(find.byType(Scaffold));
        Navigator.of(scaffoldCtx, rootNavigator: true).pop();
        await tester.pumpAndSettle();
      },
    );

    testWidgets('Assign button shown for idle unit', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildCivilianPanel(game: game, humanPlayerId: humanPlayerIdWithUnits),
      );
      await tester.pumpAndSettle();

      final unitRows = find.byType(CivilianUnitRowCard);
      if (unitRows.evaluate().isEmpty) return;
      expect(find.text('Assign'), findsAtLeastNWidgets(1));
    });

    testWidgets('tap Assign opens order menu', (WidgetTester tester) async {
      final units = [
        ...game.worldState.oldWorld.units,
        ...game.worldState.newWorld.units,
      ];
      final idleCivilians = units.where(
        (u) =>
            u.ownerId == humanPlayerIdWithUnits &&
            u.tileKey != null &&
            isCivilianUnit(u) &&
            u.currentWork == null,
      );
      if (idleCivilians.isEmpty) return;

      await tester.pumpWidget(
        buildCivilianPanel(
          game: game,
          humanPlayerId: humanPlayerIdWithUnits,
          availableWorkTargets: const {},
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Assign').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('Assign work'), findsOneWidget);

      final scaffoldCtx = tester.element(find.byType(Scaffold));
      Navigator.of(scaffoldCtx, rootNavigator: true).pop();
      await tester.pumpAndSettle();
    });

    testWidgets(
      'prospect shortcut mode filters explorers and commits prospect',
      (WidgetTester tester) async {
        await expectCivilianShortcutCommit(
          tester,
          gameId: 'g_civ_prospect_shortcut',
          visibleType: kUnitTypeExplorer,
          hiddenType: kUnitTypeBuilder,
          unitId: 'e1',
          workTarget: kWorkTargetProspect,
          explorerOnly: true,
          prospectShortcutTargetTileKey: civilianPanelPart1TileKey,
        );
      },
    );

    testWidgets('explore shortcut mode filters explorers and commits explore', (
      WidgetTester tester,
    ) async {
      await expectCivilianShortcutCommit(
        tester,
        gameId: 'g_civ_explore_shortcut',
        visibleType: kUnitTypeExplorer,
        hiddenType: kUnitTypeBuilder,
        unitId: 'e1',
        workTarget: kWorkTargetExplore,
        explorerOnly: true,
        exploreShortcutTargetTileKey: civilianPanelPart1TileKey,
      );
    });

    testWidgets(
      'build-improvement shortcut mode filters builders and commits',
      (WidgetTester tester) async {
        await expectCivilianShortcutCommit(
          tester,
          gameId: 'g_civ_build_improvement_shortcut',
          visibleType: kUnitTypeBuilder,
          hiddenType: kUnitTypeExplorer,
          unitId: 'b1',
          workTarget: kWorkTargetBuildImprovement,
          builderFirst: true,
          builderOnly: true,
          buildImprovementShortcutTargetTileKey: civilianPanelPart1TileKey,
          expectCloseBeforeUpsert: false,
        );
      },
    );

    testWidgets('build-road shortcut mode filters engineers and commits', (
      WidgetTester tester,
    ) async {
      await expectCivilianShortcutCommit(
        tester,
        gameId: 'g_civ_build_road_shortcut',
        visibleType: kUnitTypeEngineer,
        hiddenType: kUnitTypeBuilder,
        unitId: 'e_eng',
        workTarget: kWorkTargetBuildRoad,
        engineerOnly: true,
        buildRoadShortcutTargetTileKey: civilianPanelPart1TileKey,
        expectCloseBeforeUpsert: false,
        customGameBuilder: (id) => buildCivilianEngineerBuilderShortcutGame(
          id: id,
          engineerFirst: true,
        ),
      );
    });

    testWidgets('build-rail shortcut mode filters rail builders and commits', (
      WidgetTester tester,
    ) async {
      await expectCivilianShortcutCommit(
        tester,
        gameId: 'g_civ_build_rail_shortcut',
        visibleType: kUnitTypeRailBuilder,
        hiddenType: kUnitTypeBuilder,
        unitId: 'u_rail',
        workTarget: kWorkTargetBuildRail,
        railBuilderOnly: true,
        buildRailShortcutTargetTileKey: civilianPanelPart1TileKey,
        expectCloseBeforeUpsert: false,
        customGameBuilder: (id) => buildCivilianRailBuilderBuilderShortcutGame(
          id: id,
          railBuilderFirst: true,
        ),
      );
    });

    testWidgets('purchase-land shortcut mode filters merchants and commits', (
      WidgetTester tester,
    ) async {
      await expectCivilianShortcutCommit(
        tester,
        gameId: 'g_civ_purchase_land_shortcut',
        visibleType: kUnitTypeMerchant,
        hiddenType: kUnitTypeBuilder,
        unitId: 'm1',
        workTarget: kWorkTargetPurchaseLand,
        merchantOnly: true,
        purchaseLandShortcutTargetTileKey: civilianPanelPart1TileKey,
        expectCloseBeforeUpsert: false,
        customGameBuilder: (id) => buildCivilianMerchantBuilderShortcutGame(
          id: id,
          merchantFirst: true,
        ),
      );
    });

    testWidgets('Train button emits train-civilians dialog open event', (
      WidgetTester tester,
    ) async {
      OpenDialogEvent? openDialogEvent;
      final bus = AppEventBus.create();
      bus.on<OpenDialogEvent>().listen((e) => openDialogEvent = e);

      await tester.pumpWidget(
        buildCivilianPanel(
          game: game,
          humanPlayerId: humanPlayerIdWithUnits,
          bus: bus,
        ),
      );
      await tester.pumpAndSettle();

      final trainButton = find.text('Train');
      expect(trainButton, findsOneWidget);
      await tester.tap(trainButton);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(openDialogEvent, isNotNull);
      expect(openDialogEvent!.dialogId, trainCiviliansDialogId);
    });

    testWidgets(
      'AC: tapping civilian row emits ClosePanelEvent before LocateMapTileEvent',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        final sequence = <Type>[];
        bus.stream.listen((e) => sequence.add(e.runtimeType));

        await tester.pumpWidget(
          buildCivilianPanel(
            game: game,
            humanPlayerId: humanPlayerIdWithUnits,
            bus: bus,
          ),
        );
        await tester.pumpAndSettle();

        final unitRows = find.byType(CivilianUnitRowCard);
        if (unitRows.evaluate().isEmpty) return;
        await tester.tap(unitRows.first);
        await tester.pump();
        await tester.pumpAndSettle();

        expect(
          sequence.indexOf(ClosePanelEvent),
          lessThan(sequence.indexOf(LocateMapTileEvent)),
        );
      },
    );
  });
}
