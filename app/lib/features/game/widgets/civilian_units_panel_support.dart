/// Human-readable label for work target ids. SPEC/ui/civilian-units-panel.md.

part of 'civilian_units_panel.dart';

const Map<String, String> _workTargetLabels = {
  kWorkTargetExplore: 'Explore',
  kWorkTargetProspect: 'Prospect',
  kWorkTargetBuildImprovement: 'Build improvement',
  kWorkTargetUpgradeTown: 'Upgrade town',
  kWorkTargetBuildRoad: 'Build road',
  kWorkTargetBuildPort: 'Build port',
  kWorkTargetBuildFort: 'Build fort',
  kWorkTargetBuildRail: 'Build rail',
  kWorkTargetStealTech: 'Steal tech',
  kWorkTargetCounterSpy: 'Counter spy',
  kWorkTargetPurchaseLand: 'Purchase land',
};

// Sort/partition helpers live in `civilian_units_sort.dart` (public surface):
// `provinceNamesByPrefixedId`, `isCivilianUnit`, `civilianUnitsInRegion`, and
// `civilianSortProvinceName`. They are imported by the panel library root
// (`civilian_units_panel.dart`) and visible here through the shared library
// scope. Refs #2575 (Phase 4 testability).

/// Pending assigned-to line plus optional cost strip. SPEC/ui/civilian-units-panel.md.
class _PendingAssignedResolution {
  const _PendingAssignedResolution({
    required this.mainLine,
    required this.totalTurns,
    this.materialCosts,
    this.treasuryAmount,
  });

  final String mainLine;
  final int totalTurns;
  final Map<String, int>? materialCosts;
  final int? treasuryAmount;
}

_PendingAssignedResolution _resolvePendingAssignedResolution(
  Game game,
  Unit unit,
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
  final totalTurns = previewTotalTurnsForPendingWorkOrder(
    game: game,
    unit: unit,
    order: order,
  );

  if (order.target == kWorkTargetPurchaseLand) {
    final resourceId = game.worldState.resourceByTileKey[order.targetTileKey];
    if (resourceId != null && resourceId.isNotEmpty) {
      return _PendingAssignedResolution(
        mainLine: base,
        totalTurns: totalTurns,
        treasuryAmount: purchaseLandCost(resourceId),
      );
    }
    return _PendingAssignedResolution(mainLine: base, totalTurns: totalTurns);
  }
  if (order.target == kWorkTargetStealTech ||
      order.target == kWorkTargetCounterSpy) {
    return _PendingAssignedResolution(mainLine: base, totalTurns: totalTurns);
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
    return _PendingAssignedResolution(
      mainLine: base,
      totalTurns: totalTurns,
      materialCosts: costMap,
    );
  }
  return _PendingAssignedResolution(mainLine: base, totalTurns: totalTurns);
}

List<MapEntry<String, int>> _sortedMaterialCostEntries(Map<String, int> m) {
  final list = m.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
  return list;
}

class _UnitRow extends ConsumerWidget {
  const _UnitRow({
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

  String _assignedToLabelNonPending(AppLocalizations l10n) {
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
    final pending = _pendingWorkOrder;
    if (pending != null) {
      final r = _resolvePendingAssignedResolution(
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
    return Text(
      l10n.civilian_units_assignedTo(_assignedToLabelNonPending(l10n)),
    );
  }

  void _showOrderMenu(
    BuildContext context,
    List<String> availableWorkTargetIds,
  ) {
    final allowed = workOrderTargetsByUnitType[unit.type];
    if (allowed == null || allowed.isEmpty) {
      return;
    }
    final available = availableWorkTargetIds;
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
    bus.emit(const ClosePanelEvent());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      bus.emit(
        UpsertPendingCivilianWorkOrderRequestedEvent(
          playerId: humanPlayerId,
          workOrder: WorkOrder(
            unitId: unit.id,
            target: workTarget,
            targetTileKey: targetTileKey,
          ),
        ),
      );
    });
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

  List<UnitsEntityAction> _buildRowActions(
    AppLocalizations l10n,
    BuildContext context, {
    required bool showActions,
    required bool inExplorerShortcutMode,
    required List<String> availableWorkTargetIds,
  }) {
    if (!showActions || readOnly) {
      return const <UnitsEntityAction>[];
    }
    return [
      if (_isIdleNoPending)
        UnitsEntityAction(
          tooltip: l10n.civilian_units_assign,
          icon: Icons.playlist_add,
          label: l10n.civilian_units_assign,
          onPressed: inExplorerShortcutMode
              ? () => _startShortcutAssign(availableWorkTargetIds)
              : () => _showOrderMenu(context, availableWorkTargetIds),
        ),
      if (_hasWork)
        UnitsEntityAction(
          tooltip: l10n.common_cancel,
          icon: Icons.cancel_outlined,
          label: l10n.common_cancel,
          onPressed: () => _confirmCancel(context),
        ),
    ];
  }

  Widget _buildTitleDetails(
    AppLocalizations l10n, {
    required String? tileKeyForLocate,
    required String? regionIdForLocate,
  }) {
    return Row(
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
    );
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
    bus.emit(const ClosePanelEvent());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      bus.emit(LocateMapTileEvent(tileKey: tileKey, regionId: regionId));
    });
  }

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
    final rowActions = _buildRowActions(
      l10n,
      context,
      showActions: showActions,
      inExplorerShortcutMode: inExplorerShortcutMode,
      availableWorkTargetIds: availableWorkTargetIds,
    );
    return ListTile(
      selected: isTileScope && isSelectedInTileScope,
      title: UnitsEntityActionRow(
        details: _buildTitleDetails(
          l10n,
          tileKeyForLocate: tileKeyForLocate,
          regionIdForLocate: regionIdForLocate,
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
      onTap: _handleRowTap,
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
