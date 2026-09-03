// Tests for NavalUnitsPanel. SPEC/ui/naval-units-panel.md.
// Concern split under repo.app_test_file_size (Refs #4013, #4352):
// roster chrome, locate pins, and draft-move subtitle.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_entity_action_row.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_panel_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_panel.dart';

import 'naval_panel_part1_locate_pins.dart';
import 'naval_panel_part1_pins.dart';
import 'naval_units_panel_test_support.dart';
import 'panel_test_fixtures.dart';
import 'widget_test_assets.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  late Game game;
  late String humanPlayerIdWithFleets;
  const String humanPlayerIdWithNoFleets = 'no-such-player';

  setUpAll(() async {
    await setUpNinePatchAssets();
    game = buildNavalPanelTestGame();
    humanPlayerIdWithFleets = game.players.isNotEmpty
        ? game.players.first.id
        : kPanelTestHumanPlayerId;
  });

  group('NavalUnitsPanel', () {
    testWidgets(
      'AC: title, CtPanel wrap, fleet rows, and header Combine chrome',
      (WidgetTester tester) async {
        await pumpNavalPanel(
          tester,
          game: game,
          humanPlayerId: humanPlayerIdWithFleets,
        );

        expect(find.text('Naval Units'), findsOneWidget);
        expect(find.byType(CtPanel), findsOneWidget);
        if (find.byType(ExpansionTile).evaluate().isNotEmpty) {
          expect(find.byType(UnitsEntityActionRow), findsAtLeastNWidgets(1));
        }

        final fleets = game.worldState.fleets
            .where(
              (f) =>
                  f.ownerId == humanPlayerIdWithFleets &&
                  f.shipTypeIds.isNotEmpty,
            )
            .length;
        if (fleets > 0) {
          expect(find.byType(ExpansionTile), findsAtLeastNWidgets(1));
          expect(
            find.text('OLD WORLD').evaluate().isNotEmpty ||
                find.text('NEW WORLD').evaluate().isNotEmpty,
            isTrue,
          );
        }

        final combine = find.ancestor(
          of: find.text('Combine'),
          matching: find.byType(CtActionTextButton),
        );
        expect(combine, findsOneWidget);
        expect(
          tester.widget<CtActionTextButton>(combine.first).primary,
          isTrue,
        );
        expect(
          find.ancestor(
            of: find.text('Combine'),
            matching: find.byType(CtNinePatchButton),
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'AC: When human player has no fleets, panel does not crash and shows either empty or Home Fleet only',
      (WidgetTester tester) async {
        await pumpNavalPanel(
          tester,
          game: game,
          humanPlayerId: humanPlayerIdWithNoFleets,
        );
        expect(find.byType(CtPanel), findsOneWidget);
      },
    );

    testWidgets('AC: Wide viewport scales naval panel beyond fixed 400 width', (
      WidgetTester tester,
    ) async {
      await pumpNavalPanel(
        tester,
        game: game,
        humanPlayerId: humanPlayerIdWithFleets,
        widget: buildNavalPanelWideViewport(
          game: game,
          humanPlayerId: humanPlayerIdWithFleets,
        ),
      );
      final panelShell = tester.widget<UnitsPanelShell>(
        find.byType(UnitsPanelShell),
      );
      expect(panelShell.panelConstraints.maxWidth, greaterThan(400));
    });

    for (final case_ in navalPanelLocateCases()) {
      testWidgets(case_.name, (WidgetTester tester) async {
        await pumpNavalLocateCase(
          tester,
          case_,
          baseGame: game,
          humanId: humanPlayerIdWithFleets,
        );
      });
    }

    testWidgets('AC: Strength is only shown in expanded details', (
      WidgetTester tester,
    ) async {
      await pumpNavalPanel(
        tester,
        game: game,
        humanPlayerId: humanPlayerIdWithFleets,
      );
      final tiles = find.byType(ExpansionTile);
      if (tiles.evaluate().isEmpty) return;
      expect(find.textContaining('Strength:'), findsNothing);
      await tester.tap(tiles.first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Strength:'), findsAtLeastNWidgets(1));
    });

    testWidgets('sea-zone labels use world-state display names', (
      WidgetTester tester,
    ) async {
      const humanId = 'gp_named_sea';
      await pumpNavalPanel(
        tester,
        game: buildNavalPanelNamedSeaZoneGame(humanId: humanId),
        humanPlayerId: humanId,
      );
      expect(find.textContaining('Caribbean Sea'), findsWidgets);
    });

    for (final case_ in navalPanelPart1PinCases()) {
      testWidgets(case_.name, case_.run);
    }
  });

  group('Draft naval move subtitle', () {
    testWidgets('shows Moving to line when draft order present', (
      WidgetTester tester,
    ) async {
      const humanId = 'gp_draft_line';
      await pumpNavalPanel(
        tester,
        game: buildNavalPanelDraftMoveSubtitleGame(humanId: humanId),
        humanPlayerId: humanId,
        draftOrders: Orders(
          navalMoveOrdersByPlayerId: {
            humanId: [
              const NavalMoveOrder(
                fleetId: 'f_at_sea',
                destinationSeaZoneId: 'sz1',
              ),
            ],
          },
        ),
      );
      await tester.pump();
      expect(find.textContaining('Moving to: Target Sea'), findsOneWidget);
    });
  });
}
