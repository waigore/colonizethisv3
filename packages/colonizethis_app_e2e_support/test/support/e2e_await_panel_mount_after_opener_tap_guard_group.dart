// Extracted from e2e_await_panel_mount_after_opener_tap_test.dart
// (#4598 Slice C).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_helpers.dart';

import 'e2e_widget_pump_harness.dart';

const _kPanelKey = ValueKey<String>('e2e_await_panel_mount_panel');

void registerAwaitPanelMountAfterOpenerTapGuardGroup() {
  testWidgets(
    'e2eAwaitPanelMountAfterOpenerTap returns false without throwing when '
    'the panel never mounts within the timeout',
    (WidgetTester tester) async {
      await pumpE2eEmptyApp(tester);
      Object? caught;
      bool? result;
      try {
        result = await e2eAwaitPanelMountAfterOpenerTap(
          tester,
          find.byKey(_kPanelKey),
          timeout: const Duration(milliseconds: 150),
          phaseName: 'pin_never_mounts_timeout',
        );
      } catch (e) {
        caught = e;
      }
      expect(
        caught,
        isNull,
        reason:
            'Best-effort variant must NOT call fail() on timeout so the '
            'opener tryOpen closure can return false and let the outer '
            'loop dismiss transient overlays and retry the rail/marker '
            'tap (Refs GitHub #2336 AC10).',
      );
      expect(
        result,
        isFalse,
        reason:
            'Persistent not-mounted panel must surface as a false return '
            'so the opener tryOpen closure can decide whether to retry '
            'the rail/marker branch on the outer adaptive-poll loop '
            '(Refs GitHub #2336 AC1).',
      );
    },
  );

  testWidgets('e2eAwaitPanelMountAfterOpenerTap accepts a custom phaseName and '
      'E2ePerfLog on the success path', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrapE2eScaffold(
        const KeyedSubtree(
          key: _kPanelKey,
          child: SizedBox(width: 100, height: 100),
        ),
      ),
    );
    final perf = E2ePerfLog('e2e_await_panel_mount_after_opener_tap_test');
    final result = await e2eAwaitPanelMountAfterOpenerTap(
      tester,
      find.byKey(_kPanelKey),
      timeout: const Duration(seconds: 2),
      perf: perf,
      phaseName: 'pin_perf_success',
    );
    expect(result, isTrue);
  });

  testWidgets('e2eAwaitPanelMountAfterOpenerTap accepts a custom phaseName and '
      'E2ePerfLog on the timeout path without escalating to fail()', (
    WidgetTester tester,
  ) async {
    await pumpE2eEmptyApp(tester);
    final perf = E2ePerfLog('e2e_await_panel_mount_after_opener_tap_test');
    final result = await e2eAwaitPanelMountAfterOpenerTap(
      tester,
      find.byKey(_kPanelKey),
      timeout: const Duration(milliseconds: 80),
      perf: perf,
      phaseName: 'pin_perf_timeout',
    );
    expect(
      result,
      isFalse,
      reason:
          'Passing a perf log on the timeout path must keep the '
          'best-effort `false` return; perf is observability metadata '
          'only and must not promote the timeout into a fail() call '
          '(Refs GitHub #2336 AC1 / AC10).',
    );
  });

  testWidgets(
    'AC1 barrel alias `awaitPanelMountAfterOpenerTap` forwards to the '
    'shared implementation with the documented signature',
    (WidgetTester tester) async {
      final Future<bool> Function(
        WidgetTester,
        Finder, {
        required Duration timeout,
        E2ePerfLog? perf,
        required String phaseName,
      })
      tearOff = awaitPanelMountAfterOpenerTap;
      await tester.pumpWidget(
        wrapE2eScaffold(
          const KeyedSubtree(
            key: _kPanelKey,
            child: SizedBox(width: 100, height: 100),
          ),
        ),
      );
      final result = await tearOff(
        tester,
        find.byKey(_kPanelKey),
        timeout: const Duration(seconds: 1),
        phaseName: 'pin_ac1_barrel_alias',
      );
      expect(result, isTrue);
    },
  );
}
