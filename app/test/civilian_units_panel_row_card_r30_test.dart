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

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/core/services/app_event_handler_scope.dart';
import 'package:colonizethis_app/features/game/widgets/chrome/ct_action_text_button.dart';
import 'package:colonizethis_app/features/game/widgets/chrome/ct_circular_locate_button.dart';
import 'package:colonizethis_app/features/game/widgets/civilian_units_panel.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

int _argb(Color c) {
  final int a = (c.a * 255.0).round() & 0xFF;
  final int r = (c.r * 255.0).round() & 0xFF;
  final int g = (c.g * 255.0).round() & 0xFF;
  final int b = (c.b * 255.0).round() & 0xFF;
  return (a << 24) | (r << 16) | (g << 8) | b;
}

const _human = 'h1';
const _tileKey = 'oldWorld|p1|0|0';

Game _miniGame({int civilianCount = 1}) {
  return Game(
    id: 'g_civ_row_card_r30',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: const [
          Province(
            id: 'oldWorld|p1',
            regionId: 'oldWorld',
            displayName: 'Alpha',
          ),
        ],
        units: [
          for (int i = 0; i < civilianCount; i++)
            Unit(
              id: 'civ_$i',
              type: i == 0 ? kUnitTypeBuilder : kUnitTypeEngineer,
              ownerId: _human,
              locationProvinceId: 'oldWorld|p1',
              tileKey: _tileKey,
            ),
        ],
      ),
      newWorld: const RegionData(),
    ),
    players: const [Player(id: _human, displayName: 'Human', isHuman: true)],
  );
}

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [
      availableWorkTargetIdsForUnitProvider.overrideWith(
        (ref, _) => const <String>[],
      ),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

DecoratedBox _cardDecoratedBox(WidgetTester tester, Finder card) {
  final decoratedFinder = find.descendant(
    of: card,
    matching: find.byType(DecoratedBox),
  );
  expect(decoratedFinder, findsAtLeastNWidgets(1));
  return tester.widget<DecoratedBox>(decoratedFinder.first);
}

void main() {
  suppressLogsForTests();

  group('CivilianUnitsPanel row card chrome (R30 / Refs #2866 S9)', () {
    testWidgets(
      'AC: row paints vertical bgDeep -> surface gradient with default border',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        await tester.pumpWidget(
          _wrap(
            CivilianUnitsPanel(
              game: _miniGame(),
              humanPlayerId: _human,
              currentOrders: const Orders(),
              bus: bus,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final card = find.byType(CivilianUnitRowCard);
        expect(card, findsOneWidget);

        final decorated = _cardDecoratedBox(tester, card);
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
        expect(_argb(linear.colors[0]), _argb(EditorialMonoclePalette.bgDeep));
        expect(_argb(linear.colors[1]), _argb(EditorialMonoclePalette.surface));

        final border = decoration.border;
        expect(border, isA<Border>());
        final borderColor = (border! as Border).top.color;
        // Default (non-selected, non-hovered) state -> `border` token.
        expect(_argb(borderColor), _argb(EditorialMonoclePalette.border));
      },
    );

    testWidgets('AC: tile-scope selection shifts the row border to accentDim', (
      WidgetTester tester,
    ) async {
      final bus = AppEventBus.create();
      await tester.pumpWidget(
        _wrap(
          CivilianUnitsPanel(
            game: _miniGame(civilianCount: 2),
            humanPlayerId: _human,
            currentOrders: const Orders(),
            bus: bus,
            tileScopeTileKey: _tileKey,
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
          _cardDecoratedBox(tester, selectedRow).decoration as BoxDecoration;
      final unselectedDecoration =
          _cardDecoratedBox(tester, unselectedRow).decoration as BoxDecoration;

      final selectedBorder = (selectedDecoration.border! as Border).top.color;
      final unselectedBorder =
          (unselectedDecoration.border! as Border).top.color;

      expect(
        _argb(selectedBorder),
        _argb(EditorialMonoclePalette.accentDim),
        reason:
            'R30: selected tile-scope row paints `accentDim` border so '
            'selection reads against the default `border` token.',
      );
      expect(
        _argb(unselectedBorder),
        _argb(EditorialMonoclePalette.border),
        reason: 'Non-selected tile-scope row keeps default `border` token.',
      );
    });

    testWidgets(
      'AC: Locate is the right-most icon-only CtCircularLocateButton in the action cluster',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        await tester.pumpWidget(
          _wrap(
            CivilianUnitsPanel(
              game: _miniGame(),
              humanPlayerId: _human,
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

    testWidgets(
      'AC (#3514): Assign renders as a neutral CtActionTextButton pill with '
      'icon + label (mockup `.u-actions button`)',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        await tester.pumpWidget(
          _wrap(
            CivilianUnitsPanel(
              game: _miniGame(),
              humanPlayerId: _human,
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
        _wrap(
          CivilianUnitsPanel(
            game: _miniGame(),
            humanPlayerId: _human,
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
          _wrap(
            CivilianUnitsPanel(
              game: _miniGame(civilianCount: 2),
              humanPlayerId: _human,
              currentOrders: const Orders(),
              bus: bus,
              tileScopeTileKey: _tileKey,
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
