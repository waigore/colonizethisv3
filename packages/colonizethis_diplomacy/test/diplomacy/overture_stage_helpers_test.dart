import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Unit coverage for the [OvertureStageChain] ladder navigation that the
/// extracted `colonizethis_diplomacy` package owns (Refs #3290 Phase 2).
void main() {
  group('OvertureStageChain.next', () {
    test('advances forward through the overture ladder', () {
      expect(OvertureStage.none.next, OvertureStage.tradeConsulate);
      expect(OvertureStage.tradeConsulate.next, OvertureStage.embassy);
      expect(OvertureStage.embassy.next, OvertureStage.nap);
      expect(OvertureStage.nap.next, OvertureStage.joinEmpire);
    });

    test('returns null at the terminal joinEmpire stage', () {
      expect(OvertureStage.joinEmpire.next, isNull);
    });
  });

  group('OvertureStageChain.previous', () {
    test('steps backward through the overture ladder', () {
      expect(OvertureStage.joinEmpire.previous, OvertureStage.nap);
      expect(OvertureStage.nap.previous, OvertureStage.embassy);
      expect(OvertureStage.embassy.previous, OvertureStage.tradeConsulate);
      expect(OvertureStage.tradeConsulate.previous, OvertureStage.none);
    });

    test('maps the none stage to itself (no underflow)', () {
      expect(OvertureStage.none.previous, OvertureStage.none);
    });

    test('next and previous are inverse for interior stages', () {
      for (final stage in const [
        OvertureStage.tradeConsulate,
        OvertureStage.embassy,
        OvertureStage.nap,
        OvertureStage.joinEmpire,
      ]) {
        expect(stage.previous.next, stage);
      }
    });
  });
}
