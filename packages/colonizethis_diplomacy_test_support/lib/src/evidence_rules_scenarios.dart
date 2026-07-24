// Table-driven dossier evidence rule scenarios (Refs #3837 / #4028 / #4037 / #4130).

import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'call_to_arms_fixtures.dart';
import 'diplomacy_game_fixtures_base.dart';
import 'diplomacy_relation_fixtures.dart';

class EvidenceRulesScenario {
  const EvidenceRulesScenario({required this.label, required this.run});
  final String label;
  final void Function() run;
}

void runEvidenceRulesScenario(EvidenceRulesScenario scenario) => scenario.run();

const _human = Player(id: 'gp1', displayName: 'Human', isHuman: true);
const _ai = Player(id: 'gp2', displayName: 'AI', isHuman: false);
const _other = Player(id: 'gp3', displayName: 'Other', isHuman: false);
const _ai1 = Player(id: 'gp1', displayName: 'AI1', isHuman: false);
const _ai2 = Player(id: 'gp2', displayName: 'AI2', isHuman: false);
const _humanNamed = Player(id: 'human', displayName: 'Human', isHuman: true);
const _aiNamed = Player(id: 'ai', displayName: 'AI', isHuman: false);
const _humanAi = [_humanNamed, _aiNamed];

Player _p(String id, String name, {bool human = false, int? mil}) =>
    Player(id: id, displayName: name, isHuman: human, militaryLevel: mil);

DiplomacyRelation _allied(String a, String b) =>
    peaceRelation(a, b, 80, level: RelationLevel.allied, formalAlliance: true);

EvidenceRulesScenario _row(String label, void Function() run) =>
    EvidenceRulesScenario(label: label, run: run);

EvidenceRulesScenario _emptyBattle({
  required String label,
  required List<Player> players,
  required List<DossierEvidenceEntry> Function(Game) fn,
}) => _row(label, () => expect(fn(diplomacyGame(turnNumber: 2, players: players)), isEmpty));

void _expectEntry(
  DossierEvidenceEntry e, {
  required String agenda,
  required String observer,
  required String subject,
  required int delta,
  required Matcher desc,
}) {
  expect(e.agendaType, agenda);
  expect(e.observerId, observer);
  expect(e.subjectId, subject);
  expect(e.scoreDelta, delta);
  expect(e.description, desc);
}

DossierEvidenceEntry _onlyAgenda(List<DossierEvidenceEntry> entries, String agenda) {
  final matched = entries.where((e) => e.agendaType == agenda).toList();
  expect(matched.length, 1);
  return matched.single;
}

Game _mirrorGame({required int refTurn, required int currentTurn}) => diplomacyGame(
      turnNumber: currentTurn,
      players: _humanAi,
      aiControlByGpId: const {'ai': true},
      lastHumanCompletedResearchCategory: 'gathering',
      lastHumanResearchCategoryCompletionTurn: refTurn,
    );

EvidenceRulesScenario _emptyMirror({
  required String label,
  required int refTurn,
  required int currentTurn,
  required String category,
  List<DossierEvidenceEntry> pending = const [],
}) => _row(
      label,
      () => expect(
        evidenceForEnvyResearchMirror(_mirrorGame(refTurn: refTurn, currentTurn: currentTurn), 'ai', category, currentTurn, pending),
        isEmpty,
      ),
    );

Game _landPlayers(int aiMil, int otherMil) => diplomacyGame(
      turnNumber: 2,
      players: [_human, _p('gp2', 'AI', mil: aiMil), _p('gp3', 'Other', mil: otherMil)],
    );

EvidenceRulesScenario _emptyIsolationist({
  required String label,
  required Game game,
  String ally = 'ally',
  String defender = 'defender',
}) => _row(label, () => expect(evidenceForIsolationistCallToArmsRefuse(game, ally, defender, 3), isEmpty));

EvidenceRulesScenario _declareWarRow({
  required String label,
  required int aiMil,
  required int targetMil,
  required String targetId,
  List<DiplomacyRelation> relations = const [],
  required void Function(List<DossierEvidenceEntry> entries) expectEntries,
}) => _row(label, () {
      expectEntries(evidenceForDeclareWar(
        diplomacyGame(
          turnNumber: 2,
          players: [
            _p('human', 'Human', human: true, mil: 3),
            _p('ai', 'AI', mil: aiMil),
            _p(targetId, targetId == 'ally' ? 'Ally' : 'Target', mil: targetMil),
          ],
          diplomacyRelations: relations,
        ),
        'ai',
        targetId,
        2,
      ));
    });

