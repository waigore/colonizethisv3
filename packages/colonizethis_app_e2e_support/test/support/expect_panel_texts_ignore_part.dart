part of '../e2e_expect_panel_texts_match_snapshot_test.dart';

void registerExpectPanelTextsIgnoreGroup() {
  group('e2eExpectPanelTextsMatchSnapshot — ignoreActualTexts normalization', () {
    testWidgets(
      'host-width-dependent labels are dropped from actual before the ordered '
      'compare (labeled host -> matches icon-only mirror)',
      (tester) async {
        const root = Key('panel_root_ignore_labeled');
        // Simulates the wider Linux host where the dense fleet-action cluster
        // renders Move/Split as Text between the home chip and the location.
        await tester.pumpWidget(
          _wrap(root, const [
            Text('Home Fleet'),
            Text('HOME'),
            Text('Split'),
            Text('Old World — London (in port)'),
            Text('Mission: None'),
          ]),
        );
        await e2eExpectPanelTextsMatchSnapshot(
          tester,
          panelRootKey: root,
          snapshotReader: () => const Object(),
          // Canonical icon-only mirror: no Split label.
          buildExpected: () => const [
            'Home Fleet',
            'HOME',
            'Old World — London (in port)',
            'Mission: None',
          ],
          ignoreActualTexts: const ['Move', 'Split'],
        );
      },
    );

    testWidgets(
      'icon-only host (no labels present) still matches with the same filter '
      '(filter is a no-op when the labels are absent)',
      (tester) async {
        const root = Key('panel_root_ignore_icononly');
        await tester.pumpWidget(
          _wrap(root, const [
            Text('Home Fleet'),
            Text('HOME'),
            Text('Old World — London (in port)'),
            Text('Mission: None'),
          ]),
        );
        await e2eExpectPanelTextsMatchSnapshot(
          tester,
          panelRootKey: root,
          snapshotReader: () => const Object(),
          buildExpected: () => const [
            'Home Fleet',
            'HOME',
            'Old World — London (in port)',
            'Mission: None',
          ],
          ignoreActualTexts: const ['Move', 'Split'],
        );
      },
    );

    testWidgets(
      'filter does not mask non-action drift -> a genuinely missing mirror '
      'line still fails (negative)',
      (tester) async {
        const root = Key('panel_root_ignore_negative');
        await tester.pumpWidget(
          _wrap(root, const [
            Text('Home Fleet'),
            Text('Split'),
            // 'Mission: None' missing -> real drift must still surface.
          ]),
        );
        await expectLater(
          () => e2eExpectPanelTextsMatchSnapshot(
            tester,
            panelRootKey: root,
            snapshotReader: () => const Object(),
            buildExpected: () => const ['Home Fleet', 'Mission: None'],
            ignoreActualTexts: const ['Move', 'Split'],
          ),
          throwsA(isA<TestFailure>()),
          reason:
              'ignoreActualTexts must remove ONLY the named host-dependent '
              'action labels; it must not relax the ordered comparison of any '
              'other line, so a genuinely missing mirror line still fails.',
        );
      },
    );
  });

}
