/// Pins the widget-tree contract of [e2eDismissGenericOkIfPresent]
/// (`app/integration_test/e2e_test_shared_dismiss_generic_ok.dart`).
///
/// The shared broad-spectrum sweep [e2eDismissTransientUi] consumes this
/// helper for its top-level OK branch (the layer between SnackBar and
/// AlertDialog dismissal). The pre-lift inline block lived in
/// `e2eDismissTransientUi` and used `find.text('OK').hitTestable()`
/// **unscoped** — that is, an `OK` label anywhere in the widget tree
/// outside an AlertDialog context would be tapped. The lifted form
/// preserves this behaviour byte-for-byte (same finder, same 2 s budget,
/// same tap-then-pump-until-empty contract) but moves it behind a focused
/// helper so future scenarios can compose it without going through the
/// whole broad sweep.
///
/// The integration suite cannot validate this directly today (the
/// `app_e2e_linux` lane is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so this widget-test
/// layer carries the behavioural pin. This pin guards:
///
/// - **No-OK short-circuit**: helper returns `false` without tapping or
///   pumping when no hit-testable `Text('OK')` is mounted; sibling
///   widgets that happen to host other labels must not be tapped.
/// - **Top-level OK happy path**: helper taps a hit-testable `Text('OK')`
///   widget anywhere in the tree (not just inside an `AlertDialog`),
///   returns `true`, and the label leaves the tree.
/// - **Hit-testable filter contract**: an `OK` label covered by an opaque
///   `AbsorbPointer` overlay is **not** tapped; the helper short-circuits
///   to `false` so the caller can fall back to a broader dismissal
///   strategy. A regression that dropped the `.hitTestable()` filter
///   would tap the covered label and starve subsequent phases on a
///   missed dismissal.
/// - **Custom label override**: passing `label: 'Dismiss'` (or similar)
///   targets the custom label instead of the default `'OK'`, preserving
///   the API surface the legacy inline block never exposed but the
///   lifted form intentionally supports.
/// - **Constant pins**: `kE2eDefaultGenericOkDismissTimeout` matches the
///   legacy 2 s budget; `kE2eDefaultGenericOkLabel` is `'OK'`.
/// - **Perf counter pin**: a single `dismiss_generic_ok_calls` bump fires
///   on success only — the no-OK short-circuit and covered-OK branches
///   do not emit.
///
/// Refs GitHub #2336 AC1 / AC2 / AC10.
library;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

import 'support/dismiss_generic_ok_counter_group.dart';
import 'support/dismiss_generic_ok_perf_attribution_group.dart';
import 'support/e2e_dismiss_generic_ok_if_present_branch_group.dart';
import 'support/e2e_dismiss_generic_ok_if_present_guard_group.dart';

void main() {
  suppressLogsForTests();

  group('e2eDismissGenericOkIfPresent — constant pins', () {
    test('kE2eDefaultGenericOkDismissTimeout matches legacy 2 s budget', () {
      // The legacy inline top-level OK branch of e2eDismissTransientUi used
      // a hardcoded 2 s timeout. A silent drift here would either inflate
      // the per-call dismiss window (regressing AC9 aggregate wall-clock)
      // or shrink it (risking false negatives when the dismiss animation
      // runs slow under load).
      expect(
        kE2eDefaultGenericOkDismissTimeout,
        const Duration(seconds: 2),
        reason:
            'kE2eDefaultGenericOkDismissTimeout must preserve the legacy '
            '2 s inline budget to keep AC9 aggregate wall-clock attribution '
            'stable across the lift.',
      );
    });

    test('kE2eDefaultGenericOkLabel is the English literal OK', () {
      // Pre-lift literal in `e2eDismissTransientUi` was the bare English
      // 'OK'. A silent change would either miss the canonical confirmation
      // banner or tap the wrong label (for example a localised
      // 'OK'-equivalent that wasn't intentionally opted in).
      expect(
        kE2eDefaultGenericOkLabel,
        'OK',
        reason:
            'kE2eDefaultGenericOkLabel must preserve the legacy English '
            "'OK' literal so the broad-spectrum sweep continues to dismiss "
            'the canonical confirmation banner.',
      );
    });
  });

  registerE2eDismissGenericOkIfPresentBranchGroup();
  registerDismissGenericOkCounterGroup();
  registerDismissGenericOkPerfAttributionGroup();
  registerE2eDismissGenericOkIfPresentGuardGroup();
}
