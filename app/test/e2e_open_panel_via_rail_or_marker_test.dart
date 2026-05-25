/// Widget-test coverage for `e2eOpenPanelViaRailOrMarker`, the shared
/// rail-or-marker outer adaptive-poll loop that `e2eOpenCivilianPanel` and
/// `e2eOpenNavalPanel` both invoke (passing per-opener `openerLabel`,
/// finders, and `timeoutMessageBuilder`).
///
/// Before this lift each of the two panel openers inlined the same five-arm
/// outer loop body (BottomSheet dismissal → AlertDialog / CtDialogShell
/// dismissal → rail-tap arm → marker fallback arm → bounded rail/marker
/// hit-testable pump → adaptive idle pump) with hand-typed
/// `pump_until_<opener>_*` / `wait_until_<opener>_*` phase labels and a
/// hand-typed `'Timed out after ...'` diagnostic. A regression that
/// diverged either opener — for example dropping the marker arm on naval
/// while keeping it on civilian, or renaming a phase label — would surface
/// only as either a wall-clock regression or orphaned `E2E_TIMING|phase=...`
/// telemetry, both of which the `app_e2e_linux` lane cannot catch today
/// (the lane is a no-op per `SPEC/program/e2e-integration-tests.md` § CI).
/// The widget-test layer therefore carries the behavioural pins for the
/// AC1 "single canonical shared helper", AC2 "no duplicated outer-loop
/// bodies", and AC10 "no silent flakiness from timeout regressions"
/// contracts.
///
/// Pinned branches:
///
///   - Already-hit-testable panel root → fast-path returns without
///     advancing the game-start intro overlay and without tapping any
///     trigger (the post-sheet-close iteration relies on this so a
///     freshly rebuilt panel is not dismissed by a stray rail tap).
///   - Empire rail tap → outer loop selects the rail arm, taps once,
///     and returns when the panel mounts inside the bounded post-tap
///     mount probe.
///   - Marker fallback → rail finder is absent so the helper selects the
///     marker arm (passing `primary: marker, secondary: rail` into the
///     inner [e2eAwaitPanelOpenerRailHitTestable] call to mirror the
///     pre-lift inline order).
///   - Async panel mount → the post-tap mount probe pumps with adaptive
///     backoff until the panel mounts (replaces the legacy fixed
///     300–500ms post-tap settle that AC4 / AC5 retired).
///   - Persistent absence of both triggers → helper escalates to
///     `fail()` with `${timeoutMessageBuilder(overallTimeout)}. Last
///     exception: ...` so per-opener failure attribution stays stable
///     in CI logs.
///   - `timeoutMessageBuilder` callback receives the **configured**
///     `overallTimeout` argument verbatim so a caller that customises
///     the timeout sees its own interpolation reflected in the failure
///     message.
///   - `openerLabel` interpolates into the
///     `pump_until_<openerLabel>_*` / `wait_until_<openerLabel>_*` /
///     `open_panel_<openerLabel>` phase labels so downstream
///     `E2E_TIMING|phase=...` log scrapers keep attributing settle time
///     to the calling opener.
///   - AC1 barrel alias signature pin (compile-time tear-off
///     assignability) so a future signature drift fails at compile time
///     rather than silently switching consumers to a different recipe.
///
/// Refs GitHub #2336 (AC1 — shared helpers; AC2 — single canonical
/// implementation; AC10 — no silent flakiness from timeout regressions).
library;

import 'dart:async';

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_helpers.dart';

const _kRailKey = ValueKey<String>('e2e_opvrom_rail');
const _kMarkerKey = ValueKey<String>('e2e_opvrom_marker');
const _kPanelKey = ValueKey<String>('e2e_opvrom_panel');

class _TapCounter {
  int rail = 0;
  int marker = 0;
}