List<EvidenceRulesScenario> evidenceRulesLandBattleVictoryScenarios() => [
  _row('AI victor vs defender appends warmonger evidence for human observer', () {
    final entries = evidenceForLandBattleVictory(_landPlayers(4, 2), 'gp2', 'gp3', 2);
    expect(entries.length, 1);
    _expectEntry(entries.first, agenda: 'warmonger', observer: 'gp1', subject: 'gp2', delta: 2, desc: contains('weaker'));
  }),
  _row('AI victor vs non-weaker defender gives scoreDelta 1', () {
    final e = evidenceForLandBattleVictory(_landPlayers(2, 4), 'gp2', 'gp3', 2).single;
    expect(e.agendaType, 'warmonger');
    expect(e.scoreDelta, 1);
    expect(e.description, contains('attacker'));
  }),
  _emptyBattle(label: 'human victor returns no evidence', players: const [_human, _ai], fn: (g) => evidenceForLandBattleVictory(g, 'gp1', 'gp2', 2)),
  _emptyBattle(label: 'land battle: no human observer returns no evidence', players: const [_ai1, _ai2], fn: (g) => evidenceForLandBattleVictory(g, 'gp1', 'gp2', 2)),
];

List<EvidenceRulesScenario> evidenceRulesNavalBattleVictoryScenarios() => [
  _row('AI victor appends warmonger evidence for human observer', () {
    final entries = evidenceForNavalBattleVictory(diplomacyGame(turnNumber: 2, players: const [_human, _ai, _other]), 'gp2', 'gp3', 2);
    expect(entries.length, 1);
    _expectEntry(entries.first, agenda: 'warmonger', observer: 'gp1', subject: 'gp2', delta: 1, desc: contains('naval'));
  }),
  _emptyBattle(label: 'human victor returns no evidence', players: const [_human, _ai], fn: (g) => evidenceForNavalBattleVictory(g, 'gp1', 'gp2', 2)),
];

List<EvidenceRulesScenario> evidenceRulesEnvyResearchMirrorScenarios() => [
  _row('adds envy when category matches within window', () {
    final e = evidenceForEnvyResearchMirror(_mirrorGame(refTurn: 1, currentTurn: 2), 'ai', 'gathering', 2, const []).single;
    expect(e.agendaType, 'envy');
    expect(e.scoreDelta, 1);
  }),
  _emptyMirror(label: 'empty when category differs', refTurn: 1, currentTurn: 2, category: 'military'),
  _emptyMirror(label: 'empty when outside 2-turn window', refTurn: 1, currentTurn: 4, category: 'gathering'),
  _row('respects per-turn cap of 3', () {
    final pending = <DossierEvidenceEntry>[
      for (var i = 0; i < 3; i++)
        const DossierEvidenceEntry(observerId: 'human', subjectId: 'ai', agendaType: 'envy', turnNumber: 1, description: 'prior', scoreDelta: 1),
    ];
    expect(evidenceForEnvyResearchMirror(_mirrorGame(refTurn: 1, currentTurn: 1), 'ai', 'gathering', 1, pending), isEmpty);
  }),
];

List<EvidenceRulesScenario> evidenceRulesDeclareWarScenarios() => [
  _declareWarRow(
    label: 'AI declaring war on weaker allied GP adds backstabber and warmonger evidence',
    aiMil: 5,
    targetMil: 2,
    targetId: 'ally',
    relations: [_allied('ai', 'ally')],
    expectEntries: (entries) {
      expect(entries.length, 2);
      _expectEntry(_onlyAgenda(entries, 'backstabber'), agenda: 'backstabber', observer: 'human', subject: 'ai', delta: 3, desc: contains('ally'));
      _expectEntry(_onlyAgenda(entries, 'warmonger'), agenda: 'warmonger', observer: 'human', subject: 'ai', delta: 2, desc: contains('weaker'));
    },
  ),
  _declareWarRow(
    label: 'AI declaring war on weaker non-allied GP only adds warmonger evidence',
    aiMil: 5,
    targetMil: 2,
    targetId: 'target',
    expectEntries: (entries) {
      expect(entries.length, 1);
      _expectEntry(entries.first, agenda: 'warmonger', observer: 'human', subject: 'ai', delta: 2, desc: contains('weaker'));
    },
  ),
  _declareWarRow(
    label: 'AI declaring war on allied non-weaker GP only adds backstabber evidence',
    aiMil: 2,
    targetMil: 5,
    targetId: 'ally',
    relations: [_allied('ai', 'ally')],
    expectEntries: (entries) {
      expect(entries.length, 1);
      _expectEntry(entries.first, agenda: 'backstabber', observer: 'human', subject: 'ai', delta: 3, desc: contains('ally'));
    },
  ),
  _emptyBattle(label: 'human actor returns no evidence', players: _humanAi, fn: (g) => evidenceForDeclareWar(g, 'human', 'ai', 2)),
  _emptyBattle(label: 'declare war: no human observer returns no evidence', players: [_p('ai', 'AI'), _p('other', 'Other')], fn: (g) => evidenceForDeclareWar(g, 'ai', 'other', 2)),
];

