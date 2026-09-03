// Tests for the tech-gated cotton-weaving recipe lock in the Production
// Allocation subpanel. SPEC/ui/production-panel.md § Tech-gated recipe rows.
// Refs #3470 (Slice C UI: fabric_from_cotton visible-but-grayed `(locked)`).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/production/production_allocation_row.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'production_panel_test_support.dart';
import 'widget_test_pumps.dart';

void main() {
  suppressLogsForTests();

  const cottonRowKey = ValueKey<String>(
    'production_alloc_row_fabric_from_cotton',
  );
  const woolRowKey = ValueKey<String>('production_alloc_row_fabric_from_wool');

  // Full stockpile/workers but `cotton_weaving` NOT unlocked (techUnlocked is
  // null on the fixture) → fabric_from_cotton is locked.
  Player lockedPlayer() => productionPanelTestFullPlayer();

  // Same abundant fixture with `cotton_weaving` unlocked → recipe available.
  Player unlockedPlayer() => productionPanelTestFullPlayer().copyWith(
    techUnlocked: const <String, bool>{kTechIdCottonWeaving: true},
  );

  Finder lockedOpacityIn(Key rowKey) => find.descendant(
    of: find.byKey(rowKey),
    matching: find.byWidgetPredicate(
      (Widget w) =>
          w is Opacity && w.opacity == kProductionRecipeLockedOpacity,
    ),
  );

  group('Cotton-weaving recipe lock (Refs #3470 Slice C UI)', () {
    testWidgets(
      'locked recipe stays visible and shows the localized (locked) marker',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildProductionPanel(player: lockedPlayer(), height: 600),
        );
        await pumpSettleCapped(tester);
        final l10n = lookupAppLocalizations(const Locale('en'));

        // Row is still mounted (not hidden / filtered out).
        expect(find.byKey(cottonRowKey), findsOneWidget);
        final row = tester.widget<ProductionAllocationRow>(
          find.byKey(cottonRowKey),
        );
        expect(row.locked, isTrue);

        // The (locked) marker is rendered inside the locked row via l10n.
        expect(
          find.descendant(
            of: find.byKey(cottonRowKey),
            matching: find.text(l10n.production_recipeLocked),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'locked recipe omits right-aligned affordance copy (Refs #4717)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildProductionPanel(player: lockedPlayer(), height: 600),
        );
        await pumpSettleCapped(tester);
        final l10n = lookupAppLocalizations(const Locale('en'));

        expect(
          find.descendant(
            of: find.byKey(cottonRowKey),
            matching: find.textContaining('Up to'),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: find.byKey(cottonRowKey),
            matching: find.textContaining('Cannot run'),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: find.byKey(cottonRowKey),
            matching: find.byWidgetPredicate(
              (Widget w) =>
                  w is Tooltip &&
                  w.message == l10n.production_recipeAffordanceTooltip,
            ),
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'locked recipe slider sub-row is wrapped in IgnorePointer + Opacity(0.4)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildProductionPanel(player: lockedPlayer(), height: 600),
        );
        await pumpSettleCapped(tester);

        final opacity = lockedOpacityIn(cottonRowKey);
        expect(opacity, findsOneWidget);
        // The locked Opacity must sit under an IgnorePointer so the slider
        // and step controls accept no pointer input.
        expect(
          find.ancestor(
            of: opacity,
            matching: find.byType(IgnorePointer),
          ),
          findsAtLeastNWidgets(1),
        );
      },
    );

    testWidgets(
      'unlocked recipe renders normally: no (locked) marker, no locked opacity',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildProductionPanel(player: unlockedPlayer(), height: 600),
        );
        await pumpSettleCapped(tester);
        final l10n = lookupAppLocalizations(const Locale('en'));

        expect(find.byKey(cottonRowKey), findsOneWidget);
        final row = tester.widget<ProductionAllocationRow>(
          find.byKey(cottonRowKey),
        );
        expect(row.locked, isFalse);

        expect(
          find.descendant(
            of: find.byKey(cottonRowKey),
            matching: find.text(l10n.production_recipeLocked),
          ),
          findsNothing,
        );
        expect(lockedOpacityIn(cottonRowKey), findsNothing);
      },
    );

    testWidgets(
      'negative: fabric_from_wool is never locked (no requiredTechId)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildProductionPanel(player: lockedPlayer(), height: 600),
        );
        await pumpSettleCapped(tester);
        final l10n = lookupAppLocalizations(const Locale('en'));

        final woolRow = tester.widget<ProductionAllocationRow>(
          find.byKey(woolRowKey),
        );
        expect(woolRow.locked, isFalse);
        expect(
          find.descendant(
            of: find.byKey(woolRowKey),
            matching: find.text(l10n.production_recipeLocked),
          ),
          findsNothing,
        );
        expect(lockedOpacityIn(woolRowKey), findsNothing);
      },
    );
  });
}
