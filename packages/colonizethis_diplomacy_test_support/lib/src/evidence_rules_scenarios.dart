// Table-driven dossier evidence rule scenarios (Refs #3837 / #4028).

import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'diplomacy_game_fixtures_base.dart';

/// One evidence-rule test row with preserved [label] for duplicate-description lint.
class EvidenceRulesScenario {
  const EvidenceRulesScenario({required this.label, required this.run});

  final String label;
  final void Function() run;
}

void runEvidenceRulesScenario(EvidenceRulesScenario scenario) => scenario.run();

const _pHuman = Player(id: 'gp1', displayName: 'Human', isHuman: true);
const _pAi = Player(id: 'gp2', displayName: 'AI', isHuman: false);
const _pOther = Player(id: 'gp3', displayName: 'Other', isHuman: false);
const _pAi1 = Player(id: 'gp1', displayName: 'AI1', isHuman: false);
const _pAi2 = Player(id: 'gp2', displayName: 'AI2', isHuman: false);
const _pHumanNamed = Player(id: 'human', displayName: 'Human', isHuman: true);
const _pAiNamed = Player(id: 'ai', displayName: 'AI', isHuman: false);

Player _p(String id, String name, {bool human = false, int? mil}) => Player(
      id: id,
      displayName: name,
      isHuman: human,
      militaryLevel: mil,
    );

DiplomacyRelation _allied(String a, String b) => DiplomacyRelation(
      factionId1: a,
      factionId2: b,
      level: RelationLevel.allied,
    );

DiplomacyRelation _peace(String a, String b, {RelationLevel level = RelationLevel.friendly}) =>
    DiplomacyRelation(
      factionId1: a,
      factionId2: b,
      score: 50,
      level: level,
      state: RelationState.atPeace,
    );

EvidenceRulesScenario _row(String label, void Function() run) =>
    EvidenceRulesScenario(label: label, run: run);

EvidenceRulesScenario _emptyBattle({
  required String label,
  required List<Player> players,
  required List<DossierEvidenceEntry> Function(Game) fn,
}) =>
    _row(label, () => expect(fn(diplomacyGame(turnNumber: 2, players: players)), isEmpty));

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

EvidenceRulesScenario _emptyMirror({
  required String label,
  required int refTurn,
  required int currentTurn,
  required String category,
  List<DossierEvidenceEntry> pending = const [],
}) =>
    _row(label, () {
      expect(
        evidenceForEnvyResearchMirror(
          _baseMirrorGame(refTurn: refTurn, currentTurn: currentTurn),
          'ai',
          category,
          currentTurn,
          pending,
        ),
        isEmpty,
      );
    });

Game _baseMirrorGame({required int refTurn, required int currentTurn}) =>
    diplomacyGame(
      turnNumber: currentTurn,
      players: const [_pHumanNamed, _pAiNamed],
      aiControlByGpId: const {'ai': true},
      lastHumanCompletedResearchCategory: 'gathering',
      lastHumanResearchCategoryCompletionTurn: refTurn,
    );

Game _ctaRefuseGame({required bool allyIsAi, required bool atPeaceWithDefender}) =>
    diplomacyGame(
      turnNumber: 3,
      players: [
        const Player(id: 'observer', displayName: 'Human', isHuman: true),
        Player(id: 'ally', displayName: 'Ally', isHuman: !allyIsAi),
        const Player(id: 'defender', displayName: 'Defender', isHuman: false),
      ],
      diplomacyRelations: [
        DiplomacyRelation(
          factionId1: 'ally',
          factionId2: 'defender',
          score: 50,
          level: RelationLevel.friendly,
          state: atPeaceWithDefender
              ? RelationState.atPeace
              : RelationState.atWar,
        ),
      ],
    );

EvidenceRulesScenario _emptyIsolationist({
  required String label,
  required Game game,
  String ally = 'ally',
  String defender = 'defender',
}) =>
    _row(
      label,
      () => expect(
        evidenceForIsolationistCallToArmsRefuse(game, ally, defender, 3),
        isEmpty,
      ),
    );

