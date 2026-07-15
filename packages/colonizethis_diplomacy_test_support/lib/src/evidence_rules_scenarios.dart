// Table-driven dossier evidence rule scenarios (Refs #3837).

import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'diplomacy_game_fixtures_scenarios.dart';

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

EvidenceRulesScenario _emptyBattle({
  required String label,
  required List<Player> players,
  required List<DossierEvidenceEntry> Function(Game) fn,
}) =>
    EvidenceRulesScenario(
      label: label,
      run: () {
        expect(fn(evidenceGame(players: players)), isEmpty);
      },
    );

EvidenceRulesScenario _emptyMirror({
  required String label,
  required int refTurn,
  required int currentTurn,
  required String category,
  List<DossierEvidenceEntry> pending = const [],
}) =>
    EvidenceRulesScenario(
      label: label,
      run: () {
        final game = _baseMirrorGame(refTurn: refTurn, currentTurn: currentTurn);
        expect(
          evidenceForEnvyResearchMirror(
            game,
            'ai',
            category,
            currentTurn,
            pending,
          ),
          isEmpty,
        );
      },
    );

Game _baseMirrorGame({required int refTurn, required int currentTurn}) {
  return evidenceGame(
    turnNumber: currentTurn,
    players: const [
      Player(id: 'human', displayName: 'Human', isHuman: true),
      Player(id: 'ai', displayName: 'AI', isHuman: false),
    ],
    aiControlByGpId: const {'ai': true},
    lastHumanCompletedResearchCategory: 'gathering',
    lastHumanResearchCategoryCompletionTurn: refTurn,
  );
}

Game _ctaRefuseGame({
  required bool allyIsAi,
  required bool atPeaceWithDefender,
}) {
  return evidenceGame(
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
}

/// Land-battle victory scenarios from `evidence_rules_test.dart`.
List<EvidenceRulesScenario> evidenceRulesLandBattleVictoryScenarios() => [
  EvidenceRulesScenario(
    label: 'AI victor vs defender appends warmonger evidence for human observer',
    run: () {
      final game = evidenceGame(
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(
            id: 'gp2',
            displayName: 'AI',
            isHuman: false,
            militaryLevel: 4,
          ),
          Player(
            id: 'gp3',
            displayName: 'Other',
            isHuman: false,
            militaryLevel: 2,
          ),
        ],
      );
      final entries = evidenceForLandBattleVictory(game, 'gp2', 'gp3', 2);
      expect(entries.length, 1);
      expect(entries.first.observerId, 'gp1');
      expect(entries.first.subjectId, 'gp2');
      expect(entries.first.agendaType, 'warmonger');
      expect(entries.first.scoreDelta, 2);
      expect(entries.first.description, contains('weaker'));
    },
  ),
  EvidenceRulesScenario(
    label: 'AI victor vs non-weaker defender gives scoreDelta 1',
    run: () {
      final game = evidenceGame(
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(
            id: 'gp2',
            displayName: 'AI',
            isHuman: false,
            militaryLevel: 2,
          ),
          Player(
            id: 'gp3',
            displayName: 'Other',
            isHuman: false,
            militaryLevel: 4,
          ),
        ],
      );
      final entries = evidenceForLandBattleVictory(game, 'gp2', 'gp3', 2);
      expect(entries.length, 1);
      expect(entries.first.agendaType, 'warmonger');
      expect(entries.first.scoreDelta, 1);
      expect(entries.first.description, contains('attacker'));
    },
  ),
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
  EvidenceRulesScenario(
    label: 'AI victor appends warmonger evidence for human observer',
    run: () {
      final game = evidenceGame(
        players: const [_pHuman, _pAi, _pOther],
      );
      final entries = evidenceForNavalBattleVictory(game, 'gp2', 'gp3', 2);
      expect(entries.length, 1);
      expect(entries.first.observerId, 'gp1');
      expect(entries.first.subjectId, 'gp2');
      expect(entries.first.agendaType, 'warmonger');
      expect(entries.first.scoreDelta, 1);
      expect(entries.first.description, contains('naval'));
    },
  ),
  _emptyBattle(
    label: 'human victor returns no evidence',
    players: const [_pHuman, _pAi],
    fn: (g) => evidenceForNavalBattleVictory(g, 'gp1', 'gp2', 2),
  ),
];

