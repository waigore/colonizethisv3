import 'package:colonizethis_app/config/ct_e2e.dart'
    show kCtE2ESelectFirstValidWorkTileKey;
import 'package:flutter_test/flutter_test.dart';

import 'e2e_test_shared.dart';

/// Default cap for the `wait_until_first_valid_work_tile_after_*` /
/// `pump_until_*_work_tile_optional` appearance wait inside
/// [e2ePickFirstValidWorkTileAndAwaitOverlayClear] and
/// [e2eMaybePickFirstValidWorkTileAndAwaitOverlayClear].
///
/// Matches the legacy 15-second budget the inline full-turn civilian
/// "Build improvement" / Explorer "Prospect" blocks used after tapping the
/// action label, before tapping `kCtE2ESelectFirstValidWorkTileKey`
/// (Refs GitHub #2336 AC1 / AC2 / AC5).
const Duration kE2eDefaultCivilianWorkTileAppearTimeout = Duration(seconds: 15);

/// Default cap for the `pump_until_work_tile_overlay_cleared_*` settle
/// inside [e2ePickFirstValidWorkTileAndAwaitOverlayClear] and
/// [e2eMaybePickFirstValidWorkTileAndAwaitOverlayClear].
///
/// Matches the legacy 5-second `e2ePumpUntil` budget the inline full-turn
/// blocks used between the work-tile tap and the panel-close handoff so the
/// overlay [InkWell] keyed by `kCtE2ESelectFirstValidWorkTileKey` is gone
/// before the next phase opens a new bottom sheet (Refs GitHub #2336 AC1 /
/// AC2 / AC5).
const Duration kE2eDefaultCivilianWorkTileClearTimeout = Duration(seconds: 5);

/// Strict variant: waits until the `kCtE2ESelectFirstValidWorkTileKey`
/// overlay [InkWell] is hit-testable, taps it, then pumps until the
/// overlay unmounts.
///
/// Lifted from the inline Builder "Build improvement" block in
/// `new_game_full_turn_e2e_test.dart` (the post-`tap('Build improvement')`
/// sequence: `e2eWaitUntilFound(workTile.hitTestable())` →
/// `tester.tap(find.byKey(kCtE2ESelectFirstValidWorkTileKey))` →
/// `e2ePumpUntil(workTile.evaluate().isEmpty)`) so the full-turn scenario
/// consumes a shared, unit-pinned helper (Refs GitHub #2336 AC1 / AC2 /
/// Bottleneck 6).
///
/// The widget-test pin in
/// `app/test/e2e_pick_first_valid_work_tile_and_await_overlay_clear_test.dart`
/// carries the behavioural contract because the integration suite cannot
/// validate this directly today (`app_e2e_linux` is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI). A silent regression in
/// either branch would either:
///
///   - Tap the broad (non-hit-testable) finder before the overlay is
///     mounted — masking a missing work-target tile until the panel-close
///     handoff much later in the test; or
///   - Skip the `pump_until_work_tile_overlay_cleared_*` settle and let the
///     stale [InkWell] race the next panel open — inflating the
///     wall-clock budget issue #2336 is reducing.
///
/// Distinct from [e2eMaybePickFirstValidWorkTileAndAwaitOverlayClear]:
/// this strict variant **fails the test** when the overlay does not appear
/// within [appearTimeout]; the best-effort variant returns `false` and
/// emits a `meta=skipped_*` timing entry for log-scraper attribution.
///
/// Contract:
///
/// - Awaits [e2eWaitUntilFound] for `find.byKey(kCtE2ESelectFirstValidWorkTileKey).hitTestable()`
///   using [appearPhase] (forwarded verbatim) and [appearTimeout]
///   (default [kE2eDefaultCivilianWorkTileAppearTimeout]).
/// - Taps the broad `find.byKey(kCtE2ESelectFirstValidWorkTileKey)` once.
///   Mirrors the legacy `tester.tap(find.byKey(...))` so a regression
///   that switched to `tester.tap(workTile.first, warnIfMissed: false)`
///   would silently swallow an "off-screen but mounted" tile state.
/// - Awaits [e2ePumpUntil] under [clearPhase] (forwarded verbatim) up to
///   [clearTimeout] (default [kE2eDefaultCivilianWorkTileClearTimeout])
///   for the overlay to unmount.
/// - Forwards [perf] to both `e2e*` polling helpers so the legacy
///   `E2E_TIMING|...|phase=<appearPhase|clearPhase>` lines land under the
///   call site's [E2ePerfLog] (Refs `SPEC/program/e2e-integration-tests.md`
///   § Adaptive poll pacing / Determinism).
Future<void> e2ePickFirstValidWorkTileAndAwaitOverlayClear(
  WidgetTester tester, {
  required String appearPhase,
  required String clearPhase,
  Duration appearTimeout = kE2eDefaultCivilianWorkTileAppearTimeout,
  Duration clearTimeout = kE2eDefaultCivilianWorkTileClearTimeout,
  E2ePerfLog? perf,
}) async {
  final workTile = find.byKey(kCtE2ESelectFirstValidWorkTileKey);
  await e2eWaitUntilFound(
    tester,
    workTile.hitTestable(),
    timeout: appearTimeout,
    perf: perf,
    phaseName: appearPhase,
  );
  await tester.tap(workTile);
  await e2ePumpUntil(
    tester,
    () => workTile.evaluate().isEmpty,
    timeout: clearTimeout,
    perf: perf,
    phaseName: clearPhase,
  );
}

