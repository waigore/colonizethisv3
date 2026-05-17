import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  test(
    'DiplomacyFactionMembership matches linear-scan isMinorOrTribe / '
    'isGreatPower for 6 GP + 10 minor/tribe (Refs #2268 AC-6)',
    () {
      final players = List.generate(
        6,
        (i) => Player(
          id: 'gp$i',
          displayName: 'GP $i',
          isHuman: false,
          treasury: 1000,
        ),
      );
      final minors = List.generate(
        5,
        (i) => MinorNation(id: 'minor$i', displayName: 'Minor $i'),
      );
      final tribes = List.generate(
        5,
        (i) => Tribe(id: 'tribe$i', displayName: 'Tribe $i'),
      );
      final game = Game(
        id: 'g-membership',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: players,
        minorNations: minors,
        tribes: tribes,
      );
      final membership = DiplomacyFactionMembership.from(game);
      final allIds = <String>[
        ...players.map((p) => p.id),
        ...minors.map((m) => m.id),
        ...tribes.map((t) => t.id),
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
