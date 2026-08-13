// Tests for CivilianUnitsPanel. SPEC/ui/civilian-units-panel.md.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/civilian_units_panel.dart';
import 'package:colonizethis_app/widgets/resource_icon.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/civilian_units_sort.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_panel_shell.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show
        kWorkTargetBuildFort,
        kWorkTargetBuildImprovement,
        kWorkTargetBuildPort,
        kWorkTargetBuildRail,
        kWorkTargetBuildRoad,
        kWorkTargetCounterSpy,
        kWorkTargetExplore,
        kWorkTargetProspect,
        kWorkTargetPurchaseLand,
        kWorkTargetUpgradeTown;

import 'civilian_units_panel_part3_pump_support.dart';
import 'civilian_units_panel_test_support.dart';

void main() {
  suppressLogsForTests();

  late Game game;
  late String humanPlayerIdWithUnits;

  setUpAll(() {
    game = buildCivilianPanelTestGame();
    humanPlayerIdWithUnits = game.players.first.id;
  });

  group('CivilianUnitsPanel', () {
    testWidgets(
      'AC: pending build_improvement shows ResourceIcons and omits (pending)',
      (WidgetTester tester) async {
        await pumpCivilianPanelPendingUnit(
          tester,
          gameId: 'g_civ_pending_build',
          unitId: 'b1',
          unitType: kUnitTypeBuilder,
          workTarget: kWorkTargetBuildImprovement,
        );

        expect(find.textContaining('Assigned to:'), findsOneWidget);
        expect(find.textContaining('(pending)'), findsNothing);
        expect(civilianPanelResourceIcon('lumber'), findsOneWidget);
        expect(civilianPanelResourceIcon('castIron'), findsOneWidget);
      },
    );

    testWidgets(
      'AC #4262: second pending build_improvement shows muted shortfall line',
      (WidgetTester tester) async {
        const tileA = 'oldWorld|p1|0|0';
        const tileB = 'oldWorld|p1|1|0';
        await tester.pumpWidget(
          buildCivilianPanel(
            game: buildCivilianDualBuilderLowStockGame(
              id: 'g_civ_dual_shortfall',
            ),
            humanPlayerId: civilianPanelPart3HumanId,
            currentOrders: civilianPendingWorkOrders(
              humanId: civilianPanelPart3HumanId,
              workOrders: [
                WorkOrder(
                  unitId: 'b1',
                  target: kWorkTargetBuildImprovement,
                  targetTileKey: tileA,
                ),
                WorkOrder(
                  unitId: 'b2',
                  target: kWorkTargetBuildImprovement,
                  targetTileKey: tileB,
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Assigned to:'), findsNWidgets(2));
        expect(civilianPanelResourceIcon('lumber'), findsNWidgets(2));
        expect(civilianPanelResourceIcon('castIron'), findsNWidgets(2));
        expect(find.textContaining('Short:'), findsOneWidget);
      },
    );

    testWidgets(
      'AC: pending explore shows inline turns and no ResourceIcon strip',
      (WidgetTester tester) async {
        await pumpCivilianPanelPendingUnit(
          tester,
          gameId: 'g_civ_pending_explore',
          unitId: 'e1',
          unitType: kUnitTypeExplorer,
          workTarget: kWorkTargetExplore,
        );

        expect(find.textContaining('(pending)'), findsNothing);
        expect(find.textContaining('Assigned to: Explore'), findsOneWidget);
        expect(find.textContaining('turn'), findsAtLeastNWidgets(1));
        expect(find.byType(ResourceIcon), findsNothing);
      },
    );

    testWidgets(
      'AC: pending purchase_land shows treasury chip not ResourceIcon',
      (WidgetTester tester) async {
        await pumpCivilianPanelPendingUnit(
          tester,
          gameId: 'g_civ_pending_land',
          unitId: 'm1',
          unitType: kUnitTypeMerchant,
          workTarget: kWorkTargetPurchaseLand,
          resourceByTileKey: {civilianPanelPart3TileKey: 'grain'},
        );

        expect(find.textContaining('Treasury:'), findsOneWidget);
        expect(find.textContaining('(pending)'), findsNothing);
        expect(find.byType(ResourceIcon), findsNothing);
      },
    );

    testWidgets(
      'AC: pending purchase_land without tile resource still shows inline turns',
      (WidgetTester tester) async {
        await pumpCivilianPanelPendingUnit(
          tester,
          gameId: 'g_civ_pending_land_nores',
          unitId: 'm1',
          unitType: kUnitTypeMerchant,
          workTarget: kWorkTargetPurchaseLand,
        );

        expect(find.textContaining('(pending)'), findsNothing);
        expect(
          find.textContaining('Assigned to: Purchase land'),
          findsOneWidget,
        );
        expect(find.textContaining('turn'), findsAtLeastNWidgets(1));
        expect(find.textContaining('Treasury:'), findsNothing);
      },
    );

    testWidgets(
      'AC: pending rows show faithful remaining-turn number for each work target',
      (WidgetTester tester) async {
        const targetTileKey = 'oldWorld|p1|1|0';
        final cases = <({String unitType, String target, int turns})>[
          (unitType: kUnitTypeExplorer, target: kWorkTargetExplore, turns: 3),
          (unitType: kUnitTypeExplorer, target: kWorkTargetProspect, turns: 1),
          (
            unitType: kUnitTypeBuilder,
            target: kWorkTargetBuildImprovement,
            turns: 1,
          ),
          (
            unitType: kUnitTypeBuilder,
            target: kWorkTargetUpgradeTown,
            turns: 1,
          ),
          (unitType: kUnitTypeEngineer, target: kWorkTargetBuildRoad, turns: 1),
          (unitType: kUnitTypeEngineer, target: kWorkTargetBuildPort, turns: 1),
          (unitType: kUnitTypeEngineer, target: kWorkTargetBuildFort, turns: 3),
          (
            unitType: kUnitTypeRailBuilder,
            target: kWorkTargetBuildRail,
            turns: 1,
          ),
          (unitType: kUnitTypeSpy, target: kWorkTargetCounterSpy, turns: 1),
          (
            unitType: kUnitTypeMerchant,
            target: kWorkTargetPurchaseLand,
            turns: 1,
          ),
        ];

        for (var i = 0; i < cases.length; i++) {
          final c = cases[i];
          final unitId = 'u_$i';
          await tester.pumpWidget(
            buildCivilianPanel(
              game: buildCivilianOwUnitsGame(
                id: 'g_civ_pending_turns_${c.target}_$i',
                humanId: civilianPanelPart3HumanId,
                fortLevel: 2,
                resourceByTileKey: const {targetTileKey: 'grain'},
                tileKeysByRegionAndProvince: const {
                  'oldWorld': {
                    'oldWorld|p1': [civilianPanelPart3TileKey, targetTileKey],
                  },
                },
                units: [
                  civilianIdleUnit(
                    id: unitId,
                    type: c.unitType,
                    ownerId: civilianPanelPart3HumanId,
                    provinceId: 'oldWorld|p1',
                    tileKey: civilianPanelPart3TileKey,
                  ),
                ],
              ),
              humanPlayerId: civilianPanelPart3HumanId,
              currentOrders: civilianSinglePendingWorkOrder(
                humanId: civilianPanelPart3HumanId,
                unitId: unitId,
                target: c.target,
                targetTileKey: targetTileKey,
              ),
            ),
          );
          await tester.pumpAndSettle();

          final lineFinder = find.textContaining('Assigned to:');
          expect(
            lineFinder,
            findsOneWidget,
            reason: 'Expected one Assigned to line for target ${c.target}',
          );
          final line = tester.widget<Text>(lineFinder).data ?? '';
          final singular = '${c.turns} turn';
          final plural = '${c.turns} turns';
          expect(
            line.contains(singular) || line.contains(plural),
            isTrue,
            reason:
                'Expected target ${c.target} to show $singular/$plural, got: $line',
          );
          expect(
            line.contains('# turn'),
            isFalse,
            reason: 'Target ${c.target} should not render placeholder text',
          );
        }
      },
    );

    testWidgets('AC: pending build_rail shows steel and lumber icons', (
      WidgetTester tester,
    ) async {
      await pumpCivilianPanelPendingUnit(
        tester,
        gameId: 'g_civ_pending_rail',
        unitId: 'r1',
        unitType: kUnitTypeRailBuilder,
        workTarget: kWorkTargetBuildRail,
      );

      expect(find.textContaining('(pending)'), findsNothing);
      expect(civilianPanelResourceIcon('lumber'), findsOneWidget);
      expect(civilianPanelResourceIcon('steel'), findsOneWidget);
    });

    testWidgets('AC: in-progress work row has no pending cost ResourceIcons', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildCivilianPanel(
          game: buildCivilianWorkingBuilderGame(
            humanId: civilianPanelPart3HumanId,
            tileKey: civilianPanelPart3TileKey,
          ),
          humanPlayerId: civilianPanelPart3HumanId,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('2/5'), findsOneWidget);
      expect(find.byType(ResourceIcon), findsNothing);
    });

    testWidgets(
      'tile-scoped mode: Tile then Train in header; no Tile on unit rows',
      (WidgetTester tester) async {
        final units = [
          ...game.worldState.oldWorld.units,
          ...game.worldState.newWorld.units,
        ];
        final civilianWithTile = units.where(
          (u) =>
              u.ownerId == humanPlayerIdWithUnits &&
              u.tileKey != null &&
              isCivilianUnit(u),
        );
        if (civilianWithTile.isEmpty) return;
        final scopedTileKey = civilianWithTile.first.tileKey!;
        final scopedUnitId = civilianWithTile.first.id;
        final bus = AppEventBus.create();

        await pumpCivilianPanelTileScoped(
          tester,
          game: game,
          humanPlayerId: humanPlayerIdWithUnits,
          bus: bus,
          tileScopeTileKey: scopedTileKey,
          initialSelectedUnitId: scopedUnitId,
        );

        expect(find.text('Civilian Units (Tile)'), findsOneWidget);
        expect(find.text('Tile'), findsOneWidget);

        // Header actions are compact primary pills (CtActionTextButton,
        // not CtNinePatchButton) per #3514 owner decision #5.
        final shellButtons = find.descendant(
          of: find.byType(UnitsPanelShell),
          matching: find.byType(CtActionTextButton),
        );
        expect(
          find.descendant(of: shellButtons.at(0), matching: find.text('Tile')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: shellButtons.at(1), matching: find.text('Train')),
          findsOneWidget,
        );

        expect(
          find.descendant(
            of: find.byType(CivilianUnitRowCard),
            matching: find.text('Tile'),
          ),
          findsNothing,
        );
      },
    );

    testWidgets('tile-scoped empty list: header Tile is disabled', (
      WidgetTester tester,
    ) async {
      final bus = AppEventBus.create();
      await pumpCivilianPanelTileScoped(
        tester,
        game: game,
        humanPlayerId: humanPlayerIdWithUnits,
        bus: bus,
        tileScopeTileKey: 'oldWorld|no_civilian_units_on_this_province|0|0',
      );

      expect(find.text('Civilian Units (Tile)'), findsOneWidget);
      expect(find.text('No civilian units'), findsOneWidget);
      final tileButton = find.ancestor(
        of: find.text('Tile'),
        matching: find.byType(CtActionTextButton),
      );
      expect(tester.widget<CtActionTextButton>(tileButton).enabled, isFalse);
    });

    testWidgets(
      'full-list header Train renders as a primary CtActionTextButton pill '
      '(no CtNinePatchButton header chrome) — #3514 owner decision #5',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        await pumpCivilianPanelTileScoped(
          tester,
          game: game,
          humanPlayerId: humanPlayerIdWithUnits,
          bus: bus,
          settle: false,
        );

        // Scope to the header Train pill by label: row-action Assign pills are
        // now also CtActionTextButton (#3514 row-action migration), so the
        // header control is resolved via its 'Train' label rather than the
        // first CtActionTextButton in the shell.
        final trainLabel = find.descendant(
          of: find.byType(UnitsPanelShell),
          matching: find.text('Train'),
        );
        expect(trainLabel, findsOneWidget);
        final trainButtonFinder = find.ancestor(
          of: trainLabel,
          matching: find.byType(CtActionTextButton),
        );
        expect(trainButtonFinder, findsOneWidget);
        final trainButton = tester.widget<CtActionTextButton>(
          trainButtonFinder,
        );
        expect(trainButton.primary, isTrue);
        expect(trainButton.label, 'Train');
      },
    );

    testWidgets(
      'tile-scoped header Tile emits OpenMapTileDetailEvent for rendered tile',
      (WidgetTester tester) async {
        final units = [
          ...game.worldState.oldWorld.units,
          ...game.worldState.newWorld.units,
        ];
        final civilian = units.where(
          (u) =>
              u.ownerId == humanPlayerIdWithUnits &&
              u.tileKey != null &&
              isCivilianUnit(u),
        );
        if (civilian.isEmpty) return;
        final u = civilian.first;
        final rendered = u.assignedTileKey?.isNotEmpty == true
            ? u.assignedTileKey!
            : u.tileKey!;

        final bus = AppEventBus.create();
        OpenMapTileDetailEvent? captured;
        final sub = bus.on<OpenMapTileDetailEvent>().listen((e) {
          captured = e;
        });
        addTearDown(sub.cancel);

        await pumpCivilianPanelTileScoped(
          tester,
          game: game,
          humanPlayerId: humanPlayerIdWithUnits,
          bus: bus,
          tileScopeTileKey: rendered,
          initialSelectedUnitId: u.id,
          settle: false,
        );

        captured = null;
        await tester.tap(find.text('Tile'));
        await tester.pump();
        await tester.pump();
        expect(captured, isNotNull);
        expect(captured?.tileKey, rendered);
      },
    );
  });
}
