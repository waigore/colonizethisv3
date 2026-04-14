// Civilian units panel. SPEC/ui/civilian-units-panel.md.

import 'dart:async';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../config/ct_e2e.dart';
import '../../../config/ct_e2e_last_panel_snapshot.dart';
import '../../../core/services/app_event_handler_scope.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/ct_nine_patch_button.dart';
import '../../../widgets/resource_icon.dart';
import 'units/shared/region_section_header.dart';
import 'units/shared/units_entity_action_row.dart';
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
  Orders currentOrders,
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
    final tileA = projectedCivilianTileKey(
      unit: a,
      playerId: humanPlayerId,
      orders: currentOrders,
    );
    final tileB = projectedCivilianTileKey(
      unit: b,
      playerId: humanPlayerId,
      orders: currentOrders,
    );
    final provA = Unit.provinceIdFromTileKey(tileA);
    final provB = Unit.provinceIdFromTileKey(tileB);
    final regionA = Unit.regionIdFromTileKey(tileA) ?? '';
    final regionB = Unit.regionIdFromTileKey(tileB) ?? '';
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

/// Pending assigned-to line plus optional cost strip. SPEC/ui/civilian-units-panel.md.
class _PendingAssignedResolution {
  const _PendingAssignedResolution({
    required this.mainLine,
    this.materialCosts,
    this.treasuryAmount,
  });

  final String mainLine;
  final Map<String, int>? materialCosts;
  final int? treasuryAmount;
}

_PendingAssignedResolution _resolvePendingAssignedResolution(
  Game game,
  WorkOrder order,
  Map<String, String> provinceNames,
) {
  final workLabel = _workTargetLabels[order.target] ?? order.target;
  final regionId = Unit.regionIdFromTileKey(order.targetTileKey);
  final provinceId = Unit.provinceIdFromTileKey(order.targetTileKey);
  var location = '';
  if (regionId != null && provinceId != null) {
    final name =
        provinceNames['$regionId|$provinceId'] ?? '$regionId|$provinceId';
    location = ' (${unitsPanelRegionLabel(regionId)} — $name)';
  }
  final base = '$workLabel$location';

  if (order.target == kWorkTargetPurchaseLand) {
    final resourceId = game.worldState.resourceByTileKey[order.targetTileKey];
    if (resourceId != null && resourceId.isNotEmpty) {
      return _PendingAssignedResolution(
        mainLine: base,
        treasuryAmount: purchaseLandCost(resourceId),
      );
    }
    return _PendingAssignedResolution(mainLine: '$base (pending)');
  }
  if (order.target == kWorkTargetStealTech ||
      order.target == kWorkTargetCounterSpy) {
    return _PendingAssignedResolution(mainLine: '$base (pending)');
  }

  final targetProvinceId = Unit.provinceIdFromTileKey(order.targetTileKey);
  final province = targetProvinceId != null
      ? game.worldState.tryGetProvince(targetProvinceId)
      : null;

  final improvementLevel = order.target == kWorkTargetBuildImprovement
      ? game.worldState.tileState.improvementLevel(order.targetTileKey)
      : 0;
  final fortLevel = province?.fortLevel ?? 0;
  final roadLevel = game.worldState.tileState.roadLevel(order.targetTileKey);

  final costMap = WorkOrderCostCalculator(game).calculateCost(
    order.target,
    order.targetTileKey,
    improvementLevel: improvementLevel,
    fortLevel: fortLevel,
    roadLevel: roadLevel,
  );
  if (costMap != null && costMap.isNotEmpty) {
    return _PendingAssignedResolution(mainLine: base, materialCosts: costMap);
  }
  return _PendingAssignedResolution(mainLine: '$base (pending)');
}

List<MapEntry<String, int>> _sortedMaterialCostEntries(Map<String, int> m) {
  final list = m.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
  return list;
}

/// Panel that lists all civilian units for the human player. SPEC/ui/civilian-units-panel.md.
class CivilianUnitsPanel extends StatefulWidget {
  const CivilianUnitsPanel({
    super.key,
    required this.game,
    required this.humanPlayerId,
    required this.bus,
    this.currentOrders = const Orders(),
    this.availableWorkTargets = const {},
    this.tileScopeTileKey,
    this.initialSelectedUnitId,
  });

