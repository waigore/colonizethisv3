import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Returns a [Finder] matching every `RadioListTile<…>` widget that is a
/// descendant of any currently-mounted [AlertDialog].
///
/// Contract (issue #2336 AC1 / AC2):
///
///   - Composes `find.descendant(of: find.byType(AlertDialog), matching: …)`
///     so the search is scoped to dialog subtrees only — `RadioListTile`s
///     outside an [AlertDialog] (panels, settings sheets, etc.) are never
///     returned. Naval / civilian / production move dialogs all surface
///     destination tiles via `RadioListTile<…>`; scoping to [AlertDialog]
///     keeps the move-segment helpers from accidentally hitting a panel
///     radio.
///   - The matcher inspects [Widget.runtimeType] via `toString()` so it
///     accepts any generic instantiation
///     (`RadioListTile<String>`, `RadioListTile<int>`, etc.) without
///     pulling in the concrete type argument. The fleet-reach move dialog
///     parameterises radio tiles on the destination string id; binding to
///     `RadioListTile<String>` directly would silently miss future
///     dialogs that switch to a different parameter type.
///   - Pure — the function reads no globals, returns a new [Finder] on
///     every call, and never throws. The returned [Finder] is lazy and
///     only resolves against the active widget tree when iterated, which
///     keeps it safe to construct outside an `await tester.pump()`
///     boundary.
///
/// Mirrors the lifted public-name pattern used by
/// `e2eNonHomeHumanFleetInNewWorldFromCtSnapshot` and
/// `e2eNavalPanelShowsNonHomeFleetInNewWorld` so callers consume the
/// AC1 barrel (`e2e_helpers.dart`) only. A silent rename or accidental
/// scope-removal (matching every `RadioListTile` across the tree)
/// would re-introduce false positives in move-segment dialogs that
/// also host non-destination radios on the surrounding screen
/// (Refs `SPEC/program/e2e-integration-tests.md` § Determinism).
Finder e2eRadioListTilesInAlertDialogs() {
  return find.descendant(
    of: find.byType(AlertDialog),
    matching: find.byWidgetPredicate(
      (w) => w.runtimeType.toString().startsWith('RadioListTile<'),
    ),
  );
}

/// Returns a [Finder] matching the move-fleet dialog container, tolerating
/// **either** a Material [AlertDialog] **or** the production [CtDialogShell].
///
/// The production `MoveFleetDialog` renders as a [CtDialogShell] (a Material
/// `Dialog`, **not** an `AlertDialog`) per `SPEC/ui/move-fleet-dialog.md` and
/// the catalog Material-design ban. The fleet-reach move helpers were written
/// against the legacy `AlertDialog` shape; this finder lets the same helpers
/// drive the live `CtDialogShell` dialog while the focused widget-test pins —
/// which still mount `AlertDialog` fixtures — keep validating the helper logic
/// (Refs #2336; first-fleet-move parity with `e2eAttemptFirstFleetMoveOrCancel`).
Finder e2eMoveFleetDialogFinder() {
  return find.byWidgetPredicate((w) => w is AlertDialog || w is CtDialogShell);
}

/// Returns a [Finder] matching every selectable destination row inside the
/// active move-fleet dialog ([e2eMoveFleetDialogFinder]).
///
/// Tolerates both dialog shapes (Refs #2336):
///
///   - **Production** ([CtDialogShell]): custom `_MoveFleetDestinationRow`
///     widgets, each keyed via [kCtE2EMoveFleetDestinationRowKey] under
///     `CT_E2E`. No Material `Radio` / `RadioListTile` is used, per
///     `SPEC/ui/move-fleet-dialog.md` § Layout.
///   - **Widget-test fixtures** ([AlertDialog]): legacy `RadioListTile<…>`
///     rows (matched on `runtimeType.toString()` so any generic
///     instantiation qualifies).
///
/// The finder is dialog-scoped so panel-side rows never leak in, and returns a
/// fresh lazy [Finder] on every call. The fleet-reach picker
/// ([e2ePickMoveDestinationAndConfirm]) taps `.first` when no warp row is
/// present.
Finder e2eMoveFleetDestinationRows() {
  return find.descendant(
    of: e2eMoveFleetDialogFinder(),
    matching: find.byWidgetPredicate((w) {
      final Key? key = w.key;
      if (key is ValueKey &&
          key.value is String &&
          (key.value as String).startsWith(
            kCtE2EMoveFleetDestinationRowKeyPrefix,
          )) {
        return true;
      }
      return w.runtimeType.toString().startsWith('RadioListTile<');
    }),
  );
}