void main() {
  suppressLogsForTests();

  testWidgets(
    'e2eOpenPanelViaRailOrMarker returns synchronously without tapping '
    'either trigger when the panel root is already hit-testable',
    (WidgetTester tester) async {
      // Pre-lift contract: the panel-already-hit-testable fast-path is
      // critical for the post-sheet-close iteration where the panel can
      // already be rebuilt before the outer loop reaches its rail-tap
      // arm. A regression that always tapped first would dismiss the
      // freshly rebuilt panel on every outer-loop iteration after a
      // sheet close.
      final counter = _TapCounter();
      await tester.pumpWidget(
        _RailMarkerPanelHarness(counter, panelMounted: true),
      );
      await e2eOpenPanelViaRailOrMarker(
        tester,
        openerLabel: 'pin_already_mounted',
        railButton: find.byKey(_kRailKey),
        markerButton: find.byKey(_kMarkerKey),
        panelRoot: find.byKey(_kPanelKey),
        afterSheetPanelsClearPhase: 'pin_after_sheet_clear',
        overallTimeout: const Duration(seconds: 5),
        timeoutMessageBuilder: (_) =>
            'pin_already_mounted timeout should never fire',
      );
      expect(
        counter.rail,
        0,
        reason:
            'Already-hit-testable panel root must short-circuit before '
            'the outer loop reaches its rail-tap arm; a regression that '
            'always tapped would surface as a duplicate panel mount on '
            'every post-sheet-close iteration (Refs GitHub #2336 AC10).',
      );
      expect(
        counter.marker,
        0,
        reason:
            'Already-hit-testable panel root must short-circuit before '
            'the outer loop reaches its marker-fallback arm too; the '
            'short-circuit fires *before* either trigger is evaluated '
            '(Refs GitHub #2336 AC10).',
      );
    },
  );

  testWidgets(
    'e2eOpenPanelViaRailOrMarker taps the rail trigger and returns when '
    'the panel mounts synchronously after the tap',
    (WidgetTester tester) async {
      // Rail-tap branch: outer loop selects the rail arm before
      // evaluating the marker arm so a regression that swapped arm
      // priority (e.g. marker-first) would silently change the
      // post-tap mount attribution for the civilian and naval openers
      // even though both arms can mount the same panel root in fixture
      // harnesses.
      final counter = _TapCounter();
      await tester.pumpWidget(_RailMarkerPanelHarness(counter));
      await e2eOpenPanelViaRailOrMarker(
        tester,
        openerLabel: 'pin_rail_tap',
        railButton: find.byKey(_kRailKey),
        markerButton: find.byKey(_kMarkerKey),
        panelRoot: find.byKey(_kPanelKey),
        afterSheetPanelsClearPhase: 'pin_after_sheet_clear',
        overallTimeout: const Duration(seconds: 5),
        timeoutMessageBuilder: (_) => 'pin_rail_tap timeout should never fire',
      );
      expect(
        counter.rail,
        1,
        reason:
            'Rail arm must dispatch exactly one tap on the success path; '
            'a regression that double-tapped would dismiss the freshly '
            'opened panel via the pop route stack (Refs GitHub #2336 '
            'AC10).',
      );
      expect(
        counter.marker,
        0,
        reason:
            'Marker arm must not fire when the rail arm already mounted '
            'the panel; a regression that fell through to the marker '
            'arm would silently double-tap the panel surface (Refs '
            'GitHub #2336 AC1).',
      );
      expect(find.byKey(_kPanelKey), findsOneWidget);
    },
  );

  testWidgets(
    'e2eOpenPanelViaRailOrMarker falls back to the marker trigger when '
    'the rail finder resolves to zero elements',
    (WidgetTester tester) async {
      // Marker fallback path: when the empire rail button is not in the
      // tree (typical when the rail rebuild races a transient overlay),
      // the helper must take the marker arm rather than spinning on the
      // bounded rail/marker hit-testable pump.
      final counter = _TapCounter();
      await tester.pumpWidget(_MarkerOnlyPanelHarness(counter));
      await e2eOpenPanelViaRailOrMarker(
        tester,
        openerLabel: 'pin_marker_fallback',
        railButton: find.byKey(_kRailKey),
        markerButton: find.byKey(_kMarkerKey),
        panelRoot: find.byKey(_kPanelKey),
        afterSheetPanelsClearPhase: 'pin_after_sheet_clear',
        overallTimeout: const Duration(seconds: 5),
        timeoutMessageBuilder: (_) =>
            'pin_marker_fallback timeout should never fire',
      );
      expect(
        counter.rail,
        0,
        reason:
            'Rail arm must not fire when the rail trigger finder is '
            'empty; a regression that tapped a stale reference would '
            'crash with a tap-without-target (Refs GitHub #2336 AC1).',
      );
      expect(
        counter.marker,
        1,
        reason:
            'Marker arm must dispatch the fallback tap exactly once '
            'when the rail finder resolves to zero elements (Refs '
            'GitHub #2336 AC1 / AC10).',
      );
      expect(find.byKey(_kPanelKey), findsOneWidget);
    },
  );

  testWidgets('e2eOpenPanelViaRailOrMarker returns once the panel root mounts '
      'asynchronously after the rail tap (adaptive polling)', (
    WidgetTester tester,
  ) async {
    // Async-mount path exercises the bounded post-tap mount probe
    // inside the inner [e2eOpenerTapTriggerAndAwaitMount]: the helper
    // must keep pumping past the post-tap fast-check until the panel
    // mounts. A regression that promoted the mount probe to a strict
    // [e2ePumpUntil] would surface as a hard TestFailure inside the
    // outer loop rather than this success-with-async-mount path.
    final counter = _TapCounter();
    await tester.pumpWidget(
      _DelayedPanelHarness(
        counter,
        mountAfter: const Duration(milliseconds: 60),
      ),
    );
    expect(find.byKey(_kPanelKey), findsNothing);
    await e2eOpenPanelViaRailOrMarker(
      tester,
      openerLabel: 'pin_async_mount',
      railButton: find.byKey(_kRailKey),
      markerButton: find.byKey(_kMarkerKey),
      panelRoot: find.byKey(_kPanelKey),
      afterSheetPanelsClearPhase: 'pin_after_sheet_clear',
      overallTimeout: const Duration(seconds: 5),
      timeoutMessageBuilder: (_) => 'pin_async_mount timeout should never fire',
    );
    expect(
      counter.rail,
      1,
      reason:
          'Rail arm must dispatch exactly one tap before the post-tap '
          'mount probe begins polling; double-tapping would dismiss '
          'the freshly opened panel (Refs GitHub #2336 AC10).',
    );
    expect(find.byKey(_kPanelKey), findsOneWidget);
  });

  testWidgets('e2eOpenPanelViaRailOrMarker fails with TestFailure when neither '
      'trigger surfaces, and forwards the configured overallTimeout into '
      'timeoutMessageBuilder', (WidgetTester tester) async {
    // Persistent-absence path: the outer loop must escalate to
    // `fail()` rather than silently returning, so per-opener failure
    // attribution stays stable in CI logs. The
    // `timeoutMessageBuilder` callback must receive the **configured**
    // overallTimeout argument verbatim so a caller's
    // `'Timed out after ${t.inSeconds}s ...'` interpolation reflects
    // the actual cap rather than a hardcoded default.
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    const overallTimeout = Duration(milliseconds: 200);
    Duration? captured;
    Object? caught;
    try {
      await e2eOpenPanelViaRailOrMarker(
        tester,
        openerLabel: 'pin_timeout',
        railButton: find.byKey(_kRailKey),
        markerButton: find.byKey(_kMarkerKey),
        panelRoot: find.byKey(_kPanelKey),
        afterSheetPanelsClearPhase: 'pin_after_sheet_clear',
        overallTimeout: overallTimeout,
        timeoutMessageBuilder: (t) {
          captured = t;
          return 'pin_timeout diagnostic for ${t.inMilliseconds}ms';
        },
      );
    } catch (e) {
      caught = e;
    }
    expect(
      caught,
      isA<TestFailure>(),
      reason:
          'Persistent absence of both rail and marker must surface a '
          'TestFailure rather than silently returning (Refs GitHub '
          '#2336 AC10).',
    );
    expect(
      captured,
      overallTimeout,
      reason:
          'timeoutMessageBuilder must receive the configured '
          'overallTimeout argument so caller interpolation reflects '
          'the real cap, not a hardcoded default (Refs GitHub #2336 '
          'AC10 — attribution stability).',
    );
    expect(
      (caught! as TestFailure).message,
      contains('pin_timeout diagnostic for 200ms'),
      reason:
          'The fail() string must embed the caller-supplied '
          'diagnostic verbatim so CI logs attribute the timeout to '
          'the calling opener (Refs GitHub #2336 AC10).',
    );
  });

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
      final counter = _TapCounter();
      await tester.pumpWidget(_RailMarkerPanelHarness(counter));
      final perf = E2ePerfLog('pin_opener_label_interpolation');
      await e2eOpenPanelViaRailOrMarker(
        tester,
        openerLabel: 'custom_label',
        railButton: find.byKey(_kRailKey),
        markerButton: find.byKey(_kMarkerKey),
        panelRoot: find.byKey(_kPanelKey),
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
      final counter = _TapCounter();
      await tester.pumpWidget(
        _RailMarkerPanelHarness(counter, panelMounted: true),
      );
      await tearOff(
        tester,
        openerLabel: 'pin_ac1_barrel_alias',
        railButton: find.byKey(_kRailKey),
        markerButton: find.byKey(_kMarkerKey),
        panelRoot: find.byKey(_kPanelKey),
        afterSheetPanelsClearPhase: 'pin_after_sheet_clear',
        overallTimeout: const Duration(seconds: 1),
        timeoutMessageBuilder: (_) => 'pin_ac1_barrel_alias should not fire',
      );
      expect(counter.rail, 0);
      expect(counter.marker, 0);
    },
  );
}

