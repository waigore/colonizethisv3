// Reactive event dialogue scenarios (Refs #4574).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';

import 'event_dialogue_reactive_scenario_helpers.dart';

List<EventDialogueReactiveScenario> eventDialogueReactiveFortsOnBorderScenarios() => [
  edrRow('returns empty when builder is AI', () {
    expect(
      dialogueEventsForReactiveFortsOnBorder(
        edrBorderOwGame(),
        edrOldWorldBorderTopology,
        'gp2',
        'oldWorld|P2',
        0,
      ),
      isEmpty,
    );
  }),
  edrRow('emits one event per AI neighbor when human builds fort on border', () {
    final events = dialogueEventsForReactiveFortsOnBorder(
      edrBorderOwGame(),
      edrOldWorldBorderTopology,
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
  edrRow('resolves owner from newWorld when fort built in newWorld', () {
    const nw = 'newWorld';
    final events = dialogueEventsForReactiveFortsOnBorder(
      diplomacyGame(
        newWorld: const RegionData(
          provinces: [
            Province(id: 'newWorld|N1', regionId: nw, ownerId: 'gp1'),
            Province(id: 'newWorld|N2', regionId: nw, ownerId: 'gp2'),
          ],
        ),
        players: edrHumanAi,
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
