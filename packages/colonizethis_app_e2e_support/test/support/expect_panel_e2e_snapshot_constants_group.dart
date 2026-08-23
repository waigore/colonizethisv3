// Default-constant pins for per-panel E2E snapshot matchers (#4598).
library;

import 'package:colonizethis_app_e2e_support/e2e_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void registerExpectPanelE2eSnapshotConstantsGroup() {
  group('per-panel matcher default constants', () {
    test('kE2eExpectCivilianPanelTextsPhase preserves canonical literal', () {
      expect(
        kE2eExpectCivilianPanelTextsPhase,
        'wait_until_found_civilian_panel',
        reason:
            'The pre-lift inline closure forwarded this literal into '
            '`expectPanelTextsMatchSnapshot`; AC8 timing tables key on it. '
            'A silent rename here would orphan the civilian-panel `E2E_TIMING` '
            'attribution bucket.',
      );
    });

    test('kE2eExpectNavalPanelTextsPhase preserves canonical literal', () {
      expect(
        kE2eExpectNavalPanelTextsPhase,
        'wait_until_found_naval_panel',
        reason:
            'The pre-lift inline closure forwarded this literal; AC8 timing '
            'tables key on it. A silent rename would orphan the naval-panel '
            'attribution bucket.',
      );
    });

    test('kE2eExpectProductionPanelTextsPhase preserves canonical literal', () {
      expect(
        kE2eExpectProductionPanelTextsPhase,
        'wait_until_found_production_panel',
        reason:
            'The pre-lift inline closure forwarded this literal; AC8 timing '
            'tables key on it.',
      );
    });

    test(
      'kE2eExpectProvincePanelTextsPhase preserves capital-scenario literal',
      () {
        expect(
          kE2eExpectProvincePanelTextsPhase,
          'open_panel_province',
          reason:
              'The capital-panel scenario pre-lift passed this literal '
              'explicitly (matching the rest of the capital-scenario AC8 '
              'tags); a rename would orphan that bucket too.',
        );
      },
    );

    test('kE2eExpectProvincePanelTextsTimeout preserves the explicit 30-second '
        'budget used by the pre-lift capital-panel assertion', () {
      expect(
        kE2eExpectProvincePanelTextsTimeout,
        const Duration(seconds: 30),
        reason:
            'The capital-panel scenario mounts the province panel later in '
            'its run than the rail panels in the full-turn scenario; the '
            'pre-lift inline call passed 30s explicitly. Collapsing back to '
            'the 20-second default would surface as a flaky capital-panel '
            'wait on the slow CI lane only.',
      );
    });
  });
}