/// Land-battle victory scenarios from `evidence_rules_test.dart`.
List<EvidenceRulesScenario> evidenceRulesLandBattleVictoryScenarios() => [
  _row('AI victor vs defender appends warmonger evidence for human observer', () {
    final entries = evidenceForLandBattleVictory(
      diplomacyGame(
        turnNumber: 2,
        players: [_pHuman, _p('gp2', 'AI', mil: 4), _p('gp3', 'Other', mil: 2)],
      ),
      'gp2',
      'gp3',
      2,
    );
    expect(entries.length, 1);
    _expectEntry(
      entries.first,
      agenda: 'warmonger',
      observer: 'gp1',
      subject: 'gp2',
      delta: 2,
      desc: contains('weaker'),
    );
  }),
  _row('AI victor vs non-weaker defender gives scoreDelta 1', () {
    final entries = evidenceForLandBattleVictory(
      diplomacyGame(
        turnNumber: 2,
        players: [_pHuman, _p('gp2', 'AI', mil: 2), _p('gp3', 'Other', mil: 4)],
      ),
      'gp2',
      'gp3',
      2,
    );
    expect(entries.length, 1);
    expect(entries.first.agendaType, 'warmonger');
    expect(entries.first.scoreDelta, 1);
    expect(entries.first.description, contains('attacker'));
  }),
  _emptyBattle(
    label: 'human victor returns no evidence',
    players: const [_pHuman, _pAi],
    fn: (g) => evidenceForLandBattleVictory(g, 'gp1', 'gp2', 2),
  ),
  _emptyBattle(
    label: 'land battle: no human observer returns no evidence',
    players: const [_pAi1, _pAi2],
    fn: (g) => evidenceForLandBattleVictory(g, 'gp1', 'gp2', 2),
  ),
];

/// Naval-battle victory scenarios from `evidence_rules_test.dart`.
List<EvidenceRulesScenario> evidenceRulesNavalBattleVictoryScenarios() => [
  _row('AI victor appends warmonger evidence for human observer', () {
    final entries = evidenceForNavalBattleVictory(
      diplomacyGame(turnNumber: 2, players: const [_pHuman, _pAi, _pOther]),
      'gp2',
      'gp3',
      2,
    );
    expect(entries.length, 1);
    _expectEntry(
      entries.first,
      agenda: 'warmonger',
      observer: 'gp1',
      subject: 'gp2',
      delta: 1,
      desc: contains('naval'),
    );
  }),
  _emptyBattle(
    label: 'human victor returns no evidence',
    players: const [_pHuman, _pAi],
    fn: (g) => evidenceForNavalBattleVictory(g, 'gp1', 'gp2', 2),
  ),
];

/// Research-mirror envy scenarios from `evidence_rules_test.dart`.
List<EvidenceRulesScenario> evidenceRulesEnvyResearchMirrorScenarios() => [
  _row('adds envy when category matches within window', () {
    final entries = evidenceForEnvyResearchMirror(
      _baseMirrorGame(refTurn: 1, currentTurn: 2),
      'ai',
      'gathering',
      2,
      const [],
    );
    expect(entries.length, 1);
    expect(entries.single.agendaType, 'envy');
    expect(entries.single.scoreDelta, 1);
  }),
  _emptyMirror(
    label: 'empty when category differs',
    refTurn: 1,
    currentTurn: 2,
    category: 'military',
  ),
  _emptyMirror(
    label: 'empty when outside 2-turn window',
    refTurn: 1,
    currentTurn: 4,
    category: 'gathering',
  ),
  _row('respects per-turn cap of 3', () {
    final pending = <DossierEvidenceEntry>[
      for (var i = 0; i < 3; i++)
        const DossierEvidenceEntry(
          observerId: 'human',
          subjectId: 'ai',
          agendaType: 'envy',
          turnNumber: 1,
          description: 'prior',
          scoreDelta: 1,
        ),
    ];
    expect(
      evidenceForEnvyResearchMirror(
        _baseMirrorGame(refTurn: 1, currentTurn: 1),
        'ai',
        'gathering',
        1,
        pending,
      ),
      isEmpty,
    );
  }),
];

/// Declare-war scenarios from `evidence_rules_war_peace_test.dart`.
EvidenceRulesScenario _declareWarRow({
  required String label,
  required int aiMil,
  required int targetMil,
  required String targetId,
  List<DiplomacyRelation> relations = const [],
  required void Function(List<DossierEvidenceEntry> entries) expectEntries,
}) =>
    _row(label, () {
      expectEntries(
        evidenceForDeclareWar(
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
        ),
      );
    });

