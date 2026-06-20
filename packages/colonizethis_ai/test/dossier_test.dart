import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/package_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:logger/logger.dart';

void main() {
  group('suspicionBandFromScore', () {
    test('0-2 returns unknown', () {
      expect(suspicionBandFromScore(0), SuspicionBand.unknown);
      expect(suspicionBandFromScore(2), SuspicionBand.unknown);
    });
    test('3-5 returns possible', () {
      expect(suspicionBandFromScore(3), SuspicionBand.possible);
      expect(suspicionBandFromScore(5), SuspicionBand.possible);
    });
    test('6-8 returns likely', () {
      expect(suspicionBandFromScore(6), SuspicionBand.likely);
      expect(suspicionBandFromScore(8), SuspicionBand.likely);
    });
    test('9-10 returns almostCertain', () {
      expect(suspicionBandFromScore(9), SuspicionBand.almostCertain);
      expect(suspicionBandFromScore(10), SuspicionBand.almostCertain);
    });
    test('above 10 returns confirmed', () {
      expect(suspicionBandFromScore(11), SuspicionBand.confirmed);
    });
  });

  group('getDossierForSubject', () {
    Game _gameWithEvidence(List<DossierEvidenceEntry> entries) {
      return Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'obs', displayName: 'Observer', isHuman: true),
          Player(id: 'subj', displayName: 'Subject', isHuman: false),
        ],
        dossierEvidenceEntries: entries,
      );
    }

    test('empty evidence returns empty suspicion and evidence list', () {
      final game = _gameWithEvidence([]);
      final d = getDossierForSubject(game, 'obs', 'subj');
      expect(d.subjectId, 'subj');
      expect(d.suspicionByAgendaType, isEmpty);
      expect(d.evidenceList, isEmpty);
    });

    test('single entry aggregates score and maps to band', () {
      final game = _gameWithEvidence([
        const DossierEvidenceEntry(
          observerId: 'obs',
          subjectId: 'subj',
          agendaType: 'warmonger',
          turnNumber: 1,
          description: 'Declared war',
          scoreDelta: 4,
        ),
      ]);
      final d = getDossierForSubject(game, 'obs', 'subj');
      expect(d.suspicionByAgendaType['warmonger'], SuspicionBand.possible);
      expect(d.evidenceList, ['Turn 1: Declared war']);
    });

    test('multiple entries for same agenda sum scoreDelta', () {
      final game = _gameWithEvidence([
        const DossierEvidenceEntry(
          observerId: 'obs',
          subjectId: 'subj',
          agendaType: 'backstabber',
          turnNumber: 1,
          description: 'Broke alliance',
          scoreDelta: 3,
        ),
        const DossierEvidenceEntry(
          observerId: 'obs',
          subjectId: 'subj',
          agendaType: 'backstabber',
          turnNumber: 2,
          description: 'Surprise attack',
          scoreDelta: 5,
        ),
      ]);
      final d = getDossierForSubject(game, 'obs', 'subj');
      expect(d.suspicionByAgendaType['backstabber'], SuspicionBand.likely);
      expect(d.evidenceList.length, 2);
    });

    test('filters by observerId and subjectId', () {
      final game = _gameWithEvidence([
        const DossierEvidenceEntry(
          observerId: 'obs',
          subjectId: 'subj',
          agendaType: 'warmonger',
          turnNumber: 1,
          description: 'For obs-subj',
        ),
        const DossierEvidenceEntry(
          observerId: 'other',
          subjectId: 'subj',
          agendaType: 'warmonger',
          turnNumber: 1,
          description: 'Other observer',
        ),
        const DossierEvidenceEntry(
          observerId: 'obs',
          subjectId: 'other',
          agendaType: 'warmonger',
          turnNumber: 1,
          description: 'Other subject',
        ),
      ]);
      final d = getDossierForSubject(game, 'obs', 'subj');
      expect(d.evidenceList, ['Turn 1: For obs-subj']);
    });

    test('includes basic intel when players and relation exist', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'obs', displayName: 'Observer', isHuman: true, militaryLevel: 2, treasury: 100),
          Player(id: 'napoleon', displayName: 'France', isHuman: false, militaryLevel: 3, treasury: 50),
        ],
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'obs',
            factionId2: 'napoleon',
            score: 40,
            level: RelationLevel.neutral,
            state: RelationState.atPeace,
          ),
        ],
        dossierEvidenceEntries: [],
      );
      final d = getDossierForSubject(game, 'obs', 'napoleon');
      expect(d.basicIntel, isNotNull);
      expect(d.basicIntel!.relationLevel, RelationLevel.neutral);
      expect(d.basicIntel!.relationState, RelationState.atPeace);
      expect(d.basicIntel!.relativeMilitaryStrength, RelativeStrength.stronger);
      expect(d.basicIntel!.relativeEconomicStrength, RelativeStrength.weaker);
      expect(d.basicIntel!.personalityArchetype, 'Fortifier');
    });

    test('includes best-guess agenda and confidence from highest suspicion', () {
      final game = _gameWithEvidence([
        const DossierEvidenceEntry(
          observerId: 'obs',
          subjectId: 'subj',
          agendaType: 'warmonger',
          turnNumber: 1,
          description: 'declared war on weaker neighbor',
          scoreDelta: 6,
        ),
      ]);
      final d = getDossierForSubject(game, 'obs', 'subj');
      expect(d.bestGuessAgenda, isNotNull);
      expect(d.bestGuessAgenda!.agendaType, 'warmonger');
      expect(d.bestGuessAgenda!.confidencePercent, 60);
    });

    test('confidencePercentFromScore returns 0 for 0-2, 25 for 3-5, 60 for 6-8, 85 for 9-10, 100 for 11+', () {
      expect(confidencePercentFromScore(0), 0);
      expect(confidencePercentFromScore(2), 0);
      expect(confidencePercentFromScore(3), 25);
      expect(confidencePercentFromScore(5), 25);
      expect(confidencePercentFromScore(6), 60);
      expect(confidencePercentFromScore(8), 60);
      expect(confidencePercentFromScore(9), 85);
      expect(confidencePercentFromScore(10), 85);
      expect(confidencePercentFromScore(11), 100);
    });

    test('behavioral notes summarize evidence', () {
      final game = _gameWithEvidence([
        const DossierEvidenceEntry(
          observerId: 'obs',
          subjectId: 'subj',
          agendaType: 'warmonger',
          turnNumber: 1,
          description: 'declared war on weaker neighbor',
          scoreDelta: 2,
        ),
        const DossierEvidenceEntry(
          observerId: 'obs',
          subjectId: 'subj',
          agendaType: 'warmonger',
          turnNumber: 3,
          description: 'declared war on weaker neighbor',
          scoreDelta: 2,
        ),
        const DossierEvidenceEntry(
          observerId: 'obs',
          subjectId: 'subj',
          agendaType: 'peacemaker',
          turnNumber: 2,
          description: 'offered peace',
          scoreDelta: 1,
        ),
      ]);
      final d = getDossierForSubject(game, 'obs', 'subj');
      expect(d.behavioralNotes, contains('Declared war (2).'));
      expect(d.behavioralNotes, contains('Offered peace (1).'));
    });

    test('timeline is chronological', () {
      final game = _gameWithEvidence([
        const DossierEvidenceEntry(
          observerId: 'obs',
          subjectId: 'subj',
          agendaType: 'backstabber',
          turnNumber: 5,
          description: 'B',
        ),
        const DossierEvidenceEntry(
          observerId: 'obs',
          subjectId: 'subj',
          agendaType: 'warmonger',
          turnNumber: 2,
          description: 'A',
        ),
      ]);
      final d = getDossierForSubject(game, 'obs', 'subj');
      expect(d.timeline, ['Turn 2: A', 'Turn 5: B']);
    });

    test('evidence list is chronological and capped to most recent entries', () {
      const cap = 50; // kMaxDossierEvidenceEntries in colonizethis_data.
      final entries = <DossierEvidenceEntry>[];
      for (var turn = 1; turn <= cap + 10; turn++) {
        entries.add(DossierEvidenceEntry(
          observerId: 'obs',
          subjectId: 'subj',
          agendaType: 'warmonger',
          turnNumber: turn,
          description: 'E$turn',
          scoreDelta: 1,
        ));
      }
      final game = _gameWithEvidence(entries);
      final d = getDossierForSubject(game, 'obs', 'subj');
      expect(d.evidenceList.length, cap);
      expect(d.evidenceList.first, 'Turn 11: E11');
      expect(d.evidenceList.last, 'Turn 60: E60');
    });

    test(
      'result is identical whether debug logging is filtered or enabled '
      '(guarded hot-path log is behaviour-preserving) (Refs #3288 AC7)',
      () {
        final game = _gameWithEvidence([
          const DossierEvidenceEntry(
            observerId: 'obs',
            subjectId: 'subj',
            agendaType: 'warmonger',
            turnNumber: 1,
            description: 'Declared war',
            scoreDelta: 4,
          ),
        ]);
        final original = CtLogger.level;
        addTearDown(() => CtLogger.level = original);

        CtLogger.level = Level.warning;
        final filtered = getDossierForSubject(game, 'obs', 'subj');

        CtLogger.level = Level.debug;
        final enabled = getDossierForSubject(game, 'obs', 'subj');

        expect(filtered.subjectId, enabled.subjectId);
        expect(
          filtered.suspicionByAgendaType,
          enabled.suspicionByAgendaType,
        );
        expect(filtered.evidenceList, enabled.evidenceList);
        expect(
          filtered.suspicionByAgendaType['warmonger'],
          SuspicionBand.possible,
        );
      },
    );
  });
}
