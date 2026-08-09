part of '../e2e_expect_panel_texts_match_snapshot_test.dart';

void registerExpectPanelTextsMismatchAGroup() {
  group(
    'e2eExpectPanelTextsMatchSnapshot — post-mount async snapshot population',
    () {
      testWidgets(
        'snapshotReader returns null at call time, then non-null after a '
        'pump frame -> assertion passes (race fix for #2336 AC10)',
        (tester) async {
          const root = Key('panel_root_late_snapshot');
          await tester.pumpWidget(
            _wrap(root, const [Text('alpha'), Text('beta')]),
          );
          Object? lateSnapshot;
          // Schedule the snapshot setter to fire on the next post-frame
          // callback, mirroring the production `updateCtE2e*PanelSnapshotIfEnabled`
          // call sites that are invoked from a widget's first build or a
          // post-frame callback after the panel-root finder has already
          // become non-empty. Before the bounded reader poll this race
          // produced the false `null snapshot` failure documented in
          // Refs #2336 AC10.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            lateSnapshot = const Object();
          });
          await e2eExpectPanelTextsMatchSnapshot(
            tester,
            panelRootKey: root,
            snapshotReader: () => lateSnapshot,
            buildExpected: () => const ['alpha', 'beta'],
            snapshotReaderTimeout: const Duration(seconds: 1),
          );
          expect(
            lateSnapshot,
            isNotNull,
            reason:
                'Sanity: the bounded reader poll must have driven enough '
                'pumps for the post-frame callback to fire and populate '
                'the local snapshot mirror; otherwise the race-fix '
                'pin is testing nothing.',
          );
        },
      );

      testWidgets(
        'snapshotReader poll emits a dedicated phase-attribution timing '
        'event keyed on snapshotReaderPhaseName',
        (tester) async {
          const root = Key('panel_root_snapshot_reader_phase');
          await tester.pumpWidget(_wrap(root, const [Text('only')]));
          final perf = shared.E2ePerfLog('expect_panel_texts_reader_phase');
          final lines = await _captureDebugPrints(() async {
            await e2eExpectPanelTextsMatchSnapshot(
              tester,
              panelRootKey: root,
              snapshotReader: () => const Object(),
              buildExpected: () => const ['only'],
              perf: perf,
              snapshotReaderPhaseName: 'pin_snapshot_reader_phase',
              snapshotReaderTimeout: const Duration(milliseconds: 50),
            );
          });
          expect(
            lines.where(
              (line) =>
                  line.startsWith('E2E_TIMING|') &&
                  line.contains('|phase=pin_snapshot_reader_phase|'),
            ),
            isNotEmpty,
            reason:
                'The bounded snapshot-reader poll must forward the '
                'caller-supplied `snapshotReaderPhaseName` into its '
                'timing event so AC8 dashboards keep post-mount '
                'snapshot-population latency separate from the '
                'panel-root mount slice. A regression that hard-coded '
                'the default phase would silently merge the two '
                'buckets.',
          );
        },
      );
    },
  );

}
