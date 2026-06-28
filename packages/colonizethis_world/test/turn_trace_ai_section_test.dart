import 'package:colonizethis_world/src/trace/turn_trace_contracts.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  test('TurnTraceAiSection round-trips through toJson/fromJson', () {
    const original = TurnTraceAiSection(
      factionId: 'gp1',
      state: {'a': 1},
      thresholds: {'b': true},
      outcome: {'c': 'x'},
    );
    final decoded = TurnTraceAiSection.fromJson(original.toJson());
    expect(decoded.factionId, original.factionId);
    expect(decoded.state, original.state);
    expect(decoded.thresholds, original.thresholds);
    expect(decoded.outcome, original.outcome);
  });
}
