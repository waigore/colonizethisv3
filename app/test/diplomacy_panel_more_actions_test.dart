// Diplomacy panel ready-first shortlist + More actions (Refs #4265).
// SPEC/ui/diplomacy-panel.md § Per-faction row.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel_constants.dart';

import 'diplomacy_panel_test_support.dart';
import 'panel_test_fixtures.dart';
import 'widget_test_assets.dart';

void main() {
  suppressLogsForTests();

  late Game gameWithFactions;
  late String humanPlayerId;
  late MapTopology topology;

  setUp(() {
    AppEventBus.reset();
  });

  setUpAll(() async {
    await preloadNinePatchImage();
    gameWithFactions = buildDiplomacyRichPanelTestGame();
    topology = const MapTopology();
    humanPlayerId = gameWithFactions.players.first.id;
  });

  Future<void> pumpPanel(WidgetTester tester) async {
    await bindDiplomacyTallTestSurface(tester);
    await tester.pumpWidget(
      buildDiplomacyPanel(
        game: gameWithFactions,
        humanPlayerId: humanPlayerId,
        topology: topology,
      ),
    );
    await pumpDiplomacyPanelBuilt(tester);
  }

  String otherGpId() => gameWithFactions.players
      .firstWhere((p) => p.id != humanPlayerId)
      .id;

  Finder gp2Row() => find.byKey(
    ValueKey('${kDiplomacyRowBodyKeyPrefix}gp2'),
  );

  group('Diplomacy panel More actions (Refs #4265)', () {
    testWidgets('default row shows enabled actions and More control', (
      WidgetTester tester,
    ) async {
      await pumpPanel(tester);

      expect(
        find.descendant(of: gp2Row(), matching: find.text('Declare War')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: gp2Row(), matching: find.text('More actions')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: gp2Row(), matching: find.text('Offer Peace')),
        findsNothing,
      );
      expect(
        find.descendant(of: gp2Row(), matching: find.text('Establish FTP')),
        findsNothing,
      );
    });

    testWidgets('expanding More reveals disabled actions with inline reasons', (
      WidgetTester tester,
    ) async {
      await pumpPanel(tester);

      await tester.tap(
        find.descendant(of: gp2Row(), matching: find.text('More actions')),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: gp2Row(), matching: find.text('Offer Peace')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: gp2Row(), matching: find.text('Establish FTP')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: gp2Row(), matching: find.text('Fewer actions')),
        findsOneWidget,
      );
    });

    testWidgets('pending Cancel stays on default row without More', (
      WidgetTester tester,
    ) async {
      final otherGp = otherGpId();
      await bindDiplomacyTallTestSurface(tester);
      await tester.pumpWidget(
        buildDiplomacyPanel(
          game: gameWithFactions,
          humanPlayerId: humanPlayerId,
          topology: topology,
          currentOrders: Orders(
            diplomaticOrdersByPlayerId: {
              humanPlayerId: [
                DiplomaticOrder(
                  type: DiplomaticOrderType.declareWar,
                  targetFactionId: otherGp,
                ),
              ],
            },
          ),
        ),
      );
      await pumpDiplomacyPanelBuilt(tester);

      final Finder targetRow = find.byKey(
        ValueKey('${kDiplomacyRowBodyKeyPrefix}$otherGp'),
      );
      expect(
        find.descendant(of: targetRow, matching: find.text('Cancel')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: targetRow, matching: find.text('Declare War')),
        findsNothing,
      );
    });

    testWidgets('More control uses stable per-faction key', (
      WidgetTester tester,
    ) async {
      await pumpPanel(tester);

      expect(
        find.byKey(ValueKey('${kDiplomacyMoreActionsKeyPrefix}${otherGpId()}')),
        findsOneWidget,
      );
    });

    testWidgets('minor row exposes locked overture stages under More', (
      WidgetTester tester,
    ) async {
      await pumpPanel(tester);
      final Finder minorRow = find.byKey(
        const ValueKey('${kDiplomacyRowBodyKeyPrefix}m1'),
      );

      expect(
        find.descendant(of: minorRow, matching: find.text('More actions')),
        findsOneWidget,
      );

      await tester.tap(
        find.descendant(of: minorRow, matching: find.text('More actions')),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: minorRow, matching: find.text('Consulate')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: minorRow, matching: find.text('Embassy')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: minorRow, matching: find.text('NAP')),
        findsOneWidget,
      );
    });
  });
}
