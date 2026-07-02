// Table-driven resolveDiplomacyPhase scenarios (Refs #3837).

import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/src/game_player_lookup.dart';

import 'diplomacy_game_fixtures.dart';
import 'diplomacy_phase_scenarios.dart';
import 'diplomacy_resolver_phase_test_support.dart';

/// One phase-resolver integration row with preserved [label].
class DiplomacyPhaseScenario {
  const DiplomacyPhaseScenario({required this.label, required this.run});

  final String label;
  final void Function() run;
}

void runDiplomacyPhaseScenario(DiplomacyPhaseScenario scenario) => scenario.run();

/// Overture, alliance, and war/peace scenarios from part 1 integration tests.
List<DiplomacyPhaseScenario> diplomacyResolverPhasePart1WarPeaceScenarios() => [
  DiplomacyPhaseScenario(
    label: 'overture payments create consulate and embassy when treasury allows',
    run: () {
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
      final player = after.playerById('gp1')!;
      expect(player.treasury, lessThan(2000));
    },
  ),
  DiplomacyPhaseScenario(
    label: 'alliance order sets relation to allied',
    run: () {
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
      expect(rel!.level, RelationLevel.allied);
      expect(rel.score, 76);
    },
  ),
  DiplomacyPhaseScenario(
    label: 'declare war and offer peace update relation state',
    run: () {
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
    },
  ),
  DiplomacyPhaseScenario(
    label: 'declare war when already at peace updates existing relation',
    run: () {
      final game = diplomacyResolverPhaseTestBaseGame().copyWith(
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
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'minor1',
            ),
          ],
        },
      );
      final after = resolveDiplomacyPhase(game, orders).game;
      final rel = getRelation(after, 'gp1', 'minor1')!;
      expect(rel.atWar, isTrue);
      expect(rel.score, lessThan(60));
    },
  ),
];

/// Grant-aid scenarios from part 1 integration tests.
List<DiplomacyPhaseScenario> diplomacyResolverPhasePart1GrantAidScenarios() => [
  DiplomacyPhaseScenario(
    label: 'grantAid requires embassy and improves relations',
    run: () {
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
    },
  ),
  DiplomacyPhaseScenario(
    label: 'grantAid at resolution with wrong multiple throws StateError',
    run: () {
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
      expect(() => resolveDiplomacyPhase(game, orders), throwsStateError);
    },
  ),
];

/// Join-empire scenarios from part 1 integration tests.
List<DiplomacyPhaseScenario> diplomacyResolverPhasePart1JoinEmpireScenarios() => [
  DiplomacyPhaseScenario(
    label:
        'join empire absorbs minor: provinces transfer, minor removed, cost deducted',
    run: () {
      const ow = 'oldWorld';
      final game = diplomacyResolverPhaseTestBaseGame().copyWith(
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
      expect(after.playerById('gp1')!.treasury, 15000 - 9000);
    },
  ),
  DiplomacyPhaseScenario(
    label: 'join empire clears Spy timers for provinces that become owned by GP',
    run: () {
      const ow = 'oldWorld';
      final game = diplomacyResolverPhaseTestBaseGame().copyWith(
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
      final p1 = after.worldState.oldWorld.provinces
          .where((p) => p.id == '$ow|m1')
          .firstOrNull;
      expect(p1?.ownerId, 'gp1');
      expect(after.worldState.spyRevealTurnsByPlayer['gp1'], isNull);
      expect(
        after.worldState.playerVisibilityByTile['gp1']?['oldWorld|m1|0|0'],
        'fullyVisible',
      );
    },
  ),
];

/// Part 1 scenarios from `diplomacy_resolver_phase_test_part1_test.dart`.
List<DiplomacyPhaseScenario> diplomacyResolverPhasePart1Scenarios() => [
  ...diplomacyResolverPhasePart1WarPeaceScenarios(),
  ...diplomacyResolverPhasePart1GrantAidScenarios(),
  ...diplomacyResolverPhasePart1JoinEmpireScenarios(),
];

/// Part 2 scenarios from `diplomacy_resolver_phase_test_part2_test.dart`.
List<DiplomacyPhaseScenario> diplomacyResolverPhasePart2Scenarios() => [
  DiplomacyPhaseScenario(
    label: 'returns game when there are no diplomatic orders',
    run: () {
      final game = diplomacyResolverPhaseTestBaseGame();
      final result = resolveDiplomacyPhase(game, const Orders());
      expect(result.game.id, game.id);
    },
  ),
  DiplomacyPhaseScenario(
    label:
        'setSubsidy at resolution with invalid percent is skipped, not thrown '
        '(Refs #3753 R3)',
    run: () {
      final game = gpMinorEmbassyNeutralPhaseGame();
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp1': const [
            DiplomaticOrder(
              type: DiplomaticOrderType.setSubsidy,
              targetFactionId: 'minor1',
              amount: 7,
            ),
          ],
        },
      );
      final after = resolveDiplomacyPhase(game, orders).game;
      expect(after.subsidyStates, isEmpty);
    },
  ),
  DiplomacyPhaseScenario(
    label:
        'setSubsidy at resolution with valid percent records SubsidyState '
        '(Refs #3753 R3)',
    run: () {
      final game = gpMinorEmbassyNeutralPhaseGame();
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp1': const [
            DiplomaticOrder(
              type: DiplomaticOrderType.setSubsidy,
              targetFactionId: 'minor1',
              amount: 10,
            ),
          ],
        },
      );
      final after = resolveDiplomacyPhase(game, orders).game;
      expect(after.subsidyStates, hasLength(1));
      expect(after.subsidyStates.single.percent, 10);
      expect(after.subsidyStates.single.targetId, 'minor1');
    },
  ),
];
