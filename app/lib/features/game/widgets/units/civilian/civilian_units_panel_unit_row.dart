/// Per-unit civilian row builder. SPEC/ui/civilian-units-panel.md.

import 'dart:async';

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_logic/src/civilians/spy_relocate_intel.dart'
    show isForeignProvinceForPlayer;
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/services/app_event_bus_panel_nav.dart';
import '../../../../../providers/games_provider.dart';
import '../../../../../widgets/resource_icon.dart';
import '../shared/region_labels.dart';
import '../shared/units_entity_action_row.dart';
import 'civilian_units_panel_support_resolution.dart';
import 'civilian_units_panel_support_row_card.dart';
import 'civilian_units_panel_support_unit_row_actions.dart';

class CivilianUnitsPanelUnitRow extends ConsumerWidget {
  const CivilianUnitsPanelUnitRow({
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
    super.key,
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

  List<WorkOrder> get _pendingForPlayer =>
      currentOrders.workOrdersByPlayerId[humanPlayerId] ?? const [];

  MoveOrder? get _pendingMoveOrder {
    final moves =
        currentOrders.moveOrdersByPlayerId[humanPlayerId] ?? const [];
    for (final o in moves) {
      if (o.unitId == unit.id) return o;
    }
    return null;
  }

  bool get _isSpy => unit.type == kUnitTypeSpy;

  WorkOrder? get _pendingWorkOrder {
    for (final o in _pendingForPlayer) {
      if (o.unitId == unit.id) return o;
    }
    return null;
  }

  bool get _hasPendingWorkOnly => _pendingWorkOrder != null;

  bool get _canRelocateSpy =>
      _isSpy &&
      unit.status == UnitStatus.idle &&
      unit.currentWork == null &&
      !_hasPendingWorkOnly;

  int? get _pendingIndex {
    final list = _pendingForPlayer;
    for (var i = 0; i < list.length; i++) {
      if (list[i].unitId == unit.id) return i;
    }
    return null;
  }

  bool get _isIdleNoPending =>
      unit.status == UnitStatus.idle &&
      unit.currentWork == null &&
      !_hasPendingWorkOnly;

  bool get _hasWork =>
      unit.currentWork != null || _hasPendingWorkOnly || _pendingMoveOrder != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableWorkTargetIds = ref.watch(
      availableWorkTargetIdsForUnitProvider(unit.id),
    );
    final l10n = appL10n(context);
    final statusLabel = _spyStatusLabel(l10n) ??
        switch (unit.status) {
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
    final rowActions = _buildRowActions(
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
      onTap: _handleRowTap,
      details: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(unit.type, overflow: TextOverflow.ellipsis),
          Text(l10n.civilian_units_status(statusLabel)),
          Text(l10n.civilian_units_location(_locationLabel())),
          _buildAssignedToSubtitle(l10n),
        ],
      ),
      actions: rowActions,
    );
  }

  String? _spyStatusLabel(AppLocalizations l10n) {
    if (!_isSpy) return null;
    final pendingWork = _pendingWorkOrder;
    if (pendingWork?.target == kWorkTargetCounterSpy ||
        (unit.status == UnitStatus.working &&
            unit.currentWork?.workTarget == kWorkTargetCounterSpy)) {
      return l10n.civilian_units_spyStatus_counterEspionage;
    }
    if (_pendingMoveOrder != null) {
      return l10n.province_unitStatus_idle;
    }
    if (unit.status == UnitStatus.idle && unit.currentWork == null) {
      final tileKey = projectedTileKey;
      final regionId = Unit.regionIdFromTileKey(tileKey);
      final provinceFullId = Unit.provinceIdFromTileKey(tileKey);
      if (regionId != null && provinceFullId != null) {
        if (isForeignProvinceForPlayer(
          game: game,
          prefixedProvinceId: provinceFullId,
          humanPlayerId: humanPlayerId,
        )) {
          final name =
              provinceNames[provinceFullId] ??
              provinceNames['$regionId|${provinceFullId.split('|').last}'] ??
              provinceFullId;
          return l10n.civilian_units_spyStatus_holdingIntel(name);
        }
      }
      return l10n.civilian_units_spyStatus_reserve;
    }
    return null;
  }

