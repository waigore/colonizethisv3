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

import 'package:colonizethis_app_e2e_support/e2e_helpers.dart';


part 'support/open_panel_rail_part.dart';
part 'support/open_panel_marker_part.dart';

const _kRailKey = ValueKey<String>('e2e_opvrom_rail');
const _kMarkerKey = ValueKey<String>('e2e_opvrom_marker');
const _kPanelKey = ValueKey<String>('e2e_opvrom_panel');

class _TapCounter {
  int rail = 0;
  int marker = 0;
}


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

void main() {
  suppressLogsForTests();
  registerOpenPanelViaRailGroup();
  registerOpenPanelViaMarkerGroup();
}
