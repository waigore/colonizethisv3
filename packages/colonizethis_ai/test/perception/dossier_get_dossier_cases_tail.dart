import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/package_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:logger/logger.dart';

import '../support/dossier_test_support.dart';

void registerDossierGetDossierTailCases() {
  group('getDossierForSubject tail', () {
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
      final game = dossierGameWithEvidence(entries);
      final d = getDossierForSubject(game, 'obs', 'subj');
      expect(d.evidenceList.length, cap);
      expect(d.evidenceList.first, 'Turn 11: E11');
      expect(d.evidenceList.last, 'Turn 60: E60');
    });

    test(
      'result is identical whether debug logging is filtered or enabled '
      '(guarded hot-path log is behaviour-preserving) (Refs #3288 AC7)',
      () {
        final game = dossierGameWithEvidence([
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
