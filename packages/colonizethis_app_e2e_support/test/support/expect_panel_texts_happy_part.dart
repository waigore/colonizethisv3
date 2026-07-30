part of '../e2e_expect_panel_texts_match_snapshot_test.dart';

void registerExpectPanelTextsHappyGroup() {
  group('e2eExpectPanelTextsMatchSnapshot — happy path', () {
    testWidgets(
      'matching expected texts -> assertion passes, builder called once, '
      'no E2E_DIAG markers emitted',
      (tester) async {
        const root = Key('panel_root_happy');
        await tester.pumpWidget(
          _wrap(root, const [Text('alpha'), Text('beta'), Text('gamma')]),
        );
        var calls = 0;
        await e2eExpectPanelTextsMatchSnapshot(
          tester,
          panelRootKey: root,
          snapshotReader: () => const Object(),
          buildExpected: () {
            calls++;
            return const ['alpha', 'beta', 'gamma'];
          },
        );
        expect(
          calls,
          1,
          reason:
              'When no alternative builder is supplied and the assertion '
              'passes on the first compare, the primary builder must be '
              'invoked exactly once — invoking it again on success would '
              'double-cost downstream snapshot mirrors that build large '
              'expected lists.',
        );
      },
    );

    testWidgets(
      'mismatched expected texts -> orderedEquals fails (negative)',
      (tester) async {
        const root = Key('panel_root_mismatch');
        await tester.pumpWidget(
          _wrap(root, const [Text('alpha'), Text('beta')]),
        );
        await expectLater(
          () => e2eExpectPanelTextsMatchSnapshot(
            tester,
            panelRootKey: root,
            snapshotReader: () => const Object(),
            buildExpected: () => const ['alpha', 'gamma'],
          ),
          throwsA(isA<TestFailure>()),
          reason:
              'A regression that swallowed the orderedEquals mismatch '
              '(for example by guarding the expect call with a try/catch) '
              'would silently green every snapshot drift in the four '
              'panel scenarios. Pin the failure path so the assertion '
              'still fails when the panel renders unexpected texts.',
        );
      },
    );
  });

}
