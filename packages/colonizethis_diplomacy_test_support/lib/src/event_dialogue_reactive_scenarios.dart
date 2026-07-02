// Table-driven reactive event dialogue scenarios (Refs #3837).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'event_dialogue_test_support.dart';

/// One reactive dialogue test row with preserved [label].
class EventDialogueReactiveScenario {
  const EventDialogueReactiveScenario({required this.label, required this.run});

  final String label;
  final void Function() run;
}

void runEventDialogueReactiveScenario(EventDialogueReactiveScenario scenario) =>
    scenario.run();

final _oldWorldBorderTopology = MapTopology(
  nodes: const [
    TopologyNode(
      id: 'P1',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: 'P2',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
  ],
  edges: const [TopologyEdge(id1: 'P1', id2: 'P2')],
);

/// Reactive scenarios from `event_dialogue_reactive_test.dart`.
List<EventDialogueReactiveScenario> eventDialogueReactiveScenarios() => [
  EventDialogueReactiveScenario(
    label: 'returns empty when builder is AI',
    run: () {
      final game = dialogueGame(
        oldWorldProvinces: const [
          Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'gp2'),
          Province(id: 'oldWorld|P2', regionId: 'oldWorld', ownerId: 'gp1'),
        ],
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'AI', isHuman: false),
        ],
      );
      final events = dialogueEventsForReactiveFortsOnBorder(
        game,
        _oldWorldBorderTopology,
        'gp2',
        'oldWorld|P2',
        0,
      );
      expect(events, isEmpty);
    },
  ),
  EventDialogueReactiveScenario(
    label: 'emits one event per AI neighbor when human builds fort on border',
    run: () {
      final game = dialogueGame(
        oldWorldProvinces: const [
          Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'gp2'),
          Province(id: 'oldWorld|P2', regionId: 'oldWorld', ownerId: 'gp1'),
        ],
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'AI', isHuman: false),
        ],
      );
      final events = dialogueEventsForReactiveFortsOnBorder(
        game,
        _oldWorldBorderTopology,
        'gp1',
        'oldWorld|P2',
        0,
      );
      expect(events.length, 1);
      expect(events.first.leaderId, 'gp2');
      expect(events.first.category, 'reactive');
      expect(events.first.situation, 'forts_on_border');
      expect(events.first.variables['otherNation'], 'gp1');
      expect(events.first.variables['province'], 'oldWorld|P2');
    },
  ),
  EventDialogueReactiveScenario(
    label: 'resolves owner from newWorld when fort built in newWorld',
    run: () {
      const nw = 'newWorld';
      final newWorldTopology = MapTopology(
        nodes: const [
          TopologyNode(id: 'N1', regionId: nw, type: TopologyNodeType.province),
          TopologyNode(id: 'N2', regionId: nw, type: TopologyNodeType.province),
        ],
        edges: const [TopologyEdge(id1: 'N1', id2: 'N2')],
      );
      final game = dialogueGame(
        newWorldProvinces: const [
          Province(id: 'newWorld|N1', regionId: nw, ownerId: 'gp1'),
          Province(id: 'newWorld|N2', regionId: nw, ownerId: 'gp2'),
        ],
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'AI', isHuman: false),
        ],
      );
      final events = dialogueEventsForReactiveFortsOnBorder(
        game,
        newWorldTopology,
        'gp1',
        'newWorld|N1',
        0,
      );
      expect(events.length, 1);
      expect(events.first.leaderId, 'gp2');
      expect(events.first.variables['province'], 'newWorld|N1');
    },
  ),
  EventDialogueReactiveScenario(
    label: 'emits attack_on_ally for AI with a formal alliance with defender',
    run: () {
      final game = dialogueGame(
        turnNumber: 5,
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
            formalAlliance: true,
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
    },
  ),
  EventDialogueReactiveScenario(
    label:
        'suppresses attack_on_ally for informal Allied band without a formal '
        'alliance',
    run: () {
      final game = dialogueGame(
        turnNumber: 5,
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
      expect(events, isEmpty);
    },
  ),
  EventDialogueReactiveScenario(
    label: 'emits attack_on_minor and attack_on_tribe for AI with embassy',
    run: () {
      final game = dialogueGame(
        turnNumber: 5,
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
    },
  ),
  EventDialogueReactiveScenario(
    label: 'tech_discovered emits for AI discoverer only',
    run: () {
      final game = dialogueGame(
        turnNumber: 8,
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
    },
  ),
  EventDialogueReactiveScenario(
    label: 'capital_threatened emits when human attacker targets AI capital',
    run: () {
      final game = dialogueGame(
        turnNumber: 3,
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
    },
  ),
  EventDialogueReactiveScenario(
    label: 'colony_founded emits only for null->AI owner in New World',
    run: () {
      final game = dialogueGame(
        turnNumber: 10,
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
    },
  ),
  EventDialogueReactiveScenario(
    label: 'spies_caught emits only for AI speaker and human spy owner',
    run: () {
      final game = dialogueGame(
        turnNumber: 7,
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
    },
  ),
  EventDialogueReactiveScenario(
    label: 'spies_defected emits only for AI defector and human previous owner',
    run: () {
      final game = dialogueGame(
        turnNumber: 8,
        players: const [
          Player(id: 'h1', displayName: 'Human', isHuman: true),
          Player(id: 'a1', displayName: 'AI', isHuman: false),
        ],
      );
      final events = dialogueEventsForReactiveSpiesDefected(
        game,
        newOwnerId: 'a1',
        previousOwnerId: 'h1',
        provinceId: 'oldWorld|P4',
        turnNumber: 8,
        seed: 0,
      );
      expect(events.single.situation, 'spies_defected');
      expect(events.single.leaderId, 'a1');
    },
  ),
];
