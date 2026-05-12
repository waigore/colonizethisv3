import 'package:colonizethis_logic/src/diplomacy/overture_stage_helpers.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('OvertureStageNavigation.next', () {
    test('follows expected progression', () {
      expect(OvertureStage.none.next, OvertureStage.tradeConsulate);
      expect(OvertureStage.tradeConsulate.next, OvertureStage.embassy);
      expect(OvertureStage.embassy.next, OvertureStage.nap);
      expect(OvertureStage.nap.next, OvertureStage.joinEmpire);
    });

    test('returns null when already at final stage', () {
      expect(OvertureStage.joinEmpire.next, isNull);
    });
  });

  group('OvertureStageNavigation.previous', () {
    test('maps none to itself', () {
      expect(OvertureStage.none.previous, OvertureStage.none);
    });

    test('reverses the forward chain', () {
      expect(OvertureStage.tradeConsulate.previous, OvertureStage.none);
      expect(OvertureStage.embassy.previous, OvertureStage.tradeConsulate);
      expect(OvertureStage.nap.previous, OvertureStage.embassy);
      expect(OvertureStage.joinEmpire.previous, OvertureStage.nap);
    });
  });
}
