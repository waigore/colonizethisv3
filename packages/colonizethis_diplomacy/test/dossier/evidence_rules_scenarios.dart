// Table-driven dossier evidence rule scenarios (Refs #3837 / #4028 / #4037 / #4130 / #4574).

import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';

import 'evidence_rules_scenario_helpers.dart';

List<EvidenceRulesScenario> evidenceRulesLandBattleVictoryScenarios() => [
  erRow('AI victor vs defender appends warmonger evidence for human observer', () {
    final entries = evidenceForLandBattleVictory(erLandPlayers(4, 2), 'gp2', 'gp3', 2);
    expect(entries.length, 1);
    erExpectEntry(entries.first, agenda: 'warmonger', observer: 'gp1', subject: 'gp2', delta: 2, desc: contains('weaker'));
  }),
  erRow('AI victor vs non-weaker defender gives scoreDelta 1', () {
    final e = evidenceForLandBattleVictory(erLandPlayers(2, 4), 'gp2', 'gp3', 2).single;
    expect(e.agendaType, 'warmonger');
    expect(e.scoreDelta, 1);
    expect(e.description, contains('attacker'));
  }),
  erEmptyBattle(label: 'human victor returns no evidence', players: const [erHuman, erAi], fn: (g) => evidenceForLandBattleVictory(g, 'gp1', 'gp2', 2)),
  erEmptyBattle(label: 'land battle: no human observer returns no evidence', players: const [erAi1, erAi2], fn: (g) => evidenceForLandBattleVictory(g, 'gp1', 'gp2', 2)),
];

List<EvidenceRulesScenario> evidenceRulesNavalBattleVictoryScenarios() => [
  erRow('AI victor appends warmonger evidence for human observer', () {
    final entries = evidenceForNavalBattleVictory(diplomacyGame(turnNumber: 2, players: const [erHuman, erAi, erOther]), 'gp2', 'gp3', 2);
    expect(entries.length, 1);
    erExpectEntry(entries.first, agenda: 'warmonger', observer: 'gp1', subject: 'gp2', delta: 1, desc: contains('naval'));
  }),
  erEmptyBattle(label: 'human victor returns no evidence', players: const [erHuman, erAi], fn: (g) => evidenceForNavalBattleVictory(g, 'gp1', 'gp2', 2)),
];

List<EvidenceRulesScenario> evidenceRulesEnvyResearchMirrorScenarios() => [
  erRow('adds envy when category matches within window', () {
    final e = evidenceForEnvyResearchMirror(erMirrorGame(refTurn: 1, currentTurn: 2), 'ai', 'gathering', 2, const []).single;
    expect(e.agendaType, 'envy');
    expect(e.scoreDelta, 1);
  }),
  erEmptyMirror(label: 'empty when category differs', refTurn: 1, currentTurn: 2, category: 'military'),
  erEmptyMirror(label: 'empty when outside 2-turn window', refTurn: 1, currentTurn: 4, category: 'gathering'),
  erRow('respects per-turn cap of 3', () {
    final pending = <DossierEvidenceEntry>[
      for (var i = 0; i < 3; i++)
        const DossierEvidenceEntry(observerId: 'human', subjectId: 'ai', agendaType: 'envy', turnNumber: 1, description: 'prior', scoreDelta: 1),
    ];
    expect(evidenceForEnvyResearchMirror(erMirrorGame(refTurn: 1, currentTurn: 1), 'ai', 'gathering', 1, pending), isEmpty);
  }),
];