/// Best-effort variant: best-effort polls for the
/// `kCtE2ESelectFirstValidWorkTileKey` overlay to become hit-testable; if
/// it does, taps it and pumps until it clears; otherwise records a
/// zero-duration `meta=$skippedMeta` timing under [skippedTimingLabel] and
/// returns `false` without failing the test.
///
/// Lifted from the inline Explorer "Prospect" block in
/// `new_game_full_turn_e2e_test.dart` (the post-`tap('Prospect')`
/// sequence: `e2ePumpUntilConditionOrIdle(workTile.hitTestable().isNotEmpty)`
/// → if ready: `tester.tap(workTile.hitTestable().first, warnIfMissed:
/// false)` + `e2ePumpUntil(workTile.evaluate().isEmpty)`; else
/// `perf.timing('prospect_work_tile', Duration.zero, meta:
/// 'skipped_no_valid_tile_on_e2e_map')`) so the full-turn scenario
/// consumes a shared, unit-pinned helper (Refs GitHub #2336 AC1 / AC2 /
/// Bottleneck 6).
///
/// The widget-test pin in
/// `app/test/e2e_pick_first_valid_work_tile_and_await_overlay_clear_test.dart`
/// carries the behavioural contract because the integration suite cannot
/// validate this directly today (`app_e2e_linux` is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI). A regression that
/// dropped the `warnIfMissed: false` flag would re-introduce the warning
/// flood the legacy block intentionally silenced; a regression that
/// dropped the `perf.timing(..., meta: skippedMeta)` would orphan the
/// log-scraper attribution for the `skipped_no_valid_tile_on_e2e_map`
/// branch.
///
/// Distinct from [e2ePickFirstValidWorkTileAndAwaitOverlayClear]: this
/// best-effort variant **never fails the test** on absent overlay; it
/// surfaces the skip as a zero-duration timing entry instead so AC8
/// dashboards can distinguish "Prospect on this map had no valid tile"
/// from "the Build improvement contract regressed".
///
/// Contract:
///
/// - Awaits [e2ePumpUntilConditionOrIdle] for
///   `find.byKey(kCtE2ESelectFirstValidWorkTileKey).hitTestable().isNotEmpty`
///   using [appearPhase] (forwarded verbatim) and [appearTimeout]
///   (default [kE2eDefaultCivilianWorkTileAppearTimeout]). Does not fail
///   on timeout — relays the bool result.
/// - When the overlay does not appear: records
///   `perf?.timing(skippedTimingLabel, Duration.zero, meta: skippedMeta)`
///   and returns `false` without tapping or pumping further.
/// - When the overlay appears: taps
///   `find.byKey(kCtE2ESelectFirstValidWorkTileKey).hitTestable().first`
///   with `warnIfMissed: false` (mirrors the legacy block — guards against
///   the off-by-one frame where the overlay becomes not-hit-testable
///   between the predicate and the tap), then awaits [e2ePumpUntil] under
///   [clearPhase] (forwarded verbatim) up to [clearTimeout] (default
///   [kE2eDefaultCivilianWorkTileClearTimeout]) for the overlay to
///   unmount; returns `true`.
/// - Forwards [perf] to both `e2e*` polling helpers so the legacy
///   `E2E_TIMING|...|phase=<appearPhase|clearPhase>` lines land under the
///   call site's [E2ePerfLog] (Refs `SPEC/program/e2e-integration-tests.md`
///   § Adaptive poll pacing / Determinism).
Future<bool> e2eMaybePickFirstValidWorkTileAndAwaitOverlayClear(
  WidgetTester tester, {
  required String appearPhase,
  required String clearPhase,
  required String skippedTimingLabel,
  required String skippedMeta,
  Duration appearTimeout = kE2eDefaultCivilianWorkTileAppearTimeout,
  Duration clearTimeout = kE2eDefaultCivilianWorkTileClearTimeout,
  E2ePerfLog? perf,
}) async {
  final workTile = find.byKey(kCtE2ESelectFirstValidWorkTileKey);
  final ready = await e2ePumpUntilConditionOrIdle(
    tester,
    () => workTile.hitTestable().evaluate().isNotEmpty,
    timeout: appearTimeout,
    perf: perf,
    phaseName: appearPhase,
  );
  if (!ready) {
    perf?.timing(skippedTimingLabel, Duration.zero, meta: skippedMeta);
    return false;
  }
  await tester.tap(workTile.hitTestable().first, warnIfMissed: false);
  await e2ePumpUntil(
    tester,
    () => workTile.evaluate().isEmpty,
    timeout: clearTimeout,
    perf: perf,
    phaseName: clearPhase,
  );
  return true;
}