List<EvidenceRulesScenario> evidenceRulesOfferPeaceScenarios() => [
  _row('AI offering peace adds peacemaker evidence for human observer', () {
    final entries = evidenceForOfferPeace(diplomacyGame(turnNumber: 2, players: _humanAi), 'ai', 'human', 2);
    expect(entries.length, 1);
    _expectEntry(entries.first, agenda: 'peacemaker', observer: 'human', subject: 'ai', delta: 1, desc: contains('peace'));
  }),
  _emptyBattle(label: 'human offering peace returns no evidence', players: _humanAi, fn: (g) => evidenceForOfferPeace(g, 'human', 'ai', 2)),
  _emptyBattle(label: 'offer peace: no human observer returns no evidence', players: [_p('ai', 'AI'), _p('other', 'Other')], fn: (g) => evidenceForOfferPeace(g, 'ai', 'other', 2)),
];

List<EvidenceRulesScenario> evidenceRulesTreatyBreakWindowScenarios() => [
  _row('adds backstabber when war follows callToArmsRefused within 3 turns', () {
    final e = evidenceForDeclareWar(
      diplomacyGame(
        turnNumber: 6,
        players: [_p('human', 'Human', human: true, mil: 5), _p('ai', 'AI', mil: 5), _p('target', 'Target', mil: 5)],
        diplomacyRelations: [peaceRelation('ai', 'target', 50, level: RelationLevel.friendly)],
        diplomaticHistoryEvents: const [
          DiplomaticEvent(
            turn: 5,
            intraTurnIndex: 0,
            type: DiplomaticEventType.callToArmsRefused,
            participants: {'ai', 'target'},
            fromFactionId: 'ai',
            toFactionId: 'target',
          ),
        ],
      ),
      'ai',
      'target',
      6,
    ).single;
    expect(e.agendaType, 'backstabber');
    expect(e.scoreDelta, 3);
  }),
];

List<EvidenceRulesScenario> evidenceRulesIsolationistScenarios() => [
  _row('AI refusing call to arms while at peace with defender adds isolationist +2', () {
    final e = evidenceForIsolationistCallToArmsRefuse(
      ctaRefuseEvidenceGame(allyIsAi: true, atPeaceWithDefender: true),
      'ally',
      'defender',
      3,
    ).single;
    expect(e.turnNumber, 3);
    _expectEntry(e, agenda: 'isolationist', observer: 'observer', subject: 'ally', delta: 2, desc: contains('declined call to arms'));
  }),
  _emptyIsolationist(label: 'empty when ally and defender are at war', game: ctaRefuseEvidenceGame(allyIsAi: true, atPeaceWithDefender: false)),
  _emptyIsolationist(label: 'human ally returns no evidence', game: ctaRefuseEvidenceGame(allyIsAi: false, atPeaceWithDefender: true)),
  _emptyIsolationist(
    label: 'isolationist call to arms: no human observer returns no evidence',
    game: diplomacyGame(
      turnNumber: 3,
      players: [_p('ai1', 'AI1'), _p('ai2', 'AI2'), _p('defender', 'Defender')],
      diplomacyRelations: [peaceRelation('ai1', 'defender', 50)],
    ),
    ally: 'ai1',
  ),
  _emptyIsolationist(
    label: 'empty when no relation exists between ally and defender',
    game: diplomacyGame(
      turnNumber: 3,
      players: [
        const Player(id: 'observer', displayName: 'Human', isHuman: true),
        _p('ally', 'Ally'),
        _p('defender', 'Defender'),
      ],
    ),
  ),
];
