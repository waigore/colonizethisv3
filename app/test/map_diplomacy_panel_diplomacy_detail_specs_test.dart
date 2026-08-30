import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'map_diplomacy_panel_specs_support.dart';

void main() {
  suppressLogsForTests();

  group('DiplomacyDetailScreen (SPEC/ui/diplomacy-detail-screen.md)', () {
    testWidgets(
      'AC: Great Power shows dossier section title',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);
        final game = diplomacyStoryGame(
          includeHistory: true,
          includeDossier: true,
          kind: FactionKind.greatPower,
        );

        await pumpDiplomacyDetailScreen(
          tester,
          game: game,
          kind: FactionKind.greatPower,
          relation: game.diplomacyRelations.first,
          bus: bus,
        );

        // Refs #2863 S5: card titles are uppercased per mockup GAME30002.
        expect(find.text('DOSSIER'), findsOneWidget);
        expect(find.text('evidence line'), findsOneWidget);
      },
    );

    testWidgets(
      'AC: non-Great Power hides dossier section',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);
        final game = diplomacyStoryGame(
          includeHistory: false,
          includeDossier: false,
          kind: FactionKind.minor,
        );

        await pumpDiplomacyDetailScreen(
          tester,
          game: game,
          kind: FactionKind.minor,
          relation: game.diplomacyRelations.first,
          bus: bus,
        );

        expect(find.text('DOSSIER'), findsNothing);
      },
    );

    testWidgets(
      'AC: empty history shows no-events copy',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);
        final game = diplomacyStoryGame(
          includeHistory: false,
          includeDossier: false,
          kind: FactionKind.greatPower,
        );

        await pumpDiplomacyDetailScreen(
          tester,
          game: game,
          kind: FactionKind.greatPower,
          relation: game.diplomacyRelations.first,
          bus: bus,
        );

        expect(
          find.text('No recorded events with this faction.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'AC: back button emits PopNavigationEvent',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        addTearDown(bus.dispose);
        final events = <AppEvent>[];
        final sub = bus.stream.listen(events.add);
        addTearDown(sub.cancel);

        final game = diplomacyStoryGame(
          includeHistory: true,
          includeDossier: false,
          kind: FactionKind.greatPower,
        );

        await pumpDiplomacyDetailScreen(
          tester,
          game: game,
          kind: FactionKind.greatPower,
          relation: game.diplomacyRelations.first,
          bus: bus,
        );

        // Refs #2863 S5: detail screen now renders a CtTopBar with a
        // CtBackButton chevron instead of the legacy Material AppBar.
        await tester.tap(find.byType(CtBackButton));
        await tester.pumpAndSettle();

        expect(events.whereType<PopNavigationEvent>(), hasLength(1));
      },
    );

    testWidgets(
      'AC: formatDiplomaticEvent uses Unknown faction for undiscovered party',
      (WidgetTester tester) async {
        const humanId = 'gp_human';
        const event = DiplomaticEvent(
          turn: 1,
          intraTurnIndex: 0,
          type: DiplomaticEventType.declareWar,
          participants: {humanId, 'unknown_gp'},
          fromFactionId: humanId,
          toFactionId: 'unknown_gp',
        );
        final game = Game(
          id: 'unknown',
          worldState: WorldState(
            turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
          ),
          turnTimeMapping: TurnTimeMapping.gdd01,
          players: [
            Player(
              id: humanId,
              displayName: 'England',
              isHuman: true,
              treasury: 0,
            ),
          ],
          diplomaticHistoryEvents: [event],
        );

        final sentence = formatDiplomaticEvent(event, game, humanId);
        expect(sentence, contains('Unknown faction'));
      },
    );
  });
}
