// Pins that `ai_api.dart` re-exports [IncrementalCandidateValidatorArmyNaval]
// so conquest stalled-fallback can call [isArmyMoveAccepted] through the
// narrow AI contract (Refs #4587). A `show IncrementalCandidateValidator`
// hide-list drop of the extension fails the app/AI compile.
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  test('ai_api re-exports army-move incremental acceptor (Refs #4587)', () {
    bool probe(IncrementalCandidateValidator v, ArmyMoveOrder o) =>
        v.isArmyMoveAccepted(o);
    expect(probe, isNotNull);
  });
}
