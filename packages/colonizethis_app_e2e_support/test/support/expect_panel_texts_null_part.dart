part of '../e2e_expect_panel_texts_match_snapshot_test.dart';

void registerExpectPanelTextsNullGuardGroup() {
  group('e2eExpectPanelTextsMatchSnapshot — null-snapshot guard', () {
    testWidgets(
      'snapshotReader stays null after panel mounts -> assertion fails with '
      'a panel-root-keyed reason',
      (tester) async {
        const root = Key('panel_root_null_snapshot');
        await tester.pumpWidget(_wrap(root, const [Text('whatever')]));
        try {
          await e2eExpectPanelTextsMatchSnapshot(
            tester,
            panelRootKey: root,
            snapshotReader: () => null,
            buildExpected: () => const ['whatever'],
            snapshotReaderTimeout: const Duration(milliseconds: 50),
          );
          fail(
            'expected the helper to throw a TestFailure when the '
            'snapshot reader returns null',
          );
        } on TestFailure catch (e) {
          expect(
            e.message,
            isNotNull,
            reason: 'TestFailure messages must be populated for diagnosis.',
          );
          expect(
            e.message!,
            contains('panel_root_null_snapshot'),
            reason:
                'A regression that dropped the panel root key from the '
                'reason: argument would surface a generic null check '
                'failure with no panel attribution. Pin the key in the '
                'failure message so callers can trace which mirror failed '
                'to prime its CtE2e* snapshot.',
          );
        }
      },
    );

    testWidgets(
      'snapshotReader stays null -> primary builder is never invoked',
      (tester) async {
        const root = Key('panel_root_null_snapshot_no_call');
        await tester.pumpWidget(_wrap(root, const [Text('only')]));
        var called = false;
        try {
          await e2eExpectPanelTextsMatchSnapshot(
            tester,
            panelRootKey: root,
            snapshotReader: () => null,
            buildExpected: () {
              called = true;
              return const ['only'];
            },
            snapshotReaderTimeout: const Duration(milliseconds: 50),
          );
        } on TestFailure {
          // Expected — null guard fires before the builder runs.
        }
        expect(
          called,
          isFalse,
          reason:
              'A regression that called buildExpected before the '
              'null-snapshot guard would dereference a null `snap!` inside '
              'the panel-specific expected-texts function, producing a '
              'confusing Null check operator stack trace instead of the '
              'pin-friendly TestFailure carrying the panel root key.',
        );
      },
    );
  });

}
