// Civilian units panel. SPEC/ui/civilian-units-panel.md.

import 'dart:async';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_event_handler_scope.dart';
import '../../../widgets/ct_nine_patch_button.dart';
import 'units/shared/region_section_header.dart';
import 'units/shared/units_panel_region_label.dart';
import 'units/shared/units_panel_shell.dart';

/// Human-readable label for work target ids. SPEC/ui/civilian-units-panel.md.
const Map<String, String> _workTargetLabels = {
  'explore': 'Explore',
  'prospect': 'Prospect',
  'build_improvement': 'Build improvement',
  'upgrade_town': 'Upgrade town',
  'build_road': 'Build road',
  'build_port': 'Build port',
  'build_fort': 'Build fort',
  'build_rail': 'Build rail',
  'steal_tech': 'Steal tech',
  'counter_spy': 'Counter spy',
  'purchase_land': 'Purchase land',
};

/// Builds prefixed province id -> province display name from [game].
Map<String, String> _provinceNamesByPrefixedId(Game game) {
  final out = <String, String>{};
  for (final p in game.worldState.oldWorld.provinces) {
    out['${p.regionId}|${p.id}'] = p.displayName ?? p.id;
  }
  for (final p in game.worldState.newWorld.provinces) {
    out['${p.regionId}|${p.id}'] = p.displayName ?? p.id;
  }
  return out;
}

/// Returns true if [unit] is a civilian (not military, not naval). SPEC/game/civilian-units.md.
bool _isCivilianUnit(Unit unit) {
  final role = unitRoleForType(unit.type);
  if (role == null) return false;
  return role != UnitRole.military && role != UnitRole.naval;
}

/// Civilian units for one region, sorted by province name then type then id.
List<Unit> _civilianUnitsInRegion(
  List<Unit> units,
  String humanPlayerId,
  Map<String, String> provinceNames,
) {
  final list = units
      .where(
        (u) =>
            u.ownerId == humanPlayerId &&
            u.tileKey != null &&
            _isCivilianUnit(u),
      )
      .toList();
  list.sort((a, b) {
    final provA = Unit.provinceIdFromTileKey(a.tileKey);
    final provB = Unit.provinceIdFromTileKey(b.tileKey);
    final regionA = Unit.regionIdFromTileKey(a.tileKey) ?? '';
    final regionB = Unit.regionIdFromTileKey(b.tileKey) ?? '';
    final prefixedA = '$regionA|$provA';
    final prefixedB = '$regionB|$provB';
    final nameA = provinceNames[prefixedA] ?? prefixedA;
    final nameB = provinceNames[prefixedB] ?? prefixedB;
    final nameCmp = nameA.compareTo(nameB);
    if (nameCmp != 0) return nameCmp;
    final typeCmp = a.type.compareTo(b.type);
    if (typeCmp != 0) return typeCmp;
    return a.id.compareTo(b.id);
  });
  return list;
}

/// Panel that lists all civilian units for the human player. SPEC/ui/civilian-units-panel.md.
class CivilianUnitsPanel extends StatelessWidget {
  const CivilianUnitsPanel({
    super.key,
    required this.game,
    required this.humanPlayerId,
    required this.bus,
    this.currentOrders = const Orders(),
    this.availableWorkTargets = const {},
    this.onAddWorkOrder,
  });

  final Game game;
  final String humanPlayerId;
  final AppEventBus bus;

  /// Current-turn orders (to show Assign only when no pending work, Cancel when pending or in-progress).
  final Orders currentOrders;

  /// Available work targets per unit (computed at turn start). Work targets not in this list are grayed out.
  final Map<String, List<String>> availableWorkTargets;

  final void Function(WorkOrder order)? onAddWorkOrder;

  @override
  Widget build(BuildContext context) {
    final provinceNames = _provinceNamesByPrefixedId(game);
    final ow = _civilianUnitsInRegion(
      game.worldState.oldWorld.units,
      humanPlayerId,
      provinceNames,
    );
    final nw = _civilianUnitsInRegion(
      game.worldState.newWorld.units,
      humanPlayerId,
      provinceNames,
    );
    final hasAny = ow.isNotEmpty || nw.isNotEmpty;

    return UnitsPanelShell(
      title: 'Civilian Units',
      actions: [
        CtNinePatchButton(
          onPressed: () {
            Navigator.of(context).maybePop();
            bus.emit(OpenDialogEvent(trainCiviliansDialogId));
          },
          child: const Text('Train'),
        ),
      ],
      hasContent: hasAny,
      listChildren: [
        if (ow.isNotEmpty) ...[
          RegionSectionHeader(label: unitsPanelRegionLabel('oldWorld')),
          ...ow.map(
            (u) => _UnitRow(
              unit: u,
              provinceNames: provinceNames,
              currentOrders: currentOrders,
              availableWorkTargets: availableWorkTargets,
              humanPlayerId: humanPlayerId,
              bus: bus,
              onAddWorkOrder: onAddWorkOrder,
            ),
          ),
        ],
        if (nw.isNotEmpty) ...[
          RegionSectionHeader(label: unitsPanelRegionLabel('newWorld')),
          ...nw.map(
            (u) => _UnitRow(
              unit: u,
              provinceNames: provinceNames,
              currentOrders: currentOrders,
              availableWorkTargets: availableWorkTargets,
              humanPlayerId: humanPlayerId,
              bus: bus,
              onAddWorkOrder: onAddWorkOrder,
            ),
          ),
        ],
      ],
      emptyMessage: 'No civilian units',
    );
  }
}

