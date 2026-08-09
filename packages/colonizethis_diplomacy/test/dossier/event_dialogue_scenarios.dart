// Table-driven event dialogue scenarios (Refs #3837 / #4028 / #4130).

import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';

class EventDialogueScenario {
  const EventDialogueScenario({required this.label, required this.run});

  final String label;
  final void Function() run;
}

void runEventDialogueScenario(EventDialogueScenario scenario) => scenario.run();

EventDialogueScenario _row(String label, void Function() run) =>
    EventDialogueScenario(label: label, run: run);

const _human = Player(id: 'gp1', displayName: 'Human', isHuman: true);
const _ai = Player(id: 'gp2', displayName: 'AI', isHuman: false);
const _aiVictor = Player(id: 'gp2', displayName: 'AI Victor', isHuman: false);
const _aiLoser = Player(id: 'gp3', displayName: 'AI Loser', isHuman: false);
const _humanAi = [_human, _ai];
const _humanAiVictorLoser = [_human, _aiVictor, _aiLoser];
const _twoHumans = [
  Player(id: 'gp1', displayName: 'Human', isHuman: true),
  Player(id: 'gp2', displayName: 'Human', isHuman: true),
];
const _twoAis = [
  Player(id: 'gp2', displayName: 'AI', isHuman: false),
  Player(id: 'gp3', displayName: 'AI', isHuman: false),
];

List<DialogueEvent> _landBattle(
  Game g,
  String victor,
  String loser, {
  int turn = 2,
  String prov = 'ow|p1',
  int seed = 0,
}) =>
    dialogueEventsForLandBattleResult(g, victor, loser, prov, turn, seed);

List<DialogueEvent> _navalBattle(
  Game g,
  String victor,
  String loser, {
  int turn = 1,
  int seed = 0,
}) =>
    dialogueEventsForNavalBattleResult(g, victor, loser, turn, seed);

void _expectAiBattlePair(List<DialogueEvent> events, String victorId, String loserId) {
  expect(events.length, 2);
  expect(events.any((e) => e.situation == 'battle_won' && e.leaderId == victorId), isTrue);
  expect(events.any((e) => e.situation == 'battle_lost' && e.leaderId == loserId), isTrue);
}

/// Land-battle dialogue scenarios from `event_dialogue_test.dart`.
List<EventDialogueScenario> eventDialogueCoreLandBattleScenarios() => [
  _row(
    'AI victor and AI loser both emit event with era from turn-time mapping',
    () {
      const mapping = TurnTimeMapping.gdd01;
      final expectedEra = eraFromYear(mapping.yearAtTurn(2));
      final events = _landBattle(
        diplomacyGame(turnNumber: 2, players: _humanAiVictorLoser),
        'gp2',
        'gp3',
        prov: 'ow|prov1',
        seed: 12345,
      );
      expect(events.length, 2);
      final won = events.where((e) => e.situation == 'battle_won').single;
      final lost = events.where((e) => e.situation == 'battle_lost').single;
      expect(won.leaderId, 'gp2');
      expect(won.category, 'event');
      expect(won.era, expectedEra);
      expect(won.variables['otherNation'], 'gp3');
      expect(won.variables['province'], 'ow|prov1');
      expect(lost.leaderId, 'gp3');
      expect(lost.variables['otherNation'], 'gp2');
    },
  ),
  _row('human victor returns no dialogue for victor', () {
    final events = _landBattle(diplomacyGame(turnNumber: 2, players: _humanAi), 'gp1', 'gp2');
    expect(events.length, 1);
    expect(events.first.situation, 'battle_lost');
    expect(events.first.leaderId, 'gp2');
  }),
  _row('human loser returns only battle_won for AI victor', () {
    final events = _landBattle(diplomacyGame(turnNumber: 2, players: _humanAi), 'gp2', 'gp1');
    expect(events.length, 1);
    expect(events.first.situation, 'battle_won');
    expect(events.first.leaderId, 'gp2');
  }),
];

/// Naval-battle dialogue scenarios from `event_dialogue_test.dart`.
List<EventDialogueScenario> eventDialogueCoreNavalBattleScenarios() => [
  _row('AI victor and AI loser both emit event', () {
    final events = _navalBattle(
      diplomacyGame(turnNumber: 3, players: _humanAiVictorLoser),
      'gp2',
      'gp3',
      turn: 3,
      seed: 999,
    );
    _expectAiBattlePair(events, 'gp2', 'gp3');
    expect(events.first.variables['otherNation'], isNotNull);
  }),
  _row('human victor returns only battle_lost for AI loser', () {
    final events = _navalBattle(diplomacyGame(players: _humanAi), 'gp1', 'gp2');
    expect(events.length, 1);
    expect(events.first.situation, 'battle_lost');
    expect(events.first.leaderId, 'gp2');
  }),
];

/// eraFromYear mapping scenarios from `event_dialogue_test.dart`.
List<EventDialogueScenario> eventDialogueCoreEraFromYearScenarios() => [
  _row('maps year to dialogue era bands', () {
    expect(eraFromYear(1599), 'discovery');
    expect(eraFromYear(1600), 'earlyModern');
    expect(eraFromYear(1699), 'earlyModern');
    expect(eraFromYear(1700), 'imperial');
    expect(eraFromYear(1799), 'imperial');
    expect(eraFromYear(1800), 'industrial');
  }),
];

/// Era-change dialogue scenarios from `event_dialogue_test.dart`.
List<EventDialogueScenario> eventDialogueCoreEraChangeScenarios() => [
  _row('emits one event per AI leader with era_change situation', () {
    final events = dialogueEventsForEraChange(
      diplomacyGame(turnNumber: 100, players: [_human, ..._twoAis]),
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
  }),
  _row('emits no events when all players are human', () {
    expect(
      dialogueEventsForEraChange(
        diplomacyGame(turnNumber: 100, players: _twoHumans),
        'earlyModern',
        'imperial',
        0,
      ),
      isEmpty,
    );
  }),
];

/// Negotiation dialogue scenarios from `event_dialogue_test.dart`.
List<EventDialogueScenario> eventDialogueCoreNegotiationScenarios() => [
  _row('builds event with category negotiation and optional mood', () {
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
  }),
  _row('builds event without mood', () {
    final e = dialogueEventForNegotiation(
      leaderId: 'gp2',
      situation: 'opening',
      era: 'imperial',
    );
    expect(e.category, 'negotiation');
    expect(e.situation, 'opening');
    expect(e.mood, isNull);
  }),
];
