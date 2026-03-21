// Civilian units panel. SPEC/ui/civilian-units-panel.md.

import 'dart:async';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../widgets/ct_dialog_shell.dart';
import '../../../widgets/ct_nine_patch_button.dart';
import '../../../widgets/ct_panel.dart';

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

/// Region id to display label. SPEC/ui/civilian-units-panel.md.
String _regionLabel(String regionId) {
  switch (regionId) {
    case 'oldWorld':
      return 'Old World';
    case 'newWorld':
      return 'New World';
    default:
      return regionId;
  }
}

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
    this.onLocateUnit,
    this.onAddWorkOrder,
    this.onRemoveWorkOrder,
    this.onCancelUnitWork,
    this.onStartWorkTargetSelection,
    this.onTrainPressed,
  });

  final Game game;
  final String humanPlayerId;
  final AppEventBus bus;

  /// Current-turn orders (to show Assign only when no pending work, Cancel when pending or in-progress).
  final Orders currentOrders;

  /// Available work targets per unit (computed at turn start). Work targets not in this list are grayed out.
  final Map<String, List<String>> availableWorkTargets;

  /// Called when the user taps a unit row; [unit] has non-null [Unit.tileKey].
  final void Function(Unit unit)? onLocateUnit;
  final void Function(WorkOrder order)? onAddWorkOrder;
  final void Function(String playerId, int index)? onRemoveWorkOrder;
  final void Function(String unitId)? onCancelUnitWork;

  /// Called when user picked an order from the Assign menu; shell enters work-target selection mode.
  final void Function(Unit unit, String workTarget)? onStartWorkTargetSelection;

  /// Called when the user taps the Train button. The callback receives [dialogContext]
  /// which should be used to show the Train dialog.
  final void Function(BuildContext dialogContext)? onTrainPressed;

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

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: CtPanel(
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Civilian Units',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (onTrainPressed != null)
                      CtNinePatchButton(
                        onPressed: () => onTrainPressed!(context),
                        child: const Text('Train'),
                      ),
                  ],
                ),
              ),
              Flexible(
                child: hasAny
                    ? ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                        children: [
                          if (ow.isNotEmpty) ...[
                            _RegionHeader(label: _regionLabel('oldWorld')),
                            ...ow.map(
                              (u) => _UnitRow(
                                unit: u,
                                provinceNames: provinceNames,
                                currentOrders: currentOrders,
                                availableWorkTargets: availableWorkTargets,
                                humanPlayerId: humanPlayerId,
                                bus: bus,
                                onTap: onLocateUnit != null && u.tileKey != null
                                    ? () => onLocateUnit!(u)
                                    : null,
                                onAddWorkOrder: onAddWorkOrder,
                                onRemoveWorkOrder: onRemoveWorkOrder,
                                onCancelUnitWork: onCancelUnitWork,
                                onStartWorkTargetSelection:
                                    onStartWorkTargetSelection,
                              ),
                            ),
                          ],
                          if (nw.isNotEmpty) ...[
                            _RegionHeader(label: _regionLabel('newWorld')),
                            ...nw.map(
                              (u) => _UnitRow(
                                unit: u,
                                provinceNames: provinceNames,
                                currentOrders: currentOrders,
                                availableWorkTargets: availableWorkTargets,
                                humanPlayerId: humanPlayerId,
                                bus: bus,
                                onTap: onLocateUnit != null && u.tileKey != null
                                    ? () => onLocateUnit!(u)
                                    : null,
                                onAddWorkOrder: onAddWorkOrder,
                                onRemoveWorkOrder: onRemoveWorkOrder,
                                onCancelUnitWork: onCancelUnitWork,
                                onStartWorkTargetSelection:
                                    onStartWorkTargetSelection,
                              ),
                            ),
                          ],
                        ],
                      )
                    : Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'No civilian units',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegionHeader extends StatelessWidget {
  const _RegionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
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
    this.onTap,
    this.onAddWorkOrder,
    this.onRemoveWorkOrder,
    this.onCancelUnitWork,
    this.onStartWorkTargetSelection,
  });

  final Unit unit;
  final Map<String, String> provinceNames;
  final Orders currentOrders;
  final Map<String, List<String>> availableWorkTargets;
  final String humanPlayerId;
  final AppEventBus bus;
  final VoidCallback? onTap;
  final void Function(WorkOrder order)? onAddWorkOrder;
  final void Function(String playerId, int index)? onRemoveWorkOrder;
  final void Function(String unitId)? onCancelUnitWork;
  final void Function(Unit unit, String workTarget)? onStartWorkTargetSelection;

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
    final regionLabel = _regionLabel(regionId);
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
          location = ' (${_regionLabel(regionId)} — $name)';
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
      location = ' (${_regionLabel(regionId)} — $name)';
    }
    final progress = cw.totalTurns > 0
        ? ' ${cw.remainingTurns}/${cw.totalTurns} turns'
        : '';
    return '$workLabel$location$progress';
  }

  void _showOrderMenu(BuildContext context) {
    final allowed = workOrderTargetsByUnitType[unit.type];
    if (allowed == null ||
        allowed.isEmpty ||
        onStartWorkTargetSelection == null) {
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
                        onStartWorkTargetSelection!(unit, target);
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
    if (idx != null && onRemoveWorkOrder != null) {
      onRemoveWorkOrder!(humanPlayerId, idx);
    } else if (unit.currentWork != null && onCancelUnitWork != null) {
      onCancelUnitWork!(unit.id);
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
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isIdleNoPending && onStartWorkTargetSelection != null)
            CtNinePatchButton(
              onPressed: () => _showOrderMenu(context),
              child: const Text('Assign'),
            ),
          if (_hasWork &&
              (onRemoveWorkOrder != null || onCancelUnitWork != null))
            CtNinePatchButton(
              onPressed: () => _confirmCancel(context),
              child: const Text('Cancel'),
            ),
        ],
      ),
    );
  }
}
