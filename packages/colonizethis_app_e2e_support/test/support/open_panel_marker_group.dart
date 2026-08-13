library;

import 'dart:async';
import 'package:colonizethis_app_e2e_support/e2e_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'open_panel_via_rail_or_marker_harness.dart';

void registerOpenPanelViaMarkerGroup() {
  testWidgets('e2eOpenPanelViaRailOrMarker interpolates openerLabel into every '
      'derived phase label and the final open_panel_<label> perf-timing '
      'slice', (WidgetTester tester) async {
    // Telemetry-stability pin: the helper derives every internal
    // phase label from the `openerLabel` argument
    // (`pump_until_<label>_panel_after_trigger_tap`,
    // `open_panel_<label>`, etc.). A regression that swapped a
    // hardcoded literal back into the helper (`pump_until_civilian_…`
    // unconditionally) would orphan downstream `E2E_TIMING|phase=...`
    // log scrapers for non-civilian openers and silently break naval
    // telemetry for the same wall-clock event. Capturing debugPrint
    // here pins that the `openerLabel` round-trips into the timing
    // emit.
    final captured = <String>[];
    final originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) {
        captured.add(message);
      }
    };
    try {
      final counter = TapCounter();
      await tester.pumpWidget(RailMarkerPanelHarness(counter));
      final perf = E2ePerfLog('pin_opener_label_interpolation');
      await e2eOpenPanelViaRailOrMarker(
        tester,
        openerLabel: 'custom_label',
        railButton: find.byKey(kRailKey),
        markerButton: find.byKey(kMarkerKey),
        panelRoot: find.byKey(kPanelKey),
        afterSheetPanelsClearPhase: 'pin_after_sheet_clear',
        overallTimeout: const Duration(seconds: 5),
        perf: perf,
        timeoutMessageBuilder: (_) =>
            'pin_opener_label_interpolation should not time out',
      );
      expect(
        captured.any(
          (line) =>
              line.contains('E2E_TIMING') &&
              line.contains('phase=open_panel_custom_label'),
        ),
        isTrue,
        reason:
            'The final open_panel_<openerLabel> perf-timing slice must '
            'embed the caller-supplied openerLabel so downstream '
            '`E2E_TIMING|phase=...` log scrapers keep attributing the '
            'opener wall-clock event to the correct opener (Refs '
            'GitHub #2336 AC1 / AC2).',
      );
    } finally {
      debugPrint = originalDebugPrint;
    }
  });

  testWidgets(
    'AC1 barrel alias `openPanelViaRailOrMarker` forwards to the shared '
    'implementation with the documented signature',
    (WidgetTester tester) async {
      // Compile-time alias signature pin: the tear-off must assign to a
      // matching function type from the barrel without an explicit cast.
      // A future signature drift here (renamed parameters, added
      // required arg, or return-type change) would fail at compile time
      // so consumers of the AC1 barrel cannot silently switch to a
      // different recipe.
      final Future<void> Function(
        WidgetTester, {
        required String openerLabel,
        required Finder railButton,
        required Finder markerButton,
        required Finder panelRoot,
        required String afterSheetPanelsClearPhase,
        required String Function(Duration timeout) timeoutMessageBuilder,
        Duration overallTimeout,
        Duration bottomSheetCloseTimeout,
        Duration mountTimeout,
        E2ePerfLog? perf,
      })
      tearOff = openPanelViaRailOrMarker;
      final counter = TapCounter();
      await tester.pumpWidget(
        RailMarkerPanelHarness(counter, panelMounted: true),
      );
      await tearOff(
        tester,
        openerLabel: 'pin_ac1_barrel_alias',
        railButton: find.byKey(kRailKey),
        markerButton: find.byKey(kMarkerKey),
        panelRoot: find.byKey(kPanelKey),
        afterSheetPanelsClearPhase: 'pin_after_sheet_clear',
        overallTimeout: const Duration(seconds: 1),
        timeoutMessageBuilder: (_) => 'pin_ac1_barrel_alias should not fire',
      );
      expect(counter.rail, 0);
      expect(counter.marker, 0);
    },
  );
}
