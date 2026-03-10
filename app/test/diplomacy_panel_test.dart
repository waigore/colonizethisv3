// Tests for DiplomacyPanel. SPEC/ui/diplomacy-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/diplomacy_panel.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';

void main() {
  suppressLogsForTests();

  late Game gameWithFactions;
  late Game gameWithNoDiscovered;
  late String humanPlayerId;
  late MapTopology topology;

  setUpAll(() {
    final result = getDebugInitGameResult();
    gameWithFactions = result.game;
    topology = result.combinedTopology;
    humanPlayerId = gameWithFactions.players.isNotEmpty
        ? gameWithFactions.players.first.id
        : 'gp1';
    gameWithNoDiscovered = _gameWithNoDiscoveredFactions();
  });

  Widget buildPanel({
    required Game game,
    required String humanPlayerId,
    required MapTopology topology,
    Orders currentOrders = const Orders(),
    void Function(Orders)? onOrdersChanged,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: DiplomacyPanel(
          game: game,
          humanPlayerId: humanPlayerId,
          topology: topology,
          currentOrders: currentOrders,
          onOrdersChanged: onOrdersChanged ?? (_) {},
        ),
      ),
    );
  }

  group('DiplomacyPanel', () {
    testWidgets('AC: Great Powers section when player has discovered GPs',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(
        game: gameWithFactions,
        humanPlayerId: humanPlayerId,
        topology: topology,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Great Powers'), findsOneWidget);
    });

    testWidgets('AC: Faction rows show name and kind', (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(
        game: gameWithFactions,
        humanPlayerId: humanPlayerId,
        topology: topology,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsAtLeastNWidgets(1));
      final firstGp = gameWithFactions.players
          .where((p) => p.id != humanPlayerId)
          .map((p) => p.displayName)
          .firstOrNull;
      if (firstGp != null) {
        expect(find.text(firstGp), findsAtLeastNWidgets(1));
      }
    });

    testWidgets('AC: Relation state shown (Peace or War)', (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(
        game: gameWithFactions,
        humanPlayerId: humanPlayerId,
        topology: topology,
      ));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Peace').evaluate().isNotEmpty ||
            find.textContaining('War').evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('AC: Action buttons present for factions',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(
        game: gameWithFactions,
        humanPlayerId: humanPlayerId,
        topology: topology,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(FilledButton), findsAtLeastNWidgets(1));
      expect(
        find.text('Declare War').evaluate().isNotEmpty ||
            find.text('Offer Peace').evaluate().isNotEmpty ||
            find.text('Alliance').evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('AC: Tapping no-param action calls onOrdersChanged',
        (WidgetTester tester) async {
      Orders? captured;
      await tester.pumpWidget(buildPanel(
        game: gameWithFactions,
        humanPlayerId: humanPlayerId,
        topology: topology,
        onOrdersChanged: (o) => captured = o,
      ));
      await tester.pumpAndSettle();

      final declareWar = find.text('Declare War');
      if (declareWar.evaluate().isNotEmpty) {
        await tester.tap(declareWar.first);
        await tester.pumpAndSettle();
        expect(captured, isNotNull);
        expect(
          captured!.diplomaticOrdersByPlayerId[humanPlayerId] ?? [],
          hasLength(greaterThanOrEqualTo(1)),
        );
        expect(
          captured!.diplomaticOrdersByPlayerId[humanPlayerId]!
              .any((o) => o.type == DiplomaticOrderType.declareWar),
          isTrue,
        );
      }
    });

    testWidgets('AC: Empty state when no factions discovered',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(
        game: gameWithNoDiscovered,
        humanPlayerId: 'gp1',
        topology: const MapTopology(nodes: [], edges: []),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No other factions discovered yet.'), findsOneWidget);
    });

    testWidgets('panel is scrollable', (WidgetTester tester) async {
      await tester.pumpWidget(buildPanel(
        game: gameWithFactions,
        humanPlayerId: humanPlayerId,
        topology: topology,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('buildDiplomacyRows', () {
    test('returns empty list when player has no relations', () {
      final rows = buildDiplomacyRows(
        gameWithNoDiscovered,
        const MapTopology(nodes: [], edges: []),
        'gp1',
        const Orders(),
      );
      expect(rows, isEmpty);
    });

    test('returns GP rows sorted by military power then province count', () {
      final rows = buildDiplomacyRows(
        gameWithFactions,
        topology,
        humanPlayerId,
        const Orders(),
      );
      final gpRows = rows.where((r) => r.kind == FactionKind.greatPower).toList();
      if (gpRows.length < 2) return;
      for (var i = 0; i < gpRows.length - 1; i++) {
        final strA = aggregateMilitaryStrengthForPlayer(
            gameWithFactions, gpRows[i].factionId);
        final strB = aggregateMilitaryStrengthForPlayer(
            gameWithFactions, gpRows[i + 1].factionId);
        expect(strA >= strB, isTrue);
      }
    });
  });
}

/// Minimal game with one player and no diplomacy relations (no discovered factions).
Game _gameWithNoDiscoveredFactions() {
  const ow = 'oldWorld';
  final p1 = Province(
    id: '$ow|p1',
    regionId: ow,
    displayName: 'P1',
    ownerId: 'gp1',
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
    oldWorld: RegionData(provinces: [p1], units: const []),
    newWorld: const RegionData(),
    playerVisibilityByTile: const {},
    playerProspectedTiles: const {},
  );
  const player = Player(
    id: 'gp1',
    displayName: 'Solo',
    isHuman: true,
  );
  return Game(
    id: 'empty-diplo',
    worldState: world,
    players: const [player],
    diplomacyRelations: const [],
  );
}