/// Research-mirror envy scenarios from `evidence_rules_test.dart`.
List<EvidenceRulesScenario> evidenceRulesEnvyResearchMirrorScenarios() => [
  EvidenceRulesScenario(
    label: 'adds envy when category matches within window',
    run: () {
      final game = _baseMirrorGame(refTurn: 1, currentTurn: 2);
      final entries = evidenceForEnvyResearchMirror(
        game,
        'ai',
        'gathering',
        2,
        const [],
      );
      expect(entries.length, 1);
      expect(entries.single.agendaType, 'envy');
      expect(entries.single.scoreDelta, 1);
    },
  ),
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
  EvidenceRulesScenario(
    label: 'respects per-turn cap of 3',
    run: () {
      final game = _baseMirrorGame(refTurn: 1, currentTurn: 1);
      final pending = <DossierEvidenceEntry>[
        for (var i = 0; i < 3; i++)
          DossierEvidenceEntry(
            observerId: 'human',
            subjectId: 'ai',
            agendaType: 'envy',
            turnNumber: 1,
            description: 'prior',
            scoreDelta: 1,
          ),
      ];
      final entries = evidenceForEnvyResearchMirror(
        game,
        'ai',
        'gathering',
        1,
        pending,
      );
      expect(entries, isEmpty);
    },
  ),
];


