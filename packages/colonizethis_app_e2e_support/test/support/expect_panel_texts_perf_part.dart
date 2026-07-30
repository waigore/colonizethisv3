part of '../e2e_expect_panel_texts_match_snapshot_test.dart';

void registerExpectPanelTextsPerfGroup() {
  group('e2eExpectPanelTextsMatchSnapshot — perf attribution', () {
    testWidgets('phaseName forwards into the wait-until-found timing event', (
      tester,
    ) async {
      const root = Key('panel_root_phase_forward');
      await tester.pumpWidget(_wrap(root, const [Text('only')]));
      final perf = shared.E2ePerfLog('expect_panel_texts_pin');
      final lines = await _captureDebugPrints(() async {
        await e2eExpectPanelTextsMatchSnapshot(
          tester,
          panelRootKey: root,
          snapshotReader: () => const Object(),
          buildExpected: () => const ['only'],
          phaseName: 'pin_panel_phase',
          perf: perf,
        );
      });
      expect(
        lines.where(
          (line) =>
              line.startsWith('E2E_TIMING|') &&
              line.contains('|phase=pin_panel_phase|'),
        ),
        isNotEmpty,
        reason:
            'The wait-until-found gate inside the helper must forward the '
            'caller-supplied `phaseName` into its timing event so AC8 '
            'tables keep their per-panel attribution. A regression that '
            'hard-coded the default phase would silently merge '
            '`wait_until_found_civilian_panel` / `_naval_panel` / '
            '`_production_panel` / `open_panel_province` into one bucket.',
      );
    });
  });

}
