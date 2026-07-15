// Table-driven reactive event dialogue scenarios (Refs #3837 / #4028).

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

EventDialogueReactiveScenario _row(String label, void Function() run) =>
    EventDialogueReactiveScenario(label: label, run: run);

const _humanAi = [
  Player(id: 'gp1', displayName: 'Human', isHuman: true),
  Player(id: 'gp2', displayName: 'AI', isHuman: false),
];

const _h1a1 = [
  Player(id: 'h1', displayName: 'Human', isHuman: true),
  Player(id: 'a1', displayName: 'AI', isHuman: false),
];

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

Game _borderOwGame() => dialogueGame(
      oldWorldProvinces: const [
        Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'gp2'),
        Province(id: 'oldWorld|P2', regionId: 'oldWorld', ownerId: 'gp1'),
      ],
      players: _humanAi,
    );

Game _humanAttackGame({
  required List<DiplomacyRelation> diplomacyRelations,
}) =>
    dialogueGame(
      turnNumber: 5,
      players: const [
        Player(id: 'human', displayName: 'Human', isHuman: true),
        Player(id: 'ai1', displayName: 'AI', isHuman: false),
        Player(id: 'ai2', displayName: 'AI Defender', isHuman: false),
      ],
      diplomacyRelations: diplomacyRelations,
    );

List<DialogueEvent> _humanAttack(Game game) => dialogueEventsForReactiveHumanAttack(
      game,
      attackerFactionId: 'human',
      defenderFactionId: 'ai2',
      provinceId: 'oldWorld|P1',
      turnNumber: 5,
      seed: 1,
    );

/// Forts-on-border reactive scenarios from `event_dialogue_reactive_test.dart`.
List<EventDialogueReactiveScenario> eventDialogueReactiveFortsOnBorderScenarios() => [
  _row('returns empty when builder is AI', () {
    expect(
      dialogueEventsForReactiveFortsOnBorder(
        _borderOwGame(),
        _oldWorldBorderTopology,
        'gp2',
        'oldWorld|P2',
        0,
      ),
      isEmpty,
    );
  }),
  _row('emits one event per AI neighbor when human builds fort on border', () {
    final events = dialogueEventsForReactiveFortsOnBorder(
      _borderOwGame(),
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
  }),
  _row('resolves owner from newWorld when fort built in newWorld', () {
    const nw = 'newWorld';
    final events = dialogueEventsForReactiveFortsOnBorder(
      dialogueGame(
        newWorldProvinces: const [
          Province(id: 'newWorld|N1', regionId: nw, ownerId: 'gp1'),
          Province(id: 'newWorld|N2', regionId: nw, ownerId: 'gp2'),
        ],
        players: _humanAi,
      ),
      MapTopology(
        nodes: const [
          TopologyNode(id: 'N1', regionId: nw, type: TopologyNodeType.province),
          TopologyNode(id: 'N2', regionId: nw, type: TopologyNodeType.province),
        ],
        edges: const [TopologyEdge(id1: 'N1', id2: 'N2')],
      ),
      'gp1',
      'newWorld|N1',
      0,
    );
    expect(events.length, 1);
    expect(events.first.leaderId, 'gp2');
    expect(events.first.variables['province'], 'newWorld|N1');
  }),
];

/// Human-attack reactive scenarios from `event_dialogue_reactive_test.dart`.
List<EventDialogueReactiveScenario> eventDialogueReactiveHumanAttackScenarios() => [
  _row('emits attack_on_ally for AI with a formal alliance with defender', () {
    final events = _humanAttack(
      _humanAttackGame(
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'ai1',
            factionId2: 'ai2',
            level: RelationLevel.allied,
            state: RelationState.atPeace,
            formalAlliance: true,
          ),
        ],
      ),
    );
    expect(events.length, 1);
    expect(events.first.leaderId, 'ai1');
    expect(events.first.situation, 'attack_on_ally');
  }),
  _row(
    'suppresses attack_on_ally for informal Allied band without a formal '
    'alliance',
    () {
      expect(
        _humanAttack(
          _humanAttackGame(
            diplomacyRelations: const [
              DiplomacyRelation(
                factionId1: 'ai1',
                factionId2: 'ai2',
                level: RelationLevel.allied,
                state: RelationState.atPeace,
              ),
            ],
          ),
        ),
        isEmpty,
      );
    },
  ),
  _row('emits attack_on_minor and attack_on_tribe for AI with embassy', () {
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
    expect(
      dialogueEventsForReactiveHumanAttack(
        game,
        attackerFactionId: 'human',
        defenderFactionId: 'mn1',
        provinceId: 'oldWorld|P9',
        turnNumber: 5,
        seed: 1,
      ).single.situation,
      'attack_on_minor',
    );
    expect(
      dialogueEventsForReactiveHumanAttack(
        game,
        attackerFactionId: 'human',
        defenderFactionId: 'tr1',
        provinceId: 'newWorld|N2',
        turnNumber: 5,
        seed: 1,
      ).single.situation,
      'attack_on_tribe',
    );
  }),
];