/// Declare-war scenarios from `evidence_rules_war_peace_test.dart`.
List<EvidenceRulesScenario> evidenceRulesDeclareWarScenarios() => [
  EvidenceRulesScenario(
    label:
        'AI declaring war on weaker allied GP adds backstabber and warmonger evidence',
    run: () {
      final game = evidenceGame(
        players: const [
          Player(
            id: 'human',
            displayName: 'Human',
            isHuman: true,
            militaryLevel: 3,
          ),
          Player(
            id: 'ai',
            displayName: 'AI',
            isHuman: false,
            militaryLevel: 5,
          ),
          Player(
            id: 'ally',
            displayName: 'Ally',
            isHuman: false,
            militaryLevel: 2,
          ),
        ],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'ai',
            factionId2: 'ally',
            level: RelationLevel.allied,
          ),
        ],
      );
      final entries = evidenceForDeclareWar(game, 'ai', 'ally', 2);
      expect(entries.length, 2);
      final backstabberEntries = entries
          .where((e) => e.agendaType == 'backstabber')
          .toList();
      final warmongerEntries = entries
          .where((e) => e.agendaType == 'warmonger')
          .toList();
      expect(backstabberEntries.length, 1);
      expect(backstabberEntries.first.observerId, 'human');
      expect(backstabberEntries.first.subjectId, 'ai');
      expect(backstabberEntries.first.scoreDelta, 3);
      expect(backstabberEntries.first.description, contains('ally'));
      expect(warmongerEntries.length, 1);
      expect(warmongerEntries.first.observerId, 'human');
      expect(warmongerEntries.first.subjectId, 'ai');
      expect(warmongerEntries.first.scoreDelta, 2);
      expect(warmongerEntries.first.description, contains('weaker'));
    },
  ),
  EvidenceRulesScenario(
    label: 'AI declaring war on weaker non-allied GP only adds warmonger evidence',
    run: () {
      final game = evidenceGame(
        players: const [
          Player(
            id: 'human',
            displayName: 'Human',
            isHuman: true,
            militaryLevel: 3,
          ),
          Player(
            id: 'ai',
            displayName: 'AI',
            isHuman: false,
            militaryLevel: 5,
          ),
          Player(
            id: 'target',
            displayName: 'Target',
            isHuman: false,
            militaryLevel: 2,
          ),
        ],
      );
      final entries = evidenceForDeclareWar(game, 'ai', 'target', 2);
      expect(entries.length, 1);
      expect(entries.first.agendaType, 'warmonger');
      expect(entries.first.observerId, 'human');
      expect(entries.first.subjectId, 'ai');
      expect(entries.first.scoreDelta, 2);
      expect(entries.first.description, contains('weaker'));
    },
  ),
  EvidenceRulesScenario(
    label: 'AI declaring war on allied non-weaker GP only adds backstabber evidence',
    run: () {
      final game = evidenceGame(
        players: const [
          Player(
            id: 'human',
            displayName: 'Human',
            isHuman: true,
            militaryLevel: 3,
          ),
          Player(
            id: 'ai',
            displayName: 'AI',
            isHuman: false,
            militaryLevel: 2,
          ),
          Player(
            id: 'ally',
            displayName: 'Ally',
            isHuman: false,
            militaryLevel: 5,
          ),
        ],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'ai',
            factionId2: 'ally',
            level: RelationLevel.allied,
          ),
        ],
      );
      final entries = evidenceForDeclareWar(game, 'ai', 'ally', 2);
      expect(entries.length, 1);
      expect(entries.first.agendaType, 'backstabber');
      expect(entries.first.observerId, 'human');
      expect(entries.first.subjectId, 'ai');
      expect(entries.first.scoreDelta, 3);
      expect(entries.first.description, contains('ally'));
    },
  ),
  EvidenceRulesScenario(
    label: 'human actor returns no evidence',
    run: () {
      final game = evidenceGame(
        players: const [_pHumanNamed, _pAiNamed],
      );
      final entries = evidenceForDeclareWar(game, 'human', 'ai', 2);
      expect(entries, isEmpty);
    },
  ),
  EvidenceRulesScenario(
    label: 'declare war: no human observer returns no evidence',
    run: () {
      final game = evidenceGame(
        players: const [
          Player(id: 'ai', displayName: 'AI', isHuman: false),
          Player(id: 'other', displayName: 'Other', isHuman: false),
        ],
      );
      final entries = evidenceForDeclareWar(game, 'ai', 'other', 2);
      expect(entries, isEmpty);
    },
  ),
];

/// Offer-peace scenarios from `evidence_rules_war_peace_test.dart`.
List<EvidenceRulesScenario> evidenceRulesOfferPeaceScenarios() => [
  EvidenceRulesScenario(
    label: 'AI offering peace adds peacemaker evidence for human observer',
    run: () {
      final game = evidenceGame(
        players: const [_pHumanNamed, _pAiNamed],
      );
      final entries = evidenceForOfferPeace(game, 'ai', 'human', 2);
      expect(entries.length, 1);
      final entry = entries.first;
      expect(entry.agendaType, 'peacemaker');
      expect(entry.observerId, 'human');
      expect(entry.subjectId, 'ai');
      expect(entry.scoreDelta, 1);
      expect(entry.description, contains('peace'));
    },
  ),
  _emptyBattle(
    label: 'human offering peace returns no evidence',
    players: const [_pHumanNamed, _pAiNamed],
    fn: (g) => evidenceForOfferPeace(g, 'human', 'ai', 2),
  ),
  _emptyBattle(
    label: 'offer peace: no human observer returns no evidence',
    players: const [
      Player(id: 'ai', displayName: 'AI', isHuman: false),
      Player(id: 'other', displayName: 'Other', isHuman: false),
    ],
    fn: (g) => evidenceForOfferPeace(g, 'ai', 'other', 2),
  ),
];

