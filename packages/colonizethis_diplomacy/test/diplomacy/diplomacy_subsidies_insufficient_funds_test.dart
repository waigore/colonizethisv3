import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/src/game_player_lookup.dart';

void main() {
  group('processOngoingSubsidies insufficient funds', () {
    test(
      'removes subsidy state and leaves treasuries unchanged (Refs #2394)',
      () {
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.diplomacy,
              turnNumber: 2,
            ),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp1', displayName: 'GP1', isHuman: true, treasury: 100),
            Player(
              id: 'gp2',
              displayName: 'GP2',
              isHuman: false,
              treasury: 1000,
            ),
          ],
          diplomacyRelations: const [
            DiplomacyRelation(factionId1: 'gp1', factionId2: 'gp2'),
          ],
          subsidyStates: const [
            SubsidyState(payerId: 'gp1', targetId: 'gp2', amountPerTurn: 500),
          ],
        );

        final membership = DiplomacyFactionMembership.from(game);
        final out = processOngoingSubsidies(
          game,
          2,
          factionMembership: membership,
        );

        expect(out.subsidyStates, isEmpty);
        expect(out.playerById('gp1')!.treasury, 100);
        expect(out.playerById('gp2')!.treasury, 1000);
      },
    );
  });
}
