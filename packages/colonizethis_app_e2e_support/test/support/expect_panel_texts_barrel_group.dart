library;

import 'package:colonizethis_app_e2e_support/e2e_helpers.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart' as shared;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'expect_panel_texts_harness.dart';

void registerExpectPanelTextsBarrelGroup() {
  group('e2eExpectPanelTextsMatchSnapshot — AC1 barrel forwarding', () {
    testWidgets(
      'expectPanelTextsMatchSnapshot (barrel alias) is wired to the '
      'lifted form',
      (tester) async {
        const root = Key('panel_root_barrel');
        await tester.pumpWidget(
          wrap(root, const [Text('alpha'), Text('beta')]),
        );
        await expectPanelTextsMatchSnapshot(
          tester,
          panelRootKey: root,
          snapshotReader: () => const Object(),
          buildExpected: () => const ['alpha', 'beta'],
        );
      },
    );

    test(
      'expectPanelTextsMatchSnapshot is re-exported as a tear-off '
      '(compile-time signature pin)',
      () {
        final Future<void> Function(
          WidgetTester, {
          required Key panelRootKey,
          required Object? Function() snapshotReader,
          required List<String> Function() buildExpected,
          String phaseName,
          Duration timeout,
          Duration snapshotReaderTimeout,
          String snapshotReaderPhaseName,
          shared.E2ePerfLog? perf,
          List<String> Function()? buildAlternativeExpected,
          List<String> ignoreActualTexts,
        })
        ref = expectPanelTextsMatchSnapshot;
        expect(
          ref,
          isNotNull,
          reason:
              'The AC1 barrel must keep exporting the helper with the '
              'documented signature. A silent removal from the `show` '
              'clause, an arg-order swap on the wrapper, or a default '
              'change for `phaseName` / `timeout` / '
              '`snapshotReaderTimeout` / `snapshotReaderPhaseName` would '
              'fail this assignment at compile time, not at slow-CI E2E '
              'time.',
        );
      },
    );
  });
}
