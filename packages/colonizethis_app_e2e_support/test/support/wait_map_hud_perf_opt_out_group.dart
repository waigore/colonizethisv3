library;

import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared_bootstrap.dart';

import 'wait_map_hud_harness.dart';

void registerWaitMapHudPerfOptOutGroup() {
  group('e2eWaitForMapHudAfterNewGameStart perf opt-out', () {
    testWidgets('emits no markers when perf is null (default), preserving the '
        'opt-in attribution contract', (WidgetTester tester) async {
      await pumpWaitMapHudHost(tester, initial: WaitMapHudSetupPhase.mapHud);
      final lines = <String>[];
      await runWaitMapHudDebugPrintCapture(lines, () async {
        await e2eWaitForMapHudAfterNewGameStart(
          tester,
          overallCap: const Duration(seconds: 5),
        );
      });
      final mapHudMarkers = lines
          .where(
            (line) =>
                line.contains('phase=$kE2eDefaultWaitForMapHudPhase') ||
                line.contains('name=$kE2eWaitForMapHudIterationsCounter'),
          )
          .toList();
      expect(
        mapHudMarkers,
        isEmpty,
        reason:
            'Default `perf: null` must NOT emit any helper-attribution '
            'markers so callers that opt out of attribution (the existing '
            'widget-test pins, ad-hoc scenarios, future low-overhead '
            'integration paths) keep their byte-quiet contract.',
      );
    });
  });
}
