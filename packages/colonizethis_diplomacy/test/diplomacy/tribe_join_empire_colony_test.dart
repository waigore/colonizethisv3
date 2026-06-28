import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/src/game_player_lookup.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/diplomacy_resolver_phase_test_support.dart';

/// Tribe Join Empire → colony outcome (Refs #3753 R5 / S7).
/// SPEC/game/diplomacy.md § GP–Tribe Rules (Join Empire → colony).
void main() {
  const ow = 'oldWorld';

  Game baseColonyGame() => diplomacyResolverPhaseTestBaseGame().copyWith(
    players: const [
      Player(id: 'gp1', displayName: 'GP1', isHuman: true, treasury: 15000),
    ],
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: const [
          Province(id: '$ow|t1', regionId: ow, ownerId: 'tribe1'),
          Province(id: '$ow|t2', regionId: ow, ownerId: 'tribe1'),
        ],
        units: const [],
      ),
      newWorld: const RegionData(),
    ),
    overtureStates: const [
      OvertureState(
        gpId: 'gp1',
        targetId: 'tribe1',
        stage: OvertureStage.nap,
        sinceTurn: 0,
      ),
    ],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: 'gp1',
        factionId2: 'tribe1',
        score: 60,
        level: RelationLevel.friendly,
      ),
    ],
  );

  Orders joinEmpireOrder(String targetId) => Orders(
    diplomaticOrdersByPlayerId: {
      'gp1': [
        DiplomaticOrder(
          type: DiplomaticOrderType.establishOverture,
          targetFactionId: targetId,
          overtureStage: OvertureStage.joinEmpire,
        ),
      ],
    },
  );

  group('Tribe Join Empire → colony', () {
    test(
      'tribe becomes colony: stays in game, provinces not transferred, '
      'ColonyState recorded, cost deducted',
      () {
        final after = resolveDiplomacyPhase(
          baseColonyGame(),
          joinEmpireOrder('tribe1'),
        ).game;

        expect(
          after.tribes.any((t) => t.id == 'tribe1'),
          isTrue,
          reason: 'colony tribe stays in the game',
        );
        final t1 = after.worldState.oldWorld.provinces
            .singleWhere((p) => p.id == '$ow|t1');
        final t2 = after.worldState.oldWorld.provinces
            .singleWhere((p) => p.id == '$ow|t2');
        expect(t1.ownerId, 'tribe1');
        expect(t2.ownerId, 'tribe1');

        expect(after.colonyStates, hasLength(1));
        final colony = after.colonyStates.single;
        expect(colony.tribeId, 'tribe1');
        expect(colony.colonyOfGpId, 'gp1');
        expect(colony.sinceTurn, 1);

        // Cost = base 5000 + 2 provinces * 2000 = 9000.
        expect(after.playerById('gp1')!.treasury, 15000 - 9000);
      },
    );

    test('colony tribe preserves its overtures and relations', () {
      final after = resolveDiplomacyPhase(
        baseColonyGame(),
        joinEmpireOrder('tribe1'),
      ).game;

      expect(
        getOverture(after, 'gp1', 'tribe1'),
        isNotNull,
        reason: 'colony path does not clear overtures',
      );
      expect(
        getRelation(after, 'gp1', 'tribe1'),
        isNotNull,
        reason: 'colony path does not clear relations',
      );
    });

    test('re-resolving Tribe Join Empire keeps a single ColonyState', () {
      var game = baseColonyGame();
      game = resolveDiplomacyPhase(game, joinEmpireOrder('tribe1')).game;
      // Restore a NAP overture so a second Join Empire order is applicable.
      game = game.copyWith(
        players: const [
          Player(
            id: 'gp1',
            displayName: 'GP1',
            isHuman: true,
            treasury: 15000,
          ),
        ],
        overtureStates: const [
          OvertureState(
            gpId: 'gp1',
            targetId: 'tribe1',
            stage: OvertureStage.nap,
            sinceTurn: 0,
          ),
        ],
      );
      final after = resolveDiplomacyPhase(game, joinEmpireOrder('tribe1')).game;

      expect(
        after.colonyStates.where((c) => c.tribeId == 'tribe1'),
        hasLength(1),
        reason: 'colony record is replaced, not duplicated',
      );
    });

    test(
      'negative: Minor Join Empire still absorbs (no ColonyState recorded)',
      () {
        final game = baseColonyGame().copyWith(
          worldState: WorldState(
            turnState: const TurnState(
              phase: TurnPhase.orders,
              turnNumber: 1,
            ),
            oldWorld: RegionData(
              provinces: const [
                Province(id: '$ow|m1', regionId: ow, ownerId: 'minor1'),
              ],
              units: const [],
            ),
            newWorld: const RegionData(),
          ),
          overtureStates: const [
            OvertureState(
              gpId: 'gp1',
              targetId: 'minor1',
              stage: OvertureStage.nap,
              sinceTurn: 0,
            ),
          ],
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'minor1',
              score: 60,
              level: RelationLevel.friendly,
            ),
          ],
        );

        final after = resolveDiplomacyPhase(
          game,
          joinEmpireOrder('minor1'),
        ).game;

        expect(after.minorNations.any((m) => m.id == 'minor1'), isFalse);
        expect(after.colonyStates, isEmpty);
        expect(
          after.worldState.oldWorld.provinces
              .singleWhere((p) => p.id == '$ow|m1')
              .ownerId,
          'gp1',
        );
      },
    );
  });
}