  final Game game;
  final String humanPlayerId;
  final AppEventBus bus;

  /// Current-turn orders (to show Assign only when no pending work, Cancel when pending or in-progress).
  final Orders currentOrders;

  /// Available work targets per unit (computed at turn start). Work targets not in this list are grayed out.
  final Map<String, List<String>> availableWorkTargets;

  /// Optional tile key (`regionId|provinceId|x|y`) for tile-scoped mode.
  final String? tileScopeTileKey;

  /// Optional initial selected unit in tile-scoped mode.
  final String? initialSelectedUnitId;

  @override
  State<CivilianUnitsPanel> createState() => _CivilianUnitsPanelState();
}

class _CivilianUnitsPanelState extends State<CivilianUnitsPanel> {
  String? _selectedUnitId;

  @override
  void initState() {
    super.initState();
    _selectedUnitId = widget.initialSelectedUnitId;
  }

  @override
  void didUpdateWidget(covariant CivilianUnitsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSelectedUnitId != widget.initialSelectedUnitId) {
      _selectedUnitId = widget.initialSelectedUnitId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final provinceNames = _provinceNamesByPrefixedId(widget.game);
    final ow = _civilianUnitsInRegion(
      widget.game.worldState.oldWorld.units,
      widget.humanPlayerId,
      provinceNames,
      widget.currentOrders,
    );
    final nw = _civilianUnitsInRegion(
      widget.game.worldState.newWorld.units,
      widget.humanPlayerId,
      provinceNames,
      widget.currentOrders,
    );
    List<Unit> scopedOw = ow;
    List<Unit> scopedNw = nw;
    final scopeTileKey = widget.tileScopeTileKey;
    final tileScopeActive = scopeTileKey != null && scopeTileKey.isNotEmpty;
    if (tileScopeActive) {
      scopedOw = ow
          .where(
            (u) =>
                projectedCivilianTileKey(
                  unit: u,
                  playerId: widget.humanPlayerId,
                  orders: widget.currentOrders,
                ) ==
                scopeTileKey,
          )
          .toList();
      scopedNw = nw
          .where(
            (u) =>
                projectedCivilianTileKey(
                  unit: u,
                  playerId: widget.humanPlayerId,
                  orders: widget.currentOrders,
                ) ==
                scopeTileKey,
          )
          .toList();
    }
    final hasAny = scopedOw.isNotEmpty || scopedNw.isNotEmpty;
    final allScopedUnits = <Unit>[...scopedOw, ...scopedNw];
    final selectedUnitId = _selectedUnitId;
    final resolvedSelectedUnitId =
        selectedUnitId != null &&
            allScopedUnits.any((u) => u.id == selectedUnitId)
        ? selectedUnitId
        : (allScopedUnits.isNotEmpty ? allScopedUnits.first.id : null);
    Unit? resolvedSelectedUnit;
    if (resolvedSelectedUnitId != null) {
      for (final u in allScopedUnits) {
        if (u.id == resolvedSelectedUnitId) {
          resolvedSelectedUnit = u;
          break;
        }
      }
    }
    final headerTileKey = resolvedSelectedUnit == null
        ? null
        : projectedCivilianTileKey(
            unit: resolvedSelectedUnit,
            playerId: widget.humanPlayerId,
            orders: widget.currentOrders,
          );

    final panel = UnitsPanelShell(
      title: tileScopeActive
          ? l10n.civilian_units_title_tile
          : l10n.civilian_units_title,
      actions: [
        if (tileScopeActive)
          CtNinePatchButton(
            enabled: headerTileKey != null && headerTileKey.isNotEmpty,
            onPressed: () {
              final key = headerTileKey;
              if (key == null || key.isEmpty) {
                return;
              }
              widget.bus.emit(const ClosePanelEvent());
              WidgetsBinding.instance.addPostFrameCallback((_) {
                widget.bus.emit(OpenMapTileDetailEvent(tileKey: key));
              });
            },
            child: Text(l10n.civilian_units_tile),
          ),
        CtNinePatchButton(
          onPressed: () {
            widget.bus.emit(const ClosePanelEvent());
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.bus.emit(OpenDialogEvent(trainCiviliansDialogId));
            });
          },
          child: Text(l10n.common_train),
        ),
      ],
      hasContent: hasAny,
      listChildren: [
        if (scopedOw.isNotEmpty) ...[
          RegionSectionHeader(label: unitsPanelRegionLabel('oldWorld')),
          ...scopedOw.map(
            (u) => _UnitRow(
              game: widget.game,
              unit: u,
              provinceNames: provinceNames,
              currentOrders: widget.currentOrders,
              availableWorkTargets: widget.availableWorkTargets,
              humanPlayerId: widget.humanPlayerId,
              bus: widget.bus,
              isTileScope: tileScopeActive,
              isSelectedInTileScope: resolvedSelectedUnitId == u.id,
              onSelectInTileScope: () => setState(() => _selectedUnitId = u.id),
              projectedTileKey: projectedCivilianTileKey(
                unit: u,
                playerId: widget.humanPlayerId,
                orders: widget.currentOrders,
              ),
            ),
          ),
        ],
        if (scopedNw.isNotEmpty) ...[
          RegionSectionHeader(label: unitsPanelRegionLabel('newWorld')),
          ...scopedNw.map(
            (u) => _UnitRow(
              game: widget.game,
              unit: u,
              provinceNames: provinceNames,
              currentOrders: widget.currentOrders,
              availableWorkTargets: widget.availableWorkTargets,
              humanPlayerId: widget.humanPlayerId,
              bus: widget.bus,
              isTileScope: tileScopeActive,
              isSelectedInTileScope: resolvedSelectedUnitId == u.id,
              onSelectInTileScope: () => setState(() => _selectedUnitId = u.id),
              projectedTileKey: projectedCivilianTileKey(
                unit: u,
                playerId: widget.humanPlayerId,
                orders: widget.currentOrders,
              ),
            ),
          ),
        ],
      ],
      emptyMessage: l10n.civilian_units_empty,
    );
    if (kCtE2EEnabled) {
      updateCtE2eCivilianPanelSnapshotIfEnabled(
        CtE2eCivilianPanelSnapshot(
          game: widget.game,
          humanPlayerId: widget.humanPlayerId,
          currentOrders: widget.currentOrders,
          availableWorkTargets: widget.availableWorkTargets,
          tileScopeTileKey: widget.tileScopeTileKey,
          initialSelectedUnitId: widget.initialSelectedUnitId,
          resolvedSelectedUnitId: resolvedSelectedUnitId,
        ),
      );
      return KeyedSubtree(key: kCtE2ECivilianPanelRootKey, child: panel);
    }
    return panel;
  }
}

