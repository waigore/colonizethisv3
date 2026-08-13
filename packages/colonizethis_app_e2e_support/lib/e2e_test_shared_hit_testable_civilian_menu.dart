import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared_adaptive_polling.dart';

/// Civilian work-menu labels surfaced after tapping an `Assign` button in
/// the civilian panel (`Build improvement`, `Prospect`, `Explore`).
///
/// Single source of truth consumed by [e2eAwaitCivilianWorkMenuMounted] (and
/// transitively by [e2eTapFirstAssignInCivilianPanel] and
/// [e2eTapAssignOnCivilianRowWithTitle]) so a label drift in production
/// surfaces in one place. Pinned by the widget test in
/// `app/test/e2e_await_civilian_work_menu_mounted_test.dart` to keep the
/// label set deterministic across SDK upgrades. Refs GitHub #2336 AC1 / AC2 /
/// Bottleneck 6.
const List<String> kE2eCivilianWorkMenuLabels = <String>[
  'Build improvement',
  'Prospect',
  'Explore',
];

/// Default timeout for [e2eAwaitCivilianWorkMenuMounted]. Matches the legacy
/// pre-lift inline `Duration(seconds: 5)` budget shared by
/// [e2eTapFirstAssignInCivilianPanel] and [e2eTapAssignOnCivilianRowWithTitle]
/// (Refs GitHub #2336 AC1 / AC2 / Bottleneck 6).
const Duration kE2eDefaultCivilianWorkMenuMountTimeout = Duration(seconds: 5);

/// Default phase label emitted by [e2eAwaitCivilianWorkMenuMounted] — matches
/// the legacy inline `wait_until_civilian_work_menu` phase used by
/// [e2eTapFirstAssignInCivilianPanel] before the lift. Callers tapping a
/// title-scoped `Assign` row pass `wait_until_civilian_work_menu_row` to
/// preserve the historical label split.
const String kE2eDefaultCivilianWorkMenuMountPhase =
    'wait_until_civilian_work_menu';

/// Polls until any civilian work-menu label
/// (one of [kE2eCivilianWorkMenuLabels]) becomes hit-testable, using
/// [e2eWaitUntilAnyFinderHitTestable] adaptive backoff (25 → 500 ms cap).
///
/// Lifted from the inline post-`Assign`-tap waits formerly duplicated in
/// [e2eTapFirstAssignInCivilianPanel] (`wait_until_civilian_work_menu`) and
/// [e2eTapAssignOnCivilianRowWithTitle] (`wait_until_civilian_work_menu_row`).
/// Both call sites now delegate here so the label set, the 5 s default
/// timeout, and the underlying poll cadence have a single source of truth.
/// Future callers that tap an `Assign` button (or an upstream affordance that
/// equivalently mounts the work menu) compose this helper directly without
/// duplicating the recipe. Refs GitHub #2336 AC1 / AC2 / Bottleneck 6.
///
/// Contract:
///
/// - Builds the finder list from [kE2eCivilianWorkMenuLabels] in declaration
///   order so the existential short-circuit inside
///   [e2eWaitUntilAnyFinderHitTestable] resolves in a deterministic order
///   (`Build improvement` first), matching the pre-lift inline blocks.
/// - On timeout, propagates the [TestFailure] raised by
///   [e2eWaitUntilAnyFinderHitTestable] verbatim — the lift does not change
///   fail-fast semantics. The accompanying widget-test pin in
///   `app/test/e2e_await_civilian_work_menu_mounted_test.dart` exercises both
///   the immediate-found fast path and the timeout path so a regression here
///   surfaces in PR checks rather than as a silent late-timeout in the Linux
///   integration suite.
/// - Emits perf timings via the inner [e2eWaitUntilAnyFinderHitTestable] call
///   only — no extra `wait_until_civilian_work_menu_*` counter so repeated
///   waits in a single scenario are still attributable to the existing
///   `wait_until_any_calls` counter.
Future<void> e2eAwaitCivilianWorkMenuMounted(
  WidgetTester tester, {
  Duration timeout = kE2eDefaultCivilianWorkMenuMountTimeout,
  String phaseName = kE2eDefaultCivilianWorkMenuMountPhase,
  E2ePerfLog? perf,
}) async {
  final finders = <Finder>[
    for (final label in kE2eCivilianWorkMenuLabels) find.text(label),
  ];
  await e2eWaitUntilAnyFinderHitTestable(
    tester,
    finders,
    timeout: timeout,
    perf: perf,
    phaseName: phaseName,
  );
}

