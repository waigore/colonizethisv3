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
      'AC: row paints vertical bgDeep -> surface gradient with default border',
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

        final decorated = civilianRowCardDecoratedBox(tester, card);
        final decoration = decorated.decoration as BoxDecoration;
        final gradient = decoration.gradient;
        expect(
          gradient,
          isA<LinearGradient>(),
          reason: 'R30: card uses vertical LinearGradient',
        );
        final linear = gradient as LinearGradient;
        expect(linear.begin, Alignment.topCenter);
        expect(linear.end, Alignment.bottomCenter);
        expect(linear.colors.length, 2);
        expect(
          civilianRowCardArgb(linear.colors[0]),
          civilianRowCardArgb(EditorialMonoclePalette.bgDeep),
        );
        expect(
          civilianRowCardArgb(linear.colors[1]),
          civilianRowCardArgb(EditorialMonoclePalette.surface),
        );

        final border = decoration.border;
        expect(border, isA<Border>());
        final borderColor = (border! as Border).top.color;
        // Default (non-selected, non-hovered) state -> `border` token.
        expect(
          civilianRowCardArgb(borderColor),
          civilianRowCardArgb(EditorialMonoclePalette.border),
        );
      },
    );

    testWidgets('AC: tile-scope selection shifts the row border to accentDim', (
      WidgetTester tester,
    ) async {
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

      final selectedRow = find.byKey(
        const ValueKey('civilian-unit-card-civ_0'),
        skipOffstage: false,
      );
      final unselectedRow = find.byKey(
        const ValueKey('civilian-unit-card-civ_1'),
        skipOffstage: false,
      );
      expect(selectedRow, findsOneWidget);
      expect(unselectedRow, findsOneWidget);

      final selectedDecoration =
          civilianRowCardDecoratedBox(tester, selectedRow).decoration
              as BoxDecoration;
      final unselectedDecoration =
          civilianRowCardDecoratedBox(tester, unselectedRow).decoration
              as BoxDecoration;

      final selectedBorder = (selectedDecoration.border! as Border).top.color;
      final unselectedBorder =
          (unselectedDecoration.border! as Border).top.color;

      expect(
        civilianRowCardArgb(selectedBorder),
        civilianRowCardArgb(EditorialMonoclePalette.accentDim),
        reason:
            'R30: selected tile-scope row paints `accentDim` border so '
            'selection reads against the default `border` token.',
      );
      expect(
        civilianRowCardArgb(unselectedBorder),
        civilianRowCardArgb(EditorialMonoclePalette.border),
        reason: 'Non-selected tile-scope row keeps default `border` token.',
      );
    });

    testWidgets(
      'AC: Locate is the right-most icon-only CtCircularLocateButton in the action cluster',
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

        // R30 (#3514): Locate is a circular CtCircularLocateButton (mockup
        // `.u-actions .locate-btn`) rendering the icon-only Icons.my_location
        // glyph — not a CtNinePatchButton or a title-row CtIconAction.
        final locateBtn = find.descendant(
          of: card,
          matching: find.byType(CtCircularLocateButton),
        );
        expect(locateBtn, findsOneWidget);
        final locateIcon = find.descendant(
          of: locateBtn,
          matching: find.byIcon(Icons.my_location),
        );
        expect(locateIcon, findsOneWidget);
        // Icon-only -> the locate button does NOT contain the localized
        // "Locate" Text label.
        expect(
          find.descendant(of: locateBtn, matching: find.text('Locate')),
          findsNothing,
        );
        // No CtNinePatchButton row-action chrome remains on the migrated card.
        expect(
          find.descendant(of: card, matching: find.byType(CtNinePatchButton)),
          findsNothing,
        );

        // The Locate button is rightmost: it is the last action pill in the
        // right-aligned cluster (mockup `.u-actions .locate-btn`). The cluster
        // renders Assign + the circular Locate in order, so the locate button
        // centre sits to the right of the Assign pill.
        final assignPill = find.descendant(
          of: card,
          matching: find.text('Assign'),
        );
        if (assignPill.evaluate().isNotEmpty) {
          final assignDx = tester.getCenter(assignPill.first).dx;
          final locateDx = tester.getCenter(locateBtn).dx;
          expect(
            locateDx,
            greaterThan(assignDx),
            reason: 'R30: Locate must be the right-most action in the cluster.',
          );
        }
      },
    );
  });
}
