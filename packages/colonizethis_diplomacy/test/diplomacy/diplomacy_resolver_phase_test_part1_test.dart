import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/src/game_player_lookup.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';
void main() {
  group('resolveDiplomacyPhase', () {

    test('overture payments create consulate and embassy when treasury allows', () {
      final game = diplomacyResolverPhaseTestBaseGame();
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp1': const [
            DiplomaticOrder(
              type: DiplomaticOrderType.establishOverture,
              targetFactionId: 'minor1',
              overtureStage: OvertureStage.tradeConsulate,
            ),
            DiplomaticOrder(
              type: DiplomaticOrderType.establishOverture,
              targetFactionId: 'minor1',
              overtureStage: OvertureStage.embassy,
            ),
          ],
        },
      );

      final after = resolveDiplomacyPhase(game, orders).game;
      final overture = getOverture(after, 'gp1', 'minor1');
      expect(overture, isNotNull);
      expect(overture!.hasEmbassy, isTrue);
      // Treasury reduced by consulate + embassy cost.
      final player = after.playerById('gp1')!;
      expect(player.treasury, lessThan(2000));
    });

    test('alliance order sets relation to allied', () {
      final game = diplomacyGame(
        id: 'g1',
        players: const [
          Player(id: 'gp1', displayName: 'GP1', isHuman: true),
          Player(id: 'gp2', displayName: 'GP2', isHuman: true),
        ],
      );
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp1': const [
            DiplomaticOrder(
              type: DiplomaticOrderType.alliance,
              targetFactionId: 'gp2',
            ),
          ],
        },
      );
      final after = resolveDiplomacyPhase(game, orders).game;
      final rel = getRelation(after, 'gp1', 'gp2');
      expect(rel, isNotNull);
      // Alliance is an event delta this turn → per-turn decay is skipped
      // (Refs #3753 R9.4), so the clamped Allied score 76 is preserved.
      expect(rel!.level, RelationLevel.allied);
      expect(rel.score, 76);
    });

    test('declare war and offer peace update relation state', () {
      final game = diplomacyResolverPhaseTestBaseGame();
      final declareOrders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp1': const [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'minor1',
            ),
          ],
        },
      );

      final afterWar = resolveDiplomacyPhase(game, declareOrders).game;
      final relWar = getRelation(afterWar, 'gp1', 'minor1')!;
      expect(relWar.atWar, isTrue);

      final peaceOrders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp1': const [
            DiplomaticOrder(
              type: DiplomaticOrderType.offerPeace,
              targetFactionId: 'minor1',
            ),
          ],
        },
      );
      final afterPeace = resolveDiplomacyPhase(afterWar, peaceOrders).game;
      final relPeace = getRelation(afterPeace, 'gp1', 'minor1')!;
      expect(relPeace.atPeace, isTrue);
    });

    test('declare war when already at peace updates existing relation', () {
      var game = diplomacyResolverPhaseTestBaseGame().copyWith(
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'minor1',
            score: 60,
            level: RelationLevel.friendly,
            state: RelationState.atPeace,
          ),
        ],
      );
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp1': const [
            DiplomaticOrder(type: DiplomaticOrderType.declareWar, targetFactionId: 'minor1'),
          ],
        },
      );
      final after = resolveDiplomacyPhase(game, orders).game;
      final rel = getRelation(after, 'gp1', 'minor1')!;
      expect(rel.atWar, isTrue);
      expect(rel.score, lessThan(60));
    });

    test('grantAid requires embassy and improves relations', () {
      var game = diplomacyResolverPhaseTestBaseGame().copyWith(
        overtureStates: const [
          OvertureState(
            gpId: 'gp1',
            targetId: 'minor1',
            stage: OvertureStage.embassy,
            sinceTurn: 0,
          ),
        ],
      );
      final initialRel = DiplomacyRelation(
        factionId1: 'gp1',
        factionId2: 'minor1',
        score: 50,
        level: RelationLevel.neutral,
      );
      game = game.copyWith(diplomacyRelations: [initialRel]);

      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp1': const [
            DiplomaticOrder(
              type: DiplomaticOrderType.grantAid,
              targetFactionId: 'minor1',
              amount: 1000,
            ),
          ],
        },
      );

      final after = resolveDiplomacyPhase(game, orders).game;
      final rel = getRelation(after, 'gp1', 'minor1')!;
      expect(rel.score, greaterThan(initialRel.score));
      expect(tradeSlotsForGp(after, 'gp1', 'minor1'), 3);
      expect(after.playerById('gp1')!.treasury, 2000 - 1000);
    });

    test('grantAid at resolution with wrong multiple throws StateError', () {
      var game = diplomacyResolverPhaseTestBaseGame().copyWith(
        overtureStates: const [
          OvertureState(
            gpId: 'gp1',
            targetId: 'minor1',
            stage: OvertureStage.embassy,
            sinceTurn: 0,
          ),
        ],
      );
      game = game.copyWith(
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'minor1',
            score: 50,
            level: RelationLevel.neutral,
          ),
        ],
      );
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp1': const [
            DiplomaticOrder(
              type: DiplomaticOrderType.grantAid,
              targetFactionId: 'minor1',
              amount: 500,
            ),
          ],
        },
      );
      expect(
        () => resolveDiplomacyPhase(game, orders),
        throwsStateError,
      );
    });

    test('join empire absorbs minor: provinces transfer, minor removed, cost deducted', () {
      const ow = 'oldWorld';
      var game = diplomacyResolverPhaseTestBaseGame().copyWith(
        players: const [
          Player(id: 'gp1', displayName: 'GP1', isHuman: true, treasury: 15000),
        ],
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|m1', regionId: ow, ownerId: 'minor1'),
              Province(id: '$ow|m2', regionId: ow, ownerId: 'minor1'),
            ],
            units: [],
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
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'minor1',
            score: 60,
            level: RelationLevel.friendly,
          ),
        ],
      );
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp1': const [
            DiplomaticOrder(
              type: DiplomaticOrderType.establishOverture,
              targetFactionId: 'minor1',
              overtureStage: OvertureStage.joinEmpire,
            ),
          ],
        },
      );
      final after = resolveDiplomacyPhase(game, orders).game;
      expect(after.minorNations.any((m) => m.id == 'minor1'), isFalse);
      expect(getOverture(after, 'gp1', 'minor1'), isNull);
      final p1 = after.worldState.oldWorld.provinces
          .where((p) => p.id == '$ow|m1')
          .firstOrNull;
      final p2 = after.worldState.oldWorld.provinces
          .where((p) => p.id == '$ow|m2')
          .firstOrNull;
      expect(p1?.ownerId, 'gp1');
      expect(p2?.ownerId, 'gp1');
      // Cost = 5000 + 2*2000 = 9000
      expect(after.playerById('gp1')!.treasury, 15000 - 9000);
    });

    test('join empire clears Spy timers for provinces that become owned by GP', () {
      const ow = 'oldWorld';
      // gp1 has an active Spy timer for minor-owned province m1; after Join Empire,
      // gp1 owns m1 and the timer must be cleared without changing visibility.
      var game = diplomacyResolverPhaseTestBaseGame().copyWith(
        players: const [
          Player(id: 'gp1', displayName: 'GP1', isHuman: true, treasury: 15000),
        ],
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: '$ow|m1', regionId: ow, ownerId: 'minor1'),
            ],
            units: [],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'gp1': {
              'oldWorld|m1|0|0': 'fullyVisible',
            },
          },
          spyRevealTurnsByPlayer: const {
            'gp1': {
              '$ow|m1': 3,
            },
          },
          tileKeysByRegionAndProvince: const {
            ow: {
              '$ow|m1': ['oldWorld|m1|0|0'],
            },
          },
        ),
        overtureStates: const [
          OvertureState(
            gpId: 'gp1',
            targetId: 'minor1',
            stage: OvertureStage.nap,
            sinceTurn: 0,
          ),
        ],
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'minor1',
            score: 60,
            level: RelationLevel.friendly,
          ),
        ],
      );

      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp1': const [
            DiplomaticOrder(
              type: DiplomaticOrderType.establishOverture,
              targetFactionId: 'minor1',
              overtureStage: OvertureStage.joinEmpire,
            ),
          ],
        },
      );

      final after = resolveDiplomacyPhase(game, orders).game;
      // Province now owned by gp1.
      final p1 = after.worldState.oldWorld.provinces
          .where((p) => p.id == '$ow|m1')
          .firstOrNull;
      expect(p1?.ownerId, 'gp1');
      // Spy timer for (gp1, m1) is cleared.
      expect(after.worldState.spyRevealTurnsByPlayer['gp1'], isNull);
      // Tile visibility for gp1 remains fullyVisible.
      expect(
        after.worldState.playerVisibilityByTile['gp1']?['oldWorld|m1|0|0'],
        'fullyVisible',
      );
    });

  });
}
