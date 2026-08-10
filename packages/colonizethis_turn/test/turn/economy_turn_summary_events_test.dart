import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_turn/src/turn/economy_turn_summary_events.dart';
import 'package:colonizethis_turn/src/turn/turn_event_sink.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../support/turn_economy_test_harness.dart';

void main() {
  group('emitEconomyTurnSummaryEvents (Refs #4308)', () {
    test('emits treasury and stockpile deltas for human GP', () {
      final events = <GameEvent>[];
      final start = turnTestOwSingleProvinceGame(
        ownerId: 'gp1',
        treasury: 100,
        stockpile: const Stockpile().applyDelta('grain', 20),
      );
      final end = start.copyWith(
        players: [
          start.players.first.copyWith(
            treasury: 300,
            stockpile: const Stockpile().applyDelta('grain', 10),
          ),
        ],
      );

      emitEconomyTurnSummaryEvents(
        start: start,
        end: end,
        turn: 1,
        sink: TurnEventSink(onGameEvent: events.add),
      );

      final summaries = events.whereType<EconomyTurnSummaryEvent>().toList();
      expect(summaries, hasLength(1));
      expect(summaries.single.playerId, 'gp1');
      expect(summaries.single.treasuryDelta, 200);
      expect(summaries.single.stockpileDeltas, {'grain': -10});
    });

    test('omits event when treasury and stockpile are unchanged', () {
      final events = <GameEvent>[];
      final start = turnTestOwSingleProvinceGame(
        ownerId: 'gp1',
        treasury: 50,
        stockpile: const Stockpile().applyDelta('lumber', 5),
      );

      emitEconomyTurnSummaryEvents(
        start: start,
        end: start,
        turn: 2,
        sink: TurnEventSink(onGameEvent: events.add),
      );

      expect(events.whereType<EconomyTurnSummaryEvent>(), isEmpty);
    });

    test('stockpile delta keys are deterministic for repeated builds', () {
      final start = turnTestOwSingleProvinceGame(
        ownerId: 'gp1',
        stockpile: const Stockpile(quantities: {'grain': 5, 'lumber': 1}),
      );
      final end = start.copyWith(
        players: [
          start.players.first.copyWith(
            stockpile: const Stockpile(quantities: {'grain': 3, 'lumber': 4}),
          ),
        ],
      );
      final first = <GameEvent>[];
      emitEconomyTurnSummaryEvents(
        start: start,
        end: end,
        turn: 1,
        sink: TurnEventSink(onGameEvent: first.add),
      );
      final second = <GameEvent>[];
      emitEconomyTurnSummaryEvents(
        start: start,
        end: end,
        turn: 1,
        sink: TurnEventSink(onGameEvent: second.add),
      );

      final firstSummary = first.single as EconomyTurnSummaryEvent;
      final secondSummary = second.single as EconomyTurnSummaryEvent;
      expect(firstSummary.stockpileDeltas.keys.toList(), ['grain', 'lumber']);
      expect(secondSummary.stockpileDeltas, firstSummary.stockpileDeltas);
    });

    test('does not include other players deltas', () {
      final events = <GameEvent>[];
      final start = turnTestOwSingleProvinceGame(
        ownerId: 'gp1',
        treasury: 0,
      );
      final end = start.copyWith(
        players: [
          start.players.first.copyWith(treasury: 10),
          const Player(
            id: 'gp2',
            displayName: 'Rival',
            isHuman: false,
            treasury: 500,
          ),
        ],
      );

      emitEconomyTurnSummaryEvents(
        start: start,
        end: end,
        turn: 1,
        sink: TurnEventSink(onGameEvent: events.add),
      );

      final summaries = events.whereType<EconomyTurnSummaryEvent>().toList();
      expect(summaries.map((e) => e.playerId), ['gp1']);
      expect(summaries.single.treasuryDelta, 10);
    });
  });
}