List<EvidenceRulesScenario> evidenceRulesDeclareWarScenarios() => [
  _declareWarRow(
    label:
        'AI declaring war on weaker allied GP adds backstabber and warmonger evidence',
    aiMil: 5,
    targetMil: 2,
    targetId: 'ally',
    relations: [_allied('ai', 'ally')],
    expectEntries: (entries) {
      expect(entries.length, 2);
      final backstabber =
          entries.where((e) => e.agendaType == 'backstabber').toList();
      final warmonger =
          entries.where((e) => e.agendaType == 'warmonger').toList();
      expect(backstabber.length, 1);
      _expectEntry(
        backstabber.first,
        agenda: 'backstabber',
        observer: 'human',
        subject: 'ai',
        delta: 3,
        desc: contains('ally'),
      );
      expect(warmonger.length, 1);
      _expectEntry(
        warmonger.first,
        agenda: 'warmonger',
        observer: 'human',
        subject: 'ai',
        delta: 2,
        desc: contains('weaker'),
      );
    },
  ),
  _declareWarRow(
    label: 'AI declaring war on weaker non-allied GP only adds warmonger evidence',
    aiMil: 5,
    targetMil: 2,
    targetId: 'target',
    expectEntries: (entries) {
      expect(entries.length, 1);
      _expectEntry(
        entries.first,
        agenda: 'warmonger',
        observer: 'human',
        subject: 'ai',
        delta: 2,
        desc: contains('weaker'),
      );
    },
  ),
  _declareWarRow(
    label:
        'AI declaring war on allied non-weaker GP only adds backstabber evidence',
    aiMil: 2,
    targetMil: 5,
    targetId: 'ally',
    relations: [_allied('ai', 'ally')],
    expectEntries: (entries) {
      expect(entries.length, 1);
      _expectEntry(
        entries.first,
        agenda: 'backstabber',
        observer: 'human',
        subject: 'ai',
        delta: 3,
        desc: contains('ally'),
      );
    },
  ),
  _emptyBattle(
    label: 'human actor returns no evidence',
    players: const [_pHumanNamed, _pAiNamed],
    fn: (g) => evidenceForDeclareWar(g, 'human', 'ai', 2),
  ),
  _emptyBattle(
    label: 'declare war: no human observer returns no evidence',
    players: [
      _p('ai', 'AI'),
      _p('other', 'Other'),
    ],
    fn: (g) => evidenceForDeclareWar(g, 'ai', 'other', 2),
  ),
];

/// Offer-peace scenarios from `evidence_rules_war_peace_test.dart`.
List<EvidenceRulesScenario> evidenceRulesOfferPeaceScenarios() => [
  _row('AI offering peace adds peacemaker evidence for human observer', () {
    final entries = evidenceForOfferPeace(
      diplomacyGame(turnNumber: 2, players: const [_pHumanNamed, _pAiNamed]),
      'ai',
      'human',
      2,
    );
    expect(entries.length, 1);
    _expectEntry(
      entries.first,
      agenda: 'peacemaker',
      observer: 'human',
      subject: 'ai',
      delta: 1,
      desc: contains('peace'),
    );
  }),
  _emptyBattle(
    label: 'human offering peace returns no evidence',
    players: const [_pHumanNamed, _pAiNamed],
    fn: (g) => evidenceForOfferPeace(g, 'human', 'ai', 2),
  ),
  _emptyBattle(
    label: 'offer peace: no human observer returns no evidence',
    players: [_p('ai', 'AI'), _p('other', 'Other')],
    fn: (g) => evidenceForOfferPeace(g, 'ai', 'other', 2),
  ),
];

/// Treaty-break / call-to-arms follow-on war scenarios from `evidence_rules_war_peace_test.dart`.
List<EvidenceRulesScenario> evidenceRulesTreatyBreakWindowScenarios() => [
  _row('adds backstabber when war follows callToArmsRefused within 3 turns', () {
    final entries = evidenceForDeclareWar(
      diplomacyGame(
        turnNumber: 6,
        players: [
          _p('human', 'Human', human: true, mil: 5),
          _p('ai', 'AI', mil: 5),
          _p('target', 'Target', mil: 5),
        ],
        diplomacyRelations: [_peace('ai', 'target')],
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
    );
    expect(entries.length, 1);
    expect(entries.single.agendaType, 'backstabber');
    expect(entries.single.scoreDelta, 3);
  }),
];

/// Isolationist call-to-arms scenarios from `evidence_rules_isolationist_test.dart`.
List<EvidenceRulesScenario> evidenceRulesIsolationistScenarios() => [
  _row(
    'AI refusing call to arms while at peace with defender adds isolationist +2',
    () {
      final entries = evidenceForIsolationistCallToArmsRefuse(
        _ctaRefuseGame(allyIsAi: true, atPeaceWithDefender: true),
        'ally',
        'defender',
        3,
      );
      expect(entries.length, 1);
      expect(entries.single.turnNumber, 3);
      _expectEntry(
        entries.single,
        agenda: 'isolationist',
        observer: 'observer',
        subject: 'ally',
        delta: 2,
        desc: contains('declined call to arms'),
      );
    },
  ),
  _emptyIsolationist(
    label: 'empty when ally and defender are at war',
    game: _ctaRefuseGame(allyIsAi: true, atPeaceWithDefender: false),
  ),
  _emptyIsolationist(
    label: 'human ally returns no evidence',
    game: _ctaRefuseGame(allyIsAi: false, atPeaceWithDefender: true),
  ),
  _emptyIsolationist(
    label: 'isolationist call to arms: no human observer returns no evidence',
    game: diplomacyGame(
      turnNumber: 3,
      players: [_p('ai1', 'AI1'), _p('ai2', 'AI2'), _p('defender', 'Defender')],
      diplomacyRelations: [_peace('ai1', 'defender')],
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
