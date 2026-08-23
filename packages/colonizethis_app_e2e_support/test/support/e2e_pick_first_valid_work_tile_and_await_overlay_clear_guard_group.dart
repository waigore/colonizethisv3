// Extracted from e2e_pick_first_valid_work_tile_and_await_overlay_clear_test.dart (#4598 Slice C).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';
import 'work_tile_overlay_host_harness.dart';

void registerE2ePickFirstValidWorkTileAndAwaitOverlayClearGuardGroup() {
  group('Perf wiring', () {
    testWidgets(
      'strict variant forwards appearPhase and clearPhase verbatim through '
      'e2eWaitUntilFound and e2ePumpUntil',
      (WidgetTester tester) async {
        await tester.pumpWidget(const WorkTileOverlayHost());
        final perf = E2ePerfLog('work_tile_strict_phase');

        final lines = <String>[];
        final original = debugPrint;
        debugPrint = (String? message, {int? wrapWidth}) {
          lines.add(message ?? '');
        };
        try {
          await e2ePickFirstValidWorkTileAndAwaitOverlayClear(
            tester,
            appearPhase: 'custom_appear_phase',
            clearPhase: 'custom_clear_phase',
            perf: perf,
          );
        } finally {
          debugPrint = original;
        }

        expect(
          lines.any(
            (l) =>
                l.startsWith('E2E_TIMING') &&
                l.contains('phase=custom_appear_phase'),
          ),
          isTrue,
          reason:
              'appearPhase must be forwarded verbatim to e2eWaitUntilFound — '
              'log scrapers and dashboards key on the exact phase literal.',
        );
        expect(
          lines.any(
            (l) =>
                l.startsWith('E2E_TIMING') &&
                l.contains('phase=custom_clear_phase'),
          ),
          isTrue,
          reason:
              'clearPhase must be forwarded verbatim to e2ePumpUntil — log '
              'scrapers and dashboards key on the exact phase literal.',
        );
      },
    );
  });
}
