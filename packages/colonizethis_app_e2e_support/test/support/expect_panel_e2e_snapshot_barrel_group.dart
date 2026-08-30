// AC1 barrel forwarding pins for per-panel E2E snapshot matchers (#4598).
library;

import 'package:colonizethis_app_l10n/l10n/app_localizations_contract.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_helpers.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart' as shared;

void registerExpectPanelE2eSnapshotBarrelGroup() {
  group(
    'per-panel matchers — AC1 barrel forwarding (compile-time signature pin)',
    () {
      test(
        'expectCivilianPanelMatchesE2eSnapshot is re-exported as a tear-off',
        () {
          final Future<void> Function(
            WidgetTester,
            AppLocalizations, {
            shared.E2ePerfLog? perf,
          })
          ref = expectCivilianPanelMatchesE2eSnapshot;
          expect(
            ref,
            isNotNull,
            reason:
                'A silent removal from the AC1 barrel `show` clause, an '
                'arg-order swap, or a signature change would fail this '
                'assignment at compile time, not at slow-CI E2E time.',
          );
        },
      );

      test(
        'expectNavalPanelMatchesE2eSnapshot is re-exported as a tear-off',
        () {
          final Future<void> Function(
            WidgetTester,
            AppLocalizations, {
            required bool expanded,
            shared.E2ePerfLog? perf,
          })
          ref = expectNavalPanelMatchesE2eSnapshot;
          expect(
            ref,
            isNotNull,
            reason:
                'The naval wrapper must keep the required `expanded:` named '
                'parameter on the AC1 barrel; dropping it back to the '
                'pre-lift positional inline closure shape would break the '
                'full-turn scenario at compile time.',
          );
        },
      );

      test(
        'expectProductionPanelMatchesE2eSnapshot is re-exported as a tear-off',
        () {
          final Future<void> Function(
            WidgetTester,
            AppLocalizations, {
            shared.E2ePerfLog? perf,
          })
          ref = expectProductionPanelMatchesE2eSnapshot;
          expect(ref, isNotNull);
        },
      );

      test(
        'expectProvincePanelMatchesE2eSnapshot is re-exported as a tear-off',
        () {
          final Future<void> Function(
            WidgetTester,
            AppLocalizations, {
            shared.E2ePerfLog? perf,
          })
          ref = expectProvincePanelMatchesE2eSnapshot;
          expect(ref, isNotNull);
        },
      );
    },
  );
}
