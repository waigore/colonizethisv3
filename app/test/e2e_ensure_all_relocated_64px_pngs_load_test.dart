/// Pins the **canonical expected set** contract of
/// `e2eEnsureAllRelocated64pxPngsLoad` and the **suite-once memoization**
/// contract of `e2eEnsureAllRelocated64pxPngsLoadSuiteOnce`
/// (`app/integration_test/e2e_test_shared_bootstrap.dart`).
///
/// Both helpers are part of the AC1 shared-helper checklist (re-exported as
/// `ensureAllRelocated64pxPngsLoad` / `ensureAllRelocated64pxPngsLoadSuiteOnce`
/// in `e2e_helpers.dart`) and back the **single warm-cache preload** every
/// new-game E2E scenario runs through. The underlying
/// `e2eEnsureRelocated64pxPngDecode` is already pinned by
/// `e2e_ensure_relocated_64px_png_decode_test.dart`, but two adjacent
/// contracts had no direct widget-test coverage on `origin/dev`:
///
/// 1. **`e2eEnsureAllRelocated64pxPngsLoad` canonical expected set** — the
///    function constructs its expected set from the
///    `kCivilianIconSlugs` / `kResourceIconIds` / `kTownIconIds` /
///    `kProvinceLabelIconIds` source-of-truth lists plus
///    `kFleetMapIcon64PngAssetPath`. A silent regression that drops a family
///    (e.g. swapping `kResourceIconIds` for an empty constant) or shifts the
///    asset path naming convention would compile cleanly but allow the
///    real-asset preload to start drifting from the slug constants without
///    any unit-level signal.
/// 2. **`e2eEnsureAllRelocated64pxPngsLoadSuiteOnce` memoization** — the
///    `_e2eAllRelocated64pxPngLoadSuiteFuture ??=` cache is the AC3 gate
///    that keeps cross-scenario preload work to **at most one** decode pass
///    per isolate. Without the cache the helper would silently regress
///    AC9 wall-clock numbers in every scenario that calls it (currently all
///    three new-game E2E scenarios — see grep on
///    `ensureAllRelocated64pxPngsLoadSuiteOnce`). The cache also coalesces
///    concurrent callers; dropping that property would let two scenarios in
///    a sharded run double-load the manifest.
///
/// Pinning both at the widget-unit layer keeps AC1 / AC3 / AC9 protected
/// even though `integration_test/` is not part of the PR `quality` workflow
/// (`SPEC/program/e2e-integration-tests.md` § CI / no-op `app_e2e_linux`
/// lane).
library;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared_bootstrap.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  suppressLogsForTests();

  test(
    'e2eEnsureAllRelocated64pxPngsLoad succeeds against the real assets/icons/64/ manifest',
    () async {
      // Drives the **canonical** expected-set construction path:
      //   * kCivilianIconSlugs   -> ui_icon_civ_<slug>.png
      //   * kResourceIconIds     -> ui_icon_com_<id>.png
      //   * kTownIconIds         -> ui_icon_com_<id>.png
      //   * kProvinceLabelIconIds-> ui_icon_<id>.png
      //   * kFleetMapIcon64PngAssetPath (singleton)
      // The helper asserts the constructed set matches the real manifest, so
      // success here directly pins "slug constants are in sync with shipped
      // assets" — a regression in either side surfaces as a TestFailure here
      // long before it can burn wall-clock in an integration scenario.
      await e2eEnsureAllRelocated64pxPngsLoad();
    },
  );

  test(
    'e2eEnsureAllRelocated64pxPngsLoadSuiteOnce first call completes successfully',
    () async {
      // Populates the `_e2eAllRelocated64pxPngLoadSuiteFuture` cache so the
      // subsequent memoization tests in this file observe the cached path.
      // Must succeed under the same constraints as the direct caller.
      await e2eEnsureAllRelocated64pxPngsLoadSuiteOnce();
    },
  );

  test(
    'e2eEnsureAllRelocated64pxPngsLoadSuiteOnce memoizes: second call resolves observably faster than a fresh decode',
    () async {
      // The first call above already populated the cache. A subsequent call
      // must await an already-completed future — orders of magnitude faster
      // than the underlying manifest + parallel decode work the very first
      // call performed. A regression that dropped the `??=` would re-run
      // `e2eEnsureAllRelocated64pxPngsLoad` here and the second-call cost
      // would balloon back to the per-scenario decode cost.
      //
      // Using 1s as a generous upper bound: the cached path is essentially
      // an awaited completed-Future, while the fresh decode path on every
      // real CI run we have evidence for is in the seconds range (see
      // PR #2358 baseline notes). 1s leaves ample margin for slow CI runners
      // without admitting a silent fresh-decode regression.
      final secondCallSw = Stopwatch()..start();
      await e2eEnsureAllRelocated64pxPngsLoadSuiteOnce();
      secondCallSw.stop();
      expect(
        secondCallSw.elapsed < const Duration(seconds: 1),
        isTrue,
        reason:
            'Second e2eEnsureAllRelocated64pxPngsLoadSuiteOnce call must reuse '
            'the memoized future (elapsed=${secondCallSw.elapsed.inMilliseconds}ms). '
            'A slow second call indicates the `??=` cache was dropped, which '
            'would silently regress AC3 / AC9 by re-running the full manifest + '
            'parallel decode work in every new-game E2E scenario.',
      );
    },
  );

  test(
    'e2eEnsureAllRelocated64pxPngsLoadSuiteOnce coalesces concurrent callers',
    () async {
      // The memoization is populated from the prior test. Issuing many
      // concurrent calls must all resolve without throwing (no
      // double-completion of the cached future) and remain observably fast.
      // A regression that allowed concurrent callers to bypass the cache
      // would re-trigger asset decode work in parallel — visible here as
      // either a thrown exception (Future already completed) or a wall-clock
      // explosion as multiple decode passes interleave.
      final fanoutSw = Stopwatch()..start();
      await Future.wait(<Future<void>>[
        for (var i = 0; i < 8; i++) e2eEnsureAllRelocated64pxPngsLoadSuiteOnce(),
      ]);
      fanoutSw.stop();
      expect(
        fanoutSw.elapsed < const Duration(seconds: 1),
        isTrue,
        reason:
            'Eight concurrent e2eEnsureAllRelocated64pxPngsLoadSuiteOnce calls '
            'against the memoized future must all resolve quickly '
            '(elapsed=${fanoutSw.elapsed.inMilliseconds}ms). A slow fan-out '
            'indicates the cache no longer coalesces concurrent callers, which '
            'would let two scenarios in a sharded run double-load the manifest.',
      );
    },
  );
}