/// Hit-testable panel root used by the test fixtures. Mirrors the panel-root
/// fixture in `e2e_opener_tap_trigger_and_await_mount_test.dart` (a
/// [ColoredBox] paints opaque pixels and participates in hit-testing,
/// unlike a bare [SizedBox]). Sized to match the integration-test panel
/// roots so the visual area is realistic.
class _PanelRoot extends StatelessWidget {
  const _PanelRoot();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      key: _kPanelKey,
      color: Color(0xFFEEEEEE),
      child: SizedBox(width: 200, height: 120),
    );
  }
}

/// Harness exposing both the rail and marker triggers. The panel root is
/// mounted when either trigger is tapped (mirroring the production opener
/// surface where both arms can open the same panel root).
class _RailMarkerPanelHarness extends StatefulWidget {
  const _RailMarkerPanelHarness(this.counter, {this.panelMounted = false});

  final _TapCounter counter;
  final bool panelMounted;

  @override
  State<_RailMarkerPanelHarness> createState() =>
      _RailMarkerPanelHarnessState();
}

class _RailMarkerPanelHarnessState extends State<_RailMarkerPanelHarness> {
  late bool _panelOpen = widget.panelMounted;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: <Widget>[
            TextButton(
              key: _kRailKey,
              onPressed: () {
                widget.counter.rail++;
                setState(() => _panelOpen = true);
              },
              child: const Text('Rail'),
            ),
            TextButton(
              key: _kMarkerKey,
              onPressed: () {
                widget.counter.marker++;
                setState(() => _panelOpen = true);
              },
              child: const Text('Marker'),
            ),
            if (_panelOpen) const _PanelRoot(),
          ],
        ),
      ),
    );
  }
}