  String _locationLabel() {
    final regionId = Unit.regionIdFromTileKey(projectedTileKey);
    final provinceId = Unit.provinceIdFromTileKey(projectedTileKey);
    if (regionId == null || provinceId == null) return '—';
    final prefixed = '$regionId|$provinceId';
    final name = provinceNames[prefixed] ?? prefixed;
    final regionLabel = regionDisplayLabel(regionId);
    return '$regionLabel — $name';
  }

  String _assignedToLabelNonPending(AppLocalizations l10n) {
    if (unit.status != UnitStatus.working || unit.currentWork == null) {
      return '—';
    }
    final cw = unit.currentWork!;
    final workLabel =
        civilianUnitsPanelWorkTargetLabels[cw.workTarget] ?? cw.workTarget;
    final regionId = Unit.regionIdFromTileKey(cw.tileKey);
    final provinceId = Unit.provinceIdFromTileKey(cw.tileKey);
    var location = '';
    if (regionId != null && provinceId != null) {
      final name =
          provinceNames['$regionId|$provinceId'] ?? '$regionId|$provinceId';
      location = ' (${regionDisplayLabel(regionId)} — $name)';
    }
    final progress = cw.totalTurns > 0
        ? l10n.civilian_units_turnProgress(
            cw.remainingTurns.toString(),
            cw.totalTurns.toString(),
          )
        : l10n.civilian_units_turns(
            cw.remainingTurns <= 0 ? 1 : cw.remainingTurns,
          );
    return '$workLabel$location — $progress';
  }

