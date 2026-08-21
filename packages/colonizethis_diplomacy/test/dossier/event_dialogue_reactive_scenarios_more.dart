// More reactive event dialogue scenarios (Refs #4574).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';
import 'event_dialogue_reactive_scenario_helpers.dart';

List<EventDialogueReactiveScenario> eventDialogueReactiveHumanAttackScenarios() => [
  edrRow('emits attack_on_ally for AI with a formal alliance with defender', () {
    final events = edrHumanAttack(
      edrHumanAttackGame(
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
  edrRow(
    'suppresses attack_on_ally for informal Allied band without a formal '
    'alliance',
    () {
      expect(
        edrHumanAttack(
          edrHumanAttackGame(
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
  edrRow('emits attack_on_minor and attack_on_tribe for AI with embassy', () {
    final game = diplomacyGame(
      turnNumber: 5,
      players: const [
        Player(id: 'human', displayName: 'Human', isHuman: true),
        Player(id: 'ai1', displayName: 'AI', isHuman: false),
      ],
      minorNations: const [MinorNation(id: 'mn1')],
      tribes: const [Tribe(id: 'tr1')],
      overtureStates: const [
        OvertureState(gpId: 'ai1', targetId: 'mn1', stage: OvertureStage.embassy),
        OvertureState(gpId: 'ai1', targetId: 'tr1', stage: OvertureStage.embassy),
      ],
    );
    DialogueEvent attack(String defender, String province) =>
        dialogueEventsForReactiveHumanAttack(
          game,
          attackerFactionId: 'human',
          defenderFactionId: defender,
          provinceId: province,
          turnNumber: 5,
          seed: 1,
        ).single;
    expect(attack('mn1', 'oldWorld|P9').situation, 'attack_on_minor');
    expect(attack('tr1', 'newWorld|N2').situation, 'attack_on_tribe');
  }),
];

/// Tech, capital, colony, and spy reactive scenarios.
List<EventDialogueReactiveScenario> eventDialogueReactiveDiscoveryAndSpyScenarios() => [
  edrRow('tech_discovered emits for AI discoverer only', () {
    final game = diplomacyGame(turnNumber: 8, players: edrH1A1);
    List<DialogueEvent> tech(String id) => dialogueEventsForTechDiscovered(
          game,
          discovererId: id,
          techId: 'rifling',
          turnNumber: 8,
          seed: 0,
        );
    expect(tech('a1').single.situation, 'tech_discovered');
    expect(tech('h1'), isEmpty);
  }),
  edrRow('capital_threatened emits when human attacker targets AI capital', () {
    expect(
      dialogueEventsForCapitalThreatened(
        diplomacyGame(
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
      ).single.situation,
      'capital_threatened',
    );
  }),
  edrRow('colony_founded emits only for null->AI owner in New World', () {
    final game = diplomacyGame(
      turnNumber: 10,
      players: const [Player(id: 'a1', displayName: 'AI', isHuman: false)],
    );
    List<DialogueEvent> colony(String province) => dialogueEventsForColonyFounded(
          game,
          provinceId: province,
          previousOwnerId: null,
          newOwnerId: 'a1',
          turnNumber: 10,
          seed: 0,
        );
    expect(colony('newWorld|N1').single.situation, 'colony_founded');
    expect(colony('oldWorld|P1'), isEmpty);
  }),
  edrRow('spies_caught emits only for AI speaker and human spy owner', () {
    expect(
      dialogueEventsForReactiveSpiesCaught(
        diplomacyGame(turnNumber: 7, players: edrH1A1),
        speakerId: 'a1',
        caughtSpyOwnerId: 'h1',
        provinceId: 'oldWorld|P4',
        turnNumber: 7,
        seed: 0,
      ).single.situation,
      'spies_caught',
    );
  }),
  edrRow('spies_defected emits only for AI defector and human previous owner', () {
    final e = dialogueEventsForReactiveSpiesDefected(
      diplomacyGame(turnNumber: 8, players: edrH1A1),
      newOwnerId: 'a1',
      previousOwnerId: 'h1',
      provinceId: 'oldWorld|P4',
      turnNumber: 8,
      seed: 0,
    ).single;
    expect(e.situation, 'spies_defected');
    expect(e.leaderId, 'a1');
  }),
];
