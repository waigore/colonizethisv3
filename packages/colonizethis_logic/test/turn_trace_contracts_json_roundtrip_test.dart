import 'package:colonizethis_logic/src/trace/turn_trace_contracts.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  test('TurnTracePhaseTrace round-trips through toJson / fromJson', () {
    const original = TurnTracePhaseTrace(
      phaseId: 'movement',
      beforeState: <String, Object?>{'k': 1, 'nested': <String, Object?>{}},
      afterState: <String, Object?>{'k': 2},
      orderEvents: <TurnTraceOrderEvent>[
        TurnTraceOrderEvent(
          sequence: 0,
          orderId: 'm1',
          eventType: 'civilian_move_applied',
          payload: <String, Object?>{'unitId': 'u1'},
        ),
      ],
      effects: <String, Object?>{'x': true},
    );
    final decoded = TurnTracePhaseTrace.fromJson(original.toJson());
    expect(decoded.phaseId, original.phaseId);
    expect(decoded.beforeState, original.beforeState);
    expect(decoded.afterState, original.afterState);
    expect(decoded.orderEvents.length, 1);
    expect(decoded.orderEvents.first.sequence, 0);
    expect(decoded.orderEvents.first.orderId, 'm1');
    expect(decoded.orderEvents.first.eventType, 'civilian_move_applied');
    expect(
      decoded.orderEvents.first.payload,
      original.orderEvents.first.payload,
    );
    expect(decoded.effects, original.effects);
  });

  test('TurnTraceAiSection round-trips through toJson / fromJson', () {
    const original = TurnTraceAiSection(
      factionId: 'gp1',
      state: <String, Object?>{'a': 1},
      thresholds: <String, Object?>{'t': 2},
      outcome: <String, Object?>{'o': 3},
    );
    final decoded = TurnTraceAiSection.fromJson(original.toJson());
    expect(decoded.factionId, original.factionId);
    expect(decoded.state, original.state);
    expect(decoded.thresholds, original.thresholds);
    expect(decoded.outcome, original.outcome);
  });
}