  Widget _buildAssignedToSubtitle(AppLocalizations l10n) {
    final pendingMove = _pendingMoveOrder;
    if (pendingMove != null) {
      final destTile = pendingMove.destinationTileKey;
      final regionId = Unit.regionIdFromTileKey(destTile);
      final provinceId = Unit.provinceIdFromTileKey(destTile);
      var location = destTile;
      if (regionId != null && provinceId != null) {
        final name =
            provinceNames['$regionId|$provinceId'] ?? '$regionId|$provinceId';
        location = '${regionDisplayLabel(regionId)} — $name';
      }
      return Text(l10n.civilian_units_pendingRelocate(location));
    }
    final pending = _pendingWorkOrder;
    if (pending != null) {
      final r = resolveCivilianUnitsPanelPendingAssignedResolution(
        game,
        unit,
        pending,
        provinceNames,
      );
      final turns = l10n.civilian_units_turns(r.totalTurns);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.civilian_units_assignedTo('${r.mainLine} — $turns')),
          if (r.materialCosts != null && r.materialCosts!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final e in sortedCivilianUnitsPanelMaterialCostEntries(
                    r.materialCosts!,
                  ))
                    CivilianUnitsPanelAssignedCostChip(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ResourceIcon(commodityId: e.key, size: 14),
                          const SizedBox(width: 4),
                          Text(e.value.toString()),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          if (r.treasuryAmount != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: CivilianUnitsPanelAssignedCostChip(
                child: Text(
                  l10n.trainUnits_treasury(r.treasuryAmount!.toString()),
                ),
              ),
            ),
        ],
      );
    }
    return Text(
      l10n.civilian_units_assignedTo(_assignedToLabelNonPending(l10n)),
    );
  }

  void _startShortcutAssign(List<String> availableWorkTargetIds) {
    final hasExploreShortcut =
        exploreShortcutTargetTileKey != null &&
        exploreShortcutTargetTileKey!.isNotEmpty;
    final hasProspectShortcut =
        prospectShortcutTargetTileKey != null &&
        prospectShortcutTargetTileKey!.isNotEmpty;
    final hasBuildImprovementShortcut =
        buildImprovementShortcutTargetTileKey != null &&
        buildImprovementShortcutTargetTileKey!.isNotEmpty;
    final targetTileKey = hasBuildImprovementShortcut
        ? buildImprovementShortcutTargetTileKey
        : hasExploreShortcut
        ? exploreShortcutTargetTileKey
        : hasProspectShortcut
        ? prospectShortcutTargetTileKey
        : null;
    if (targetTileKey == null || targetTileKey.isEmpty) return;
    final workTarget = hasBuildImprovementShortcut
        ? kWorkTargetBuildImprovement
        : hasExploreShortcut
        ? kWorkTargetExplore
        : kWorkTargetProspect;
    if (!_isIdleNoPending || !availableWorkTargetIds.contains(workTarget)) {
      return;
    }
    bus.closePanelThenEmit(
      UpsertPendingCivilianWorkOrderRequestedEvent(
        playerId: humanPlayerId,
        workOrder: WorkOrder(
          unitId: unit.id,
          target: workTarget,
          targetTileKey: targetTileKey,
        ),
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final completer = Completer<bool>();
    bus.emit(
      ConfirmDialogEvent(
        title: 'Cancel work order?',
        message:
            'This will cancel the current or pending work for this unit. Materials are not refunded.',
        confirmLabel: 'Yes',
        cancelLabel: 'No',
        onResult: completer.complete,
      ),
    );
    final confirmed = await completer.future;
    if (!confirmed || !context.mounted) return;
    final pendingMove = _pendingMoveOrder;
    if (pendingMove != null) {
      bus.emit(
        RemovePendingCivilianMoveRequestedEvent(
          playerId: humanPlayerId,
          unitId: unit.id,
        ),
      );
      return;
    }
    final idx = _pendingIndex;
    if (idx != null) {
      bus.emit(
        RemovePendingWorkOrderRequestedEvent(
          playerId: humanPlayerId,
          index: idx,
        ),
      );
    } else if (unit.currentWork != null) {
      bus.emit(CancelInProgressCivilianWorkRequestedEvent(unitId: unit.id));
    }
  }

  List<UnitsEntityAction> _buildRowActions(
    AppLocalizations l10n,
    BuildContext context, {
    required bool showActions,
    required bool inExplorerShortcutMode,
    required List<String> availableWorkTargetIds,
    required String? tileKeyForLocate,
    required String? regionIdForLocate,
  }) {
    if (readOnly) {
      return const <UnitsEntityAction>[];
    }
    final canLocate =
        tileKeyForLocate != null &&
        tileKeyForLocate.isNotEmpty &&
        regionIdForLocate != null;
    return [
      if (showActions && _canRelocateSpy)
        UnitsEntityAction(
          tooltip: l10n.civilian_units_relocate,
          icon: Icons.directions_walk,
          label: l10n.civilian_units_relocate,
          onPressed: () {
            bus.closePanelThenEmit(
              StartCivilianRelocateSelectionEvent(unitId: unit.id),
            );
          },
        ),
      if (showActions && _isIdleNoPending && !_hasPendingWorkOnly)
        UnitsEntityAction(
          tooltip: l10n.civilian_units_assign,
          icon: Icons.playlist_add,
          label: l10n.civilian_units_assign,
          onPressed: !_isSpy && inExplorerShortcutMode
              ? () => _startShortcutAssign(availableWorkTargetIds)
              : () => showCivilianUnitsPanelOrderMenu(
                  context,
                  bus: bus,
                  unit: unit,
                  availableWorkTargetIds: availableWorkTargetIds,
                ),
        ),
      if (showActions && _hasWork)
        UnitsEntityAction(
          tooltip: l10n.common_cancel,
          icon: Icons.cancel_outlined,
          label: l10n.common_cancel,
          variant: UnitsEntityActionVariant.danger,
          onPressed: () => _confirmCancel(context),
        ),
      UnitsEntityAction(
        tooltip: l10n.common_locate,
        icon: Icons.my_location,
        label: l10n.common_locate,
        iconOnly: true,
        onPressed: canLocate
            ? () {
                bus.emit(
                  LocateMapTileEvent(
                    tileKey: tileKeyForLocate,
                    regionId: regionIdForLocate,
                  ),
                );
              }
            : null,
      ),
    ];
  }

  void _handleRowTap() {
    if (isTileScope) {
      onSelectInTileScope();
      return;
    }
    final tileKey = projectedTileKey;
    if (tileKey == null) return;
    final regionId = Unit.regionIdFromTileKey(tileKey);
    if (regionId == null) return;
    bus.closePanelThenEmit(
      LocateMapTileEvent(tileKey: tileKey, regionId: regionId),
    );
  }
}
