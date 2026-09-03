// Tests for CivilianUnitsPanel. SPEC/ui/civilian-units-panel.md.
// Concern split under repo.app_test_file_size (Refs #4013, #4352):
// pending-work icons, shortfall, and assigned-to copy.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/resource_icon.dart';
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
  });
}
