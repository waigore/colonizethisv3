import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/diplomacy_resolver_phase_test_support.dart';

void main() {
  group('resolveDiplomacyPhase part2 placeholder', () {
    test('returns game when there are no diplomatic orders', () {
      final game = diplomacyResolverPhaseTestBaseGame();
      final result = resolveDiplomacyPhase(game, const Orders());
      expect(result.game.id, game.id);
    });
  });
}
