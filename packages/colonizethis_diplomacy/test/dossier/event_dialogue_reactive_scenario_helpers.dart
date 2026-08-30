// Table-driven reactive event dialogue scenarios (Refs #3837 / #4028 / #4130).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';

class EventDialogueReactiveScenario {
  const EventDialogueReactiveScenario({required this.label, required this.run});

  final String label;
  final void Function() run;
}

void runEventDialogueReactiveScenario(EventDialogueReactiveScenario scenario) =>
    scenario.run();

EventDialogueReactiveScenario edrRow(String label, void Function() run) =>
    EventDialogueReactiveScenario(label: label, run: run);

const edrHumanAi = [
  Player(id: 'gp1', displayName: 'Human', isHuman: true),
  Player(id: 'gp2', displayName: 'AI', isHuman: false),
];

const edrH1A1 = [
  Player(id: 'h1', displayName: 'Human', isHuman: true),
  Player(id: 'a1', displayName: 'AI', isHuman: false),
];

final edrOldWorldBorderTopology = MapTopology(
  nodes: const [
    TopologyNode(id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
    TopologyNode(id: 'P2', regionId: 'oldWorld', type: TopologyNodeType.province),
  ],
  edges: const [TopologyEdge(id1: 'P1', id2: 'P2')],
);

Game edrBorderOwGame() => diplomacyGame(
      oldWorld: const RegionData(
        provinces: [
          Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'gp2'),
          Province(id: 'oldWorld|P2', regionId: 'oldWorld', ownerId: 'gp1'),
        ],
      ),
      players: edrHumanAi,
    );

Game edrHumanAttackGame({
  required List<DiplomacyRelation> diplomacyRelations,
}) =>
    diplomacyGame(
      turnNumber: 5,
      players: const [
        Player(id: 'human', displayName: 'Human', isHuman: true),
        Player(id: 'ai1', displayName: 'AI', isHuman: false),
        Player(id: 'ai2', displayName: 'AI Defender', isHuman: false),
      ],
      diplomacyRelations: diplomacyRelations,
    );

List<DialogueEvent> edrHumanAttack(Game game) => dialogueEventsForReactiveHumanAttack(
      game,
      attackerFactionId: 'human',
      defenderFactionId: 'ai2',
      provinceId: 'oldWorld|P1',
      turnNumber: 5,
      seed: 1,
    );

/// Forts-on-border reactive scenarios from `event_dialogue_reactive_test.dart`.
