library;

import 'package:colonizethis_app_e2e_support/e2e_helpers.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart' as shared;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'expect_panel_texts_harness.dart';

void registerExpectPanelTextsMismatchBGroup() {
  group(
    'e2eExpectPanelTextsMatchSnapshot — alternative-expected anyOf fallback',
    () {
      testWidgets(
        'primary expected matches -> alternative builder is never called',
        (tester) async {
          const root = Key('panel_root_alt_primary');
          await tester.pumpWidget(
            wrap(root, const [Text('alpha'), Text('beta')]),
          );
          var altCalls = 0;
          await e2eExpectPanelTextsMatchSnapshot(
            tester,
            panelRootKey: root,
            snapshotReader: () => const Object(),
            buildExpected: () => const ['alpha', 'beta'],
            buildAlternativeExpected: () {
              altCalls++;
              return const ['x', 'y'];
            },
          );
          expect(
            altCalls,
            1,
            reason:
                'The naval-panel use case relies on `anyOf(orderedEquals(a), '
                'orderedEquals(b))` semantics — `anyOf` evaluates both '
                'matchers up front to produce its or-of-matchers, so the '
                'alternative builder is invoked exactly once even when the '
                'primary already matches. A regression that switched to '
                'short-circuit evaluation would change the perf cost '
                'characteristics of the naval expanded-fallback path; pin '
                'the pre-lift behaviour here.',
          );
        },
      );

      testWidgets(
        'primary fails, alternative matches -> assertion still passes',
        (tester) async {
          const root = Key('panel_root_alt_match');
          await tester.pumpWidget(
            wrap(root, const [Text('collapsed-only')]),
          );
          await e2eExpectPanelTextsMatchSnapshot(
            tester,
            panelRootKey: root,
            snapshotReader: () => const Object(),
            buildExpected: () => const ['expanded-only'],
            buildAlternativeExpected: () => const ['collapsed-only'],
          );
        },
      );

      testWidgets(
        'both expected lists fail -> assertion fails (negative)',
        (tester) async {
          const root = Key('panel_root_alt_both_fail');
          await tester.pumpWidget(wrap(root, const [Text('actual-only')]));
          await expectLater(
            () => e2eExpectPanelTextsMatchSnapshot(
              tester,
              panelRootKey: root,
              snapshotReader: () => const Object(),
              buildExpected: () => const ['expanded-only'],
              buildAlternativeExpected: () => const ['collapsed-only'],
            ),
            throwsA(isA<TestFailure>()),
            reason:
                'When neither variant of a two-state panel matches the '
                'rendered tree, the helper must still fail. A regression '
                'that fell through to a silent pass after both legs missed '
                'would mask real snapshot drift on the naval expanded path.',
          );
        },
      );
    },
  );

}
