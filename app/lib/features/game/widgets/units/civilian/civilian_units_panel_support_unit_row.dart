/// Per-unit civilian row builder shell. SPEC/ui/civilian-units-panel.md.
///
/// De-parted wave-9 cluster (Refs #4117).

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../providers/games_provider.dart';
import 'civilian_units_panel_support_row_card.dart';
import 'civilian_units_panel_support_unit_row_actions.dart';
import 'civilian_units_panel_support_unit_row_labels.dart';

class CivilianUnitRow extends ConsumerWidget {
  const CivilianUnitRow({
    super.key,
    required this.game,
    required this.unit,
    required this.provinceNames,
    required this.currentOrders,
    required this.humanPlayerId,
    required this.bus,
    required this.isTileScope,
    required this.isSelectedInTileScope,
    required this.onSelectInTileScope,
    required this.projectedTileKey,
    required this.prospectShortcutTargetTileKey,
    required this.exploreShortcutTargetTileKey,
    required this.buildImprovementShortcutTargetTileKey,
    this.readOnly = false,
  });

  final Game game;
  final Unit unit;
  final Map<String, String> provinceNames;
  final Orders currentOrders;
  final String humanPlayerId;
  final AppEventBus bus;
  final bool isTileScope;
  final bool isSelectedInTileScope;
  final VoidCallback onSelectInTileScope;
  final String? projectedTileKey;
  final String? prospectShortcutTargetTileKey;
  final String? exploreShortcutTargetTileKey;
  final String? buildImprovementShortcutTargetTileKey;
  final bool readOnly;

  List<WorkOrder> get pendingForPlayer =>
      currentOrders.workOrdersByPlayerId[humanPlayerId] ?? const [];

  WorkOrder? get pendingWorkOrder {
    for (final o in pendingForPlayer) {
      if (o.unitId == unit.id) return o;
    }
    return null;
  }

  bool get hasPending => pendingWorkOrder != null;

  int? get pendingIndex {
    final list = pendingForPlayer;
    for (var i = 0; i < list.length; i++) {
      if (list[i].unitId == unit.id) return i;
    }
    return null;
  }

  bool get isIdleNoPending =>
      unit.status == UnitStatus.idle &&
      unit.currentWork == null &&
      !hasPending;

  bool get hasWork => unit.currentWork != null || hasPending;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableWorkTargetIds = ref.watch(
      availableWorkTargetIdsForUnitProvider(unit.id),
    );
    final l10n = appL10n(context);
    final statusLabel = switch (unit.status) {
      UnitStatus.idle => l10n.province_unitStatus_idle,
      UnitStatus.working => l10n.province_unitStatus_working,
    };
    final showActions = !isTileScope || isSelectedInTileScope;
    final inExplorerShortcutMode =
        (prospectShortcutTargetTileKey != null &&
            prospectShortcutTargetTileKey!.isNotEmpty) ||
        (exploreShortcutTargetTileKey != null &&
            exploreShortcutTargetTileKey!.isNotEmpty) ||
        (buildImprovementShortcutTargetTileKey != null &&
            buildImprovementShortcutTargetTileKey!.isNotEmpty);
    final tileKeyForLocate = projectedTileKey;
    final regionIdForLocate = Unit.regionIdFromTileKey(tileKeyForLocate);
    final rowActions = buildRowActions(
      l10n,
      context,
      showActions: showActions,
      inExplorerShortcutMode: inExplorerShortcutMode,
      availableWorkTargetIds: availableWorkTargetIds,
      tileKeyForLocate: tileKeyForLocate,
      regionIdForLocate: regionIdForLocate,
    );
    final selected = isTileScope && isSelectedInTileScope;
    return CivilianUnitRowCard(
      key: ValueKey('civilian-unit-card-${unit.id}'),
      selected: selected,
      onTap: handleRowTap,
      details: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(unit.type, overflow: TextOverflow.ellipsis),
          Text(l10n.civilian_units_status(statusLabel)),
          Text(l10n.civilian_units_location(locationLabel())),
          buildAssignedToSubtitle(l10n),
        ],
      ),
      actions: rowActions,
    );
  }
}
