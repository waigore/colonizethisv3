import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/diplomacy_game_fixtures.dart';

void main() {
  test(
    'DiplomacyFactionMembership matches linear-scan isMinorOrTribe / '
    'isGreatPower for 6 GP + 10 minor/tribe (Refs #2268 AC-6)',
    () {
      final game = factionMembershipStressTestGame();
      final membership = DiplomacyFactionMembership.from(game);
      final allIds = <String>[
        ...game.players.map((p) => p.id),
        ...game.minorNations.map((m) => m.id),
        ...game.tribes.map((t) => t.id),
        'not_a_faction',
      ];
      for (final id in allIds) {
        expect(
          membership.isMinorOrTribe(id),
          isMinorOrTribe(game, id),
          reason: 'isMinorOrTribe($id)',
        );
        expect(
          membership.isGreatPower(id),
          isGreatPower(game, id),
          reason: 'isGreatPower($id)',
        );
      }
    },
  );
}
