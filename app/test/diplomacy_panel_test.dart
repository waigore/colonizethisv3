// DiplomacyPanel widget tests (merged part1+part2). SPEC/ui/diplomacy-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel_constants.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';

import 'diplomacy_panel_test_scenarios.dart';
import 'diplomacy_panel_test_support.dart';
import 'panel_test_fixtures.dart';
import 'diplomacy_panel_widget_harness.dart';
import 'widget_test_assets.dart';

void main() {
  suppressLogsForTests();

  late DiplomacyPanelRichFixture fixture;

  setUp(() => AppEventBus.reset());

  setUpAll(() async {
    await preloadNinePatchImage();
    fixture = DiplomacyPanelRichFixture.create();
  });

  Future<void> pumpDefault(WidgetTester tester, {Orders? orders}) =>
      pumpDiplomacyPanelOnTallSurface(
        tester,
        game: fixture.gameWithFactions,
        humanPlayerId: fixture.humanPlayerId,
        topology: fixture.topology,
        currentOrders: orders ?? const Orders(),
      );

  group('DiplomacyPanel', () {
    testWidgets('AC: Great Powers section when player has discovered GPs', (
      WidgetTester tester,
    ) async {
      await pumpDefault(tester);
      expect(find.text('Great Powers'), findsOneWidget);
    });

    testWidgets('AC: Faction rows show name and kind', (
      WidgetTester tester,
    ) async {
      await pumpDefault(tester);
      final firstGp = fixture.gameWithFactions.players
          .where((p) => p.id != fixture.humanPlayerId)
          .map((p) => p.displayName)
          .firstOrNull;
      if (firstGp != null) {
        expect(find.text(firstGp), findsAtLeastNWidgets(1));
      }
    });

    testWidgets('AC: Relation state badge shows PEACE or WAR label', (
      WidgetTester tester,
    ) async {
      await pumpDefault(tester);
      expect(
        find.text('WAR').evaluate().isNotEmpty ||
            find.text('PEACE').evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets(
      'AC: One-word 10-step ladder relation state shown, score hidden (Refs #3753)',
      (WidgetTester tester) async {
        await pumpDefault(tester);
        expect(find.textContaining('Neutral'), findsWidgets);
        expect(find.textContaining('Distrustful'), findsWidgets);
        expect(find.textContaining(' (50)'), findsNothing);
        expect(find.textContaining(' (20)'), findsNothing);
      },
    );

    testWidgets(
      'AC-6/AC-10: overture and FTP buttons behind More when invalid',
      (WidgetTester tester) async {
        await pumpDefault(tester);
        final Finder gp2Row = find.byKey(
          const ValueKey('${kDiplomacyRowBodyKeyPrefix}gp2'),
        );
        expect(
          find.descendant(of: gp2Row, matching: find.text('More actions')),
          findsOneWidget,
        );
        for (final label in ['Embassy', 'Establish FTP', 'Offer Peace']) {
          expect(
            find.descendant(of: gp2Row, matching: find.text(label)),
            findsNothing,
          );
        }
        await tester.tap(
          find.descendant(of: gp2Row, matching: find.text('More actions')),
        );
        await tester.pumpAndSettle();
        for (final label in ['Embassy', 'Establish FTP', 'Offer Peace']) {
          expect(
            find.descendant(of: gp2Row, matching: find.text(label)),
            findsOneWidget,
          );
        }
      },
    );

    testWidgets('AC: Action buttons present for factions', (
      WidgetTester tester,
    ) async {
      await pumpDefault(tester);
      expect(find.byType(CtNinePatchButton), findsAtLeastNWidgets(1));
      expect(
        find.text('Declare War').evaluate().isNotEmpty ||
            find.text('Offer Peace').evaluate().isNotEmpty ||
            find.text('Alliance').evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('AC: Pending orders show Cancel button, action button hidden', (
      WidgetTester tester,
    ) async {
      final otherGp = fixture.gameWithFactions.players.firstWhere(
        (p) => p.id != fixture.humanPlayerId,
      );
      final initialOrders = Orders(
        diplomaticOrdersByPlayerId: {
          fixture.humanPlayerId: [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: otherGp.id,
            ),
          ],
        },
      );
      final targetRow = buildDiplomacyRows(
        fixture.gameWithFactions,
        fixture.topology,
        fixture.humanPlayerId,
        initialOrders,
      ).firstWhere((r) => r.factionId == otherGp.id);
      expect(
        targetRow.pendingOrderTypes,
        contains(DiplomaticOrderType.declareWar),
      );
      await pumpDefault(tester, orders: initialOrders);
      expect(find.text('Cancel'), findsWidgets);
    });

    testWidgets(
      'AC-1: Empty state shows all three section headings + tribe placeholder',
      (WidgetTester tester) async {
        await pumpDiplomacyPanelOnTallSurface(
          tester,
          game: fixture.gameWithNoDiscovered,
          humanPlayerId: 'gp1',
          topology: const MapTopology(nodes: [], edges: []),
        );
        for (final heading in ['Great Powers', 'Minor Nations', 'Tribes']) {
          expect(find.text(heading), findsOneWidget);
        }
        expect(find.text('No tribes contacted yet.'), findsOneWidget);
      },
    );

    testWidgets(
      'AC-5 (Refs #3341): tribe discovered by visibility renders under Tribes '
      'with no prior relation (no empty placeholder)',
      (WidgetTester tester) async {
        await pumpDiplomacyPanelOnTallSurface(
          tester,
          game: buildDiplomacyPanelGameWithTribeDiscoveredByVisibility(),
          humanPlayerId: 'gp1',
          topology: const MapTopology(nodes: [], edges: []),
        );
        expect(find.text('Tribes'), findsOneWidget);
        expect(find.text('Tribe One'), findsOneWidget);
        expect(find.text('No tribes contacted yet.'), findsNothing);
      },
    );

    testWidgets('panel is scrollable', (WidgetTester tester) async {
      await pumpDefault(tester);
      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('DiplomacyPanel mode bar', () {
    testWidgets(
      'AC: default state — All button active (--accent), others inactive (--muted)',
      (WidgetTester tester) async {
        await pumpDefault(tester);
        expect(
          tester.widget<Text>(find.text('All')).style?.color,
          EditorialMonoclePalette.accent,
        );
        for (final label in ['Great Powers only', 'Minors only']) {
          expect(
            tester.widget<Text>(find.text(label)).style?.color,
            EditorialMonoclePalette.muted,
          );
        }
      },
    );

    for (final scenario in diplomacyModeBarFilterScenarios) {
      testWidgets(
        'AC: tapping "${scenario.filterLabel}" applies section filter',
        (WidgetTester tester) async {
          await pumpDefault(tester);
          expect(find.text('Great Powers'), findsOneWidget);
          await tester.tap(find.text(scenario.filterLabel));
          await pumpDiplomacyPanelBuilt(tester);
          for (final heading in scenario.visibleSectionHeadings) {
            expect(find.text(heading), findsOneWidget);
          }
          for (final heading in scenario.hiddenSectionHeadings) {
            expect(find.text(heading), findsNothing);
          }
          expect(
            tester.widget<Text>(find.text(scenario.filterLabel)).style?.color,
            EditorialMonoclePalette.accent,
          );
        },
      );
    }

    testWidgets('AC: mode bar renders all three filter labels', (
      WidgetTester tester,
    ) async {
      await pumpDefault(tester);
      for (final label in diplomacyModeBarFilterLabels) {
        expect(find.text(label), findsOneWidget);
      }
    });
  });

  group('DiplomacyPanel GP relative-power line rendering', () {
    Future<void> pumpAndRows(WidgetTester tester) async {
      await pumpDefault(tester);
    }

    testWidgets('AC: stronger GP relative-power line renders in --danger', (
      WidgetTester tester,
    ) async {
      await pumpAndRows(tester);
      final stronger = buildDiplomacyRows(
        fixture.gameWithFactions,
        fixture.topology,
        fixture.humanPlayerId,
        const Orders(),
      ).where(
        (r) =>
            r.kind == FactionKind.greatPower &&
            r.powerScore != null &&
            r.playerPowerScore != null &&
            powerComparisonPercent(r.powerScore!, r.playerPowerScore!) > 0,
      );
      if (stronger.isEmpty) return;
      for (final r in stronger) {
        final colors = relativePowerSpanColors(tester, r.factionId);
        expect(colors.pctColor, EditorialMonoclePalette.danger);
        expect(colors.tierColor, EditorialMonoclePalette.danger);
      }
    });

    testWidgets(
      'AC: weaker/equal GP relative-power line renders in --success',
      (WidgetTester tester) async {
        await pumpAndRows(tester);
        final weakerOrEqual = buildDiplomacyRows(
          fixture.gameWithFactions,
          fixture.topology,
          fixture.humanPlayerId,
          const Orders(),
        ).where(
          (r) =>
              r.kind == FactionKind.greatPower &&
              r.powerScore != null &&
              r.playerPowerScore != null &&
              powerComparisonPercent(r.powerScore!, r.playerPowerScore!) <= 0,
        );
        if (weakerOrEqual.isEmpty) return;
        for (final r in weakerOrEqual) {
          final colors = relativePowerSpanColors(tester, r.factionId);
          expect(colors.pctColor, EditorialMonoclePalette.success);
          expect(colors.tierColor, EditorialMonoclePalette.success);
        }
      },
    );

    testWidgets(
      'AC: Great Power rows render the localized "Relative power:" prefix',
      (WidgetTester tester) async {
        await pumpAndRows(tester);
        final hasGp = buildDiplomacyRows(
          fixture.gameWithFactions,
          fixture.topology,
          fixture.humanPlayerId,
          const Orders(),
        ).any((r) => r.kind == FactionKind.greatPower);
        if (!hasGp) return;
        expect(find.byType(RelativePowerLine), findsAtLeastNWidgets(1));
        expect(find.textContaining('Relative power:'), findsAtLeastNWidgets(1));
      },
    );

    testWidgets(
      'absolute "Power: N" score label is no longer rendered on GP rows',
      (WidgetTester tester) async {
        await pumpAndRows(tester);
        expect(find.textContaining('Power: '), findsNothing);
      },
    );
  });

  group('DiplomacyPanel section headings (editorial-monocle)', () {
    testWidgets('AC: Section heading text resolves to --accent color', (
      WidgetTester tester,
    ) async {
      await pumpDefault(tester);
      final heading = tester.widget<Text>(find.text('Great Powers'));
      expect(heading.style?.color, EditorialMonoclePalette.accent);
      expect(heading.style?.fontFamily, 'Cinzel');
    });

    testWidgets(
      'AC: Section heading container exposes a 2 px --accent-dim bottom border',
      (WidgetTester tester) async {
        await pumpDefault(tester);
        final decorated = find.ancestor(
          of: find.text('Great Powers'),
          matching: find.byType(DecoratedBox),
        );
        expect(decorated, findsAtLeastNWidgets(1));
        final box = tester.widget<DecoratedBox>(decorated.first);
        final decoration = box.decoration as BoxDecoration;
        expect(decoration.border!.bottom.color, EditorialMonoclePalette.accentDim);
        expect(decoration.border!.bottom.width, 2);
      },
    );
  });

  group('DiplomacyPanel faction kind badges (editorial-monocle)', () {
    Future<List<DiplomacyRowData>> rows(WidgetTester tester) async {
      await pumpDefault(tester);
      return buildDiplomacyRows(
        fixture.gameWithFactions,
        fixture.topology,
        fixture.humanPlayerId,
        const Orders(),
      );
    }

    testWidgets(
      'AC: GP badge background --accent-dim and foreground --bg-deep',
      (WidgetTester tester) async {
        final panelRows = await rows(tester);
        if (!panelRows.any((r) => r.kind == FactionKind.greatPower)) return;
        final gpText = find.text('GP').first;
        final container = tester.widget<Container>(
          find.ancestor(of: gpText, matching: find.byType(Container)).first,
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, EditorialMonoclePalette.accentDim);
        expect(decoration.border, isNull);
        expect(
          tester.widget<Text>(gpText).style?.color,
          EditorialMonoclePalette.bgDeep,
        );
      },
    );

    testWidgets('AC: Minor badge background --muted and foreground --bg-deep', (
      WidgetTester tester,
    ) async {
      final panelRows = await rows(tester);
      if (!panelRows.any((r) => r.kind == FactionKind.minor)) return;
      final minorText = find.text('Minor').first;
      final container = tester.widget<Container>(
        find.ancestor(of: minorText, matching: find.byType(Container)).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, EditorialMonoclePalette.muted);
      expect(decoration.border, isNull);
      expect(
        tester.widget<Text>(minorText).style?.color,
        EditorialMonoclePalette.bgDeep,
      );
    });

    testWidgets(
      'AC: Tribe badge outlined with --muted border, transparent background',
      (WidgetTester tester) async {
        final panelRows = await rows(tester);
        final tribeRows =
            panelRows.where((r) => r.kind == FactionKind.tribe).toList();
        if (tribeRows.isEmpty) return;
        final tribeRow = tribeRows.first;
        final tribeText = find.descendant(
          of: find.byKey(
            ValueKey('$kDiplomacyRowBodyKeyPrefix${tribeRow.factionId}'),
          ),
          matching: find.text('Tribe'),
        );
        await tester.scrollUntilVisible(
          tribeText,
          120,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump();
        final container = tester.widget<Container>(
          find.ancestor(of: tribeText, matching: find.byType(Container)).first,
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, isNull);
        expect(decoration.border!.top.color, EditorialMonoclePalette.muted);
        expect(
          tester.widget<Text>(tribeText).style?.color,
          EditorialMonoclePalette.muted,
        );
      },
    );

    testWidgets(
      'AC: No badge uses raw Material chrome (Colors.blue/grey/orange)',
      (WidgetTester tester) async {
        await pumpDefault(tester);
        for (final label in ['GP', 'Minor', 'Tribe']) {
          final finder = find.text(label);
          if (finder.evaluate().isEmpty) continue;
          final color = tester.widget<Text>(finder.first).style?.color;
          expect(color, isNot(equals(Colors.blue)));
          expect(color, isNot(equals(Colors.grey)));
          expect(color, isNot(equals(Colors.orange)));
        }
      },
    );
  });
}
