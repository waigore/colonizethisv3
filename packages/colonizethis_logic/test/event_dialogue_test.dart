// Tests for event dialogue (battle result, reactive, negotiation). SPEC/ai/dialogue-and-mood.md, SPEC/program/ai-events-and-dossier.md.

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('dialogueEventsForLandBattleResult', () {
    test(
      'AI victor and AI loser both emit event with era from turn-time mapping',
      () {
        const mapping = TurnTimeMapping.gdd01;
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp1', displayName: 'Human', isHuman: true),
            Player(id: 'gp2', displayName: 'AI Victor', isHuman: false),
            Player(id: 'gp3', displayName: 'AI Loser', isHuman: false),
          ],
        );
        final expectedEra = eraFromYear(mapping.yearAtTurn(2));
        final events = dialogueEventsForLandBattleResult(
          game,
          'gp2',
          'gp3',
          'ow|prov1',
          2,
          12345,
        );
        expect(events.length, 2);
        final won = events.where((e) => e.situation == 'battle_won').toList();
        final lost = events.where((e) => e.situation == 'battle_lost').toList();
        expect(won.length, 1);
        expect(lost.length, 1);
        expect(won.first.leaderId, 'gp2');
        expect(won.first.category, 'event');
        expect(won.first.era, expectedEra);
        expect(won.first.variables['otherNation'], 'gp3');
        expect(won.first.variables['province'], 'ow|prov1');
        expect(lost.first.leaderId, 'gp3');
        expect(lost.first.variables['otherNation'], 'gp2');
      },
    );

    test('human victor returns no dialogue for victor', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'AI', isHuman: false),
        ],
      );
      final events = dialogueEventsForLandBattleResult(
        game,
        'gp1',
        'gp2',
        'ow|p1',
        2,
        0,
      );
      expect(events.length, 1);
      expect(events.first.situation, 'battle_lost');
      expect(events.first.leaderId, 'gp2');
    });

    test('human loser returns only battle_won for AI victor', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'AI', isHuman: false),
        ],
      );
      final events = dialogueEventsForLandBattleResult(
        game,
        'gp2',
        'gp1',
        'ow|p1',
        2,
        0,
      );
      expect(events.length, 1);
      expect(events.first.situation, 'battle_won');
      expect(events.first.leaderId, 'gp2');
    });
  });

  group('dialogueEventsForNavalBattleResult', () {
    test('AI victor and AI loser both emit event', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 3),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'AI Victor', isHuman: false),
          Player(id: 'gp3', displayName: 'AI Loser', isHuman: false),
        ],
      );
      final events = dialogueEventsForNavalBattleResult(
        game,
        'gp2',
        'gp3',
        3,
        999,
      );
      expect(events.length, 2);
      expect(
        events.any((e) => e.situation == 'battle_won' && e.leaderId == 'gp2'),
        isTrue,
      );
      expect(
        events.any((e) => e.situation == 'battle_lost' && e.leaderId == 'gp3'),
        isTrue,
      );
      expect(events.first.variables['otherNation'], isNotNull);
    });

    test('human victor returns only battle_lost for AI loser', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'AI', isHuman: false),
        ],
      );
      final events = dialogueEventsForNavalBattleResult(
        game,
        'gp1',
        'gp2',
        1,
        0,
      );
      expect(events.length, 1);
      expect(events.first.situation, 'battle_lost');
      expect(events.first.leaderId, 'gp2');
    });
  });

  group('eraFromYear', () {
    test('maps year to dialogue era bands', () {
      expect(eraFromYear(1599), 'discovery');
      expect(eraFromYear(1600), 'earlyModern');
      expect(eraFromYear(1699), 'earlyModern');
      expect(eraFromYear(1700), 'imperial');
      expect(eraFromYear(1799), 'imperial');
      expect(eraFromYear(1800), 'industrial');
    });
  });

  group('dialogueEventsForEraChange', () {
    test('emits one event per AI leader with era_change situation', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 100),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'AI', isHuman: false),
          Player(id: 'gp3', displayName: 'AI', isHuman: false),
        ],
      );
      final events = dialogueEventsForEraChange(
        game,
        'earlyModern',
        'imperial',
        42,
      );
      expect(events.length, 2);
      for (final e in events) {
        expect(e.category, 'event');
        expect(e.situation, 'era_change');
        expect(e.era, 'imperial');
        expect(e.variables['previousEra'], 'earlyModern');
        expect(['gp2', 'gp3'], contains(e.leaderId));
      }
    });

    test('emits no events when all players are human', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 100),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'Human', isHuman: true),
        ],
      );
      final events = dialogueEventsForEraChange(
        game,
        'earlyModern',
        'imperial',
        0,
      );
      expect(events, isEmpty);
    });
  });

  group('dialogueEventsForReactiveFortsOnBorder', () {
    test('returns empty when builder is AI', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'P1',
            regionId: 'ow',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'P2',
            regionId: 'ow',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [TopologyEdge(id1: 'P1', id2: 'P2')],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: 'ow|P1', regionId: 'ow', ownerId: 'gp2'),
              Province(id: 'ow|P2', regionId: 'ow', ownerId: 'gp1'),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'AI', isHuman: false),
        ],
      );
      final events = dialogueEventsForReactiveFortsOnBorder(
        game,
        topology,
        'gp2',
        'ow|P2',
        0,
      );
      expect(events, isEmpty);
    });

    test(
      'emits one event per AI neighbor when human builds fort on border',
      () {
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'P1',
              regionId: 'ow',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'P2',
              regionId: 'ow',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [TopologyEdge(id1: 'P1', id2: 'P2')],
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [
                Province(id: 'ow|P1', regionId: 'ow', ownerId: 'gp2'),
                Province(id: 'ow|P2', regionId: 'ow', ownerId: 'gp1'),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp1', displayName: 'Human', isHuman: true),
            Player(id: 'gp2', displayName: 'AI', isHuman: false),
          ],
        );
        final events = dialogueEventsForReactiveFortsOnBorder(
          game,
          topology,
          'gp1',
          'ow|P2',
          0,
        );
        expect(events.length, 1);
        expect(events.first.leaderId, 'gp2');
        expect(events.first.category, 'reactive');
        expect(events.first.situation, 'forts_on_border');
        expect(events.first.variables['otherNation'], 'gp1');
        expect(events.first.variables['province'], 'ow|P2');
      },
    );

    test('resolves owner from newWorld when fort built in newWorld', () {
      const nw = 'newWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'N1', regionId: nw, type: TopologyNodeType.province),
          TopologyNode(id: 'N2', regionId: nw, type: TopologyNodeType.province),
        ],
        edges: const [TopologyEdge(id1: 'N1', id2: 'N2')],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: RegionData(
            provinces: [
              Province(id: 'newWorld|N1', regionId: nw, ownerId: 'gp1'),
              Province(id: 'newWorld|N2', regionId: nw, ownerId: 'gp2'),
            ],
          ),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'AI', isHuman: false),
        ],
      );
      final events = dialogueEventsForReactiveFortsOnBorder(
        game,
        topology,
        'gp1',
        'newWorld|N1',
        0,
      );
      expect(events.length, 1);
      expect(events.first.leaderId, 'gp2');
      expect(events.first.variables['province'], 'newWorld|N1');
    });
  });

  group('dialogueEventForNegotiation', () {
    test('builds event with category negotiation and optional mood', () {
      final e = dialogueEventForNegotiation(
        leaderId: 'gp1',
        situation: 'counter_offer',
        era: 'earlyModern',
        mood: 'skeptical',
        variables: {'offer': 'gold'},
      );
      expect(e.leaderId, 'gp1');
      expect(e.category, 'negotiation');
      expect(e.situation, 'counter_offer');
      expect(e.era, 'earlyModern');
      expect(e.mood, 'skeptical');
      expect(e.variables['offer'], 'gold');
    });

    test('builds event without mood', () {
      final e = dialogueEventForNegotiation(
        leaderId: 'gp2',
        situation: 'opening',
        era: 'imperial',
      );
      expect(e.category, 'negotiation');
      expect(e.situation, 'opening');
      expect(e.mood, isNull);
    });
  });

  group('dialogueEventsForReactiveHumanAttack', () {
    test('emits attack_on_ally for AI allied with defender', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 5),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'human', displayName: 'Human', isHuman: true),
          Player(id: 'ai1', displayName: 'AI', isHuman: false),
          Player(id: 'ai2', displayName: 'AI Defender', isHuman: false),
        ],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'ai1',
            factionId2: 'ai2',
            level: RelationLevel.allied,
            state: RelationState.atPeace,
          ),
        ],
      );
      final events = dialogueEventsForReactiveHumanAttack(
        game,
        attackerFactionId: 'human',
        defenderFactionId: 'ai2',
        provinceId: 'oldWorld|P1',
        turnNumber: 5,
        seed: 1,
      );
      expect(events.length, 1);
      expect(events.first.leaderId, 'ai1');
      expect(events.first.situation, 'attack_on_ally');
    });

    test('emits attack_on_minor and attack_on_tribe for AI with embassy', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 5),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'human', displayName: 'Human', isHuman: true),
          Player(id: 'ai1', displayName: 'AI', isHuman: false),
        ],
        minorNations: const [MinorNation(id: 'mn1')],
        tribes: const [Tribe(id: 'tr1')],
        overtureStates: const [
          OvertureState(
            gpId: 'ai1',
            targetId: 'mn1',
            stage: OvertureStage.embassy,
          ),
          OvertureState(
            gpId: 'ai1',
            targetId: 'tr1',
            stage: OvertureStage.embassy,
          ),
        ],
      );
      final minorEvents = dialogueEventsForReactiveHumanAttack(
        game,
        attackerFactionId: 'human',
        defenderFactionId: 'mn1',
        provinceId: 'oldWorld|P9',
        turnNumber: 5,
        seed: 1,
      );
      final tribeEvents = dialogueEventsForReactiveHumanAttack(
        game,
        attackerFactionId: 'human',
        defenderFactionId: 'tr1',
        provinceId: 'newWorld|N2',
        turnNumber: 5,
        seed: 1,
      );
      expect(minorEvents.single.situation, 'attack_on_minor');
      expect(tribeEvents.single.situation, 'attack_on_tribe');
    });
  });

  group('additional event/reactive situations', () {
    test('tech_discovered emits for AI discoverer only', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 8),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'h1', displayName: 'Human', isHuman: true),
          Player(id: 'a1', displayName: 'AI', isHuman: false),
        ],
      );
      final aiEvents = dialogueEventsForTechDiscovered(
        game,
        discovererId: 'a1',
        techId: 'rifling',
        turnNumber: 8,
        seed: 0,
      );
      final humanEvents = dialogueEventsForTechDiscovered(
        game,
        discovererId: 'h1',
        techId: 'rifling',
        turnNumber: 8,
        seed: 0,
      );
      expect(aiEvents.single.situation, 'tech_discovered');
      expect(humanEvents, isEmpty);
    });

    test('capital_threatened emits when human attacker targets AI capital', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 3),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'h1', displayName: 'Human', isHuman: true),
          Player(
            id: 'a1',
            displayName: 'AI',
            isHuman: false,
            capitalProvinceId: 'oldWorld|P2',
          ),
        ],
      );
      final events = dialogueEventsForCapitalThreatened(
        game,
        capitalOwnerId: 'a1',
        provinceId: 'oldWorld|P2',
        attackerFactionIds: const ['h1'],
        turnNumber: 3,
        seed: 0,
      );
      expect(events.single.situation, 'capital_threatened');
    });

    test('colony_founded emits only for null->AI owner in New World', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 10),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'a1', displayName: 'AI', isHuman: false)],
      );
      final yes = dialogueEventsForColonyFounded(
        game,
        provinceId: 'newWorld|N1',
        previousOwnerId: null,
        newOwnerId: 'a1',
        turnNumber: 10,
        seed: 0,
      );
      final no = dialogueEventsForColonyFounded(
        game,
        provinceId: 'oldWorld|P1',
        previousOwnerId: null,
        newOwnerId: 'a1',
        turnNumber: 10,
        seed: 0,
      );
      expect(yes.single.situation, 'colony_founded');
      expect(no, isEmpty);
    });

    test('spies_caught emits only for AI speaker and human spy owner', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 7),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'h1', displayName: 'Human', isHuman: true),
          Player(id: 'a1', displayName: 'AI', isHuman: false),
        ],
      );
      final events = dialogueEventsForReactiveSpiesCaught(
        game,
        speakerId: 'a1',
        caughtSpyOwnerId: 'h1',
        provinceId: 'oldWorld|P4',
        turnNumber: 7,
        seed: 0,
      );
      expect(events.single.situation, 'spies_caught');
    });
  });
}