/// Treaty-break / call-to-arms follow-on war scenarios from `evidence_rules_war_peace_test.dart`.
List<EvidenceRulesScenario> evidenceRulesTreatyBreakWindowScenarios() => [
  EvidenceRulesScenario(
    label: 'adds backstabber when war follows callToArmsRefused within 3 turns',
    run: () {
      final game = evidenceGame(
        turnNumber: 6,
        players: const [
          Player(
            id: 'human',
            displayName: 'Human',
            isHuman: true,
            militaryLevel: 5,
          ),
          Player(
            id: 'ai',
            displayName: 'AI',
            isHuman: false,
            militaryLevel: 5,
          ),
          Player(
            id: 'target',
            displayName: 'Target',
            isHuman: false,
            militaryLevel: 5,
          ),
        ],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'ai',
            factionId2: 'target',
            level: RelationLevel.friendly,
            state: RelationState.atPeace,
          ),
        ],
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
      );
      final entries = evidenceForDeclareWar(game, 'ai', 'target', 6);
      expect(entries.length, 1);
      expect(entries.single.agendaType, 'backstabber');
      expect(entries.single.scoreDelta, 3);
    },
  ),
];


/// Isolationist call-to-arms scenarios from `evidence_rules_isolationist_test.dart`.
List<EvidenceRulesScenario> evidenceRulesIsolationistScenarios() => [
  EvidenceRulesScenario(
    label:
        'AI refusing call to arms while at peace with defender adds isolationist +2',
    run: () {
      final game = _ctaRefuseGame(allyIsAi: true, atPeaceWithDefender: true);
      final entries = evidenceForIsolationistCallToArmsRefuse(
        game,
        'ally',
        'defender',
        3,
      );
      expect(entries.length, 1);
      expect(entries.single.observerId, 'observer');
      expect(entries.single.subjectId, 'ally');
      expect(entries.single.agendaType, 'isolationist');
      expect(entries.single.scoreDelta, 2);
      expect(entries.single.turnNumber, 3);
      expect(entries.single.description, contains('declined call to arms'));
    },
  ),
  EvidenceRulesScenario(
    label: 'empty when ally and defender are at war',
    run: () {
      final game = _ctaRefuseGame(allyIsAi: true, atPeaceWithDefender: false);
      final entries = evidenceForIsolationistCallToArmsRefuse(
        game,
        'ally',
        'defender',
        3,
      );
      expect(entries, isEmpty);
    },
  ),
  EvidenceRulesScenario(
    label: 'human ally returns no evidence',
    run: () {
      final game = _ctaRefuseGame(allyIsAi: false, atPeaceWithDefender: true);
      final entries = evidenceForIsolationistCallToArmsRefuse(
        game,
        'ally',
        'defender',
        3,
      );
      expect(entries, isEmpty);
    },
  ),
  EvidenceRulesScenario(
    label: 'isolationist call to arms: no human observer returns no evidence',
    run: () {
      final game = evidenceGame(
        turnNumber: 3,
        players: const [
          Player(id: 'ai1', displayName: 'AI1', isHuman: false),
          Player(id: 'ai2', displayName: 'AI2', isHuman: false),
          Player(id: 'defender', displayName: 'Defender', isHuman: false),
        ],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'ai1',
            factionId2: 'defender',
            score: 50,
            level: RelationLevel.friendly,
            state: RelationState.atPeace,
          ),
        ],
      );
      final entries = evidenceForIsolationistCallToArmsRefuse(
        game,
        'ai1',
        'defender',
        3,
      );
      expect(entries, isEmpty);
    },
  ),
  EvidenceRulesScenario(
    label: 'empty when no relation exists between ally and defender',
    run: () {
      final game = evidenceGame(
        turnNumber: 3,
        players: const [
          Player(id: 'observer', displayName: 'Human', isHuman: true),
          Player(id: 'ally', displayName: 'Ally', isHuman: false),
          Player(id: 'defender', displayName: 'Defender', isHuman: false),
        ],
      );
      final entries = evidenceForIsolationistCallToArmsRefuse(
        game,
        'ally',
        'defender',
        3,
      );
      expect(entries, isEmpty);
    },
  ),
];