/// Harness exposing only the marker trigger — used to pin the marker
/// fallback arm of [e2eOpenPanelViaRailOrMarker] when the rail finder
/// resolves to zero elements.
class _MarkerOnlyPanelHarness extends StatefulWidget {
  const _MarkerOnlyPanelHarness(this.counter);

  final _TapCounter counter;

  @override
  State<_MarkerOnlyPanelHarness> createState() =>
      _MarkerOnlyPanelHarnessState();
}

class _MarkerOnlyPanelHarnessState extends State<_MarkerOnlyPanelHarness> {
  bool _panelOpen = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: <Widget>[
            TextButton(
              key: _kMarkerKey,
              onPressed: () {
                widget.counter.marker++;
                setState(() => _panelOpen = true);
              },
              child: const Text('Marker'),
            ),
            if (_panelOpen) const _PanelRoot(),
          ],
        ),
      ),
    );
  }
}

/// Harness that mounts the panel root only after a fake-async timer fires,
/// so the helper exercises its adaptive post-tap mount probe before
/// returning. Mirrors the async-mount pattern in
/// `app/test/e2e_open_civilian_panel_test.dart`.
class _DelayedPanelHarness extends StatefulWidget {
  const _DelayedPanelHarness(this.counter, {required this.mountAfter});

  final _TapCounter counter;
  final Duration mountAfter;

  @override
  State<_DelayedPanelHarness> createState() => _DelayedPanelHarnessState();
}

class _DelayedPanelHarnessState extends State<_DelayedPanelHarness> {
  bool _panelOpen = false;
  bool _scheduled = false;

  void _handleRailTap() {
    widget.counter.rail++;
    if (_scheduled) {
      return;
    }
    _scheduled = true;
    Timer(widget.mountAfter, () {
      if (!mounted) return;
      setState(() => _panelOpen = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: <Widget>[
            TextButton(
              key: _kRailKey,
              onPressed: _handleRailTap,
              child: const Text('Rail'),
            ),
            TextButton(
              key: _kMarkerKey,
              onPressed: () => widget.counter.marker++,
              child: const Text('Marker'),
            ),
            if (_panelOpen) const _PanelRoot(),
          ],
        ),
      ),
    );
  }
}
