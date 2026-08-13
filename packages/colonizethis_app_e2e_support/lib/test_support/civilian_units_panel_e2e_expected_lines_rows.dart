// coverage:ignore-file
// E2E test fixture; exercised only by integration_test scenarios (which do not
// run in `flutter test test/`). Pulled into the test isolate's import graph by
// `app/integration_test/e2e_test_shared_panel_text_match.dart` (Refs #2336);
// excluded from the app coverage gate using the same convention as
// `app/lib/widgetbook/catalog*.dart`.
// Expected plain-text lines for CivilianUnitsPanel (bottom sheet). Mirrors
// app/lib/features/game/widgets/units/civilian/civilian_units_panel.dart for e2e.
// If drift fails tests, align this file with the panel widget.


import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/civilian_units_sort.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/region_labels.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'civilian_units_panel_e2e_expected_lines_assigned.dart';

String locationLabel(
  String? projectedTileKey,
  Map<String, String> provinceNames,
) {
  final regionId = Unit.regionIdFromTileKey(projectedTileKey);
  final provinceId = Unit.provinceIdFromTileKey(projectedTileKey);
  if (regionId == null || provinceId == null) return '—';
  final prefixed = '$regionId|$provinceId';
  final name = provinceNames[prefixed] ?? prefixed;
  final regionLabel = regionDisplayLabel(regionId);
  return '$regionLabel — $name';
}

void addUnitRowTexts({
  required List<String> out,
  required Game game,
  required Unit unit,
  required String humanPlayerId,
  required Orders currentOrders,
  required Map<String, String> provinceNames,
  required AppLocalizations l10n,
  required bool isTileScope,
  required String? resolvedSelectedUnitId,
  required String? projectedTileKey,
}) {
  final statusLabel = switch (unit.status) {
    UnitStatus.idle => l10n.province_unitStatus_idle,
    UnitStatus.working => l10n.province_unitStatus_working,
  };
  final showActions = !isTileScope || resolvedSelectedUnitId == unit.id;

  out.add(unit.type);
  out.add(l10n.civilian_units_status(statusLabel));
  out.add(
    l10n.civilian_units_location(
      locationLabel(projectedTileKey, provinceNames),
    ),
  );
  addAssignedLines(
    out,
    game,
    unit,
    currentOrders,
    humanPlayerId,
    provinceNames,
    l10n,
  );
  // Action labels render in the row card's trailing slot, after the details
  // column (type/status/location/assignedTo) — see _UnitRow.build /
  // CivilianUnitRowCard in civilian_units_panel_support.dart (Refs #2866 R30
  // card layout). The Locate action is icon-only and contributes no Text, so
  // it is intentionally omitted here (Refs #2336).
  if (showActions) {
    if (isIdleNoPending(unit, currentOrders, humanPlayerId)) {
      out.add(l10n.civilian_units_assign);
    }
    if (hasWork(unit, currentOrders, humanPlayerId)) {
      out.add(l10n.common_cancel);
    }
  }
}
