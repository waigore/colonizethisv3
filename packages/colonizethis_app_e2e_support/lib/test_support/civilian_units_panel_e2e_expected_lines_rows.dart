part of 'civilian_units_panel_e2e_expected_lines.dart';

String _locationLabel(
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

void _addUnitRowTexts({
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
      _locationLabel(projectedTileKey, provinceNames),
    ),
  );
  _addAssignedLines(
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
    if (_isIdleNoPending(unit, currentOrders, humanPlayerId)) {
      out.add(l10n.civilian_units_assign);
    }
    if (_hasWork(unit, currentOrders, humanPlayerId)) {
      out.add(l10n.common_cancel);
    }
  }
}
