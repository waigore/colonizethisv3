// Tests for CivilianUnitsPanel. SPEC/ui/civilian-units-panel.md.
// Concern split under repo.app_test_file_size (Refs #4013, #4352):
// pending-work icons, shortfall, and assigned-to copy.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/civilian_units_panel.dart';
import 'package:colonizethis_app/widgets/resource_icon.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/civilian_units_sort.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_panel_shell.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show
        kWorkTargetBuildImprovement,
        kWorkTargetBuildRail,
        kWorkTargetExplore,
        kWorkTargetPurchaseLand;

import 'civilian_units_panel_pending_support.dart';
import 'civilian_units_panel_pump_support.dart';
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
        await pumpCivilianDualBuilderShortfall(tester);

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
        for (var i = 0; i < civilianPanelPendingTurnCases.length; i++) {
          final c = civilianPanelPendingTurnCases[i];
          await expectCivilianPendingTurnLine(
            tester,
            index: i,
            unitType: c.unitType,
            target: c.target,
            turns: c.turns,
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
