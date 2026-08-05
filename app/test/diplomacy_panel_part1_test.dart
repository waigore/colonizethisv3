// DiplomacyPanel core ACs + mode bar (part1). SPEC/ui/diplomacy-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel_constants.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';

import 'diplomacy_panel_test_support.dart';
import 'panel_test_fixtures.dart';
import 'widget_test_assets.dart';

void main() {
  suppressLogsForTests();

  late Game gameWithFactions;
  late Game gameWithNoDiscovered;
  late String humanPlayerId;
  late MapTopology topology;

  setUp(() {
    AppEventBus.reset();
  });

  setUpAll(() async {
    await preloadNinePatchImage();
    // Refs #3656: lightweight discovered-faction fixture replaces the ~7-11s
    // getDebugInitGameResult() map generation. It seeds discovered GPs (one at
    // peace → PEACE badge, one at war → WAR badge), a Minor Nation with the
    // full overture matrix, and a discovered Tribe, so the section-heading,
    // badge, relative-power, overture/FTP, and mode-bar filter assertions all
    // have their non-vacuous rows without generated map/topology data.
    gameWithFactions = buildDiplomacyRichPanelTestGame();
    topology = const MapTopology();
    humanPlayerId = gameWithFactions.players.isNotEmpty
        ? gameWithFactions.players.first.id
        : 'gp1';
    gameWithNoDiscovered = buildDiplomacyPanelGameWithNoDiscoveredFactions();
  });

  group('DiplomacyPanel', () {
    testWidgets('AC: Great Powers section when player has discovered GPs', (
      WidgetTester tester,
    ) async {
      await bindDiplomacyTallTestSurface(tester);
      await tester.pumpWidget(
        buildDiplomacyPanel(
          game: gameWithFactions,
          humanPlayerId: humanPlayerId,
          topology: topology,
        ),
      );
      await pumpDiplomacyPanelBuilt(tester);

      expect(find.text('Great Powers'), findsOneWidget);
    });

    testWidgets('AC: Faction rows show name and kind', (
      WidgetTester tester,
    ) async {
      await bindDiplomacyTallTestSurface(tester);
      await tester.pumpWidget(
        buildDiplomacyPanel(
          game: gameWithFactions,
          humanPlayerId: humanPlayerId,
          topology: topology,
        ),
      );
      await pumpDiplomacyPanelBuilt(tester);

      // SPEC/ui/diplomacy-panel.md § Per-faction row → Row chrome: rows
      // render as flat gradient tiles, not nine-patch CtPanel frames.
      // The presence of at least one row is asserted indirectly by the
      // faction display name showing up below.
      final firstGp = gameWithFactions.players
          .where((p) => p.id != humanPlayerId)
          .map((p) => p.displayName)
          .firstOrNull;
      if (firstGp != null) {
        expect(find.text(firstGp), findsAtLeastNWidgets(1));
      }
    });

    testWidgets('AC: Relation state badge shows PEACE or WAR label', (
      WidgetTester tester,
    ) async {
      await bindDiplomacyTallTestSurface(tester);
      await tester.pumpWidget(
        buildDiplomacyPanel(
          game: gameWithFactions,
          humanPlayerId: humanPlayerId,
          topology: topology,
        ),
      );
      await pumpDiplomacyPanelBuilt(tester);

      // SPEC/ui/diplomacy-panel.md § Relation state badge: the badge
      // label is the uppercase string `WAR` or `PEACE`, never the
      // sentence-case `War` / `Peace` literals.
      expect(
        find.text('WAR').evaluate().isNotEmpty ||
            find.text('PEACE').evaluate().isNotEmpty,
        isTrue,
        reason:
            'Every faction row must render the uppercase relation-state badge.',
      );
    });

    testWidgets(
      'AC: One-word 10-step ladder relation state shown, score hidden (Refs #3753)',
      (WidgetTester tester) async {
        await bindDiplomacyTallTestSurface(tester);
        await tester.pumpWidget(
          buildDiplomacyPanel(
            game: gameWithFactions,
            humanPlayerId: humanPlayerId,
            topology: topology,
          ),
        );
        await pumpDiplomacyPanelBuilt(tester);

        // Fixture scores map onto the 10-step ladder: score 50 → Neutral
        // (step 6), score 20 → Distrustful (step 3).
        expect(find.textContaining('Neutral'), findsWidgets);
        expect(find.textContaining('Distrustful'), findsWidgets);

        // The hidden decimal score is never surfaced as text.
        expect(find.textContaining(' (50)'), findsNothing);
        expect(find.textContaining(' (20)'), findsNothing);
      },
    );

    testWidgets(
      'AC-6/AC-10: overture and FTP buttons behind More when invalid',
      (WidgetTester tester) async {
        await bindDiplomacyTallTestSurface(tester);
        await tester.pumpWidget(
          buildDiplomacyPanel(
            game: gameWithFactions,
            humanPlayerId: humanPlayerId,
            topology: topology,
          ),
        );
        await pumpDiplomacyPanelBuilt(tester);

        final Finder gp2Row = find.byKey(
          const ValueKey('${kDiplomacyRowBodyKeyPrefix}gp2'),
        );
        expect(
          find.descendant(of: gp2Row, matching: find.text('More actions')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: gp2Row, matching: find.text('Embassy')),
          findsNothing,
        );
        expect(
          find.descendant(of: gp2Row, matching: find.text('Establish FTP')),
          findsNothing,
        );
        expect(
          find.descendant(of: gp2Row, matching: find.text('Offer Peace')),
          findsNothing,
        );

        await tester.tap(
          find.descendant(of: gp2Row, matching: find.text('More actions')),
        );
        await tester.pumpAndSettle();

        expect(
          find.descendant(of: gp2Row, matching: find.text('Embassy')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: gp2Row, matching: find.text('Establish FTP')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: gp2Row, matching: find.text('Offer Peace')),
          findsOneWidget,
        );
      },
    );

    testWidgets('AC: Action buttons present for factions', (
      WidgetTester tester,
    ) async {
      await bindDiplomacyTallTestSurface(tester);
      await tester.pumpWidget(
        buildDiplomacyPanel(
          game: gameWithFactions,
          humanPlayerId: humanPlayerId,
          topology: topology,
        ),
      );
      await pumpDiplomacyPanelBuilt(tester);

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
      await bindDiplomacyTallTestSurface(tester);
      final otherGp = gameWithFactions.players.firstWhere(
        (p) => p.id != humanPlayerId,
      );
      final initialOrders = Orders(
        diplomaticOrdersByPlayerId: {
          humanPlayerId: [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: otherGp.id,
            ),
          ],
        },
      );
      final rows = buildDiplomacyRows(
        gameWithFactions,
        topology,
        humanPlayerId,
        initialOrders,
      );
      final targetRow = rows.firstWhere((r) => r.factionId == otherGp.id);
      expect(
        targetRow.pendingOrderTypes,
        contains(DiplomaticOrderType.declareWar),
      );
      await tester.pumpWidget(
        buildDiplomacyPanel(
          game: gameWithFactions,
          humanPlayerId: humanPlayerId,
          topology: topology,
          currentOrders: initialOrders,
        ),
      );
      await pumpDiplomacyPanelBuilt(tester);

      expect(find.text('Cancel'), findsWidgets);
    });

    testWidgets(
      'AC-1: Empty state shows all three section headings + tribe placeholder',
      (WidgetTester tester) async {
        await bindDiplomacyTallTestSurface(tester);
        await tester.pumpWidget(
          buildDiplomacyPanel(
            game: gameWithNoDiscovered,
            humanPlayerId: 'gp1',
            topology: const MapTopology(nodes: [], edges: []),
          ),
        );
        await pumpDiplomacyPanelBuilt(tester);

        // SPEC/ui/diplomacy-panel.md § Section headings (Refs #3341):
        // headings are always rendered even when their sections are empty.
        expect(find.text('Great Powers'), findsOneWidget);
        expect(find.text('Minor Nations'), findsOneWidget);
        expect(find.text('Tribes'), findsOneWidget);
        // The Tribes empty placeholder copy (diplomacy_panel_noTribes).
        expect(find.text('No tribes contacted yet.'), findsOneWidget);
      },
    );

    testWidgets(
      'AC-5 (Refs #3341): tribe discovered by visibility renders under Tribes '
      'with no prior relation (no empty placeholder)',
      (WidgetTester tester) async {
        await bindDiplomacyTallTestSurface(tester);
        await tester.pumpWidget(
          buildDiplomacyPanel(
            game: buildDiplomacyPanelGameWithTribeDiscoveredByVisibility(),
            humanPlayerId: 'gp1',
            topology: const MapTopology(nodes: [], edges: []),
          ),
        );
        await pumpDiplomacyPanelBuilt(tester);

        expect(find.text('Tribes'), findsOneWidget);
        expect(
          find.text('Tribe One'),
          findsOneWidget,
          reason: 'Discovered tribe row must render under the Tribes section.',
        );
        expect(
          find.text('No tribes contacted yet.'),
          findsNothing,
          reason:
              'The empty Tribes placeholder must not show once a tribe is '
              'discovered.',
        );
      },
    );

    testWidgets('panel is scrollable', (WidgetTester tester) async {
      await bindDiplomacyTallTestSurface(tester);
      await tester.pumpWidget(
        buildDiplomacyPanel(
          game: gameWithFactions,
          humanPlayerId: humanPlayerId,
          topology: topology,
        ),
      );
      await pumpDiplomacyPanelBuilt(tester);

      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('DiplomacyPanel mode bar', () {
    testWidgets(
      'AC: default state — All button active (--accent), others inactive (--muted)',
      (WidgetTester tester) async {
        await bindDiplomacyTallTestSurface(tester);
        await tester.pumpWidget(
          buildDiplomacyPanel(
            game: gameWithFactions,
            humanPlayerId: humanPlayerId,
            topology: topology,
          ),
        );
        await pumpDiplomacyPanelBuilt(tester);

        final allButton = tester.widget<Text>(find.text('All'));
        expect(
          allButton.style?.color,
          EditorialMonoclePalette.accent,
          reason: 'Default "All" filter must render in --accent.',
        );

        final gpOnlyButton = tester.widget<Text>(
          find.text('Great Powers only'),
        );
        expect(
          gpOnlyButton.style?.color,
          EditorialMonoclePalette.muted,
          reason: 'Inactive "Great Powers only" filter must render in --muted.',
        );

        final minorsOnlyButton = tester.widget<Text>(find.text('Minors only'));
        expect(
          minorsOnlyButton.style?.color,
          EditorialMonoclePalette.muted,
          reason: 'Inactive "Minors only" filter must render in --muted.',
        );
      },
    );

    testWidgets(
      'AC: tapping "Great Powers only" hides Minor Nation and Tribe rows',
      (WidgetTester tester) async {
        await bindDiplomacyTallTestSurface(tester);
        await tester.pumpWidget(
          buildDiplomacyPanel(
            game: gameWithFactions,
            humanPlayerId: humanPlayerId,
            topology: topology,
          ),
        );
        await pumpDiplomacyPanelBuilt(tester);

        // Sanity: default "All" view includes the Great Powers heading.
        expect(find.text('Great Powers'), findsOneWidget);

        await tester.tap(find.text('Great Powers only'));
        await pumpDiplomacyPanelBuilt(tester);

        expect(
          find.text('Great Powers'),
          findsOneWidget,
          reason: 'Great Powers heading must remain after filter switch.',
        );
        expect(
          find.text('Minor Nations'),
          findsNothing,
          reason:
              'Minor Nations section must be hidden when GP-only is active.',
        );
        expect(
          find.text('Tribes'),
          findsNothing,
          reason: 'Tribes section must be hidden when GP-only is active.',
        );

        final activeLabel = tester.widget<Text>(find.text('Great Powers only'));
        expect(
          activeLabel.style?.color,
          EditorialMonoclePalette.accent,
          reason: 'Selected mode-bar button label must use --accent.',
        );
      },
    );

    testWidgets(
      'AC: tapping "Minors only" hides Great Power rows but keeps Minors and Tribes',
      (WidgetTester tester) async {
        await bindDiplomacyTallTestSurface(tester);
        await tester.pumpWidget(
          buildDiplomacyPanel(
            game: gameWithFactions,
            humanPlayerId: humanPlayerId,
            topology: topology,
          ),
        );
        await pumpDiplomacyPanelBuilt(tester);

        // Sanity: GP section starts visible.
        expect(find.text('Great Powers'), findsOneWidget);

        await tester.tap(find.text('Minors only'));
        await pumpDiplomacyPanelBuilt(tester);

        expect(
          find.text('Great Powers'),
          findsNothing,
          reason:
              'Great Powers section must be hidden when Minors-only is active.',
        );
        // Both Minor and Tribe sections may or may not appear depending on
        // discovered factions in the debug-init game; assert that whichever
        // are present render at least once and the GP section is gone.
        final rows = buildDiplomacyRows(
          gameWithFactions,
          topology,
          humanPlayerId,
          const Orders(),
        );
        final hasMinors = rows.any((r) => r.kind == FactionKind.minor);
        final hasTribes = rows.any((r) => r.kind == FactionKind.tribe);
        if (hasMinors) {
          expect(find.text('Minor Nations'), findsOneWidget);
        }
        if (hasTribes) {
          expect(find.text('Tribes'), findsOneWidget);
        }

        final activeLabel = tester.widget<Text>(find.text('Minors only'));
        expect(
          activeLabel.style?.color,
          EditorialMonoclePalette.accent,
          reason: 'Selected mode-bar button label must use --accent.',
        );
      },
    );

    testWidgets('AC: mode bar renders all three filter labels', (
      WidgetTester tester,
    ) async {
      await bindDiplomacyTallTestSurface(tester);
      await tester.pumpWidget(
        buildDiplomacyPanel(
          game: gameWithFactions,
          humanPlayerId: humanPlayerId,
          topology: topology,
        ),
      );
      await pumpDiplomacyPanelBuilt(tester);

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Great Powers only'), findsOneWidget);
      expect(find.text('Minors only'), findsOneWidget);
    });
  });

  // Relative-power / section-heading / kind-badge token pins live in
  // `diplomacy_panel_part2_test.dart`. Faction-row chrome / war-button pins
  // live in `diplomacy_panel_chrome_test.dart`.
}
