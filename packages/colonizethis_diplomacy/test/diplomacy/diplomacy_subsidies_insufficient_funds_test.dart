import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/src/game_player_lookup.dart';

void main() {
  group('processOngoingSubsidies treasury independence (Refs #3753 R3)', () {
    test(
      'a low-treasury payer keeps a valid Minor subsidy (no per-turn payment)',
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
            Player(id: 'gp1', displayName: 'GP1', isHuman: true, treasury: 0),
          ],
          minorNations: const [
            MinorNation(id: 'minor1', displayName: 'Minor 1'),
          ],
          diplomacyRelations: const [
            DiplomacyRelation(factionId1: 'gp1', factionId2: 'minor1'),
          ],
          overtureStates: const [
            OvertureState(
              gpId: 'gp1',
              targetId: 'minor1',
              stage: OvertureStage.embassy,
              sinceTurn: 0,
            ),
          ],
          subsidyStates: const [
            SubsidyState(payerId: 'gp1', targetId: 'minor1', percent: 20),
          ],
        );

        final membership = DiplomacyFactionMembership.from(game);
        final out = processOngoingSubsidies(
          game,
          2,
          factionMembership: membership,
        );

        // Percent subsidies charge no per-turn payment, so a broke payer keeps
        // the subsidy and the treasury is untouched.
        expect(out.subsidyStates.length, 1);
        expect(out.subsidyStates.single.percent, 20);
        expect(out.playerById('gp1')!.treasury, 0);
      },
    );
  });
}
