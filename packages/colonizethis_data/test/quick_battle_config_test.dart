import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('quick battle config', () {
    test('constants match quick battle spec defaults', () {
      expect(quickBattleMaxCohesion, 3);
      expect(quickBattleMaxRounds, 3);
      expect(quickBattleCpPerRoundMin, 2);
      expect(quickBattleCpPerRoundMax, 3);
      expect(quickBattleCpPerRoundMin <= quickBattleCpPerRoundMax, isTrue);
    });
  });
}
