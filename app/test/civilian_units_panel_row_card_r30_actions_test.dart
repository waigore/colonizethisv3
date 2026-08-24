// Mockup-fidelity tests for the civilian units panel row card chrome
// (R30 / Refs #2866 S9). Pins the SPEC/ui/civilian-units-panel.md
// "Row card chrome" + locate-button placement contracts:
//
//   * Each civilian row is a bordered `CivilianUnitRowCard` with a
//     vertical `bgDeep` -> `surface` gradient and a 1 dp border that
//     defaults to `EditorialMonoclePalette.border` and shifts to
//     `EditorialMonoclePalette.accentDim` when the row is the tile-scope
//     selection.
//   * The "Locate" control lives at the right end of the action cluster
//     as an icon-only `CtNinePatchButton` with the `Icons.my_location`
//     icon, not in the title row.
//   * Locate is exposed for **every** visible row, including non-selected
//     rows in tile-scope mode where Assign / Cancel are hidden.

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app/widgets/ct_circular_locate_button.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/civilian_units_panel.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'civilian_units_panel_row_card_r30_support.dart';
import 'civilian_units_panel_test_support.dart';

void main() {
  suppressLogsForTests();

  group('CivilianUnitsPanel row card chrome (R30 / Refs #2866 S9)', () {
    testWidgets(
      'AC (#3514): Assign renders as a neutral CtActionTextButton pill with '
      'icon + label (mockup `.u-actions button`)',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        await tester.pumpWidget(
          wrapCivilianRowCardHost(
            CivilianUnitsPanel(
              game: civilianRowCardMiniGame(),
              humanPlayerId: kCivilianRowCardHumanId,
              currentOrders: const Orders(),
              bus: bus,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final card = find.byType(CivilianUnitRowCard);
        expect(card, findsOneWidget);

        final assignLabel = find.descendant(
          of: card,
          matching: find.text('Assign'),
        );
        expect(assignLabel, findsOneWidget);
        final assignPill = find.ancestor(
          of: assignLabel,
          matching: find.byType(CtActionTextButton),
        );
        expect(assignPill, findsOneWidget);
        final assignButton = tester.widget<CtActionTextButton>(assignPill);
        // Row-action pills are the neutral (non-primary) variant; primary is
        // reserved for header actions (Train) per #3514 owner decision #5.
        expect(assignButton.primary, isFalse);
        expect(assignButton.label, 'Assign');
        expect(assignButton.icon, Icons.playlist_add);
        expect(assignButton.onPressed, isNotNull);
        // Icon + label per owner decision #7 (Assign keeps its icon).
        expect(
          find.descendant(
            of: assignPill,
            matching: find.byIcon(Icons.playlist_add),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('AC (#3514): read-only panel renders no row-action pills', (
      WidgetTester tester,
    ) async {
      final bus = AppEventBus.create();
      await tester.pumpWidget(
        wrapCivilianRowCardHost(
          CivilianUnitsPanel(
            game: civilianRowCardMiniGame(),
            humanPlayerId: kCivilianRowCardHumanId,
            currentOrders: const Orders(),
            bus: bus,
            readOnly: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final card = find.byType(CivilianUnitRowCard);
      expect(card, findsOneWidget);
      expect(
        find.descendant(of: card, matching: find.byType(CtActionTextButton)),
        findsNothing,
      );
      expect(
        find.descendant(
          of: card,
          matching: find.byType(CtCircularLocateButton),
        ),
        findsNothing,
      );
      expect(
        find.descendant(of: card, matching: find.text('Assign')),
        findsNothing,
      );
    });

    testWidgets(
      'AC: Locate stays visible on non-selected tile-scope rows even when '
      'Assign/Cancel are hidden',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        await tester.pumpWidget(
          wrapCivilianRowCardHost(
            CivilianUnitsPanel(
              game: civilianRowCardMiniGame(civilianCount: 2),
              humanPlayerId: kCivilianRowCardHumanId,
              currentOrders: const Orders(),
              bus: bus,
              tileScopeTileKey: kCivilianRowCardTileKey,
              initialSelectedUnitId: 'civ_0',
            ),
          ),
        );
        await tester.pumpAndSettle();

        final unselectedRow = find.byKey(
          const ValueKey('civilian-unit-card-civ_1'),
          skipOffstage: false,
        );
        expect(unselectedRow, findsOneWidget);

        final locateOnUnselected = find.descendant(
          of: unselectedRow,
          matching: find.byTooltip('Locate', skipOffstage: false),
        );
        expect(
          locateOnUnselected,
          findsOneWidget,
          reason:
              'Non-selected tile-scope rows must still expose Locate per '
              'SPEC/ui/civilian-units-panel.md § Per-unit row content.',
        );
      },
    );
  });
}
