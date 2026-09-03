// DiplomacyPanel widget tests (merged part1+part2). SPEC/ui/diplomacy-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';

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
        for (final label in [
          'Embassy',
          'Establish Favored partner',
          'Offer Peace',
        ]) {
          expect(
            find.descendant(of: gp2Row, matching: find.text(label)),
            findsNothing,
          );
        }
        await tester.tap(
          find.descendant(of: gp2Row, matching: find.text('More actions')),
        );
        await tester.pumpAndSettle();
        for (final label in [
          'Embassy',
          'Establish Favored partner',
          'Offer Peace',
        ]) {
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
}
