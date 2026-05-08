// Tests for battle-victory and research/spy dossier evidence rules.
// Diplomacy / war-peace / isolationist rules live in sibling files:
//  - evidence_rules_war_peace_test.dart
//  - evidence_rules_isolationist_test.dart
// SPEC/ai/hidden-agendas.md, SPEC/program/ai-events-and-dossier.md.

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'evidence_rules_test_support.dart';

void main() {
  group('evidenceForLandBattleVictory', () {
    test(
      'AI victor vs defender appends warmonger evidence for human observer',
      () {
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
    );

    test('AI victor vs non-weaker defender gives scoreDelta 1', () {
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
    });

    test('human victor returns no evidence', () {
      final game = evidenceGame(
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'AI', isHuman: false),
        ],
      );
      final entries = evidenceForLandBattleVictory(game, 'gp1', 'gp2', 2);
      expect(entries, isEmpty);
    });

    test('no human observer returns no evidence', () {
      final game = evidenceGame(
        players: const [
          Player(id: 'gp1', displayName: 'AI1', isHuman: false),
          Player(id: 'gp2', displayName: 'AI2', isHuman: false),
        ],
      );
      final entries = evidenceForLandBattleVictory(game, 'gp1', 'gp2', 2);
      expect(entries, isEmpty);
    });
  });

  group('evidenceForNavalBattleVictory', () {
    test('AI victor appends warmonger evidence for human observer', () {
      final game = evidenceGame(
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'AI', isHuman: false),
          Player(id: 'gp3', displayName: 'Other', isHuman: false),
        ],
      );
      final entries = evidenceForNavalBattleVictory(game, 'gp2', 'gp3', 2);
      expect(entries.length, 1);
      expect(entries.first.observerId, 'gp1');
      expect(entries.first.subjectId, 'gp2');
      expect(entries.first.agendaType, 'warmonger');
      expect(entries.first.scoreDelta, 1);
      expect(entries.first.description, contains('naval'));
    });

    test('human victor returns no evidence', () {
      final game = evidenceGame(
        players: const [
          Player(id: 'gp1', displayName: 'Human', isHuman: true),
          Player(id: 'gp2', displayName: 'AI', isHuman: false),
        ],
      );
      final entries = evidenceForNavalBattleVictory(game, 'gp1', 'gp2', 2);
      expect(entries, isEmpty);
    });
  });

  group('evidenceForEnvyResearchMirror', () {
    Game baseMirrorGame({required int refTurn, required int currentTurn}) {
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

    test('adds envy when category matches within window', () {
      final game = baseMirrorGame(refTurn: 1, currentTurn: 2);
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
    });

    test('empty when category differs', () {
      final game = baseMirrorGame(refTurn: 1, currentTurn: 2);
      final entries = evidenceForEnvyResearchMirror(
        game,
        'ai',
        'military',
        2,
        const [],
      );
      expect(entries, isEmpty);
    });

    test('empty when outside 2-turn window', () {
      final game = baseMirrorGame(refTurn: 1, currentTurn: 4);
      final entries = evidenceForEnvyResearchMirror(
        game,
        'ai',
        'gathering',
        4,
        const [],
      );
      expect(entries, isEmpty);
    });

    test('respects per-turn cap of 3', () {
      final game = baseMirrorGame(refTurn: 1, currentTurn: 1);
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
    });
  });

  group('evidenceForAiStealTechResolved', () {
    Game baseSpyEvidenceGame() {
      return evidenceGame(
        turnNumber: 4,
        players: const [
          Player(id: 'human', displayName: 'Human', isHuman: true),
          Player(id: 'ai', displayName: 'AI', isHuman: false),
        ],
      );
    }

    test('failed steal adds tech_thief +1 for human observer', () {
      final game = baseSpyEvidenceGame();
      final entries = evidenceForAiStealTechResolved(
        game,
        'ai',
        4,
        success: false,
      );
      expect(entries.length, 1);
      expect(entries.single.observerId, 'human');
      expect(entries.single.subjectId, 'ai');
      expect(entries.single.agendaType, 'tech_thief');
      expect(entries.single.scoreDelta, 1);
      expect(entries.single.turnNumber, 4);
      expect(entries.single.description, contains('attempt'));
    });

    test('successful steal adds tech_thief +3 for human observer', () {
      final game = baseSpyEvidenceGame();
      final entries = evidenceForAiStealTechResolved(
        game,
        'ai',
        4,
        success: true,
      );
      expect(entries.length, 1);
      expect(entries.single.agendaType, 'tech_thief');
      expect(entries.single.scoreDelta, 3);
      expect(entries.single.description, contains('succeeded'));
    });

    test('human spy owner returns no evidence', () {
      final game = baseSpyEvidenceGame();
      final entries = evidenceForAiStealTechResolved(
        game,
        'human',
        4,
        success: true,
      );
      expect(entries, isEmpty);
    });

    test('no human observer returns no evidence', () {
      final game = evidenceGame(
        turnNumber: 4,
        players: const [
          Player(id: 'ai1', displayName: 'AI1', isHuman: false),
          Player(id: 'ai2', displayName: 'AI2', isHuman: false),
        ],
      );
      final entries = evidenceForAiStealTechResolved(
        game,
        'ai1',
        4,
        success: false,
      );
      expect(entries, isEmpty);
    });
  });
}