/// Tech, capital, colony, and spy reactive scenarios.
List<EventDialogueReactiveScenario> eventDialogueReactiveDiscoveryAndSpyScenarios() => [
  _row('tech_discovered emits for AI discoverer only', () {
    final game = dialogueGame(turnNumber: 8, players: _h1a1);
    expect(
      dialogueEventsForTechDiscovered(
        game,
        discovererId: 'a1',
        techId: 'rifling',
        turnNumber: 8,
        seed: 0,
      ).single.situation,
      'tech_discovered',
    );
    expect(
      dialogueEventsForTechDiscovered(
        game,
        discovererId: 'h1',
        techId: 'rifling',
        turnNumber: 8,
        seed: 0,
      ),
      isEmpty,
    );
  }),
  _row('capital_threatened emits when human attacker targets AI capital', () {
    final events = dialogueEventsForCapitalThreatened(
      dialogueGame(
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
      ),
      capitalOwnerId: 'a1',
      provinceId: 'oldWorld|P2',
      attackerFactionIds: const ['h1'],
      turnNumber: 3,
      seed: 0,
    );
    expect(events.single.situation, 'capital_threatened');
  }),
  _row('colony_founded emits only for null->AI owner in New World', () {
    final game = dialogueGame(
      turnNumber: 10,
      players: const [Player(id: 'a1', displayName: 'AI', isHuman: false)],
    );
    expect(
      dialogueEventsForColonyFounded(
        game,
        provinceId: 'newWorld|N1',
        previousOwnerId: null,
        newOwnerId: 'a1',
        turnNumber: 10,
        seed: 0,
      ).single.situation,
      'colony_founded',
    );
    expect(
      dialogueEventsForColonyFounded(
        game,
        provinceId: 'oldWorld|P1',
        previousOwnerId: null,
        newOwnerId: 'a1',
        turnNumber: 10,
        seed: 0,
      ),
      isEmpty,
    );
  }),
  _row('spies_caught emits only for AI speaker and human spy owner', () {
    expect(
      dialogueEventsForReactiveSpiesCaught(
        dialogueGame(turnNumber: 7, players: _h1a1),
        speakerId: 'a1',
        caughtSpyOwnerId: 'h1',
        provinceId: 'oldWorld|P4',
        turnNumber: 7,
        seed: 0,
      ).single.situation,
      'spies_caught',
    );
  }),
  _row('spies_defected emits only for AI defector and human previous owner', () {
    final events = dialogueEventsForReactiveSpiesDefected(
      dialogueGame(turnNumber: 8, players: _h1a1),
      newOwnerId: 'a1',
      previousOwnerId: 'h1',
      provinceId: 'oldWorld|P4',
      turnNumber: 8,
      seed: 0,
    );
    expect(events.single.situation, 'spies_defected');
    expect(events.single.leaderId, 'a1');
  }),
];
