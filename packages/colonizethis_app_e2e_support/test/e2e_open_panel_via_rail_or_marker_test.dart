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

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;

import 'support/open_panel_via_rail_or_marker_harness.dart';
import 'support/open_panel_rail_group.dart';
import 'support/open_panel_marker_group.dart';

void main() {
  suppressLogsForTests();
  registerOpenPanelViaRailGroup();
  registerOpenPanelViaMarkerGroup();
}
