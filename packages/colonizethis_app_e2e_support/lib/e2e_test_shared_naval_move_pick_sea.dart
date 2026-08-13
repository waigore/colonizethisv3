import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart'
    show ctE2eNavalPanelSnapshot;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_e2e_support/e2e_test_shared_fleet_nav.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared_move_dialog_finders.dart';

/// Returns the [kCtE2EMoveFleetDestinationSeaZoneRowKey] for the adjacent sea
/// zone that makes the most BFS progress toward the New World, or `null` when
/// topology-guided selection is unavailable.
///
/// Reads the combined topology from the live [ctE2eNavalPanelSnapshot] and the
/// candidate sea-zone ids from the open move dialog's keyed rows. Returns
/// `null` (so the caller falls back to `seaRadio.first`) when the snapshot is
/// missing or no sea-zone-keyed rows are mounted — for example under the
/// widget-test fixtures that build legacy `RadioListTile` rows without the
/// `CT_E2E` sea-zone keys (Refs #2336 AC6/AC7).
Key? e2eBestSeaZoneRowKeyTowardNewWorld() {
  final topology = ctE2eNavalPanelSnapshot?.topology;
  if (topology == null) {
    return null;
  }
  final candidateIds = <String>[];
  final seaRows = find.byWidgetPredicate((w) {
    final Key? key = w.key;
    return key is ValueKey<String> &&
        key.value.startsWith(kCtE2EMoveFleetDestinationSeaZoneRowKeyPrefix);
  });
  for (final element in seaRows.evaluate()) {
    final Key? key = element.widget.key;
    if (key is ValueKey<String>) {
      candidateIds.add(
        key.value.substring(
          kCtE2EMoveFleetDestinationSeaZoneRowKeyPrefix.length,
        ),
      );
    }
  }
  if (candidateIds.isEmpty) {
    return null;
  }
  final best = e2eBestSeaZoneTowardRegion(
    topology: topology,
    candidates: candidateIds,
  );
  if (best == null) {
    return null;
  }
  return kCtE2EMoveFleetDestinationSeaZoneRowKey(best);
}

/// Picks a sea-zone move destination, preferring the adjacent zone that makes
/// BFS progress toward the New World (Refs #2336 AC6/AC7).
///
/// When the live naval snapshot exposes the combined topology and the dialog
/// tags its sea-zone rows with `kCtE2EMoveFleetDestinationSeaZoneRowKey`, the
/// topology-best row is tapped (scrolling it into view first when needed).
/// Falls back to `e2eMoveFleetDestinationRows().first` when the snapshot/keys
/// are unavailable (e.g. the widget-test fixtures), preserving the legacy
/// contract pinned by
/// `app/test/e2e_pick_move_destination_and_confirm_test.dart`.
///
/// Extracted from `e2ePickMoveDestinationAndConfirm` to keep control-flow
/// nesting within the repo-lint depth budget (Refs #2336).
Future<void> e2eTapSeaZoneDestinationTowardNewWorld(
  WidgetTester tester,
) async {
  final towardKey = e2eBestSeaZoneRowKeyTowardNewWorld();
  if (towardKey == null) {
    final seaRadio = e2eMoveFleetDestinationRows();
    expect(seaRadio, findsWidgets);
    await tester.tap(seaRadio.first, warnIfMissed: false);
    return;
  }
  final towardRow = find.byKey(towardKey);
  if (towardRow.hitTestable().evaluate().isEmpty) {
    await e2eScrollSeaZoneRowIntoView(tester, towardRow);
  }
  final towardHit = towardRow.hitTestable();
  await tester.tap(
    (towardHit.evaluate().isNotEmpty ? towardHit : towardRow).first,
    warnIfMissed: false,
  );
}

/// Scrolls [towardRow] into view within the move-fleet dialog's scrollable when
/// one is present; a no-op when the row is already visible or has no scrollable
/// ancestor (Refs #2336).
Future<void> e2eScrollSeaZoneRowIntoView(
  WidgetTester tester,
  Finder towardRow,
) async {
  final dialogScrollable = find.descendant(
    of: e2eMoveFleetDialogFinder(),
    matching: find.byType(Scrollable),
  );
  if (dialogScrollable.evaluate().isEmpty) {
    return;
  }
  try {
    await tester.scrollUntilVisible(
      towardRow.first,
      120,
      scrollable: dialogScrollable.first,
    );
  } catch (_) {
    // Row may already be visible or have no scrollable ancestor; the
    // hit-testable resolve below still taps from a sane position.
  }
}