class _UnitRow extends StatelessWidget {
  const _UnitRow({
    required this.unit,
    required this.provinceNames,
    required this.currentOrders,
    required this.availableWorkTargets,
    required this.humanPlayerId,
    required this.bus,
    this.onAddWorkOrder,
  });

  final Unit unit;
  final Map<String, String> provinceNames;
  final Orders currentOrders;
  final Map<String, List<String>> availableWorkTargets;
  final String humanPlayerId;
  final AppEventBus bus;
  final void Function(WorkOrder order)? onAddWorkOrder;

  List<WorkOrder> get _pendingForPlayer =>
      currentOrders.workOrdersByPlayerId[humanPlayerId] ?? const [];

  bool get _hasPending => _pendingForPlayer.any((o) => o.unitId == unit.id);

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
      !_hasPending;

  bool get _hasWork => unit.currentWork != null || _hasPending;

  String _locationLabel() {
    final regionId = Unit.regionIdFromTileKey(unit.tileKey);
    final provinceId = Unit.provinceIdFromTileKey(unit.tileKey);
    if (regionId == null || provinceId == null) return '—';
    final prefixed = '$regionId|$provinceId';
    final name = provinceNames[prefixed] ?? prefixed;
    final regionLabel = unitsPanelRegionLabel(regionId);
    return '$regionLabel — $name';
  }

  String _assignedToLabel() {
    // Check for pending work orders first
    final pendingOrders = _pendingForPlayer;
    for (final order in pendingOrders) {
      if (order.unitId == unit.id) {
        final workLabel = _workTargetLabels[order.target] ?? order.target;
        final regionId = Unit.regionIdFromTileKey(order.targetTileKey);
        final provinceId = Unit.provinceIdFromTileKey(order.targetTileKey);
        String location = '';
        if (regionId != null && provinceId != null) {
          final name =
              provinceNames['$regionId|$provinceId'] ?? '$regionId|$provinceId';
          location = ' (${unitsPanelRegionLabel(regionId)} — $name)';
        }
        return '$workLabel$location (pending)';
      }
    }
    // Then check for in-progress work
    if (unit.status != UnitStatus.working || unit.currentWork == null) {
      return '—';
    }
    final cw = unit.currentWork!;
    final workLabel = _workTargetLabels[cw.workTarget] ?? cw.workTarget;
    final regionId = Unit.regionIdFromTileKey(cw.tileKey);
    final provinceId = Unit.provinceIdFromTileKey(cw.tileKey);
    String location = '';
    if (regionId != null && provinceId != null) {
      final name =
          provinceNames['$regionId|$provinceId'] ?? '$regionId|$provinceId';
      location = ' (${unitsPanelRegionLabel(regionId)} — $name)';
    }
    final progress = cw.totalTurns > 0
        ? ' ${cw.remainingTurns}/${cw.totalTurns} turns'
        : '';
    return '$workLabel$location$progress';
  }

  void _showOrderMenu(BuildContext context) {
    final allowed = workOrderTargetsByUnitType[unit.type];
    if (allowed == null || allowed.isEmpty) {
      return;
    }
    final available = availableWorkTargets[unit.id] ?? [];
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Assign work: ${unit.type}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            ...allowed.map(
              (target) => ListTile(
                title: Text(
                  _workTargetLabels[target] ?? target,
                  style: TextStyle(
                    color: available.contains(target)
                        ? null
                        : Theme.of(context).disabledColor,
                  ),
                ),
                enabled: available.contains(target),
                onTap: available.contains(target)
                    ? () {
                        Navigator.of(ctx).pop();
                        bus.emit(
                          StartCivilianWorkTargetSelectionEvent(
                            unitId: unit.id,
                            workTarget: target,
                          ),
                        );
                      }
                    : null,
              ),
            ),
          ],
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

  @override
  Widget build(BuildContext context) {
    final statusLabel = switch (unit.status) {
      UnitStatus.idle => 'Idle',
      UnitStatus.working => 'Working',
      UnitStatus.done => 'Done',
    };
    return ListTile(
      title: Text(unit.type),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Status: $statusLabel'),
          Text('Location: ${_locationLabel()}'),
          Text('Assigned to: ${_assignedToLabel()}'),
        ],
      ),
      dense: true,
      onTap: unit.tileKey == null
          ? null
          : () {
              final tileKey = unit.tileKey!;
              final regionId = Unit.regionIdFromTileKey(tileKey);
              if (regionId == null) return;
              bus.emit(
                LocateMapTileEvent(
                  tileKey: tileKey,
                  regionId: regionId,
                  closeCurrentPanel: true,
                ),
              );
            },
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isIdleNoPending)
            CtNinePatchButton(
              onPressed: () => _showOrderMenu(context),
              child: const Text('Assign'),
            ),
          if (_hasWork)
            CtNinePatchButton(
              onPressed: () => _confirmCancel(context),
              child: const Text('Cancel'),
            ),
        ],
      ),
    );
  }
}