class _UnitRow extends StatelessWidget {
  const _UnitRow({
    required this.game,
    required this.unit,
    required this.provinceNames,
    required this.currentOrders,
    required this.availableWorkTargets,
    required this.humanPlayerId,
    required this.bus,
    required this.isTileScope,
    required this.isSelectedInTileScope,
    required this.onSelectInTileScope,
    required this.projectedTileKey,
  });

  final Game game;
  final Unit unit;
  final Map<String, String> provinceNames;
  final Orders currentOrders;
  final Map<String, List<String>> availableWorkTargets;
  final String humanPlayerId;
  final AppEventBus bus;
  final bool isTileScope;
  final bool isSelectedInTileScope;
  final VoidCallback onSelectInTileScope;
  final String? projectedTileKey;

  List<WorkOrder> get _pendingForPlayer =>
      currentOrders.workOrdersByPlayerId[humanPlayerId] ?? const [];

  WorkOrder? get _pendingWorkOrder {
    for (final o in _pendingForPlayer) {
      if (o.unitId == unit.id) return o;
    }
    return null;
  }

  bool get _hasPending => _pendingWorkOrder != null;

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
    final regionId = Unit.regionIdFromTileKey(projectedTileKey);
    final provinceId = Unit.provinceIdFromTileKey(projectedTileKey);
    if (regionId == null || provinceId == null) return '—';
    final prefixed = '$regionId|$provinceId';
    final name = provinceNames[prefixed] ?? prefixed;
    final regionLabel = unitsPanelRegionLabel(regionId);
    return '$regionLabel — $name';
  }

  String _assignedToLabelNonPending() {
    if (unit.status != UnitStatus.working || unit.currentWork == null) {
      return '—';
    }
    final cw = unit.currentWork!;
    final workLabel = _workTargetLabels[cw.workTarget] ?? cw.workTarget;
    final regionId = Unit.regionIdFromTileKey(cw.tileKey);
    final provinceId = Unit.provinceIdFromTileKey(cw.tileKey);
    var location = '';
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

  Widget _buildAssignedToSubtitle(AppLocalizations l10n) {
    final pending = _pendingWorkOrder;
    if (pending != null) {
      final r = _resolvePendingAssignedResolution(game, pending, provinceNames);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.civilian_units_assignedTo(r.mainLine)),
          if (r.materialCosts != null && r.materialCosts!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final e in _sortedMaterialCostEntries(r.materialCosts!))
                    _AssignedCostChip(
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
              child: _AssignedCostChip(
                child: Text(
                  l10n.trainUnits_treasury(r.treasuryAmount!.toString()),
                ),
              ),
            ),
        ],
      );
    }
    return Text(l10n.civilian_units_assignedTo(_assignedToLabelNonPending()));
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
                appL10n(context).civilian_assignWorkTitle(unit.type),
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
                        bus.emit(const ClosePanelEvent());
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          bus.emit(
                            StartCivilianWorkTargetSelectionEvent(
                              unitId: unit.id,
                              workTarget: target,
                            ),
                          );
                        });
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
    final l10n = appL10n(context);
    final statusLabel = switch (unit.status) {
      UnitStatus.idle => l10n.province_unitStatus_idle,
      UnitStatus.working => l10n.province_unitStatus_working,
    };
    final showActions = !isTileScope || isSelectedInTileScope;
    final tileKeyForLocate = projectedTileKey;
    final regionIdForLocate = Unit.regionIdFromTileKey(tileKeyForLocate);
    final rowActions = showActions
        ? [
            if (_isIdleNoPending)
              UnitsEntityAction(
                tooltip: l10n.civilian_units_assign,
                icon: Icons.playlist_add,
                label: l10n.civilian_units_assign,
                onPressed: () => _showOrderMenu(context),
              ),
            if (_hasWork)
              UnitsEntityAction(
                tooltip: l10n.common_cancel,
                icon: Icons.cancel_outlined,
                label: l10n.common_cancel,
                onPressed: () => _confirmCancel(context),
              ),
          ]
        : const <UnitsEntityAction>[];
    return ListTile(
      selected: isTileScope && isSelectedInTileScope,
      title: UnitsEntityActionRow(
        details: Row(
          children: [
            Expanded(child: Text(unit.type, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 4),
            IconButton(
              tooltip: l10n.common_locate,
              onPressed:
                  tileKeyForLocate != null &&
                      tileKeyForLocate.isNotEmpty &&
                      regionIdForLocate != null
                  ? () {
                      bus.emit(
                        LocateMapTileEvent(
                          tileKey: tileKeyForLocate,
                          regionId: regionIdForLocate,
                        ),
                      );
                    }
                  : null,
              icon: const Icon(Icons.my_location),
              iconSize: 18,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        actions: rowActions,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.civilian_units_status(statusLabel)),
          Text(l10n.civilian_units_location(_locationLabel())),
          _buildAssignedToSubtitle(l10n),
        ],
      ),
      dense: true,
      onTap: () {
        if (isTileScope) {
          onSelectInTileScope();
          return;
        }
        final tileKey = projectedTileKey;
        if (tileKey == null) return;
        final regionId = Unit.regionIdFromTileKey(tileKey);
        if (regionId == null) return;
        bus.emit(const ClosePanelEvent());
        WidgetsBinding.instance.addPostFrameCallback((_) {
          bus.emit(LocateMapTileEvent(tileKey: tileKey, regionId: regionId));
        });
      },
    );
  }
}

/// Dense chip matching training cost rows (`train_military_dialog`). SPEC/ui/civilian-units-panel.md.
class _AssignedCostChip extends StatelessWidget {
  const _AssignedCostChip({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: child,
      ),
    );
  }
}
