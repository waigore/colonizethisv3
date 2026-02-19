import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

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
  });
}
